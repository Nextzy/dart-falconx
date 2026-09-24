import 'dart:convert';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import 'interceptors/_scripted_adapter.dart';

class _Client extends BaseHttpClient {
  new(HttpClientAdapter adapter)
    : super(
        dio: Dio()
          ..httpClientAdapter = adapter
          ..transformer = FoldingTransformer(),
      );
}

/// Records every error it sees and passes it on.
class _ErrorSpy extends Interceptor {
  final List<int?> statuses = [];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    statuses.add(err.response?.statusCode);
    handler.next(err);
  }
}

class _RefreshLike extends Interceptor {
  new(this.dio);

  final Dio dio;
}

class _SelfConfiguringClient extends BaseHttpClient {
  new() : super(dio: Dio()) {
    configure(HttpClientConfig(interceptors: [_RefreshLike(dio)]));
  }
}

const _policy = TokenBucketPolicy(permits: 2, per: Duration(seconds: 10));

void main() {
  group('default configuration', () {
    test('keeps the options and chain DefaultHttpClient always had', () {
      final client = _Client(ScriptedAdapter([reply(200)]));

      expect(client.options.contentType, Headers.jsonContentType);
      expect(client.options.connectTimeout, const Duration(seconds: 20));
      expect(client.options.receiveTimeout, const Duration(seconds: 20));
      expect(client.options.sendTimeout, isNull);
      expect(client.interceptors.map((i) => '${i.runtimeType}'), [
        'ImplyContentTypeInterceptor',
        'DefaultNetworkExceptionHandlerInterceptor',
      ]);
      expect(client.currentConfig, const HttpClientConfig());
    });

    test('DefaultHttpClient.instance starts on the default config', () {
      expect(
        DefaultHttpClient.instance.currentConfig,
        const HttpClientConfig(),
      );
    });
  });

  group('configure', () {
    test('assembles every box in the fixed order', () {
      final custom = _ErrorSpy();
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(
          HttpClientConfig(
            interceptors: [custom],
            log: const LogConfig(),
            cache: const CacheConfig(),
            concurrency: const ConcurrencyConfig(global: 4),
            rateLimit: const RateLimitConfig.pauseOnly(),
            retry: const RetryConfig(),
          ),
        );
      addTearDown(client.dispose);

      expect(client.interceptors.map((i) => '${i.runtimeType}'), [
        'ImplyContentTypeInterceptor',
        '_ErrorSpy',
        'HttpLogInterceptor',
        'CacheInterceptor',
        'ConcurrencyLimitInterceptor',
        'RetryAfterPauseInterceptor',
        'RetryInterceptor',
        'DefaultNetworkExceptionHandlerInterceptor',
      ]);
    });

    test('keeps an unchanged box and rebuilds a changed one', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(
          const HttpClientConfig(
            rateLimit: RateLimitConfig.tokenBucket(global: [_policy]),
            retry: RetryConfig(),
          ),
        );
      addTearDown(client.dispose);
      final limiter = client.interceptors
          .whereType<TokenBucketRateLimitInterceptor>()
          .single;
      final retry = client.interceptors.whereType<RetryInterceptor>().single;

      client.configure(
        client.currentConfig.copyWith(
          log: const LogConfig(),
          retry: const RetryConfig(maxAttempts: 1),
        ),
      );

      expect(
        client.interceptors.whereType<TokenBucketRateLimitInterceptor>().single,
        same(limiter),
      );
      expect(
        client.interceptors.whereType<RetryInterceptor>().single,
        isNot(same(retry)),
      );
    });

    test('a kept limiter keeps its spent tokens', () {
      fakeAsync((async) {
        final adapter = ScriptedAdapter([reply(200)]);
        final client = _Client(adapter)
          ..configure(
            const HttpClientConfig(
              baseUrl: 'https://a.test',
              rateLimit: RateLimitConfig.tokenBucket(
                global: [
                  TokenBucketPolicy(
                    permits: 1,
                    per: Duration(seconds: 10),
                    burst: 1,
                  ),
                ],
              ),
            ),
          );
        client.dio.get<dynamic>('/1').ignore();
        async.elapse(Duration.zero);
        client.configure(client.currentConfig.copyWith(log: const LogConfig()));
        client.dio.get<dynamic>('/2').ignore();
        async.elapse(Duration.zero);

        expect(adapter.requests, hasLength(1));

        async.elapse(const Duration(seconds: 10));
        expect(adapter.requests, hasLength(2));
        client.dispose();
      });
    });

    test('a request that started before configure finishes on the old '
        'options and chain', () {
      fakeAsync((async) {
        final adapter = GatedAdapter();
        final oldSpy = _ErrorSpy();
        final client = _Client(adapter)
          ..configure(
            HttpClientConfig(
              baseUrl: 'https://a.test',
              headers: const {'X-Env': 'dev'},
              interceptors: [oldSpy],
            ),
          );
        client.dio.get<dynamic>('/a').ignore();
        async.elapse(Duration.zero);

        client.configure(
          const HttpClientConfig(
            baseUrl: 'https://a.test',
            headers: {'X-Env': 'prod'},
          ),
        );
        client.dio.get<dynamic>('/b').ignore();
        async.elapse(Duration.zero);
        adapter.requests[0].respond(500);
        adapter.requests[1].respond(500);
        async.elapse(Duration.zero);

        expect(adapter.requests[0].options.headers['X-Env'], 'dev');
        expect(adapter.requests[1].options.headers['X-Env'], 'prod');
        expect(oldSpy.statuses, [500]);
      });
    });

    test('a config that cannot be built throws and changes nothing', () {
      final client = _Client(ScriptedAdapter([reply(200)]));
      final before = client.interceptors.toList();

      expect(
        () => client.configure(
          const HttpClientConfig(
            baseUrl: 'https://b.test',
            concurrency: ConcurrencyConfig(global: 0),
          ),
        ),
        throwsArgumentError,
      );
      expect(client.currentConfig, const HttpClientConfig());
      expect(client.baseUrl, '');
      expect(client.interceptors.toList(), before);
    });

    // dio checks a base URL only off the web, where a relative one is valid.
    for (final (name, rejected, testOn)
        in <(String, HttpClientConfig, String?)>[
          (
            'a base URL',
            const HttpClientConfig(baseUrl: 'api.example.com'),
            'vm',
          ),
          (
            'a timeout',
            const HttpClientConfig(
              baseUrl: 'https://b.test',
              connectTimeout: Duration(seconds: -1),
            ),
            null,
          ),
        ]) {
      test('$name dio rejects throws and changes nothing', testOn: testOn, () {
        const headers = HttpClientConfig(headers: {'X-Key': 'k'});
        final client = _Client(ScriptedAdapter([reply(200)]))
          ..configure(headers);
        final before = client.interceptors.toList();

        expect(() => client.configure(rejected), throwsA(isA<Error>()));
        expect(client.currentConfig, headers);
        expect(client.options.headers['X-Key'], 'k');
        expect(client.baseUrl, '');
        expect(client.interceptors.toList(), before);
      });
    }

    test('a relative base URL is accepted on web', testOn: 'browser', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(const HttpClientConfig(baseUrl: 'api/'));

      expect(client.baseUrl, 'api/');
    });

    test('keeps a header set on dio.options and drops one the config '
        'stopped setting', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(const HttpClientConfig(headers: {'X-A': '1'}));
      client.options.headers['X-Manual'] = 'kept';

      client.configure(const HttpClientConfig(headers: {'X-B': '2'}));

      expect(client.options.headers['X-Manual'], 'kept');
      expect(client.options.headers['X-B'], '2');
      expect(client.options.headers.containsKey('X-A'), isFalse);
    });

    test('configure with the same config keeps every interceptor', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(
          const HttpClientConfig(
            cache: CacheConfig(),
            concurrency: ConcurrencyConfig(global: 2),
            rateLimit: RateLimitConfig.pauseOnly(),
            retry: RetryConfig(),
          ),
        );
      addTearDown(client.dispose);
      final before = client.interceptors.toList();

      client.configure(client.currentConfig);

      expect(client.interceptors.toList(), before);
    });

    test('a header whose key changes only in case keeps its new value', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(const HttpClientConfig(headers: {'x-a': '1'}))
        ..configure(const HttpClientConfig(headers: {'X-A': '2'}));

      expect(client.options.headers['X-A'], '2');
    });

    test('a User-Agent the config stopped setting is removed', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(const HttpClientConfig(userAgent: 'falcon/2'))
        ..configure(const HttpClientConfig());

      expect(client.options.headers.containsKey('User-Agent'), isFalse);
    });

    test('a timeout dropped from the config is cleared', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(const HttpClientConfig(sendTimeout: Duration(seconds: 3)))
        ..configure(const HttpClientConfig());

      expect(client.options.sendTimeout, isNull);
    });

    test('keeps a field the config does not own', () {
      final client = _Client(ScriptedAdapter([reply(200)]));
      client.options.responseType = ResponseType.plain;

      client.configure(const HttpClientConfig(baseUrl: 'https://a.test'));

      expect(client.options.responseType, ResponseType.plain);
    });
  });

  group('validateStatus', () {
    test('a 4xx reaches the error interceptors by default', () async {
      final spy = _ErrorSpy();
      final client = _Client(ScriptedAdapter([reply(404)]))
        ..configure(
          HttpClientConfig(baseUrl: 'https://a.test', interceptors: [spy]),
        );

      await expectLater(
        client.dio.get<dynamic>('/x'),
        throwsA(isA<DioException>()),
      );
      expect(spy.statuses, [404]);
    });

    test('a 429 reaches RetryInterceptor', () {
      fakeAsync((async) {
        final adapter = ScriptedAdapter([reply(429), reply(200)]);
        final client = _Client(adapter)
          ..configure(
            const HttpClientConfig(
              baseUrl: 'https://a.test',
              retry: RetryConfig(delay: Duration(milliseconds: 1)),
            ),
          );
        client.dio.get<dynamic>('/x').ignore();
        async.elapse(const Duration(seconds: 1));

        expect(adapter.requests, hasLength(2));
      });
    });
  });

  group('diagnostics', () {
    test('a kept interceptor follows the current log box', () {
      fakeAsync((async) {
        final lines = <Object?>[];
        final adapter = ScriptedAdapter([reply(500)]);
        final client = _Client(adapter)
          ..configure(
            const HttpClientConfig(
              baseUrl: 'https://a.test',
              retry: RetryConfig(
                maxAttempts: 1,
                delay: Duration(milliseconds: 1),
              ),
            ),
          );
        client.dio.get<dynamic>('/quiet').ignore();
        async.elapse(const Duration(seconds: 1));
        expect(lines, isEmpty);

        client.configure(
          client.currentConfig.copyWith(
            log: LogConfig(
              request: false,
              requestHeader: false,
              requestBody: false,
              responseBody: false,
              error: false,
              logPrint: lines.add,
            ),
          ),
        );
        client.dio.get<dynamic>('/loud').ignore();
        async.elapse(const Duration(seconds: 1));

        expect(
          lines.whereType<String>().where(
            (line) => line.startsWith('[RetryInterceptor]'),
          ),
          hasLength(1),
        );
      });
    });
  });

  group('log variants', () {
    test('switching the log between pretty, JSON, and null rebuilds only '
        'the log', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(
          const HttpClientConfig(
            log: LogConfig(),
            rateLimit: RateLimitConfig.tokenBucket(global: [_policy]),
            retry: RetryConfig(),
          ),
        );
      addTearDown(client.dispose);
      final limiter = client.interceptors
          .whereType<TokenBucketRateLimitInterceptor>()
          .single;
      final retry = client.interceptors.whereType<RetryInterceptor>().single;

      client.configure(
        client.currentConfig.copyWith(log: const LogConfig.json()),
      );

      expect(client.interceptors.whereType<HttpLogInterceptor>(), isEmpty);
      final json = client.interceptors.whereType<HttpJsonLogInterceptor>();
      expect(json, hasLength(1));
      expect(client.interceptors.elementAt(1), same(json.single));
      expect(
        client.interceptors.whereType<TokenBucketRateLimitInterceptor>().single,
        same(limiter),
      );
      expect(
        client.interceptors.whereType<RetryInterceptor>().single,
        same(retry),
      );

      client.configure(client.currentConfig.copyWith(log: null));

      expect(client.interceptors.whereType<HttpJsonLogInterceptor>(), isEmpty);
      expect(
        client.interceptors.whereType<TokenBucketRateLimitInterceptor>().single,
        same(limiter),
      );
    });

    test('the pretty log takes the redaction sets of its box', () async {
      final lines = <Object?>[];
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(
          HttpClientConfig(
            baseUrl: 'https://a.test',
            headers: const {'X-Tenant': 'acme'},
            log: LogConfig(
              redactHeaders: const {'x-tenant'},
              redactQueryParameters: const {'page'},
              logPrint: lines.add,
            ),
          ),
        );

      await client.dio.get<dynamic>('/x?page=2');

      // Colour codes wrap header values; drop them to read the text.
      final printed = lines
          .join('\n')
          .replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
      expect(printed, contains('X-Tenant: REDACTED'));
      expect(printed, contains('https://a.test/x?page=REDACTED'));
      expect(printed, isNot(contains('acme')));
    });

    test('a limiter diagnostic prints as a JSON line in JSON mode', () {
      fakeAsync((async) {
        final lines = <Object?>[];
        final client = _Client(ScriptedAdapter([reply(200)]))
          ..configure(
            HttpClientConfig(
              baseUrl: 'https://a.test',
              log: LogConfig.json(logPrint: lines.add),
              rateLimit: const RateLimitConfig.tokenBucket(
                perHost: [
                  TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
                ],
                queueRequests: false,
              ),
            ),
          );
        client.dio.get<dynamic>('/1').ignore();
        async.elapse(Duration.zero);
        client.dio.get<dynamic>('/2').ignore();
        async.elapse(Duration.zero);
        client.dispose();

        final decoded = [
          for (final line in lines)
            jsonDecode(line! as String) as Map<String, Object?>,
        ];
        final debug = decoded.where((l) => l['severity_text'] == 'DEBUG');
        expect(debug.single.keys, ['timestamp', 'severity_text', 'body']);
        expect(
          debug.single['body'],
          '[TokenBucketRateLimitInterceptor] Rate limit queue full for a.test',
        );
        expect(decoded.where((l) => l.containsKey('url.full')), hasLength(2));
      });
    });

    test(
      'a printer that throws fails no request through a diagnostic',
      () async {
        final client =
            _Client(
              ScriptedAdapter([
                reply(200, headers: {'cache-control': 'max-age=60'}),
              ]),
            )..configure(
              HttpClientConfig(
                baseUrl: 'https://a.test',
                log: LogConfig.json(logPrint: (_) => throw StateError('sink')),
                cache: const CacheConfig(),
              ),
            );

        final network = await client.dio.get<dynamic>('/x');
        final hit = await client.dio.get<dynamic>('/x');

        expect(network.statusCode, 200);
        expect(hit.isCacheHit, isTrue);
      },
    );

    test('a JSON log with diagnostics off prints no diagnostic', () {
      fakeAsync((async) {
        final lines = <Object?>[];
        final client = _Client(ScriptedAdapter([reply(500)]))
          ..configure(
            HttpClientConfig(
              baseUrl: 'https://a.test',
              log: LogConfig.json(logPrint: lines.add, diagnostics: false),
              retry: const RetryConfig(
                maxAttempts: 1,
                delay: Duration(milliseconds: 1),
              ),
            ),
          );
        client.dio.get<dynamic>('/x').ignore();
        async.elapse(const Duration(seconds: 1));

        expect(lines, hasLength(2));
        expect(lines, everyElement(contains('"url.full"')));
      });
    });
  });

  group('addInterceptors and setupBaseUrl', () {
    test('addInterceptors puts the interceptor in the custom slot, where it '
        'sees errors and survives configure', () async {
      final spy = _ErrorSpy();
      final client = _Client(ScriptedAdapter([reply(500)]))
        ..setupBaseUrl('https://a.test')
        ..addInterceptors([spy]);
      client.configure(
        client.currentConfig.copyWith(log: LogConfig(logPrint: (_) {})),
      );

      await expectLater(
        client.dio.get<dynamic>('/x'),
        throwsA(isA<DioException>()),
      );
      expect(client.currentConfig.interceptors, [spy]);
      expect(spy.statuses, [500]);
    });

    test('setupBaseUrl updates the config and the options', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..setupBaseUrl('https://b.test');

      expect(client.currentConfig.baseUrl, 'https://b.test');
      expect(client.baseUrl, 'https://b.test');
    });
  });

  test('a subclass can hand its own dio to an interceptor', () {
    final client = _SelfConfiguringClient();

    expect(
      client.interceptors.whereType<_RefreshLike>().single.dio,
      same(client.dio),
    );
  });

  test('dispose disposes the current limiters', () {
    final client = _Client(ScriptedAdapter([reply(200)]))
      ..configure(
        const HttpClientConfig(
          baseUrl: 'https://a.test',
          rateLimit: RateLimitConfig.tokenBucket(global: [_policy]),
        ),
      )
      ..dispose();

    expect(
      client.dio.get<dynamic>('/x'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
  });

  test('configure after dispose rebuilds the limiters', () async {
    final client = _Client(ScriptedAdapter([reply(200)]))
      ..configure(
        const HttpClientConfig(
          baseUrl: 'https://a.test',
          concurrency: ConcurrencyConfig(global: 2),
          rateLimit: RateLimitConfig.tokenBucket(global: [_policy]),
        ),
      )
      ..dispose();

    client.configure(client.currentConfig);
    addTearDown(client.dispose);

    await expectLater(client.dio.get<dynamic>('/x'), completes);
  });
}
