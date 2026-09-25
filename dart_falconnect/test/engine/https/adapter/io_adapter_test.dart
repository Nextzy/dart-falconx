@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/src/engine/https/adapter/platform_adapter_io.dart';
import 'package:test/test.dart';

import '../../../fixtures/localhost_certificate.dart';

const _wrongPin = 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';

/// A loopback server that counts the requests it receives and answers
/// each with 200 once [gate] completes.
class _Server {
  new _(this.server) {
    server.listen((request) async {
      requests.add(request.uri);
      await gate?.future;
      request.response.write('{"ok":true}');
      await request.response.close();
    });
  }

  static Future<_Server> https() async {
    final context = SecurityContext()
      ..useCertificateChain('test/fixtures/localhost.crt.pem')
      ..usePrivateKey('test/fixtures/localhost.key.pem');
    return _Server._(
      await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context),
    );
  }

  static Future<_Server> http() async =>
      _Server._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer server;
  final List<Uri> requests = [];
  Completer<void>? gate;

  int get port => server.port;

  Future<void> close() => server.close(force: true);
}

class _Client extends BaseHttpClient {
  new(HttpClientConfig config) : super(dio: Dio(), config: config);
}

/// Counts the attempts that pass the custom slot.
class _AttemptCounter extends Interceptor {
  int attempts = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    attempts++;
    handler.next(options);
  }
}

Future<Response<Object?>> _get(BaseHttpClient client, String url) =>
    client.dio.get<Object?>(
      url,
      options: Options(headers: {'Authorization': 'Bearer secret-token'}),
    );

Matcher _pinFailure(PinFailure failure, {String? presented}) => throwsA(
  isA<DioException>()
      .having((e) => e.type, 'type', DioExceptionType.badCertificate)
      .having(
        (e) => e.error,
        'error',
        isA<CertificatePinningException>()
            .having((e) => e.failure, 'failure', failure)
            .having((e) => e.host, 'host', 'localhost')
            .having((e) => e.presented, 'presented', presented),
      ),
);

