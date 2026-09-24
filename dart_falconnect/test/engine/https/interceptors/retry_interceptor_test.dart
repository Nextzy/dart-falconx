import 'dart:async';
import 'dart:math';

import 'package:dart_falconnect/engine/https/config/retry_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falconnect/engine/https/interceptors/retry_interceptor.dart';
import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

const _config = RetryConfig(
  maxAttempts: 3,
  delay: Duration(seconds: 1),
  maxDelay: Duration(seconds: 30),
  maxDuration: Duration(seconds: 60),
);

class _Client {
  new(List<Reply> script, {RetryConfig config = _config})
    : adapter = ScriptedAdapter(script) {
    dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter
      ..transformer = FoldingTransformer();
    dio.interceptors.add(
      RetryInterceptor(
        config: RetryConfig(
          maxAttempts: config.maxAttempts,
          delay: config.delay,
          maxDelay: config.maxDelay,
          maxDuration: config.maxDuration,
          onRetry: (error, attempt, delay) {
            retries.add((attempt, delay));
            retryErrors.add(error);
          },
        ),
        dio: dio,
        random: Random(7),
      ),
    );
  }

  final ScriptedAdapter adapter;
  late final Dio dio;
  final List<(int, Duration)> retries = [];
  final List<DioException> retryErrors = [];
  Object? outcome;

  void send(Future<Response<dynamic>> Function(Dio dio) call) {
    unawaited(
      call(dio).then(
        (response) => outcome = response,
        onError: (Object error) => outcome = error,
      ),
    );
  }

  int get sent => adapter.requests.length;
}

