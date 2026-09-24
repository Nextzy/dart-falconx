import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/auth_extra.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

class _Client extends BaseHttpClient {
  new(HttpClientAdapter adapter, HttpClientConfig config)
    : super(
        dio: Dio()
          ..httpClientAdapter = adapter
          ..transformer = FoldingTransformer(),
        config: config,
      );
}

const _noWait = RetryConfig(delay: Duration.zero);

/// Returns 'id-1', 'id-2', ... and counts its calls.
class _Ids {
  int calls = 0;

  String next() => 'id-${++calls}';
}

AuthConfig _auth(String? Function() token, {String? scheme, String? name}) =>
    AuthConfig(
      accessToken: token,
      refresh: () async => false,
      scheme: scheme ?? 'Bearer',
      headerName: name ?? 'Authorization',
    );

void main() {
  group('request ID', () {
    test('every attempt of a retried request carries one ID', () async {
      final ids = _Ids();
      final adapter = ScriptedAdapter([reply(503), reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(
          requestId: RequestIdConfig(generate: ids.next),
          retry: _noWait,
        ),
      );

      final response = await client.dio.get<dynamic>('/x');

      expect(adapter.requests.map((r) => r.headers['x-request-id']), [
        'id-1',
        'id-1',
      ]);
      expect(ids.calls, 1);
      expect(response.requestOptions.requestId, 'id-1');
    });

    test('a request that sets its own ID keeps it', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        const HttpClientConfig(requestId: RequestIdConfig()),
      );

      final response = await client.dio.get<dynamic>(
        '/x',
        options: Options(headers: {'X-Request-ID': 'mine'}),
      );

      expect(adapter.requests.single.headers['x-request-id'], 'mine');
      expect(response.requestOptions.requestId, 'mine');
    });

    test('the default ID is a UUID v7 under the configured header', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        const HttpClientConfig(
          requestId: RequestIdConfig(headerName: 'X-Correlation-ID'),
        ),
      );

      await client.dio.get<dynamic>('/x');

      expect(
        adapter.requests.single.headers['x-correlation-id'],
        matches(
          RegExp(
            '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}'
            r'-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(adapter.requests.single.headers, isNot(contains('x-request-id')));
    });

    test('without the box no ID is sent and no stamp is built', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(adapter, const HttpClientConfig());

      final response = await client.dio.get<dynamic>('/x');

      expect(adapter.requests.single.headers, isNot(contains('x-request-id')));
      expect(response.requestOptions.requestId, isNull);
      expect(client.interceptors.whereType<RequestStampInterceptor>(), isEmpty);
    });
  });

  group('header provider', () {
    test('overrides configured headers and loses to the request', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(
          headers: const {'A': 'config', 'B': 'config'},
          headerProvider: (_) => {'A': 'provider', 'C': 'provider'},
        ),
      );

      await client.dio.get<dynamic>(
        '/x',
        options: Options(headers: {'C': 'request'}),
      );

      final headers = adapter.requests.single.headers;
      expect(headers['a'], 'provider');
      expect(headers['b'], 'config');
      expect(headers['c'], 'request');
    });

    test('a retry attempt calls the provider again and overwrites its own '
        'values', () async {
      var calls = 0;
      final adapter = ScriptedAdapter([reply(503), reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(
          headerProvider: (_) async => {'X-Stamp': '${++calls}'},
          retry: _noWait,
        ),
      );

      await client.dio.get<dynamic>('/x');

      expect(adapter.requests.map((r) => r.headers['x-stamp']), ['1', '2']);
    });

    test('a request header wins over the provider whatever its case', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(headerProvider: (_) => {'Accept-Language': 'en'}),
      );

      await client.dio.get<dynamic>(
        '/x',
        options: Options(headers: {'accept-language': 'th'}),
      );

      expect(adapter.requests.single.headers['Accept-Language'], 'th');
    });

    test('sees the request ID', () async {
      final ids = _Ids();
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(
          requestId: RequestIdConfig(generate: ids.next),
          headerProvider: (options) => {'X-Seen': options.requestId ?? 'none'},
        ),
      );

      await client.dio.get<dynamic>('/x');

      expect(adapter.requests.single.headers['x-seen'], 'id-1');
    });
  });

  group('auth header', () {
    test('stamps Bearer and the token by default', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(auth: _auth(() => 't1')),
      );

      await client.dio.get<dynamic>('/x');

      expect(adapter.requests.single.headers['authorization'], 'Bearer t1');
    });

    test('an empty scheme sends the bare token under the configured '
        'header', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(
          auth: _auth(() => 't1', scheme: '', name: 'X-Token'),
        ),
      );

      await client.dio.get<dynamic>('/x');

      final headers = adapter.requests.single.headers;
      expect(headers['x-token'], 't1');
      expect(headers, isNot(contains('authorization')));
    });

    test('a null token sends no header', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(auth: _auth(() => null)),
      );

      await client.dio.get<dynamic>('/x');

      expect(adapter.requests.single.headers, isNot(contains('authorization')));
    });

    test(
      'isUseToken false sends no header and never reads the token',
      () async {
        var reads = 0;
        final adapter = ScriptedAdapter([reply(200)]);
        final client = _Client(
          adapter,
          HttpClientConfig(auth: _auth(() => 't${++reads}')),
        );

        await client.get<Object?>(
          '/x',
          isUseToken: false,
          converter: (json) => json,
        );

        expect(
          adapter.requests.single.headers,
          isNot(contains('authorization')),
        );
        expect(reads, 0);
      },
    );

    test('overwrites an Authorization the request set', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(auth: _auth(() => 't1')),
      );

      await client.dio.get<dynamic>(
        '/x',
        options: Options(headers: {'Authorization': 'Basic abc'}),
      );

      expect(adapter.requests.single.headers['authorization'], 'Bearer t1');
    });

    test(
      'a retry attempt drops the token once accessToken returns null',
      () async {
        String? token = 't1';
        final adapter = ScriptedAdapter([reply(503), reply(200)]);
        final client = _Client(
          adapter,
          HttpClientConfig(
            auth: _auth(() => token),
            retry: RetryConfig(
              delay: Duration.zero,
              onRetry: (_, _, _) => token = null,
            ),
          ),
        );

        await client.dio.get<dynamic>('/x');

        expect(adapter.requests.map((r) => r.headers['authorization']), [
          'Bearer t1',
          null,
        ]);
        expect(adapter.requests.map((r) => r.stampedToken), ['t1', null]);
      },
    );

    test('the cache keeps one entry per token under a custom header', () async {
      var token = 't1';
      final adapter = ScriptedAdapter([
        reply(200, headers: {'cache-control': 'max-age=60'}),
      ]);
      final client = _Client(
        adapter,
        HttpClientConfig(
          baseUrl: 'https://a.test',
          cache: const CacheConfig(),
          auth: _auth(() => token, name: 'X-Access-Token'),
        ),
      );

      await client.dio.get<dynamic>('/x');
      token = 't2';
      final second = await client.dio.get<dynamic>('/x');

      expect(adapter.requests, hasLength(2));
      expect(second.isCacheHit, isFalse);
    });

    test('the cache keeps one entry per token', () async {
      var token = 't1';
      final adapter = ScriptedAdapter([
        reply(200, headers: {'cache-control': 'max-age=60'}),
      ]);
      final client = _Client(
        adapter,
        HttpClientConfig(
          baseUrl: 'https://a.test',
          cache: const CacheConfig(),
          auth: _auth(() => token),
        ),
      );

      await client.dio.get<dynamic>('/x');
      token = 't2';
      await client.dio.get<dynamic>('/x');
      token = 't1';
      final hit = await client.dio.get<dynamic>('/x');

      expect(adapter.requests, hasLength(2));
      expect(hit.isCacheHit, isTrue);
    });
  });

  group('callback failures', () {
    test('a throwing provider fails the request before the network, and the '
        'log sees it', () async {
      final lines = <Object?>[];
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(
          headerProvider: (_) => throw StateError('no locale'),
          log: LogConfig.json(logPrint: lines.add),
          concurrency: const ConcurrencyConfig(global: 1),
        ),
      );
      addTearDown(client.dispose);

      final error = await client.dio
          .get<dynamic>('/x')
          .then<DioException?>(
            (_) => null,
            onError: (Object e) => e as DioException,
          );

      expect(error!.type, DioExceptionType.unknown);
      expect(error.error, isA<StateError>());
      expect(error.message, contains('HttpClientConfig.headerProvider'));
      expect(adapter.requests, isEmpty);
      expect(lines, hasLength(1));
      final limiter = client.interceptors
          .whereType<ConcurrencyLimitInterceptor>()
          .single;
      expect(limiter.getStatistics().globalActive, 0);
    });

    test('a throwing generate names its callback', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(
          requestId: RequestIdConfig(
            generate: () => throw StateError('no entropy'),
          ),
        ),
      );

      final error = await client.dio
          .get<dynamic>('/x')
          .then<DioException?>(
            (_) => null,
            onError: (Object e) => e as DioException,
          );

      expect(error!.error, isA<StateError>());
      expect(error.message, contains('RequestIdConfig.generate'));
      expect(adapter.requests, isEmpty);
    });

    test('a throwing accessToken names its callback', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(
        adapter,
        HttpClientConfig(auth: _auth(() => throw StateError('locked'))),
      );

      final error = await client.dio
          .get<dynamic>('/x')
          .then<DioException?>(
            (_) => null,
            onError: (Object e) => e as DioException,
          );

      expect(error!.message, contains('AuthConfig.accessToken'));
      expect(adapter.requests, isEmpty);
    });
  });
  group('logs', () {
    test('the pretty log prints the request ID in the request title and '
        'never the token', () async {
      final lines = <Object?>[];
      final client = _Client(
        ScriptedAdapter([reply(200)]),
        HttpClientConfig(
          log: LogConfig(logPrint: lines.add, requestHeader: true),
          requestId: RequestIdConfig(generate: () => 'id-1'),
          auth: _auth(() => 'secret-token'),
        ),
      );

      await client.dio.get<dynamic>('/x');

      final text = lines.join('\n');
      expect(text, contains('*** Request id-1 ***'));
      expect(text, contains('dart_falconnect.auth.token: REDACTED'));
      expect(text, isNot(contains('secret-token')));
    });

    test('a custom token header is redacted in both logs, as Authorization '
        'is', () async {
      final lines = <Object?>[];
      final client = _Client(
        ScriptedAdapter([reply(200)]),
        HttpClientConfig(
          log: LogConfig(logPrint: lines.add, requestHeader: true),
          auth: _auth(() => 'secret-token', name: 'X-Access-Token'),
        ),
      );

      await client.dio.get<dynamic>('/x');
      client.configure(
        client.currentConfig.copyWith(
          log: LogConfig.json(logPrint: lines.add, requestHeaders: true),
        ),
      );
      await client.dio.get<dynamic>('/x');

      final text = lines.join('\n');
      expect(text, contains('X-Access-Token'));
      expect(text, contains('http.request.header.x-access-token'));
      expect(text, isNot(contains('secret-token')));
    });

    test('an empty redaction set still prints a custom token header', () async {
      final lines = <Object?>[];
      final client = _Client(
        ScriptedAdapter([reply(200)]),
        HttpClientConfig(
          log: LogConfig(
            logPrint: lines.add,
            requestHeader: true,
            redactHeaders: const {},
          ),
          auth: _auth(() => 'secret-token', name: 'X-Access-Token'),
        ),
      );

      await client.dio.get<dynamic>('/x');

      expect(lines.join('\n'), contains('secret-token'));
    });
  });
}
