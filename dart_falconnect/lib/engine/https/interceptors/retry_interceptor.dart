import 'dart:async';
import 'dart:math';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
import 'package:dart_falmodel/networks/https/retry_after.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:dio/dio.dart';

const String _disableKey = 'dart_falconnect.retry.disable';
const String _attemptsKey = 'dart_falconnect.retry.attempts';
const String _nonIdempotentKey = 'dart_falconnect.retry.nonIdempotent';
const String _attemptKey = 'dart_falconnect.retry.attempt';

/// Called before each retry waits.
///
/// [attempt] is 1 for the first retry. The stack trace of the failure is
/// `error.stackTrace`.
typedef RetryCallback = void Function(
  DioException error,
  int attempt,
  Duration delay,
);

/// Per-request retry settings on [RequestOptions].
extension FalconRetryRequestOptionsExtensions on RequestOptions {
  /// Whether [RetryInterceptor] leaves this request alone.
  bool get disableRetry => extra[_disableKey] == true;
  set disableRetry(bool value) => extra = {...extra, _disableKey: value};

  /// Most retries for this request; null uses
  /// `HttpClientConfig.maxRetryAttempts`.
  int? get retryAttempts => extra[_attemptsKey] as int?;
  set retryAttempts(int? value) =>
      extra = {...extra, _attemptsKey: _checkAttempts(value)};

  /// Whether a `POST` or `PATCH` may be retried in the cases limited to
  /// idempotent methods.
  bool get retryNonIdempotent => extra[_nonIdempotentKey] == true;
  set retryNonIdempotent(bool value) =>
      extra = {...extra, _nonIdempotentKey: value};

  /// 0 for the original request, 1 for the first retry, and so on.
  int get retryAttempt => (extra[_attemptKey] as int?) ?? 0;
}

/// Per-request retry settings on [Options].
extension FalconRetryOptionsExtensions on Options {
  /// Whether [RetryInterceptor] leaves this request alone.
  bool get disableRetry => extra?[_disableKey] == true;
  set disableRetry(bool value) => extra = {...?extra, _disableKey: value};

  /// Most retries for this request; null uses
  /// `HttpClientConfig.maxRetryAttempts`.
  int? get retryAttempts => extra?[_attemptsKey] as int?;
  set retryAttempts(int? value) =>
      extra = {...?extra, _attemptsKey: _checkAttempts(value)};

  /// Whether a `POST` or `PATCH` may be retried in the cases limited to
  /// idempotent methods.
  bool get retryNonIdempotent => extra?[_nonIdempotentKey] == true;
  set retryNonIdempotent(bool value) =>
      extra = {...?extra, _nonIdempotentKey: value};
}

int? _checkAttempts(int? value) {
  if (value != null && value < 0) {
    throw ArgumentError.value(value, 'retryAttempts', 'must not be negative');
  }
  return value;
}

/// Retries failed requests with backoff, honouring `Retry-After`.
///
/// Every attempt is sent with `dio.fetch`, so it passes the whole
/// interceptor chain again: a rate limiter placed before this interceptor
/// holds retries to a paused host, and the total wait is the longer of the
/// retry delay and the pause, never their sum.
///
/// A 429 or a `connectionTimeout` is retried for every method, because the
/// server did not act on the request. Timeouts, connection errors, 408,
/// 409, and 5xx are retried only for `GET`, `HEAD`, `OPTIONS`, `PUT`,
/// `DELETE`, and `TRACE`, unless the request sets `retryNonIdempotent`. A
/// cancelled request, a local 429, a `Stream` body, and a bad certificate
/// are never retried.
///
/// A 429 or 503 with `Retry-After` waits that long, and is not retried when
/// it exceeds `maxRetryDelay`. Other failures wait a random time between
/// zero and `min(maxRetryDelay, retryDelay * 2^(attempt - 1))`. No retry is
/// sent when its delay would end past `maxRetryDuration`.
///
/// Error interceptors see the error of every attempt. Placed before this
/// interceptor, one sees each attempt exactly once, with a distinct
/// `requestOptions.retryAttempt`. Placed after it, one sees attempts
/// 1..n from inside the retries plus the final error again, so it reports
/// the last failure twice; place error loggers and crash reporters before
/// this interceptor.
class RetryInterceptor extends Interceptor {
  /// Creates a retry interceptor.
  ///
  /// [random] drives the backoff jitter; tests pass a seeded one.
  new({required this.config, required this.dio, this.onRetry, Random? random})
    : _random = random ?? Random();

  /// Configuration: `maxRetryAttempts`, `retryDelay`, `maxRetryDelay`,
  /// `maxRetryDuration`, and `enableLogging`.
  final HttpClientConfig config;