void main() {
  late _Server tls;

  setUp(() async => tls = await _Server.https());
  tearDown(() => tls.close());

  String tlsUrl() => 'https://localhost:${tls.port}/me';

  // The fixture is self-signed, so every pin test also sets the debug
  // switch, which works under `dart test` because assertions are on.
  IoAdapterConfig pinned(Set<String> pins, {String? proxy}) => IoAdapterConfig(
    pins: {'localhost': pins},
    proxy: proxy,
    debugTrustAnyCertificate: true,
  );

  group('pins', () {
    test('a matching pin sends the request', () async {
      final client = _Client(
        HttpClientConfig(ioAdapter: pinned({localhostPin})),
      );

      final response = await _get(client, tlsUrl());

      expect(response.statusCode, 200);
      expect(tls.requests, hasLength(1));
      client.dispose();
    });

    test('a backup pin sends the request', () async {
      final client = _Client(
        HttpClientConfig(ioAdapter: pinned({_wrongPin, localhostPin})),
      );

      expect((await _get(client, tlsUrl())).statusCode, 200);
      client.dispose();
    });

    test('a wrong pin fails before the server receives anything', () async {
      final client = _Client(HttpClientConfig(ioAdapter: pinned({_wrongPin})));

      await expectLater(
        _get(client, tlsUrl()),
        _pinFailure(PinFailure.mismatch, presented: localhostPin),
      );
      expect(tls.requests, isEmpty);
      client.dispose();
    });

    test('the error names the presented pin', () async {
      final client = _Client(HttpClientConfig(ioAdapter: pinned({_wrongPin})));

      try {
        await _get(client, tlsUrl());
        fail('the request should fail');
      } on DioException catch (e) {
        expect(
          '${e.error}',
          'CertificatePinningException: localhost presented $localhostPin, '
              'expected one of $_wrongPin',
        );
      }
      client.dispose();
    });

    test('a pin without base64 padding matches', () async {
      final client = _Client(
        HttpClientConfig(ioAdapter: pinned({localhostPin.replaceAll('=', '')})),
      );

      expect((await _get(client, tlsUrl())).statusCode, 200);
      client.dispose();
    });

    test('an unpinned https host still has its chain validated', () async {
      final client = _Client(
        const HttpClientConfig(
          ioAdapter: IoAdapterConfig(
            pins: {
              'pinned.example': {localhostPin},
            },
          ),
        ),
      );

      await expectLater(
        _get(client, tlsUrl()),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<HandshakeException>(),
          ),
        ),
      );
      expect(tls.requests, isEmpty);
      client.dispose();
    });

    test('an unpinned https host passes with the debug switch', () async {
      final client = _Client(
        const HttpClientConfig(
          ioAdapter: IoAdapterConfig(
            pins: {
              'pinned.example': {localhostPin},
            },
            debugTrustAnyCertificate: true,
          ),
        ),
      );

      expect((await _get(client, tlsUrl())).statusCode, 200);
      client.dispose();
    });

    test('a host is matched without regard to case', () async {
      final client = _Client(
        const HttpClientConfig(
          ioAdapter: IoAdapterConfig(
            pins: {
              'LocalHost': {_wrongPin},
            },
            debugTrustAnyCertificate: true,
          ),
        ),
      );

      await expectLater(
        _get(client, tlsUrl()),
        _pinFailure(PinFailure.mismatch, presented: localhostPin),
      );
      client.dispose();
    });

    test('a host with a trailing dot is matched to its pin', () async {
      final client = _Client(HttpClientConfig(ioAdapter: pinned({_wrongPin})));

      await expectLater(
        _get(client, 'https://localhost.:${tls.port}/me'),
        _pinFailure(PinFailure.mismatch, presented: localhostPin),
      );
      expect(tls.requests, isEmpty);
      client.dispose();
    });

    test('a pinned host through a proxy fails before any connect', () async {
      final proxy = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      var proxyConnections = 0;
      proxy.listen((socket) {
        proxyConnections++;
        socket.destroy();
      });
      addTearDown(proxy.close);
      final client = _Client(
        HttpClientConfig(
          ioAdapter: pinned({localhostPin}, proxy: 'localhost:${proxy.port}'),
        ),
      );

      await expectLater(
        _get(client, tlsUrl()),
        _pinFailure(PinFailure.proxied),
      );
      expect(proxyConnections, 0);
      expect(tls.requests, isEmpty);
      client.dispose();
    });

    test('a pinned host over plain http fails before any connect', () async {
      final plain = await _Server.http();
      addTearDown(plain.close);
      final client = _Client(
        HttpClientConfig(ioAdapter: pinned({localhostPin})),
      );

      await expectLater(
        _get(client, 'http://localhost:${plain.port}/me'),
        _pinFailure(PinFailure.plainHttp),
      );
      expect(plain.requests, isEmpty);
      client.dispose();
    });

    // dart:io checks the scheme only while no connection factory is set.
    for (final scheme in ['ftp', 'wss']) {
      test('a pinning client refuses a $scheme URL, as dart:io does', () async {
        final plain = await _Server.http();
        addTearDown(plain.close);
        final client = _Client(
          const HttpClientConfig(
            ioAdapter: IoAdapterConfig(
              pins: {
                'pinned.example': {localhostPin},
              },
            ),
          ),
        );

        await expectLater(
          _get(client, '$scheme://127.0.0.1:${plain.port}/me'),
          throwsA(
            isA<DioException>().having(
              (e) => e.error,
              'error',
              isA<ArgumentError>(),
            ),
          ),
        );
        expect(plain.requests, isEmpty);
        client.dispose();
      });
    }

    test('RetryInterceptor makes one attempt on a pin failure', () async {
      final counter = _AttemptCounter();
      final client = _Client(
        HttpClientConfig(
          interceptors: [counter],
          retry: const RetryConfig(delay: Duration.zero),
          ioAdapter: pinned({_wrongPin}),
        ),
      );

      await expectLater(
        _get(client, tlsUrl()),
        _pinFailure(PinFailure.mismatch, presented: localhostPin),
      );
      expect(counter.attempts, 1);
      client.dispose();
    });
  });

  group('debug switch', () {
    test('without it, a self-signed server fails its handshake', () async {
      final client = _Client(
        const HttpClientConfig(ioAdapter: IoAdapterConfig()),
      );

      await expectLater(
        _get(client, tlsUrl()),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<HandshakeException>(),
          ),
        ),
      );
      expect(tls.requests, isEmpty);
      client.dispose();
    });

    test('with it, a self-signed server answers', () async {
      final client = _Client(
        const HttpClientConfig(
          ioAdapter: IoAdapterConfig(debugTrustAnyCertificate: true),
        ),
      );

      expect((await _get(client, tlsUrl())).statusCode, 200);
      client.dispose();
    });

    test('takes effect only while assertions are enabled', () {
      const on = IoAdapterConfig(debugTrustAnyCertificate: true);
      const off = IoAdapterConfig();

      expect(trustsAnyCertificate(on, assertionsEnabled: true), isTrue);
      expect(trustsAnyCertificate(on, assertionsEnabled: false), isFalse);
      expect(trustsAnyCertificate(off, assertionsEnabled: true), isFalse);
    });
  });

  group('proxy', () {
    late _Server origin;
    late _Server proxy;

    setUp(() async {
      origin = await _Server.http();
      proxy = await _Server.http();
    });
    tearDown(() async {
      await origin.close();
      await proxy.close();
    });

    // Pins on another host keep the connection factory in the path.
    for (final pins in <Map<String, Set<String>>>[
      {},
      {
        'pinned.example': {localhostPin},
      },
    ]) {
      final label = pins.isEmpty ? 'without pins' : 'with a factory';

      test('$label, an unpinned request goes through the proxy', () async {
        final client = _Client(
          HttpClientConfig(
            ioAdapter: IoAdapterConfig(
              proxy: '127.0.0.1:${proxy.port}',
              pins: pins,
            ),
          ),
        );

        final response = await _get(
          client,
          'http://127.0.0.1:${origin.port}/me',
        );

        expect(response.statusCode, 200);
        expect(proxy.requests.single.path, '/me');
        expect(origin.requests, isEmpty);
        client.dispose();
      });

      test('$label, a closed proxy falls back to direct', () async {
        final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final port = closed.port;
        await closed.close();
        final client = _Client(
          HttpClientConfig(
            ioAdapter: IoAdapterConfig(proxy: '127.0.0.1:$port', pins: pins),
          ),
        );

        final response = await _get(
          client,
          'http://127.0.0.1:${origin.port}/me',
        );

        expect(response.statusCode, 200);
        expect(origin.requests, hasLength(1));
        client.dispose();
      });
    }

    test('a pinned host over http skips a warm proxy connection', () async {
      final client = _Client(
        HttpClientConfig(
          ioAdapter: IoAdapterConfig(
            proxy: '127.0.0.1:${proxy.port}',
            pins: {
              'localhost': {localhostPin},
            },
          ),
        ),
      );
      // An unpinned request leaves an idle connection to the proxy, which
      // dart:io reuses without calling the connection factory.
      await _get(client, 'http://127.0.0.1:${origin.port}/warm');

      await expectLater(
        _get(client, 'http://localhost:${origin.port}/secret'),
        _pinFailure(PinFailure.plainHttp),
      );
      expect(proxy.requests.map((uri) => uri.path), ['/warm']);
      expect(origin.requests, isEmpty);
      client.dispose();
    });

    test('a pinned host over http skips a warm environment proxy', () async {
      // Stands in for http_proxy in the environment, which a test cannot set.
      await HttpOverrides.runZoned(
        () async {
          final client = _Client(
            const HttpClientConfig(
              ioAdapter: IoAdapterConfig(
                pins: {
                  'localhost': {localhostPin},
                },
              ),
            ),
          );
          await _get(client, 'http://127.0.0.1:${origin.port}/warm');

          await expectLater(
            _get(client, 'http://localhost:${origin.port}/secret'),
            _pinFailure(PinFailure.plainHttp),
          );
          expect(proxy.requests.map((uri) => uri.path), ['/warm']);
          expect(origin.requests, isEmpty);
          client.dispose();
        },
        findProxyFromEnvironment: (uri, environment) =>
            'PROXY 127.0.0.1:${proxy.port}',
      );
    });
  });

  group('findProxyFor', () {
    const pins = {
      'localhost': {localhostPin},
    };
    const environment = {
      'http_proxy': 'env.proxy:3128',
      'https_proxy': 'env.proxy:3128',
    };
    final http = Uri.parse('http://localhost/me');
    final https = Uri.parse('https://localhost/me');

    test('sends a pinned host over http direct, to the factory', () {
      expect(findProxyFor(http, pins, proxy: 'p.test:1'), 'DIRECT');
      expect(findProxyFor(http, pins, environment: environment), 'DIRECT');
      expect(
        findProxyFor(
          Uri.parse('http://localhost./me'),
          pins,
          proxy: 'p.test:1',
        ),
        'DIRECT',
      );
    });

    test('keeps a pinned https host on its proxy, with no DIRECT', () {
      expect(findProxyFor(https, pins, proxy: 'p.test:1'), 'PROXY p.test:1');
      expect(
        findProxyFor(https, pins, environment: environment),
        'PROXY env.proxy:3128',
      );
    });

    test('lets an unpinned host fall back to direct', () {
      final other = Uri.parse('http://other.test/me');

      expect(
        findProxyFor(other, pins, proxy: 'p.test:1'),
        'PROXY p.test:1; DIRECT',
      );
      expect(
        findProxyFor(other, pins, environment: environment),
        HttpClient.findProxyFromEnvironment(other, environment: environment),
      );
    });
  });

  group('HttpClient', () {
    test('takes the idle timeout and the connection limit', () {
      final client = createIoHttpClient(
        const IoAdapterConfig(
          maxConnectionsPerHost: 2,
          idleTimeout: Duration(seconds: 9),
        ),
        trustAny: false,
      );

      expect(client.idleTimeout, const Duration(seconds: 9));
      expect(client.maxConnectionsPerHost, 2);
      client.close(force: true);
    });

    test('opens one connection at a time when the limit is 1', () async {
      final origin = await _Server.http();
      addTearDown(origin.close);
      origin.gate = Completer<void>();
      final client = _Client(
        const HttpClientConfig(
          ioAdapter: IoAdapterConfig(maxConnectionsPerHost: 1),
        ),
      );
      final url = 'http://127.0.0.1:${origin.port}/me';

      final first = _get(client, url);
      final second = _get(client, url);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(origin.requests, hasLength(1));
      expect(origin.server.connectionsInfo().total, 1);
      origin.gate!.complete();
      expect((await first).statusCode, 200);
      expect((await second).statusCode, 200);
      expect(origin.requests, hasLength(2));
      client.dispose();
    });
  });

  group('diagnostics', () {
    test('warn when the connection limit is below a concurrency limit', () {
      const config = HttpClientConfig(
        concurrency: ConcurrencyConfig(perHost: 4, hosts: {'a.test': 8}),
        ioAdapter: IoAdapterConfig(maxConnectionsPerHost: 2),
      );

      const message =
          '[ioAdapter] maxConnectionsPerHost 2 is below the concurrency limit '
          '8: requests past 2 wait inside HttpClient and count toward '
          'connectTimeout';

      expect(adapterDiagnostics(config, adapterBuilt: false), [message]);
    });

    test('stay quiet when the connection limit covers concurrency', () {
      const config = HttpClientConfig(
        concurrency: ConcurrencyConfig(perHost: 4),
        ioAdapter: IoAdapterConfig(maxConnectionsPerHost: 4),
      );

      expect(adapterDiagnostics(config, adapterBuilt: true), isEmpty);
    });

    test('name the debug switch and a host with one pin', () {
      final config = HttpClientConfig(ioAdapter: pinned({localhostPin}));

      const trusted =
          '[ioAdapter] debugTrustAnyCertificate is in effect: every '
          'certificate chain is trusted';

      expect(adapterDiagnostics(config, adapterBuilt: true), [
        trusted,
        '[ioAdapter] localhost has one pin: add a backup pin',
      ]);
      expect(adapterDiagnostics(config, adapterBuilt: false), isEmpty);
    });

    test('print through the log box when configure builds', () {
      final lines = <String>[];
      final client = _Client(
        HttpClientConfig(
          log: LogConfig(logPrint: (line) => lines.add('$line')),
          concurrency: const ConcurrencyConfig(perHost: 4),
          ioAdapter: const IoAdapterConfig(maxConnectionsPerHost: 2),
        ),
      );
      expect(
        lines.where((line) => line.startsWith('[ioAdapter]')),
        hasLength(1),
      );

      client.configure(
        client.currentConfig.copyWith(
          concurrency: const ConcurrencyConfig(perHost: 6),
        ),
      );
      expect(
        lines.where((line) => line.startsWith('[ioAdapter]')),
        hasLength(2),
      );

      client.configure(
        client.currentConfig.copyWith(baseUrl: 'https://x.test'),
      );
      expect(
        lines.where((line) => line.startsWith('[ioAdapter]')),
        hasLength(2),
      );
      client.dispose();
    });
  });
}
