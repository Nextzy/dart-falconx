import 'dart:async';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_faltool/dart_faltool.dart'
    show BulkheadRejectedException, TokenBucketPolicy;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

const _config = HttpClientConfig(
  enableCache: false,
  maxRetryAttempts: 1,
  retryDelay: Duration(seconds: 1),
  maxRetryDelay: Duration(seconds: 1),
);

Dio _dio(HttpClientAdapter adapter, List<Interceptor> Function(Dio) chain) {
  final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll(chain(dio));
  return dio;
}

/// Starts a GET and records its outcome: a response or an error.
void _get(
  Dio dio,
  String url,
  List<Object> outcomes, {
  CancelToken? cancelToken,
  Options? options,
}) {
  unawaited(
    dio
        .get<dynamic>(url, cancelToken: cancelToken, options: options)
        .then(outcomes.add, onError: outcomes.add),
  );
}

/// Runs every timer and microtask due now.
void _settle(FakeAsync async) => async.elapse(Duration.zero);

List<String> _urls(Iterable<GatedRequest> requests) => [
  for (final request in requests) request.options.uri.toString(),
];

/// Records what the interceptor does with a request, standing in for the
/// rest of the Dio chain.
class _RecordingHandler extends RequestInterceptorHandler {
  final forwarded = <RequestOptions>[];

  @override
  void next(RequestOptions requestOptions) => forwarded.add(requestOptions);
}

/// Re-sends the first failed request from `onError`, as an auth refresh
/// interceptor does.
class _ResendOnce extends Interceptor {
  new(this.dio);

  final Dio dio;
  bool _sent = false;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_sent) {
      handler.next(err);
      return;
    }
    _sent = true;
    try {
      handler.resolve(await dio.fetch<dynamic>(err.requestOptions));
    } on DioException catch (error) {
      handler.next(error);
    }
  }
}