  /// The [Dio] instance that sends every retry.
  final Dio dio;

  /// Called before each retry waits.
  final RetryCallback? onRetry;

  final Random _random;

  static const Set<String> _idempotentMethods = {
    'GET',
    'HEAD',
    'OPTIONS',
    'PUT',
    'DELETE',
    'TRACE',
  };

  /// Largest argument `Random.nextInt` accepts, 2^32. A literal, not
  /// `1 << 32`: shifts are 32-bit on the web.
  static const int _maxRandomRange = 4294967296;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final original = err.requestOptions;
    if (original.retryAttempt > 0) {
      // A nested attempt: the loop that sent it decides what comes next.
      handler.next(err);
      return;
    }
    final started = clock.now();
    var current = err;
    for (var attempt = 1; ; attempt++) {
      final delay = _delayFor(
        current,
        attempt,
        clock.now().difference(started),
      );
      if (delay == null) {
        handler.next(current);
        return;
      }
      onRetry?.call(current, attempt, delay);
      _log(
        'Retrying request $attempt after ${delay.inMilliseconds}ms: '
        '${original.method} ${original.uri}',
      );
      if (!await _wait(delay, original.cancelToken)) {
        handler.next(current);
        return;
      }
      final RequestOptions options;
      try {
        options = _attemptOptions(original, attempt);
      } on Object {
        // A FormData whose files cannot be read again.
        handler.next(current);
        return;
      }
      try {
        // dynamic keeps the caller's responseType; any other type argument
        // makes dio overwrite it.
        final response = await dio.fetch<dynamic>(options);
        handler.resolve(response);
        return;
      } on DioException catch (error) {
        current = error;
      }
    }
  }

  /// Returns the wait before retry number [attempt], or null to stop.
  Duration? _delayFor(DioException err, int attempt, Duration elapsed) {
    if (!_isRetryable(err, attempt)) {
      return null;
    }
    final status = err.response?.statusCode;
    final retryAfter = status == 429 || status == 503
        ? err.response?.headers.retryAfter
        : null;
    final Duration delay;
    if (retryAfter != null) {
      if (retryAfter > config.maxRetryDelay) {
        return null;
      }
      delay = retryAfter;
    } else {
      delay = _backoff(attempt);
    }
    if (elapsed + delay > config.maxRetryDuration) {
      return null;
    }
    return delay;
  }

  bool _isRetryable(DioException err, int attempt) {
    final options = err.requestOptions;
    final response = err.response;
    if (options.disableRetry ||
        err.type == DioExceptionType.cancel ||
        (options.cancelToken?.isCancelled ?? false) ||
        (response?.isLocalRateLimit ?? false) ||
        options.data is Stream ||
        err.type == DioExceptionType.badCertificate) {
      return false;
    }
    if (attempt > (options.retryAttempts ?? config.maxRetryAttempts)) {
      return false;
    }
    final status = response?.statusCode;
    if (status == 429 || err.type == DioExceptionType.connectionTimeout) {
      return true;
    }
    final transient =
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        status == 408 ||
        status == 409 ||
        (status != null && status >= 500 && status < 600);
    return transient &&
        (_idempotentMethods.contains(options.method.toUpperCase()) ||
            options.retryNonIdempotent);
  }

  Duration _backoff(int attempt) {
    // Doubles never wrap, and 2^30 keeps the result exact on the web.
    final exponential =
        config.retryDelay.inMilliseconds * pow(2.0, min(attempt - 1, 30));
    final cap = max(
      0,
      min(config.maxRetryDelay.inMilliseconds, exponential).toInt(),
    );
    return Duration(
      milliseconds: _random.nextInt(min(cap + 1, _maxRandomRange)),
    );
  }

  /// Waits [delay]; returns false at once when [cancelToken] cancels.
  Future<bool> _wait(Duration delay, CancelToken? cancelToken) {
    if (cancelToken?.isCancelled ?? false) {
      return Future.value(false);
    }
    final done = Completer<bool>();
    void Function()? unwatch;
    final timer = Timer(delay, () {
      unwatch?.call();
      if (!done.isCompleted) done.complete(true);
    });
    if (cancelToken != null) {
      unwatch = watchCancel(cancelToken, (_) {
        timer.cancel();
        if (!done.isCompleted) done.complete(false);
      });
    }
    return done.future;
  }

  RequestOptions _attemptOptions(RequestOptions original, int attempt) {
    final data = original.data;
    return original.copyWith(
      data: data is FormData ? data.clone() : data,
      extra: {...original.extra, _attemptKey: attempt},
    );
  }

  void _log(String message) {
    if (config.enableLogging) {
      // Intentional logging for retry diagnostics.
      // ignore: avoid_print
      print('[RetryInterceptor] $message');
    }
  }
}