void main() {
  test('retries a GET up to maxRetryAttempts, then fails', () {
    fakeAsync((async) {
      final client = _Client([reply(500)])..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 4);
      expect(client.retries.map((r) => r.$1), [1, 2, 3]);
      final error = client.outcome! as DioException;
      expect(error.response?.statusCode, 500);
      expect(error.requestOptions.retryAttempt, 3);
      expect(
        client.retryErrors.map((e) => e.response?.statusCode),
        everyElement(500),
      );
    });
  });

  test('returns the first successful retry', () {
    fakeAsync((async) {
      final client = _Client([reply(503), reply(200)])
        ..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 5));

      expect(client.sent, 2);
      expect((client.outcome! as Response<dynamic>).statusCode, 200);
    });
  });

  test('backoff uses full jitter under the exponential cap', () {
    fakeAsync((async) {
      final client = _Client(
        [reply(500)],
        config: _config.copyWith(maxDelay: const Duration(seconds: 3)),
      )..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 30));

      final delays = client.retries.map((r) => r.$2).toList();
      expect(delays[0], lessThanOrEqualTo(const Duration(seconds: 1)));
      expect(delays[1], lessThanOrEqualTo(const Duration(seconds: 2)));
      expect(delays[2], lessThanOrEqualTo(const Duration(seconds: 3)));
    });
  });

  test('does not retry a POST after a 500', () {
    fakeAsync((async) {
      final client = _Client([reply(500), reply(200)])
        ..send((d) => d.post('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 1);
      expect(client.outcome, isA<DioException>());
    });
  });

  test('retries a POST after a 429 or a connection timeout', () {
    fakeAsync((async) {
      final client = _Client([
        reply(429, headers: {'retry-after': '1'}),
        failWith(DioExceptionType.connectionTimeout),
        reply(201),
      ])..send((d) => d.post('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 3);
      expect((client.outcome! as Response<dynamic>).statusCode, 201);
    });
  });

  test('retryNonIdempotent lets a POST retry after a 500', () {
    fakeAsync((async) {
      final client = _Client([reply(500), reply(200)])
        ..send(
          (d) => d.post('/x', options: Options()..retryNonIdempotent = true),
        );

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 2);
    });
  });

  test('waits exactly Retry-After when it fits maxRetryDelay', () {
    fakeAsync((async) {
      final client = _Client([
        reply(429, headers: {'retry-after': '3'}),
        reply(200),
      ])..send((d) => d.get('/x'));

      async.elapse(const Duration(milliseconds: 2999));
      expect(client.sent, 1);
      async.elapse(const Duration(milliseconds: 1));
      expect(client.sent, 2);
    });
  });

  test('does not retry when Retry-After exceeds maxRetryDelay', () {
    fakeAsync((async) {
      final client = _Client([
        reply(503, headers: {'retry-after': '31'}),
        reply(200),
      ])..send((d) => d.get('/x'));

      async.elapse(const Duration(minutes: 1));

      expect(client.sent, 1);
      expect(client.retries, isEmpty);
    });
  });

  test('stops before a retry would end past maxDuration', () {
    fakeAsync((async) {
      final client = _Client(
        [
          reply(429, headers: {'retry-after': '1'}),
        ],
        config: _config.copyWith(maxDuration: const Duration(seconds: 2)),
      )..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 3);
    });
  });

  test('a cancel during the wait stops at once', () {
    fakeAsync((async) {
      final token = CancelToken();
      final client = _Client([
        reply(429, headers: {'retry-after': '5'}),
        reply(200),
      ])..send((d) => d.get('/x', cancelToken: token));
      async.elapse(const Duration(milliseconds: 10));
      expect(client.retries, hasLength(1));

      token.cancel('user left');
      async.elapse(const Duration(milliseconds: 1));

      expect((client.outcome! as DioException).type, DioExceptionType.cancel);
      expect(async.pendingTimers, isEmpty);
      expect(client.sent, 1);
    });
  });

  test('never retries a Stream body or a bad certificate', () {
    fakeAsync((async) {
      final stream = _Client([reply(500), reply(200)])
        ..send(
          (d) => d.put(
            '/x',
            data: Stream.value([1, 2, 3]),
            options: Options(headers: {Headers.contentLengthHeader: 3}),
          ),
        );
      final certificate = _Client([
        failWith(DioExceptionType.badCertificate),
        reply(200),
      ])..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(stream.sent, 1);
      expect(certificate.sent, 1);
    });
  });

  test('clones FormData for every retry', () {
    fakeAsync((async) {
      final client = _Client([reply(500), reply(200)])
        ..send(
          (d) => d.put(
            '/x',
            data: FormData.fromMap({'file': MultipartFile.fromString('abc')}),
          ),
        );

      async.elapse(const Duration(seconds: 30));

      expect((client.outcome! as Response<dynamic>).statusCode, 200);
      final first = client.adapter.requests[0].data;
      final second = client.adapter.requests[1].data;
      expect(second, isA<FormData>());
      expect(identical(first, second), isFalse);
    });
  });

  test('keeps responseType plain across a retry (upstream issue #49)', () {
    fakeAsync((async) {
      final client = _Client([reply(500), reply(200)])
        ..send((d) => d.get<String>('/x'));

      async.elapse(const Duration(seconds: 30));

      final response = client.outcome! as Response<dynamic>;
      expect(response.data, '{"status":200}');
      expect(client.adapter.requests[1].responseType, ResponseType.plain);
    });
  });

  test('per-request disableRetry and retryAttempts', () {
    fakeAsync((async) {
      final disabled = _Client([reply(500)])
        ..send((d) => d.get('/x', options: Options()..disableRetry = true));
      final once = _Client([reply(500)])
        ..send((d) => d.get('/x', options: Options()..retryAttempts = 1));

      async.elapse(const Duration(seconds: 30));

      expect(disabled.sent, 1);
      expect(once.sent, 2);
    });
  });

  test('a local 429 is not retried and calls no onRetry', () {
    fakeAsync((async) {
      // No retry-after, so only the isLocalRateLimit guard can stop the
      // loop; a 429 alone would retry under the seeded jitter.
      final local = localRateLimitRejection(
        RequestOptions(path: 'https://a.test/x'),
      );
      final client = _Client([failLocal(local)])..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 30));

      // Only the original request was sent; the local 429 stops the loop.
      expect(client.sent, 1);
      expect(client.retries, isEmpty);
      final error = client.outcome! as DioException;
      expect(error.response?.isLocalRateLimit, isTrue);
      expect(error.response?.statusCode, 429);
    });
  });

  test('survives 80 attempts without a backoff overflow', () {
    fakeAsync((async) {
      final client = _Client(
        [reply(500)],
        config: const RetryConfig(
          maxAttempts: 80,
          delay: Duration(seconds: 1),
          maxDelay: Duration(milliseconds: 1),
          maxDuration: Duration(days: 365),
        ),
      )..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 5));

      expect(client.sent, 81);
      expect(client.outcome, isA<DioException>());
    });
  });

  test('per-request setters copy a const extra map', () {
    final options = Options(extra: const {'k': 1})
      ..disableRetry = true
      ..retryAttempts = 2;
    expect(options.extra?['k'], 1);
    expect(options.disableRetry, isTrue);
    expect(options.retryAttempts, 2);
    expect(() => options.retryAttempts = -1, throwsArgumentError);
  });

  test('maxAttempts 0 never retries', () {
    fakeAsync((async) {
      final client = _Client([
        reply(503),
      ], config: const RetryConfig(maxAttempts: 0))..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 1);
    });
  });

  test('retry waits leave no cancel watch on a long-lived token', () {
    fakeAsync((async) {
      final token = CancelToken();
      final client = _Client([reply(503), reply(503), reply(200)])
        ..send((d) => d.get('/x', cancelToken: token));
      async.elapse(const Duration(milliseconds: 1));
      expect(client.retries, hasLength(1));
      expect(activeCancelWatches(token), 1);

      async.elapse(const Duration(seconds: 10));

      expect((client.outcome! as Response<dynamic>).statusCode, 200);
      expect(client.sent, 3);
      expect(activeCancelWatches(token), 0);
    });
  });
}
