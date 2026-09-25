import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

import '../../../fixtures/localhost_certificate.dart';
import '../interceptors/_scripted_adapter.dart';

class _Client extends BaseHttpClient {
  new(HttpClientAdapter adapter)
    : super(
        dio: Dio()
          ..httpClientAdapter = adapter
          ..transformer = FoldingTransformer(),
      );
}

Matcher _argumentError(String message) =>
    throwsA(isA<ArgumentError>().having((e) => e.message, 'message', message));

void main() {
  group('defaults', () {
    test('leave both adapters alone', () {
      const config = HttpClientConfig();

      expect(config.ioAdapter, isNull);
      expect(config.webAdapter, isNull);
    });

    test('match what dio does without a box', () {
      const io = IoAdapterConfig();
      const web = WebAdapterConfig();

      expect(io.maxConnectionsPerHost, isNull);
      expect(io.idleTimeout, const Duration(seconds: 3));
      expect(io.proxy, isNull);
      expect(io.pins, isEmpty);
      expect(io.debugTrustAnyCertificate, isFalse);
      expect(web.withCredentials, isFalse);
    });

    test('boxes with equal pins are equal', () {
      const a = IoAdapterConfig(
        pins: {
          'api.example.com': {localhostPin},
        },
      );
      const b = IoAdapterConfig(
        pins: {
          'api.example.com': {localhostPin},
        },
      );

      expect(a, b);
    });
  });

  group('validate', () {
    test('accepts a host name or IPv4 proxy and padded or bare pins', () {
      final unpadded = localhostPin.replaceAll('=', '');

      expect(
        () => IoAdapterConfig(
          maxConnectionsPerHost: 1,
          idleTimeout: Duration.zero,
          proxy: '192.168.1.10:9090',
          pins: {
            'API.Example.com': {localhostPin, unpadded},
          },
        ).validate(),
        returnsNormally,
      );
      expect(
        () => const IoAdapterConfig(proxy: 'proxy.local:65535').validate(),
        returnsNormally,
      );
    });

    test('rejects a connection limit below 1', () {
      expect(
        () => const IoAdapterConfig(maxConnectionsPerHost: 0).validate(),
        _argumentError('maxConnectionsPerHost must be at least 1'),
      );
    });

    test('rejects a negative idle timeout', () {
      expect(
        () =>
            const IoAdapterConfig(idleTimeout: Duration(seconds: -1))
                .validate(),
        _argumentError('idleTimeout must not be negative'),
      );
    });

    for (final proxy in [
      'http://p:8080',
      'p',
      ':8080',
      'p:0',
      'p:65536',
      'p:80a',
      '[::1]:8080',
      '::1:8080',
      'p:8080/path',
      'a;b:8080',
      'DIRECT;x:8080',
      'a%20b:8080',
    ]) {
      test('rejects the proxy "$proxy"', () {
        expect(
          () => IoAdapterConfig(proxy: proxy).validate(),
          _argumentError('proxy "$proxy" must be host:port'),
        );
      });
    }

    test('rejects an empty pin host', () {
      expect(
        () => const IoAdapterConfig(
          pins: {
            '': {localhostPin},
          },
        ).validate(),
        _argumentError('pin host "" is empty'),
      );
    });

    test('rejects a pin host with a port', () {
      expect(
        () => const IoAdapterConfig(
          pins: {
            'api.example.com:443': {localhostPin},
          },
        ).validate(),
        _argumentError(
          'pin host "api.example.com:443" must be a bare host name',
        ),
      );
    });

    // Neither can match a request's host, so each would turn pinning off.
    for (final host in ['*.example.com', 'api.example.com.']) {
      test('rejects the pin host "$host"', () {
        expect(
          () => IoAdapterConfig(
            pins: {
              host: {localhostPin},
            },
          ).validate(),
          _argumentError('pin host "$host" must be a bare host name'),
        );
      });
    }

    test('rejects a pin host with no pin', () {
      expect(
        () =>
            const IoAdapterConfig(pins: {'api.example.com': <String>{}})
                .validate(),
        _argumentError('pin host "api.example.com" has no pin'),
      );
    });

    for (final pin in [
      'AAAA',
      'sha1/QqpXzCTGTZNjvpITlKLoKPESRb8C33BVNBPi3mSWk+s=',
      'sha256/not base64!',
      'sha256/AAAA',
    ]) {
      test('rejects the pin "$pin"', () {
        expect(
          () => IoAdapterConfig(
            pins: {
              'api.example.com': {pin},
            },
          ).validate(),
          _argumentError(
            'pin "$pin" for api.example.com must be "sha256/" followed by '
            'base64 of 32 bytes',
          ),
        );
      });
    }
  });

  test('configure throws on a bad pin and keeps the configuration', () {
    final adapter = ScriptedAdapter([reply(200)]);
    final client = _Client(adapter);
    const before = HttpClientConfig(baseUrl: 'https://before.test');
    client.configure(before);

    expect(
      () => client.configure(
        const HttpClientConfig(
          baseUrl: 'https://after.test',
          ioAdapter: IoAdapterConfig(
            pins: {
              'after.test': {'AAAA'},
            },
          ),
        ),
      ),
      throwsArgumentError,
    );
    expect(client.currentConfig, before);
    expect(client.baseUrl, 'https://before.test');
    expect(client.dio.httpClientAdapter, same(adapter));
  });
}
