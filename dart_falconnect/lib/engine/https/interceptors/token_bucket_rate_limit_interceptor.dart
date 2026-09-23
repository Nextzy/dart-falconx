import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart';
import 'package:dart_faltool/dart_faltool.dart'
    show
        RateLimitExceededException,
        RateLimiter,
        ResiliencePipeline,
        TokenBucketPolicy,
        immutable;
import 'package:dio/dio.dart';

/// Activity counters of a [TokenBucketRateLimitInterceptor].
@immutable
class TokenBucketRateLimitStatistics {
  /// Creates a statistics snapshot.
  const new({
    required this.forwarded,
    required this.rejected,
    required this.waitingByHost,
    required this.globalWaiting,
    required this.heldByHost,
    required this.pausedUntilByHost,
  });

  /// Requests passed to the next handler since construction. A request
  /// cancelled before it was forwarded is not counted.
  final int forwarded;

  /// Requests rejected with a local 429 since construction, for a full
  /// queue or a paused host.
  final int rejected;

  /// Requests waiting in each host's own tiers, keyed by host.
  final Map<String, int> waitingByHost;

  /// Requests waiting in the global tiers.
  final int globalWaiting;

  /// Requests held by a pause, keyed by host.
  final Map<String, int> heldByHost;

  /// End time of each active pause, keyed by host.
  final Map<String, DateTime> pausedUntilByHost;
}

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
/// Refill timers keep running until every bucket is full again. Call
/// [dispose] at the end of a `testWidgets` body (`addTearDown` runs after
/// Flutter's pending-timer check), before a CLI's `main` returns, or when a
/// scoped client is discarded. A long-lived app or server client needs no
/// call. On a server, build one interceptor per process: a new instance per
/// request starts with full buckets and limits nothing.
class TokenBucketRateLimitInterceptor extends Interceptor {
  /// Creates a token bucket rate limit interceptor.
  ///
  /// Each key of [hosts] must be a bare host exactly as `Uri.host` returns
  /// it: lowercase, with no port, brackets, or spaces.
  new({
    required this.config,
    List<TokenBucketPolicy> global = const [],
    List<TokenBucketPolicy> perHost = const [],
    Map<String, List<TokenBucketPolicy>> hosts = const {},
    this.queueRequests = true,
    this.maxQueueSize = 50,
    this.maxGlobalQueueSize = 500,
    Duration maxPauseWait = const Duration(seconds: 10),
    Duration maxPause = const Duration(minutes: 10),
    Duration? defaultPause = const Duration(seconds: 5),
  }) : _perHost = List.unmodifiable(perHost),
       _hosts = Map.unmodifiable({
         for (final entry in hosts.entries)
           entry.key: List<TokenBucketPolicy>.unmodifiable(entry.value),
       }),
       _globalLimiters = [
         for (final policy in global)
           policy.toRateLimiter(
             maxQueueLength: queueRequests ? maxGlobalQueueSize : 0,
           ),
       ],
       _pause = _buildPause(
         maxPauseWait: maxPauseWait,
         maxPause: maxPause,
         defaultPause: defaultPause,
         maxQueueSize: maxQueueSize,
         holdRequests: queueRequests,
       ) {
    for (final host in hosts.keys) {
      if (!_isHostKey(host)) {
        throw ArgumentError.value(
          host,
          'hosts',
          'keys must be bare lowercase hosts, as Uri.host returns them',
        );
      }
    }
    for (final policy in [...perHost, ...hosts.values.expand((p) => p)]) {
      policy.validate();
    }
  }

  /// Configuration; `enableLogging` gates diagnostic prints.
  final HttpClientConfig config;

  /// Whether a request with no token, or to a briefly paused host, waits
  /// (`true`) or is rejected.
  final bool queueRequests;

  /// Wait-queue capacity of each host tier, and of each host's pause.
  final int maxQueueSize;

  /// Wait-queue capacity of each global tier.
  final int maxGlobalQueueSize;

  final List<TokenBucketPolicy> _perHost;
  final Map<String, List<TokenBucketPolicy>> _hosts;
  final List<RateLimiter> _globalLimiters;
  final RetryAfterPause _pause;
  final Map<String, List<RateLimiter>> _hostLimiters = {};
  final Map<String, ResiliencePipeline> _pipelines = {};
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
      final pipeline = _pipelines.putIfAbsent(
        host,
        () => _buildPipeline(host, hostPolicies),
      );
      try {
        await pipeline.execute(() async {});
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
        for (final entry in _hostLimiters.entries)
          entry.key: waiting(entry.value),
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
      ..._hostLimiters.values.expand((limiters) => limiters),
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

  static bool _isHostKey(String key) {
    if (key.isEmpty) {
      return false;
    }
    try {
      return Uri(scheme: 'http', host: key).host == key;
    } on FormatException {
      return false;
    }
  }

  ResiliencePipeline _buildPipeline(
    String host,
    List<TokenBucketPolicy> policies,
  ) {
    final hostLimiters = [
      for (final policy in policies)
        policy.toRateLimiter(maxQueueLength: queueRequests ? maxQueueSize : 0),
    ];
    _hostLimiters[host] = hostLimiters;
    return ResiliencePipeline([...hostLimiters, ..._globalLimiters]);
  }

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

  void _log(String message) {
    if (config.enableLogging) {
      // Intentional logging for rate limit diagnostics.
      // ignore: avoid_print
      print('[TokenBucketRateLimitInterceptor] $message');
    }
  }
}
