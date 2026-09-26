import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:test/test.dart';

RetryConfig _retry(int attempts) => RetryConfig(maxAttempts: attempts);

TokenBucketPolicy _policy(int permits) =>
    TokenBucketPolicy(permits: permits, per: const Duration(seconds: 1));

void main() {
  test('defaults match the interceptor defaults', () {
    const retry = RetryConfig();
    expect(retry.maxAttempts, 3);
    expect(retry.delay, const Duration(seconds: 1));
    expect(retry.maxDelay, const Duration(seconds: 30));
    expect(retry.maxDuration, const Duration(seconds: 60));
    expect(retry.onRetry, isNull);

    const cache = CacheConfig();
    expect(cache.policy, CachePolicy.request);
    expect(cache.maxStale, isNull);
    expect(cache.maxSize, 50 * 1024 * 1024);
    expect(cache.store, isNull);
    expect(cache.keyHeaders, {'authorization', 'accept', 'accept-language'});
    expect(cache.hitCacheOnNetworkFailure, isFalse);
    expect(cache.hitCacheOnErrorCodes, isEmpty);

    const pause = PauseConfig();
    expect(pause.maxPauseWait, const Duration(seconds: 10));
    expect(pause.maxPause, const Duration(minutes: 10));
    expect(pause.defaultPause, const Duration(seconds: 5));

    const concurrency = ConcurrencyConfig();
    expect(concurrency.global, isNull);
    expect(concurrency.perHost, isNull);
    expect(concurrency.hosts, isEmpty);
    expect(concurrency.queueRequests, isTrue);
    expect(concurrency.maxQueueSize, 50);
    expect(concurrency.maxGlobalQueueSize, 500);

    const log = PrettyLogConfig();
    expect(log.responseHeader, isFalse);
    expect(log.logPrint, isNull);
    expect(log.diagnostics, isTrue);
  });

  test('request ID and auth boxes default to the documented values', () {
    const id = RequestIdConfig();
    expect(id.headerName, 'X-Request-ID');
    expect(id.generate, isNull);

    final auth = AuthConfig(accessToken: () => null, refresh: () async => true);
    expect(auth.headerName, 'Authorization');
    expect(auth.scheme, 'Bearer');
    expect(auth.onAuthFailed, isNull);

    const config = HttpClientConfig();
    expect(config.headerProvider, isNull);
    expect(config.requestId, isNull);
    expect(config.auth, isNull);
  });

  test('noToken carries useTokenExtraKey set to false', () {
    expect(useTokenExtraKey, 'dart_falconnect.auth.useToken');
    expect(noToken.data, {useTokenExtraKey: false});
    expect((RequestOptions()..extra = {...noToken.data}).useToken, isFalse);
    expect(RequestOptions().useToken, isTrue);
  });

  test('boxes compare by value', () {
    expect(_retry(2), const RetryConfig(maxAttempts: 2));
    expect(_retry(2).hashCode, const RetryConfig(maxAttempts: 2).hashCode);
    expect(_retry(2), isNot(_retry(3)));
    expect(
      RateLimitConfig.tokenBucket(global: [_policy(5)]),
      RateLimitConfig.tokenBucket(global: [_policy(5)]),
    );
    expect(
      RateLimitConfig.tokenBucket(global: [_policy(5)]),
      isNot(RateLimitConfig.tokenBucket(global: [_policy(6)])),
    );
  });

  test('RateLimitConfig has exactly three variants', () {
    String name(RateLimitConfig config) => switch (config) {
      NoRateLimitConfig() => 'none',
      PauseOnlyRateLimitConfig() => 'pause',
      TokenBucketRateLimitConfig() => 'bucket',
    };

    expect(
      [
        name(const RateLimitConfig.none()),
        name(const RateLimitConfig.pauseOnly()),
        name(const RateLimitConfig.tokenBucket()),
      ],
      ['none', 'pause', 'bucket'],
    );
  });
}
