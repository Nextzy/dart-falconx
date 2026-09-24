@TestOn('browser')
library;

import 'dart:convert';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falmodel/dart_falmodel.dart' show parseRetryAfter;
import 'package:test/test.dart';

import '../engine/https/interceptors/_scripted_adapter.dart';
import '_stub_http_client.dart';

void main() {
  group('dart_falconnect on web', () {
    test('HttpClientConfig builds with every box set', () {
      expect(
        const HttpClientConfig(
          log: LogConfig(),
          performance: PerformanceConfig(),
          cache: CacheConfig(),
          concurrency: ConcurrencyConfig(global: 16, perHost: 4),
          rateLimit: RateLimitConfig.tokenBucket(),
          retry: RetryConfig(),
        ),
        isNotNull,
      );
    });

    test('BaseHttpClient subclass instantiates with default adapter', () {
      final dio = Dio();
      final client = StubHttpClient(dio: dio);
      expect(client.dio, same(dio));
      expect(dio.httpClientAdapter, isNotNull);
    });

    test('All HTTP interceptors instantiate on web', () {
      final dio = Dio();
      expect(CacheInterceptor(), isNotNull);
      expect(ConcurrencyLimitInterceptor(), isNotNull);
      expect(RetryInterceptor(dio: dio), isNotNull);
      expect(PerformanceInterceptor(), isNotNull);
      expect(TokenBucketRateLimitInterceptor(), isNotNull);
      expect(RetryAfterPauseInterceptor(), isNotNull);
      expect(HttpLogInterceptor(), isNotNull);
      expect(HttpJsonLogInterceptor(), isNotNull);
      expect(DefaultNetworkExceptionHandlerInterceptor(), isNotNull);
    });

    test('HttpJsonLogInterceptor prints one JSON line on web', () async {
      final lines = <Object?>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = ScriptedAdapter([reply(200)]);
      dio.interceptors.add(
        HttpJsonLogInterceptor(config: JsonLogConfig(logPrint: lines.add)),
      );

      await dio.get<dynamic>('/x?token=t');

      final line = jsonDecode(lines.single! as String) as Map<String, Object?>;
      expect(line['url.full'], 'https://a.test/x?token=REDACTED');
      expect(line['http.response.status_code'], 200);
    });

    test('parseRetryAfter reads an HTTP-date on web', () {
      expect(
        parseRetryAfter(
          'Wed, 21 Oct 2026 07:28:30 GMT',
          serverDate: DateTime.utc(2026, 10, 21, 7, 28),
        ),
        const Duration(seconds: 30),
      );
    });

    test('DefaultJsonRpcService builds on web', () {
      final dio = Dio();
      final rpc = DefaultJsonRpcService(
        dio,
        baseUrl: 'https://example.com',
        jsonrpc: '2.0',
      );
      expect(rpc, isNotNull);
    });

    test('RetryInterceptor backs off and retries on web', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = ScriptedAdapter([reply(500), reply(200)]);
      dio.interceptors.add(
        RetryInterceptor(
          config: const RetryConfig(
            maxAttempts: 2,
            delay: Duration(milliseconds: 1),
            maxDelay: Duration(milliseconds: 5),
          ),
          dio: dio,
        ),
      );

      final response = await dio.get<dynamic>('/x');

      expect(response.statusCode, 200);
      expect((dio.httpClientAdapter as ScriptedAdapter).requests, hasLength(2));
    });

    test(
      'ConcurrencyLimitInterceptor passes requests through a limit of 1 on web',
      () async {
        final adapter = ScriptedAdapter([reply(200)]);
        final concurrency = ConcurrencyLimitInterceptor(
          config: const ConcurrencyConfig(perHost: 1),
        );
        final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
          ..httpClientAdapter = adapter;
        dio.interceptors.add(concurrency);

        final responses = await Future.wait([
          dio.get<dynamic>('/1'),
          dio.get<dynamic>('/2'),
        ]);

        expect(responses.map((r) => r.statusCode), [200, 200]);
        expect(concurrency.getStatistics().forwarded, 2);
        expect(concurrency.getStatistics().activeByHost, isEmpty);
      },
    );
  });
}
