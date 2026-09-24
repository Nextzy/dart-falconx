import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

Dio _dio(List<Reply> script) =>
    Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = ScriptedAdapter(script);

void main() {
  test('RetryInterceptor prints through logPrint', () {
    fakeAsync((async) {
      final lines = <String>[];
      final dio = _dio([reply(500), reply(200)]);
      dio.interceptors.add(
        RetryInterceptor(
          config: const RetryConfig(delay: Duration(milliseconds: 1)),
          dio: dio,
          logPrint: lines.add,
        ),
      );

      dio.get<dynamic>('/x').ignore();
      async.elapse(const Duration(seconds: 1));

      expect(lines, hasLength(1));
      expect(lines.single, startsWith('[RetryInterceptor] Retrying request 1'));
    });
  });

  test('CacheInterceptor prints a hit through logPrint', () async {
    final lines = <String>[];
    final dio = _dio([reply(200)]);
    dio.interceptors.add(CacheInterceptor(logPrint: lines.add));

    await dio.get<dynamic>('/x');
    await dio.get<dynamic>('/x');

    expect(
      lines.where((line) => line.startsWith('[CacheInterceptor] Cache hit')),
      hasLength(1),
    );
  });

  test('an interceptor without logPrint prints nothing', () {
    fakeAsync((async) {
      final dio = _dio([reply(500), reply(200)]);
      dio.interceptors.add(
        RetryInterceptor(
          config: const RetryConfig(delay: Duration(milliseconds: 1)),
          dio: dio,
        ),
      );

      var done = false;
      dio.get<dynamic>('/x').then((_) => done = true).ignore();
      async.elapse(const Duration(seconds: 1));

      expect(done, isTrue);
    });
  });

  test('every config parameter has a default box', () {
    final dio = Dio();

    expect(CacheInterceptor().config, const CacheConfig());
    expect(PerformanceInterceptor().config, const PerformanceConfig());
    expect(RetryInterceptor(dio: dio).config, const RetryConfig());
    expect(ConcurrencyLimitInterceptor().config, const ConcurrencyConfig());
    expect(
      TokenBucketRateLimitInterceptor().config,
      const TokenBucketRateLimitConfig(),
    );
    expect(
      RetryAfterPauseInterceptor().config,
      const PauseOnlyRateLimitConfig(),
    );
  });
}
