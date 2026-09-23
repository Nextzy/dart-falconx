import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
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
  });

  /// Requests passed to the next handler since construction.
  final int forwarded;

  /// Requests rejected with 429 since construction.
  final int rejected;

  /// Requests waiting in each host's own tiers, keyed by host.
  final Map<String, int> waitingByHost;

  /// Requests waiting in the global tiers.
  final int globalWaiting;
}

/// Limits outgoing requests with token buckets built on `resilience`.
///
/// Every request passes all tiers of its host, then all `global` tiers.
/// A host's tiers come from `hosts[host]` when that key exists, otherwise
/// from `perHost`. A scope with no policy is unlimited: a request to a host
/// whose tiers and the global tiers are all empty is forwarded
/// synchronously and creates no limiter.
///
/// Each [TokenBucketPolicy] guarantees at most `permits` requests in any
/// window of `per`. Refills are driven by `Timer`, not by reading the
/// clock: `fakeAsync`'s `elapse` advances them, and
/// `withClock(Clock.fixed(...))` has no effect on them.
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
  /// Keys of [hosts] must be lowercase, because `Uri` lowercases hosts.
  new({
    required this.config,
    List<TokenBucketPolicy> global = const [],
    List<TokenBucketPolicy> perHost = const [],
    Map<String, List<TokenBucketPolicy>> hosts = const {},
    this.queueRequests = true,
    this.maxQueueSize = 50,
    this.maxGlobalQueueSize = 500,
  }) : _perHost = perHost,
       _hosts = hosts,
       _globalLimiters = [
         for (final policy in global)
           policy.toRateLimiter(
             maxQueueLength: queueRequests ? maxGlobalQueueSize : 0,
           ),
       ] {
    for (final host in hosts.keys) {
      if (host != host.toLowerCase()) {
        throw ArgumentError.value(host, 'hosts', 'keys must be lowercase');
      }
    }
    for (final policy in [...perHost, ...hosts.values.expand((p) => p)]) {
      policy.validate();
    }
  }

  /// Configuration; `enableLogging` gates diagnostic prints.
  final HttpClientConfig config;

  /// Whether a request with no token waits (`true`) or is rejected.
  final bool queueRequests;

  /// Wait-queue capacity of each host tier.
  final int maxQueueSize;

  /// Wait-queue capacity of each global tier.
  final int maxGlobalQueueSize;

  final List<TokenBucketPolicy> _perHost;
  final Map<String, List<TokenBucketPolicy>> _hosts;
  final List<RateLimiter> _globalLimiters;
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
    if (hostPolicies.isEmpty && _globalLimiters.isEmpty) {
      _forwarded++;
      handler.next(options);
      return;
    }
    if (_disposed) {
      handler.reject(_cancelled(options, StateError('RateLimiter disposed')));
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
      handler.reject(_tooManyRequests(options, error));
      return;
    } on Object catch (error) {
      // resilience fails waiting calls with a StateError once disposed.
      if (!_disposed) rethrow;
      handler.reject(_cancelled(options, error));
      return;
    }
    _forwarded++;
    handler.next(options);
  }

  /// Returns the current activity counters.
  TokenBucketRateLimitStatistics getStatistics() {
    int waiting(Iterable<RateLimiter> limiters) =>
        limiters.fold(0, (sum, limiter) => sum + limiter.queueLength);
    return TokenBucketRateLimitStatistics(
      forwarded: _forwarded,
      rejected: _rejected,
      waitingByHost: {
        for (final entry in _hostLimiters.entries)
          entry.key: waiting(entry.value),
      },
      globalWaiting: waiting(_globalLimiters),
    );
  }

  /// Stops every refill timer and cancels waiting requests.
  ///
  /// Afterwards, requests to a limited host are cancelled and requests to
  /// an unlimited host still pass. Calling it again has no effect.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final limiter in [
      ..._globalLimiters,
      ..._hostLimiters.values.expand((limiters) => limiters),
    ]) {
      limiter.dispose();
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

  DioException _tooManyRequests(
    RequestOptions options,
    RateLimitExceededException error,
  ) => DioException(
    requestOptions: options,
    error: error,
    message: 'Rate limit queue full for ${options.uri.host}',
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: 429,
      statusMessage: 'Too Many Requests',
    ),
  );

  DioException _cancelled(RequestOptions options, Object error) => DioException(
    requestOptions: options,
    type: DioExceptionType.cancel,
    error: error,
    message: 'Rate limiter disposed',
  );

  void _log(String message) {
    if (config.enableLogging) {
      // Intentional logging for rate limit diagnostics.
      // ignore: avoid_print
      print('[TokenBucketRateLimitInterceptor] $message');
    }
  }
}
