@TestOn('browser')
library;

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falmodel/dart_falmodel.dart' show parseRetryAfter;
import 'package:test/test.dart';

import '../engine/https/interceptors/_scripted_adapter.dart';
import '_stub_http_client.dart';

void main() {
  group('dart_falconnect on web', () {
    test('HttpClientConfig factories build without throwing', () {
      expect(HttpClientConfig.production(), isNotNull);
      expect(HttpClientConfig.development(), isNotNull);
      expect(HttpClientConfig.test(), isNotNull);
    });

    test('BaseHttpClient subclass instantiates with default adapter', () {
      final dio = Dio();
      final client = StubHttpClient(dio: dio);
      expect(client.dio, same(dio));
      expect(dio.httpClientAdapter, isNotNull);
    });

    test('All HTTP interceptors instantiate on web', () {
      final cfg = HttpClientConfig.development();
      final dio = Dio();
      expect(CacheInterceptor(config: cfg), isNotNull);
      expect(RetryInterceptor(config: cfg, dio: dio), isNotNull);
      expect(PerformanceInterceptor(config: cfg), isNotNull);
      expect(TokenBucketRateLimitInterceptor(config: cfg), isNotNull);
      expect(RetryAfterPauseInterceptor(config: cfg), isNotNull);
      expect(HttpLogInterceptor(), isNotNull);
      expect(DefaultNetworkExceptionHandlerInterceptor(), isNotNull);
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
          config: const HttpClientConfig(
            maxRetryAttempts: 2,
            retryDelay: Duration(milliseconds: 1),
            maxRetryDelay: Duration(milliseconds: 5),
          ),
          dio: dio,
        ),
      );

      final response = await dio.get<dynamic>('/x');

      expect(response.statusCode, 200);
      expect((dio.httpClientAdapter as ScriptedAdapter).requests, hasLength(2));
    });
  });
}
