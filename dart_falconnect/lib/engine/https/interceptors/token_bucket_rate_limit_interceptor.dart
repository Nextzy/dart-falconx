import 'package:dart_falconnect/engine/https/config/rate_limit_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/models/token_bucket_rate_limit_statistics.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/host_key.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart';
import 'package:dart_faltool/dart_faltool.dart'
    show
        RateLimitExceededException,
        RateLimiter,
        ResiliencePipeline,
        TokenBucketPolicy,
        clock;
import 'package:dio/dio.dart';

/// Limits outgoing requests with token buckets built on `resilience`, and
/// pauses a host after it answers 429, or 503 with `Retry-After`.
///
/// Every request passes all tiers of its host, then all `global` tiers.
/// A host's tiers come from `hosts[host]` when that key exists, otherwise
/// from `perHost`. A scope with no policy has no token limit: a request to
/// a host whose tiers and the global tiers are all empty is forwarded
/// synchronously and creates no limiter, unless the host is paused.
///
/// Each [TokenBucketPolicy] guarantees at most `permits` requests in any
/// window of `per`. Refills are driven by `Timer`, not by reading the
/// clock: `fakeAsync`'s `elapse` advances them, and
/// `withClock(Clock.fixed(...))` has no effect on them.
///
/// A 429 pauses its host for its `Retry-After`, else for `defaultPause`;
/// a 503 pauses only for its `Retry-After`. Every pause is clamped to
/// `maxPause`, and applies to hosts without a policy too. While a host is
/// paused, a request waits when the remaining pause is at most
/// `maxPauseWait`, `queueRequests` is true, and fewer than `maxQueueSize`
/// requests already wait; otherwise it fails with a local 429. A request
/// that gets its tokens while its host is paused spends them and waits
/// again, so the ceiling also holds after a pause. This class contains
/// everything `RetryAfterPauseInterceptor` does; do not add both.
///
/// A local 429, for a full queue or a paused host, has type
/// `DioExceptionType.badResponse`, answers `isLocalRateLimit`, and goes
/// through every error interceptor, so callers get the same
/// `NetworkLimitExceededException` as for a server 429. Place this
/// interceptor before `RetryInterceptor` and before the network exception
/// handler.
///
/// Tokens are never returned. When a later tier rejects a request, tokens
/// already taken by earlier tiers stay spent. A request cancelled through
/// its `CancelToken` while it waits for tokens keeps its queue place and
/// still spends a token, but it is neither forwarded nor counted.
///
/// Each host gets its own buckets on its first request. When a new host
/// arrives, the interceptor forgets every idle host whose buckets are full
/// again, so the number of remembered hosts stays bounded by recent traffic.
///
/// Refill timers keep running until every bucket is full again. Call
/// [dispose] at the end of a `testWidgets` body (`addTearDown` runs after
/// Flutter's pending-timer check), before a CLI's `main` returns, or when a
/// scoped client is discarded. A long-lived app or server client needs no
/// call. On a server, build one interceptor per process: a new instance per
/// request starts with full buckets and limits nothing.
class TokenBucketRateLimitInterceptor extends Interceptor {
  /// Creates a token bucket rate limit interceptor.
  ///
  /// Each key of `config.hosts` must be a bare host exactly as `Uri.host`
  /// returns it: lowercase, with no port, brackets, or spaces.
  new({this.config = const TokenBucketRateLimitConfig(), this.logPrint})
    : _perHost = List.unmodifiable(config.perHost),
      _hosts = Map.unmodifiable({
        for (final entry in config.hosts.entries)
          entry.key: List<TokenBucketPolicy>.unmodifiable(entry.value),
      }),
      _globalLimiters = [
        for (final policy in config.global)
          policy.toRateLimiter(
            maxQueueLength: config.queueRequests
                ? config.maxGlobalQueueSize
                : 0,
          ),
      ],
      _pause = _buildPause(
        maxPauseWait: config.pause.maxPauseWait,
        maxPause: config.pause.maxPause,
        defaultPause: config.pause.defaultPause,
        maxQueueSize: config.maxQueueSize,
        holdRequests: config.queueRequests,
      ) {
    for (final host in config.hosts.keys) {
      if (!isHostKey(host)) {
        throw ArgumentError.value(
          host,
          'hosts',
          'keys must be bare lowercase hosts, as Uri.host returns them',
        );
      }
    }
    for (final policy in [
      ...config.perHost,
      ...config.hosts.values.expand((p) => p),
    ]) {
      policy.validate();
    }
  }

