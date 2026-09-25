@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/src/engine/https/adapter/platform_adapter_io.dart';
import 'package:test/test.dart';

/// A loopback HTTP server that records each request's path and answers
/// once [gate] completes.
class _Server {
  new _(this.server) {
    server.listen((request) async {
      paths.add(request.uri.path);
      arrived.add(null);
      await gate?.future;
      request.response.write('{"ok":true}');
      await request.response.close();
    });
  }

  static Future<_Server> start() async =>
      _Server._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer server;
  final List<String> paths = [];
  final StreamController<void> arrived = StreamController<void>.broadcast();
  Completer<void>? gate;

  String url(String path) => 'http://127.0.0.1:${server.port}$path';

  Future<void> close() => server.close(force: true);
}

/// An adapter the app set itself; records whether it was closed.
class _AppAdapter implements HttpClientAdapter {
  int closes = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('{"app":true}', 200);

  @override
  void close({bool force = false}) => closes++;
}

class _Client extends BaseHttpClient {
  new(Dio dio, [HttpClientConfig config = const HttpClientConfig()])
    : super(dio: dio, config: config);
}

Future<void> _expectClosed(HttpClientAdapter adapter) => expectLater(
  adapter.fetch(RequestOptions(path: 'http://127.0.0.1:9/'), null, null),
  throwsStateError,
);

void main() {
  late _Server origin;

  setUp(() async => origin = await _Server.start());
  tearDown(() => origin.close());

  test('a box replaces the app adapter; null restores it unclosed', () {
    final app = _AppAdapter();
    final client = _Client(
      Dio()..httpClientAdapter = app,
      const HttpClientConfig(ioAdapter: IoAdapterConfig()),
    );
    expect(client.dio.httpClientAdapter, isA<PinningIoAdapter>());

    client.configure(const HttpClientConfig());
    expect(client.dio.httpClientAdapter, same(app));
    expect(app.closes, 0);
  });

  test('an equal box keeps the adapter', () {
    final client = _Client(
      Dio(),
      const HttpClientConfig(ioAdapter: IoAdapterConfig(proxy: 'p.test:1')),
    );
    final built = client.dio.httpClientAdapter;

    client.configure(
      const HttpClientConfig(
        baseUrl: 'https://other.test',
        ioAdapter: IoAdapterConfig(proxy: 'p.test:1'),
      ),
    );

    expect(client.dio.httpClientAdapter, same(built));
  });

  test('a webAdapter box leaves the dart:io adapter alone', () {
    final app = _AppAdapter();
    final client = _Client(
      Dio()..httpClientAdapter = app,
      const HttpClientConfig(
        webAdapter: WebAdapterConfig(withCredentials: true),
      ),
    );

    expect(client.dio.httpClientAdapter, same(app));
  });

  test('a changed box lets a running request finish, then closes', () async {
    final client = _Client(
      Dio(),
      const HttpClientConfig(ioAdapter: IoAdapterConfig()),
    );
    final old = client.dio.httpClientAdapter;
    origin.gate = Completer<void>();

    final running = client.dio.get<Object?>(origin.url('/running'));
    await origin.arrived.stream.first;
    client.configure(
      const HttpClientConfig(
        ioAdapter: IoAdapterConfig(idleTimeout: Duration(seconds: 1)),
      ),
    );
    origin.gate!.complete();

    expect((await running).statusCode, 200);
    expect(client.dio.httpClientAdapter, isNot(same(old)));
    await _expectClosed(old);
    client.dispose();
  });

  test('a request waiting in a limiter goes through the new adapter', () async {
    final proxy = await _Server.start();
    addTearDown(proxy.close);
    const concurrency = ConcurrencyConfig(global: 1);
    final client = _Client(
      Dio(),
      const HttpClientConfig(
        concurrency: concurrency,
        ioAdapter: IoAdapterConfig(),
      ),
    );
    origin.gate = Completer<void>();

    final first = client.dio.get<Object?>(origin.url('/first'));
    await origin.arrived.stream.first;
    final second = client.dio.get<Object?>(origin.url('/second'));
    client.configure(
      HttpClientConfig(
        concurrency: concurrency,
        ioAdapter: IoAdapterConfig(proxy: '127.0.0.1:${proxy.server.port}'),
      ),
    );
    origin.gate!.complete();

    expect((await first).statusCode, 200);
    expect((await second).statusCode, 200);
    expect(origin.paths, ['/first']);
    expect(proxy.paths, ['/second']);
    client.dispose();
  });

  test('dispose closes the built adapter and restores the app one', () async {
    final app = _AppAdapter();
    final client = _Client(
      Dio()..httpClientAdapter = app,
      const HttpClientConfig(ioAdapter: IoAdapterConfig()),
    );
    final built = client.dio.httpClientAdapter;

    client.dispose();

    expect(client.dio.httpClientAdapter, same(app));
    expect(app.closes, 0);
    await _expectClosed(built);

    client.configure(client.currentConfig);
    expect(client.dio.httpClientAdapter, isA<PinningIoAdapter>());
    expect(client.dio.httpClientAdapter, isNot(same(built)));
    client.dispose();
  });
}
