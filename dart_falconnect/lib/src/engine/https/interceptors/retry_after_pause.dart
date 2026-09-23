import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falmodel/networks/https/retry_after.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:dio/dio.dart';

/// Key in `Response.extra` that marks a 429 built on the client.
const String localRateLimitKey = 'dart_falconnect.localRateLimit';

/// Builds the 429 that `TokenBucketRateLimitInterceptor` and
/// `RetryAfterPauseInterceptor` reject with.
///
/// [error] is the cause (a `RateLimitExceededException` when a queue is
/// full). [retryAfter] is the remaining pause; when given, it becomes a
/// `Retry-After` header in whole seconds, rounded up, at least 1.
DioException localRateLimitRejection(
  RequestOptions options, {
  Object? error,
  Duration? retryAfter,
}) {
  final headers = <String, List<String>>{};
  if (retryAfter != null) {
    const second = Duration.microsecondsPerSecond;
    final seconds = (retryAfter.inMicroseconds + second - 1) ~/ second;
    headers['retry-after'] = ['${math.max(1, seconds)}'];
  }
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    error: error,
    message: 'Rate limited locally for ${options.uri.host}',
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: 429,
      statusMessage: 'Too Many Requests',
      headers: Headers.fromMap(headers),
      extra: {localRateLimitKey: true},
    ),
  );
}

/// What a paused host does with a request.
sealed class PauseAdmission {
  const new();
}

/// The host is not paused: the request may go on.
final class PausePass extends PauseAdmission {
  const new();
}

/// The host is paused briefly: the request waits for the pause to end.
final class PauseHold extends PauseAdmission {
  const new();
}

/// The host is paused too long, or its hold queue is full.
final class PauseReject extends PauseAdmission {
  const new(this.remaining);

  /// Time left until the pause ends.
  final Duration remaining;
}

/// Per-host pauses started by 429 and 503 responses.
///
/// A pause is stored as an end time read from `clock.now()`. A `Timer`
/// exists only while a host has held requests, so a long pause with nobody
/// waiting keeps no timer alive. A pause extension past [maxPauseWait]
/// releases every held request instead of rescheduling, so a held request
/// waits at most about [maxPauseWait] from admission.
class RetryAfterPause {
  /// Creates the pause state shared by the rate-limit interceptors.
  new({
    required this.maxPauseWait,
    required this.maxPause,
    required this.defaultPause,
    required this.maxHeld,
    required this.holdRequests,
  }) {
    if (maxPauseWait.isNegative) {
      throw ArgumentError.value(
        maxPauseWait,
        'maxPauseWait',
        'must not be negative',
      );
    }
    if (maxPause <= Duration.zero) {
      throw ArgumentError.value(maxPause, 'maxPause', 'must be positive');
    }
    final fallback = defaultPause;
    if (fallback != null && fallback <= Duration.zero) {
      throw ArgumentError.value(
        fallback,
        'defaultPause',
        'must be positive or null',
      );
    }
    if (maxHeld < 0) {
      throw ArgumentError.value(maxHeld, 'maxHeld', 'must not be negative');
    }
  }

  /// Longest remaining pause a request waits out instead of failing.
  final Duration maxPauseWait;

  /// Longest pause any response can start.
  final Duration maxPause;

  /// Pause for a 429 without a readable `Retry-After`; null means none.
  final Duration? defaultPause;

  /// Most requests held per host.
  final int maxHeld;

  /// Whether a briefly paused host holds requests (`true`) or rejects them.
  final bool holdRequests;

  final Map<String, DateTime> _until = {};
  final Map<String, _Held> _held = {};
  bool _disposed = false;

  /// Decides what happens to a request for [host] right now.
  PauseAdmission admit(String host) {
    final remaining = _remaining(host);
    if (remaining == null) {
      return const PausePass();
    }
    final held = _held[host]?.waiters.length ?? 0;
    if (holdRequests && remaining <= maxPauseWait && held < maxHeld) {
      return const PauseHold();
    }
    return PauseReject(remaining);
  }

  /// Whether [host] is paused at this moment.
  bool isPaused(String host) => _remaining(host) != null;

  /// Completes when the pause of [host] ends.
  ///
  /// Fails with the cancel error when [cancelToken] cancels, and with a
  /// [StateError] when [dispose] runs.
  Future<void> wait(String host, CancelToken? cancelToken) {
    if (_disposed) {
      return Future.error(StateError('RetryAfterPause disposed'));
    }
    final held = _held.putIfAbsent(host, _Held.new);
    final waiter = Completer<void>();
    held.waiters.add(waiter);
    _schedule(host, held);
    if (cancelToken != null) {
      unawaited(
        cancelToken.whenCancel.then((error) {
          if (held.waiters.remove(waiter)) {
            waiter.completeError(error);
            if (held.waiters.isEmpty) {
              held.timer?.cancel();
              _held.remove(host);
            }
          }
        }),
      );
    }
    return waiter.future;
  }

  /// Starts or extends a pause from a server response.
  ///
  /// A 429 pauses for its `Retry-After`, else for [defaultPause]; a 503
  /// pauses only for its `Retry-After`. A local 429 starts nothing. Every
  /// pause is clamped to [maxPause] and never shortens an existing one.
  void observe(Response<dynamic> response) {
    if (_disposed || response.isLocalRateLimit) {
      return;
    }
    final length = switch (response.statusCode) {
      429 => response.headers.retryAfter ?? defaultPause,
      503 => response.headers.retryAfter,
      _ => null,
    };
    if (length == null || length <= Duration.zero) {
      return;
    }
    final host = response.requestOptions.uri.host;
    final until = clock.now().add(length > maxPause ? maxPause : length);
    final current = _until[host];
    if (current == null || until.isAfter(current)) {
      _until[host] = until;
    }
  }

  /// Requests held per host.
  Map<String, int> get heldByHost => Map.unmodifiable({
    for (final entry in _held.entries) entry.key: entry.value.waiters.length,
  });

  /// End time of every active pause, per host.
  Map<String, DateTime> get pausedUntilByHost {
    final now = clock.now();
    return Map.unmodifiable({
      for (final entry in _until.entries)
        if (entry.value.isAfter(now)) entry.key: entry.value,
    });
  }

  /// Fails every held request, cancels the timers, and forgets every
  /// pause. Afterwards [admit] always passes and [observe] does nothing.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _until.clear();
    for (final held in _held.values) {
      held.timer?.cancel();
      while (held.waiters.isNotEmpty) {
        held.waiters.removeFirst().completeError(
          StateError('RetryAfterPause disposed'),
        );
      }
    }
    _held.clear();
  }

  Duration? _remaining(String host) {
    final until = _until[host];
    if (until == null) {
      return null;
    }
    final remaining = until.difference(clock.now());
    if (remaining > Duration.zero) {
      return remaining;
    }
    _until.remove(host);
    return null;
  }

  void _schedule(String host, _Held held) {
    held.timer?.cancel();
    final remaining = _remaining(host) ?? Duration.zero;
    held.timer = Timer(remaining, () => _release(host));
  }

  void _release(String host) {
    final held = _held[host];
    if (held == null) {
      return;
    }
    held.timer = null;
    final remaining = _remaining(host);
    if (remaining != null && remaining <= maxPauseWait) {
      // A later response extended the pause while requests were held, and
      // the extension is still short enough to wait out.
      _schedule(host, held);
      return;
    }
    _held.remove(host);
    while (held.waiters.isNotEmpty) {
      held.waiters.removeFirst().complete();
    }
  }
}

class _Held {
  final Queue<Completer<void>> waiters = Queue<Completer<void>>();
  Timer? timer;
}
