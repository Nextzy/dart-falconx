import 'dart:async';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

const _retry = RetryConfig(
  maxAttempts: 3,
  delay: Duration(seconds: 1),
  maxDelay: Duration(seconds: 30),
  maxDuration: Duration(seconds: 60),
);

/// The order the documentation prescribes: rate limiter, retry, exception
/// handler.
Dio _chain(ScriptedAdapter adapter, TokenBucketRateLimitInterceptor limiter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll([
    limiter,
    RetryInterceptor(config: _retry, dio: dio),
    DefaultNetworkExceptionHandlerInterceptor(),
  ]);
  return dio;
}

/// The full order of the SP3 spec, section 12, without a cache.
Dio _limitedChain(
  HttpClientAdapter adapter,
  ConcurrencyLimitInterceptor concurrency,
  TokenBucketRateLimitInterceptor limiter, {
  bool retry = true,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll([
    concurrency,
    limiter,
    if (retry) RetryInterceptor(config: _retry, dio: dio),
    DefaultNetworkExceptionHandlerInterceptor(),
  ]);
  return dio;
}

void main() {
  test('a retry waits for Retry-After once, not twice', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        reply(429, headers: {'retry-after': '3'}),
        reply(200),
      ]);
      final limiter = TokenBucketRateLimitInterceptor();
      final dio = _chain(adapter, limiter);
      final sentAt = <Duration>[];
      Object? outcome;

      unawaited(
        dio
            .get<dynamic>('/x')
            .then((r) => outcome = r, onError: (Object e) => outcome = e),
      );
      // Record when each request reaches the adapter.
      var seen = 0;
      for (var ms = 0; ms <= 7000; ms += 100) {
        async.elapse(const Duration(milliseconds: 100));
        while (seen < adapter.requests.length) {
          seen++;
          sentAt.add(async.elapsed);
        }
      }

      expect((outcome! as Response<dynamic>).statusCode, 200);
      expect(adapter.requests, hasLength(2));
      expect(sentAt[1], lessThanOrEqualTo(const Duration(milliseconds: 3100)));
      limiter.dispose();
    });
  });

  test('a request sent during the pause is held, then sent', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        reply(429, headers: {'retry-after': '3'}),
        reply(200),
      ]);
      final limiter = TokenBucketRateLimitInterceptor();
      final dio = _chain(adapter, limiter);

      unawaited(dio.get<dynamic>('/x').then((_) {}, onError: (_) {}));
      async.elapse(const Duration(seconds: 1));
      Object? second;
      unawaited(
        dio
            .get<dynamic>('/y')
            .then((r) => second = r, onError: (Object e) => second = e),
      );
      async.elapse(const Duration(milliseconds: 1900));
      expect(adapter.requests, hasLength(1));

      async.elapse(const Duration(seconds: 2));
      expect((second! as Response<dynamic>).statusCode, 200);
      limiter.dispose();
    });
  });

  test('a local 429 reaches the caller as NetworkLimitExceededException', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = TokenBucketRateLimitInterceptor(
        config: const TokenBucketRateLimitConfig(
          perHost: [TokenBucketPolicy(permits: 1, per: Duration(minutes: 1))],
          queueRequests: false,
        ),
      );
      final dio = _chain(adapter, limiter);
      final outcomes = <Object>[];

      for (var i = 0; i < 2; i++) {
        unawaited(
          dio.get<dynamic>('/x').then(outcomes.add, onError: outcomes.add),
        );
      }
      async.elapse(const Duration(seconds: 1));

      expect(adapter.requests, hasLength(1));
      final error = outcomes.whereType<DioException>().single;
      expect(error.error, isA<NetworkLimitExceededException>());
      expect(error.response?.isLocalRateLimit, isTrue);
      limiter.dispose();
    });
  });

  test('a 429 on a retry extends the pause for other requests', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        reply(429, headers: {'retry-after': '2'}),
        reply(429, headers: {'retry-after': '2'}),
        reply(200),
      ]);
      final limiter = TokenBucketRateLimitInterceptor();
      final dio = _chain(adapter, limiter);

      unawaited(dio.get<dynamic>('/x').then((_) {}, onError: (_) {}));
      async.elapse(const Duration(milliseconds: 2500));
      unawaited(dio.get<dynamic>('/y').then((_) {}, onError: (_) {}));

      async.elapse(const Duration(milliseconds: 1400));
      expect(adapter.requests, hasLength(2), reason: 'held until 4 s');
      async.elapse(const Duration(milliseconds: 200));
      expect(adapter.requests, hasLength(4));
      limiter.dispose();
    });
  });

  test('with validateStatus below 500 a 429 reaches the caller as a '
      'response and still pauses the host', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        reply(429, headers: {'retry-after': '2'}),
        reply(200),
      ]);
      final limiter = TokenBucketRateLimitInterceptor();
      final dio = _chain(adapter, limiter)
        ..options.validateStatus = (status) => status != null && status < 500;
      final outcomes = <Object>[];

      unawaited(dio.get<dynamic>('/x').then(outcomes.add));
      async.elapse(const Duration(milliseconds: 10));
      unawaited(dio.get<dynamic>('/y').then(outcomes.add));
      async.elapse(const Duration(seconds: 1));

      expect((outcomes.single as Response<dynamic>).statusCode, 429);
      expect(adapter.requests, hasLength(1));
      async.elapse(const Duration(seconds: 1));
      expect(adapter.requests, hasLength(2));
      limiter.dispose();
    });
  });

  test('the token ceiling holds on the wire behind a concurrency limit', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final concurrency = ConcurrencyLimitInterceptor(
        config: const ConcurrencyConfig(perHost: 4),
      );
      final limiter = TokenBucketRateLimitInterceptor(
        config: const TokenBucketRateLimitConfig(
          perHost: [
            TokenBucketPolicy(permits: 2, per: Duration(seconds: 1), burst: 2),
          ],
        ),
      );
      final dio = _limitedChain(adapter, concurrency, limiter);
      for (var i = 0; i < 12; i++) {
        unawaited(dio.get<dynamic>('/$i').then((_) {}, onError: (_) {}));
      }

      // The server answers every request in flight at once, every 6 s, so
      // four slots free up together. Requests that took tokens before
      // their slot would all leave at that moment.
      for (var second = 6; second <= 30; second += 6) {
        async.elapse(const Duration(seconds: 6));
        for (final request in adapter.inFlight) {
          request.respond(200);
        }
      }

      final sentAt = [for (final r in adapter.requests) r.sentAt];
      expect(sentAt, hasLength(12));
      for (final start in sentAt) {
        final end = start.add(const Duration(seconds: 1));
        final window = sentAt.where(
          (t) => !t.isBefore(start) && t.isBefore(end),
        );
        expect(window.length, lessThanOrEqualTo(2), reason: 'from $start');
      }
      concurrency.dispose();
      limiter.dispose();
    });
  });

  test('a request waiting for a slot is not sent to a host paused '
      'meanwhile', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final concurrency = ConcurrencyLimitInterceptor(
        config: const ConcurrencyConfig(perHost: 1),
      );
      final limiter = TokenBucketRateLimitInterceptor();
      final dio = _limitedChain(adapter, concurrency, limiter, retry: false);
      final outcomes = <Object>[];

      for (final path in ['/1', '/2']) {
        unawaited(
          dio.get<dynamic>(path).then(outcomes.add, onError: outcomes.add),
        );
      }
      async.elapse(Duration.zero);
      adapter.requests.single.respond(429, headers: {'retry-after': '3'});
      async.elapse(const Duration(milliseconds: 2900));
      expect(adapter.requests, hasLength(1), reason: 'held by the pause');

      async.elapse(const Duration(milliseconds: 200));
      expect(adapter.requests, hasLength(2));
      concurrency.dispose();
      limiter.dispose();
    });
  });

  test('a 429 pauses the host, and the retry passes the pause with a '
      'concurrency limit of 1', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        reply(429, headers: {'retry-after': '2'}),
        reply(200),
      ]);
      final concurrency = ConcurrencyLimitInterceptor(
        config: const ConcurrencyConfig(perHost: 1),
      );
      final limiter = TokenBucketRateLimitInterceptor();
      final dio = _limitedChain(adapter, concurrency, limiter);
      Object? outcome;

      unawaited(
        dio
            .get<dynamic>('/x')
            .then((r) => outcome = r, onError: (Object e) => outcome = e),
      );
      async.elapse(const Duration(seconds: 3));

      expect((outcome! as Response<dynamic>).statusCode, 200);
      expect(adapter.requests, hasLength(2));
      expect(concurrency.getStatistics().activeByHost, isEmpty);
      concurrency.dispose();
      limiter.dispose();
    });
  });

  test('a request waiting for a slot is not sent to a host paused '
      'meanwhile, when the 429 arrives as a response', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final concurrency = ConcurrencyLimitInterceptor(
        config: const ConcurrencyConfig(perHost: 1),
      );
      final limiter = TokenBucketRateLimitInterceptor();
      final dio = _limitedChain(adapter, concurrency, limiter, retry: false)
        ..options.validateStatus = (status) => status != null && status < 500;
      final outcomes = <Object>[];

      for (final path in ['/1', '/2']) {
        unawaited(
          dio.get<dynamic>(path).then(outcomes.add, onError: outcomes.add),
        );
      }
      async.elapse(Duration.zero);
      adapter.requests.single.respond(429, headers: {'retry-after': '3'});
      async.elapse(const Duration(milliseconds: 2900));
      expect(adapter.requests, hasLength(1), reason: 'held by the pause');

      async.elapse(const Duration(milliseconds: 200));
      expect(adapter.requests, hasLength(2));
      concurrency.dispose();
      limiter.dispose();
    });
  });
}
