import 'dart:async';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falconnect/engine/https/interceptors/retry_after_pause_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

class _Handler extends RequestInterceptorHandler {
  new(this.forwarded, this.rejected);

  final List<RequestOptions> forwarded;
  final List<DioException> rejected;

  @override
  void next(RequestOptions requestOptions) => forwarded.add(requestOptions);

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) => rejected.add(error);
}

class _SilentResponseHandler extends ResponseInterceptorHandler {
  @override
  void next(Response<dynamic> response) {}
}

class _SilentErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException error) {}
}

Response<dynamic> _response(int status, {String? retryAfter}) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: 'https://a.test/items'),
      statusCode: status,
      headers: Headers.fromMap({
        if (retryAfter != null) 'retry-after': [retryAfter],
      }),
    );

void main() {
  const config = HttpClientConfig();
  late List<RequestOptions> forwarded;
  late List<DioException> rejected;

  void send(RetryAfterPauseInterceptor interceptor, {String host = 'a.test'}) {
    unawaited(
      interceptor.onRequest(
        RequestOptions(path: 'https://$host/items'),
        _Handler(forwarded, rejected),
      ),
    );
  }

  setUp(() {
    forwarded = [];
    rejected = [];
  });

  test('forwards synchronously while no host is paused', () {
    fakeAsync((async) {
      final interceptor = RetryAfterPauseInterceptor(config: config);

      send(interceptor);

      expect(forwarded, hasLength(1));
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('holds a request until a short pause ends', () {
    fakeAsync((async) {
      final interceptor = RetryAfterPauseInterceptor(config: config)
        ..onResponse(_response(429, retryAfter: '2'), _SilentResponseHandler());

      send(interceptor);
      send(interceptor, host: 'b.test');
      async.flushMicrotasks();
      expect(forwarded.map((o) => o.uri.host), ['b.test']);

      async.elapse(const Duration(seconds: 2));
      expect(forwarded, hasLength(2));
    });
  });

  test('rejects with a local 429 when the pause is long', () {
    fakeAsync((async) {
      final interceptor = RetryAfterPauseInterceptor(config: config)
        ..onError(
          DioException.badResponse(
            statusCode: 503,
            requestOptions: RequestOptions(path: 'https://a.test/items'),
            response: _response(503, retryAfter: '30'),
          ),
          _SilentErrorHandler(),
        );

      send(interceptor);
      async.flushMicrotasks();

      expect(rejected.single.response?.isLocalRateLimit, isTrue);
      expect(rejected.single.response?.headers.value('retry-after'), '30');
    });
  });

  test('dispose cancels held requests and lifts every pause', () {
    fakeAsync((async) {
      final interceptor = RetryAfterPauseInterceptor(config: config)
        ..onResponse(_response(429, retryAfter: '2'), _SilentResponseHandler());
      send(interceptor);
      async.flushMicrotasks();

      interceptor.dispose();
      async.flushMicrotasks();
      send(interceptor);

      expect(rejected.single.type, DioExceptionType.cancel);
      expect(forwarded, hasLength(1));
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('rejects invalid settings', () {
    expect(
      () => RetryAfterPauseInterceptor(config: config, maxQueueSize: -1),
      throwsArgumentError,
    );
  });
}
