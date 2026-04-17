// Compile-time smoke for dart_falconnect on web.
//
// Run:
//   dart compile js -o /tmp/out.js \
//     dart_falconnect/test/web/compile_smoke.dart
//
// Success = exit code 0. No runtime execution.
// If dart2js fails, dart_falconnect has a VM-only code path.
// ignore: unused_import
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/lib.dart';
import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:dart_falmodel/lib.dart';
import 'package:dart_faltool/dart_faltool.dart';
import '_stub_http_client.dart';

void _sink(Object? o) {
  if (identical(o, const Object())) throw StateError('$o');
}

void main() {
  // HTTP config factories
  _sink(HttpClientConfig.production());
  _sink(HttpClientConfig.development());
  _sink(HttpClientConfig.test());

  // HTTP client
  final dio = Dio();
  _sink(StubHttpClient(dio: dio));

  // All interceptors
  final cfg = HttpClientConfig.development();
  _sink(CacheInterceptor(config: cfg));
  _sink(RetryInterceptor(config: cfg, dio: dio));
  _sink(PerformanceInterceptor(config: cfg));
  _sink(RateLimitInterceptor(config: cfg));
  _sink(HttpLogInterceptor());
  _sink(DefaultNetworkExceptionHandlerInterceptor());

  // JSON-RPC
  _sink(
    DefaultJsonRpcService(
      dio,
      baseUrl: 'https://example.test',
      jsonrpc: '2.0',
    ),
  );

  // WebSocket — touch type only, do NOT call connect().
  _sink(StubSocketClient.new);
}