  /// Policies, queue sizes, and pause settings.
  final TokenBucketRateLimitConfig config;

  /// Prints diagnostics; null prints nothing.
  final void Function(String message)? logPrint;

  /// Whether a request with no token, or to a briefly paused host, waits
  /// (`true`) or is rejected.
  bool get queueRequests => config.queueRequests;

  /// Wait-queue capacity of each host tier, and of each host's pause.
  int get maxQueueSize => config.maxQueueSize;

  /// Wait-queue capacity of each global tier.
  int get maxGlobalQueueSize => config.maxGlobalQueueSize;

  final List<TokenBucketPolicy> _perHost;
  final Map<String, List<TokenBucketPolicy>> _hosts;
  final List<RateLimiter> _globalLimiters;
  final RetryAfterPause _pause;
  final Map<String, _HostBuckets> _buckets = {};

  /// Idle hosts are swept at most this often: the longest time any host's
  /// buckets need to refill, so a sweep can find something to forget.
  late final Duration _sweepInterval = [
    for (final policy in [..._perHost, ..._hosts.values.expand((p) => p)])
      _refillTime(policy.toRateLimiter()),
  ].fold(Duration.zero, _longer);
  DateTime? _lastSweep;
  int _forwarded = 0;
  int _rejected = 0;
  bool _disposed = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final host = options.uri.host;
    final hostPolicies = _hosts[host] ?? _perHost;
    final unlimited = hostPolicies.isEmpty && _globalLimiters.isEmpty;
    while (true) {
      final admission = _pause.admit(host);
      if (admission is PauseReject) {
        _rejected++;
        _log('Paused host $host rejected a request');
        handler.reject(
          localRateLimitRejection(options, retryAfter: admission.remaining),
          true,
        );
        return;
      }
      if (admission is PauseHold) {
        try {
          await _pause.wait(host, options.cancelToken);
        } on Object catch (error) {
          handler.reject(_cancelled(options, error, 'Request cancelled'));
          return;
        }
        continue;
      }
      if (unlimited) {
        _forwarded++;
        handler.next(options);
        return;
      }
      if (_disposed) {
        handler.reject(
          _cancelled(
            options,
            StateError('RateLimiter disposed'),
            'Rate limiter disposed',
          ),
        );
        return;
      }
      final buckets = _buckets[host] ?? _addHost(host, hostPolicies);
      buckets.active++;
      try {
        await buckets.pipeline.execute(() async {});
      } on RateLimitExceededException catch (error) {
        _rejected++;
        _log('Rate limit queue full for $host');
        handler.reject(localRateLimitRejection(options, error: error), true);
        return;
      } on Object catch (error) {
        // resilience fails waiting calls with a StateError once disposed.
        if (!_disposed) rethrow;
        handler.reject(_cancelled(options, error, 'Rate limiter disposed'));
        return;
      } finally {
        buckets
          ..active -= 1
          ..lastUsed = clock.now();
      }
      final cancelToken = options.cancelToken;
      if (cancelToken != null && cancelToken.isCancelled) {
        handler.reject(
          _cancelled(options, cancelToken.cancelError, 'Request cancelled'),
        );
        return;
      }
      if (_pause.isPaused(host)) {
        // A 429 arrived while this request waited for tokens. The tokens
        // are spent; the request takes new ones after the pause.
        continue;
      }
      _forwarded++;
      handler.next(options);
      return;
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _pause.observe(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      _pause.observe(response);
    }
    handler.next(err);
  }

  /// Returns the current activity counters.
  TokenBucketRateLimitStatistics getStatistics() {
    int waiting(Iterable<RateLimiter> limiters) =>
        limiters.fold(0, (sum, limiter) => sum + limiter.queueLength);
    return TokenBucketRateLimitStatistics(
      forwarded: _forwarded,
      rejected: _rejected,
      waitingByHost: Map.unmodifiable({
        for (final MapEntry(:key, :value) in _buckets.entries)
          key: waiting(value.limiters),
      }),
      globalWaiting: waiting(_globalLimiters),
      heldByHost: _pause.heldByHost,
      pausedUntilByHost: _pause.pausedUntilByHost,
    );
  }

