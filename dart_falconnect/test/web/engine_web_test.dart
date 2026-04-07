@TestOn('browser')
library;

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:test/test.dart';

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
      expect(RateLimitInterceptor(config: cfg), isNotNull);
      expect(HttpLogInterceptor(), isNotNull);
      expect(DefaultNetworkExceptionHandlerInterceptor(), isNotNull);
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
  });
}
