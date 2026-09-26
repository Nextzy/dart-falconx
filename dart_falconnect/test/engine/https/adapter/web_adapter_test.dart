@TestOn('browser')
library;

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dio/browser.dart';
import 'package:test/test.dart';

import '../../../fixtures/localhost_certificate.dart';

class _Client extends BaseHttpClient {
  new(Dio dio, HttpClientConfig config) : super(dio: dio, config: config);
}

void main() {
  test('webAdapter sets withCredentials on a browser adapter', () {
    final client = _Client(
      Dio(),
      const HttpClientConfig(
        webAdapter: WebAdapterConfig(withCredentials: true),
      ),
    );

    expect(
      client.dio.httpClientAdapter,
      isA<BrowserHttpClientAdapter>().having(
        (a) => a.withCredentials,
        'withCredentials',
        isTrue,
      ),
    );
  });

  test('an ioAdapter box leaves the browser adapter alone', () {
    final dio = Dio();
    final original = dio.httpClientAdapter;
    _Client(
      dio,
      const HttpClientConfig(
        ioAdapter: IoAdapterConfig(
          maxConnectionsPerHost: 2,
          proxy: 'localhost:9090',
          pins: {
            'api.example.com': {localhostPin},
          },
          debugTrustAnyCertificate: true,
        ),
      ),
    );

    expect(dio.httpClientAdapter, same(original));
  });

  test('a webAdapter box that returns to null restores the adapter', () {
    final dio = Dio();
    final original = dio.httpClientAdapter;
    final client = _Client(
      dio,
      const HttpClientConfig(
        webAdapter: WebAdapterConfig(withCredentials: true),
      ),
    );
    expect(dio.httpClientAdapter, isNot(same(original)));

    client.configure(const HttpClientConfig());
    expect(dio.httpClientAdapter, same(original));
  });
}