  /// Stops every refill timer, cancels waiting and held requests, and
  /// forgets every pause.
  ///
  /// Afterwards, requests to a limited host are cancelled and requests to
  /// an unlimited host pass. Calling it again has no effect.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _pause.dispose();
    for (final limiter in [
      ..._globalLimiters,
      ..._buckets.values.expand((buckets) => buckets.limiters),
    ]) {
      limiter.dispose();
    }
  }

  /// Builds the pause core, reporting a negative queue size under its
  /// public name before the core's own check can.
  static RetryAfterPause _buildPause({
    required Duration maxPauseWait,
    required Duration maxPause,
    required Duration? defaultPause,
    required int maxQueueSize,
    required bool holdRequests,
  }) {
    if (maxQueueSize < 0) {
      throw ArgumentError.value(
        maxQueueSize,
        'maxQueueSize',
        'must not be negative',
      );
    }
    return RetryAfterPause(
      maxPauseWait: maxPauseWait,
      maxPause: maxPause,
      defaultPause: defaultPause,
      maxHeld: maxQueueSize,
      holdRequests: holdRequests,
    );
  }

  /// Builds the buckets of a host seen for the first time. Before the map
  /// grows, it forgets every idle host whose buckets are full again, so a
  /// client that calls many hosts does not keep one set of buckets per host
  /// forever.
  _HostBuckets _addHost(String host, List<TokenBucketPolicy> policies) {
    final now = clock.now();
    final lastSweep = _lastSweep;
    if (lastSweep == null || now.difference(lastSweep) >= _sweepInterval) {
      _lastSweep = now;
      _buckets.removeWhere((_, buckets) {
        if (!buckets.isForgettableAt(now)) return false;
        for (final limiter in buckets.limiters) {
          limiter.dispose();
        }
        return true;
      });
    }
    final limiters = [
      for (final policy in policies)
        policy.toRateLimiter(maxQueueLength: queueRequests ? maxQueueSize : 0),
    ];
    return _buckets[host] = _HostBuckets(
      limiters,
      ResiliencePipeline([...limiters, ..._globalLimiters]),
      refillTime: limiters.map(_refillTime).fold(Duration.zero, _longer),
      lastUsed: now,
    );
  }

  static Duration _longer(Duration a, Duration b) => a > b ? a : b;

  /// The finest step of a `resilience` refill timer (its `_minTick`).
  static const Duration _refillTickFloor = Duration(milliseconds: 4);

  /// How long [limiter] needs after its last token to be full again: its
  /// refill period, plus one timer tick, since tokens arrive per tick.
  static Duration _refillTime(RateLimiter limiter) =>
      limiter.per +
      _longer(limiter.per ~/ limiter.maxPermits, _refillTickFloor);

  DioException _cancelled(
    RequestOptions options,
    Object? error,
    String message,
  ) => DioException(
    requestOptions: options,
    type: DioExceptionType.cancel,
    error: error,
    message: message,
  );

  void _log(String message) =>
      logPrint?.call('[TokenBucketRateLimitInterceptor] $message');
}

/// The token buckets of one host, and what forgetting them needs to know.
class _HostBuckets {
  new(
    this.limiters,
    this.pipeline, {
    required this.refillTime,
    required this.lastUsed,
  });

  /// The host's own tiers; empty when only global tiers apply.
  final List<RateLimiter> limiters;
  final ResiliencePipeline pipeline;

  /// How long [limiters] need after their last token to be full again.
  final Duration refillTime;

  /// Requests of this host still inside [pipeline].
  int active = 0;

  /// When the last of those requests left [pipeline].
  DateTime lastUsed;

  /// Whether dropping these buckets changes nothing: no request is inside
  /// or waiting, and every bucket has refilled, so new buckets built for the
  /// host's next request start in the same state.
  bool isForgettableAt(DateTime now) =>
      active == 0 &&
      limiters.every((limiter) => limiter.queueLength == 0) &&
      now.difference(lastUsed) >= refillTime;
}