void main() {
  test('forwards synchronously and builds nothing without a limit', () {
    final limiter = ConcurrencyLimitInterceptor(config: _config);
    final handler = _RecordingHandler();

    unawaited(
      limiter.onRequest(RequestOptions(path: 'https://a.test/x'), handler),
    );

    expect(handler.forwarded, hasLength(1));
    final stats = limiter.getStatistics();
    expect(stats.forwarded, 1);
    expect(stats.activeByHost, isEmpty);
    expect(stats.globalActive, 0);
  });

  test('perHost holds extra requests and releases them in FIFO order', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 2);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      for (final path in ['/1', '/2', '/3', '/4']) {
        _get(dio, path, outcomes);
      }
      _settle(async);
      expect(_urls(adapter.requests), ['https://a.test/1', 'https://a.test/2']);
      expect(limiter.getStatistics().waitingByHost, {'a.test': 2});

      adapter.requests[1].respond(200);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/1', 'https://a.test/3']);

      adapter.requests[0].respond(200);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/3', 'https://a.test/4']);
      expect(limiter.getStatistics().activeByHost, {'a.test': 2});

      for (final request in adapter.inFlight) {
        request.respond(200);
      }
      _settle(async);
      expect(outcomes, hasLength(4));
      expect(limiter.getStatistics().forwarded, 4);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('hosts overrides perHost, and a null value opts out', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        perHost: 1,
        hosts: {'b.test': 2, 'c.test': null},
      );
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      for (final host in ['a', 'a', 'b', 'b', 'b', 'c', 'c', 'c']) {
        _get(dio, 'https://$host.test/x', outcomes);
      }
      _settle(async);

      int sentTo(String host) =>
          adapter.requests.where((r) => r.options.uri.host == host).length;
      expect(sentTo('a.test'), 1);
      expect(sentTo('b.test'), 2);
      expect(sentTo('c.test'), 3);
      expect(limiter.getStatistics().activeByHost.keys, ['a.test', 'b.test']);
    });
  });

  test('global is shared by every host, opted-out hosts included', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        global: 2,
        hosts: {'c.test': null},
      );
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      for (final host in ['a', 'b', 'c']) {
        _get(dio, 'https://$host.test/x', outcomes);
      }
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/x', 'https://b.test/x']);
      final stats = limiter.getStatistics();
      expect(stats.globalActive, 2);
      expect(stats.globalWaiting, 1);
      // Hosts without a host limit store nothing per host.
      expect(stats.activeByHost, isEmpty);

      adapter.requests[0].respond(200);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://b.test/x', 'https://c.test/x']);
    });
  });

  test('a full queue fails with a local 429 that is not retried', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        perHost: 1,
        maxQueueSize: 1,
      );
      final dio = _dio(
        adapter,
        (dio) => [limiter, RetryInterceptor(config: _config, dio: dio)],
      );
      final outcomes = <Object>[];

      for (final path in ['/1', '/2', '/3']) {
        _get(dio, path, outcomes);
      }
      _settle(async);

      final error = outcomes.single as DioException;
      expect(error.error, isA<BulkheadRejectedException>());
      expect(error.response?.statusCode, 429);
      expect(error.response?.isLocalRateLimit, isTrue);
      expect(error.response?.headers.value('retry-after'), isNull);
      expect(limiter.getStatistics().rejected, 1);

      async.elapse(const Duration(seconds: 5));
      expect(adapter.requests, hasLength(1));
    });
  });

  test('a global rejection gives the host slot back', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        global: 1,
        perHost: 2,
        maxGlobalQueueSize: 0,
      );
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes);
      _settle(async);

      expect(outcomes.single, isA<DioException>());
      expect(limiter.getStatistics().activeByHost, {'a.test': 1});
    });
  });

  test('queueRequests false rejects at once when no slot is free', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        perHost: 1,
        queueRequests: false,
      );
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes);
      _settle(async);

      expect((outcomes.single as DioException).response?.statusCode, 429);
      expect(adapter.requests, hasLength(1));
    });
  });

  test('a server error gives the slot back', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes);
      _settle(async);
      adapter.requests[0].respond(500);
      _settle(async);

      expect(_urls(adapter.inFlight), ['https://a.test/2']);
    });
  });

  test('a local 429 and a cancel from the token bucket give the slot back', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final bucket = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
        queueRequests: false,
      );
      final dio = _dio(adapter, (_) => [limiter, bucket]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _settle(async);
      _get(dio, '/2', outcomes);
      _settle(async);
      expect((outcomes.last as DioException).response?.isLocalRateLimit, true);
      expect(limiter.getStatistics().activeByHost, isEmpty);

      bucket.dispose();
      _get(dio, '/3', outcomes);
      _settle(async);
      expect((outcomes.last as DioException).type, DioExceptionType.cancel);
      expect(limiter.getStatistics().activeByHost, isEmpty);
    });
  });

  test('a request cancelled while it waits lets the next one through', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];
      final token = CancelToken();

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes, cancelToken: token);
      _get(dio, '/3', outcomes);
      _settle(async);
      token.cancel();
      _settle(async);
      expect((outcomes.single as DioException).type, DioExceptionType.cancel);

      adapter.requests[0].respond(200);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/3']);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('one CancelToken shared by requests in flight frees every slot', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 3);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];
      final token = CancelToken();

      for (final path in ['/1', '/2', '/3']) {
        _get(dio, path, outcomes, cancelToken: token);
      }
      _settle(async);
      expect(adapter.inFlight, hasLength(3));

      token.cancel();
      _settle(async);
      expect(outcomes, hasLength(3));
      expect(limiter.getStatistics().activeByHost, isEmpty);

      for (final path in ['/4', '/5', '/6']) {
        _get(dio, path, outcomes);
      }
      _settle(async);
      expect(adapter.inFlight, hasLength(3));
    });
  });

  for (final limiterFirst in [true, false]) {
    test('a retry with a limit of 1 does not deadlock '
        '(limiter ${limiterFirst ? 'before' : 'after'} RetryInterceptor)', () {
      fakeAsync((async) {
        final adapter = ScriptedAdapter([reply(503), reply(200)]);
        final limiter = ConcurrencyLimitInterceptor(
          config: _config,
          perHost: 1,
        );
        final dio = _dio(adapter, (dio) {
          final retry = RetryInterceptor(config: _config, dio: dio);
          return limiterFirst ? [limiter, retry] : [retry, limiter];
        });
        final outcomes = <Object>[];

        _get(dio, '/x', outcomes);
        async.elapse(const Duration(seconds: 2));

        expect((outcomes.single as Response<dynamic>).statusCode, 200);
        expect(adapter.requests, hasLength(2));
        expect(limiter.getStatistics().activeByHost, isEmpty);
      });
    });
  }

  test('a re-send from an interceptor placed before it reuses the slot', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(401), reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (dio) => [_ResendOnce(dio), limiter]);
      final outcomes = <Object>[];

      _get(dio, '/x', outcomes);
      _settle(async);

      expect((outcomes.single as Response<dynamic>).statusCode, 200);
      expect(limiter.getStatistics().activeByHost, isEmpty);
    });
  });

  test('a cache hit, with CacheInterceptor first, takes no slot', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(
        adapter,
        (_) => [CacheInterceptor(config: const HttpClientConfig()), limiter],
      );
      final outcomes = <Object>[];

      _get(dio, '/x', outcomes);
      _settle(async);
      _get(dio, '/x', outcomes);
      _settle(async);

      expect(outcomes, hasLength(2));
      expect(adapter.requests, hasLength(1));
      expect(limiter.getStatistics().forwarded, 1);
      expect(limiter.getStatistics().activeByHost, isEmpty);
    });
  });

  test('dispose cancels waiters and leaves requests in flight alone', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        perHost: 1,
        hosts: {'free.test': null},
      );
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes);
      _settle(async);
      limiter
        ..dispose()
        ..dispose();
      _settle(async);
      final waiter = outcomes.single as DioException;
      expect(waiter.type, DioExceptionType.cancel);
      expect(waiter.error, isA<StateError>());

      adapter.requests[0].respond(200);
      _settle(async);
      expect((outcomes.last as Response<dynamic>).statusCode, 200);

      _get(dio, '/3', outcomes);
      _get(dio, 'https://free.test/x', outcomes);
      _settle(async);
      expect((outcomes[2] as DioException).type, DioExceptionType.cancel);
      expect(_urls(adapter.inFlight), ['https://free.test/x']);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('dispose cancels a retry that would reuse a held slot', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(
        adapter,
        (dio) => [RetryInterceptor(config: _config, dio: dio), limiter],
      );
      final outcomes = <Object>[];

      _get(dio, '/x', outcomes);
      _settle(async);
      adapter.requests.single.respond(503);
      _settle(async);
      limiter.dispose();
      async.elapse(const Duration(seconds: 2));

      expect((outcomes.single as DioException).type, DioExceptionType.cancel);
      expect(adapter.requests, hasLength(1));
      expect(limiter.getStatistics().activeByHost, isEmpty);
    });
  });

  test('a stream response gives the slot back when its headers arrive', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(
        dio,
        '/1',
        outcomes,
        options: Options(responseType: ResponseType.stream),
      );
      _get(dio, '/2', outcomes);
      _settle(async);
      adapter.requests[0].respond(200);
      _settle(async);

      expect(outcomes.single, isA<Response<dynamic>>());
      expect(_urls(adapter.inFlight), ['https://a.test/2']);
    });
  });

  test('an idle host limit is forgotten', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, 'https://a.test/x', outcomes);
      _get(dio, 'https://b.test/x', outcomes);
      _settle(async);
      expect(limiter.getStatistics().activeByHost.keys, ['a.test', 'b.test']);

      adapter.requests[0].respond(200);
      _settle(async);
      expect(limiter.getStatistics().activeByHost, {'b.test': 1});
    });
  });

  test('the permit in extra reads as its state', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/x', outcomes);
      _settle(async);

      final extra = (outcomes.single as Response<dynamic>).requestOptions.extra;
      final permits = [
        for (final entry in extra.entries)
          if (entry.key.startsWith('dart_falconnect.concurrency.permit.'))
            entry.value.toString(),
      ];
      expect(permits, ['ConcurrencyPermit(released)']);
    });
  });

  test('rejects invalid settings', () {
    ConcurrencyLimitInterceptor build({
      int? global,
      int? perHost,
      Map<String, int?> hosts = const {},
      int maxQueueSize = 50,
      int maxGlobalQueueSize = 500,
    }) => ConcurrencyLimitInterceptor(
      config: _config,
      global: global,
      perHost: perHost,
      hosts: hosts,
      maxQueueSize: maxQueueSize,
      maxGlobalQueueSize: maxGlobalQueueSize,
    );

    expect(() => build(global: 0), throwsArgumentError);
    expect(() => build(perHost: 0), throwsArgumentError);
    expect(() => build(hosts: {'a.test': 0}), throwsArgumentError);
    expect(() => build(maxQueueSize: -1), throwsArgumentError);
    expect(() => build(maxGlobalQueueSize: -1), throwsArgumentError);
    for (final key in ['A.test', 'a.test:8080', ' a.test', '[::1]', '']) {
      expect(() => build(hosts: {key: 1}), throwsArgumentError, reason: key);
    }
    expect(build(hosts: {'::1': 1}), isNotNull);
  });

  test('two limiters in one chain both give their slots back', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final global = ConcurrencyLimitInterceptor(config: _config, global: 5);
      final perHost = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [global, perHost]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/1']);
      expect(global.getStatistics().globalActive, 2);
      adapter.requests.single.respond(200);
      _settle(async);

      expect(_urls(adapter.inFlight), ['https://a.test/2']);
      adapter.inFlight.single.respond(200);
      _settle(async);
      expect(global.getStatistics().globalActive, 0);
      expect(perHost.getStatistics().activeByHost, isEmpty);
    });
  });

  test('an interceptor that throws after it gives the slot back', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      var throws = true;
      final dio = _dio(
        adapter,
        (_) => [
          limiter,
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (throws) {
                throw StateError('no token');
              }
              handler.next(options);
            },
          ),
        ],
      );
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _settle(async);
      expect(outcomes.single, isA<DioException>());

      throws = false;
      _get(dio, '/2', outcomes);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/2']);
    });
  });

  test('a request with a const extra map passes and gives its slot back', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/x', outcomes, options: Options(extra: const {'tag': 1}));
      _settle(async);

      expect((outcomes.single as Response<dynamic>).statusCode, 200);
      expect(limiter.getStatistics().activeByHost, isEmpty);
    });
  });

  test(
    'a cancelled waiter keeps its queue place until it reaches the head',
    () {
      fakeAsync((async) {
        final adapter = GatedAdapter();
        final limiter = ConcurrencyLimitInterceptor(
          config: _config,
          perHost: 1,
          maxQueueSize: 2,
        );
        final dio = _dio(adapter, (_) => [limiter]);
        final outcomes = <Object>[];
        final token = CancelToken();

        _get(dio, '/1', outcomes);
        _get(dio, '/2', outcomes, cancelToken: token);
        _get(dio, '/3', outcomes);
        _settle(async);
        token.cancel();
        _settle(async);
        expect(limiter.getStatistics().waitingByHost, {'a.test': 2});

        _get(dio, '/4', outcomes);
        _settle(async);
        expect((outcomes.last as DioException).response?.statusCode, 429);

        adapter.requests.single.respond(200);
        _settle(async);
        expect(_urls(adapter.inFlight), ['https://a.test/3']);
        expect(limiter.getStatistics().waitingByHost, {'a.test': 0});
      });
    },
  );

  test('a cancel after the response changes nothing', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];
      final token = CancelToken();

      _get(dio, '/1', outcomes, cancelToken: token);
      _settle(async);
      token.cancel();
      _get(dio, '/2', outcomes);
      _settle(async);

      expect(outcomes.whereType<Response<dynamic>>(), hasLength(2));
      expect(limiter.getStatistics().activeByHost, isEmpty);
    });
  });

  test('a waiter cancelled in the host queue never joins the global queue', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        global: 1,
        perHost: 1,
      );
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];
      final token = CancelToken();

      _get(dio, 'https://a.test/1', outcomes);
      _get(dio, 'https://a.test/2', outcomes, cancelToken: token);
      _get(dio, 'https://a.test/3', outcomes);
      _get(dio, 'https://b.test/1', outcomes);
      _settle(async);
      token.cancel();
      _settle(async);

      adapter.requests.single.respond(200);
      _settle(async);
      // a/2 gave its host slot back at once, so a/3 now waits for the
      // global slot that b/1 holds.
      expect(limiter.getStatistics().waitingByHost['a.test'], 0);
      expect(limiter.getStatistics().globalWaiting, 1);

      _get(dio, 'https://c.test/1', outcomes);
      _settle(async);
      adapter.inFlight.single.respond(200);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/3']);
    });
  });

  test('two fetches of one queued RequestOptions share its slot', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];
      final shared = RequestOptions(path: '/shared', baseUrl: 'https://a.test');

      _get(dio, '/x', outcomes);
      _settle(async);
      for (var i = 0; i < 2; i++) {
        unawaited(
          dio.fetch<dynamic>(shared).then(outcomes.add, onError: outcomes.add),
        );
      }
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/x']);

      adapter.requests.single.respond(200);
      _settle(async);
      expect(_urls(adapter.inFlight), [
        'https://a.test/shared',
        'https://a.test/shared',
      ]);
      for (final request in adapter.inFlight) {
        request.respond(200);
      }
      _settle(async);

      expect(outcomes.whereType<Response<dynamic>>(), hasLength(3));
      expect(limiter.getStatistics().activeByHost, isEmpty);
      _get(dio, '/after', outcomes);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/after']);
    });
  });
}
