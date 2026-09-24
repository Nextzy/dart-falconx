import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import 'interceptors/_scripted_adapter.dart';

class _Client extends BaseHttpClient {
  new(HttpClientAdapter adapter)
    : super(dio: Dio()..httpClientAdapter = adapter);
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
            performance: const PerformanceConfig(),
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
        'PerformanceInterceptor',
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
}
