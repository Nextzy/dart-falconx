import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

/// A 200 the server marks cacheable for a minute.
Reply _cacheable() => reply(200, headers: {'cache-control': 'max-age=60'});

/// Skips the cached answer, so the request reaches the network.
Options _refresh() => Options()..cachePolicy = CachePolicy.refresh;

/// A chain with the cache first and its fallback after [RetryInterceptor],
/// as `BaseHttpClient` builds it.
Dio _dio(
  HttpClientAdapter adapter,
  CacheInterceptor cache, {
  List<Interceptor> Function(Dio dio)? between,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
    ..httpClientAdapter = adapter
    ..transformer = FoldingTransformer();
  dio.interceptors.addAll([cache, ...?between?.call(dio), cache.fallback]);
  return dio;
}

CacheInterceptor _offline({
  bool network = true,
  Set<int> codes = const {},
  void Function(String)? logPrint,
}) => CacheInterceptor(
  config: CacheConfig(
    hitCacheOnNetworkFailure: network,
    hitCacheOnErrorCodes: codes,
  ),
  logPrint: logPrint,
);

void main() {
  test('a network failure after every retry answers from the cache', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        _cacheable(),
        failWith(DioExceptionType.connectionError),
      ]);
      final dio = _dio(
        adapter,
        _offline(),
        between: (dio) => [
          RetryInterceptor(
            config: const RetryConfig(
              maxAttempts: 2,
              delay: Duration(milliseconds: 1),
              maxDelay: Duration(milliseconds: 1),
            ),
            dio: dio,
          ),
        ],
      );
      final outcomes = <Object>[];

      dio.get<dynamic>('/x').then(outcomes.add).ignore();
      async.elapse(Duration.zero);
      dio
          .get<dynamic>('/x', options: _refresh())
          .then(outcomes.add, onError: outcomes.add)
          .ignore();
      async.elapse(const Duration(seconds: 1));

      final answer = outcomes.last as Response<dynamic>;
      expect(answer.isCacheFallback, isTrue);
      expect(answer.isCacheHit, isTrue);
      expect(answer.data, {'status': 200});
      expect(answer.requestOptions.uri.path, '/x');
      // The first request, then the refresh and its two retries.
      expect(adapter.requests, hasLength(4));
    });
  });

  test('a plain hit is not a fallback', () async {
    final dio = _dio(ScriptedAdapter([_cacheable()]), _offline());

    await dio.get<dynamic>('/x');
    final hit = await dio.get<dynamic>('/x');

    expect(hit.isCacheHit, isTrue);
    expect(hit.isCacheFallback, isFalse);
  });

  test('a listed status falls back and an unlisted one fails', () async {
    final adapter = ScriptedAdapter([
      _cacheable(),
      (options) => ResponseBody.fromString(
        '{}',
        options.uri.path == '/x' ? 503 : 500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    ]);
    final dio = _dio(adapter, _offline(network: false, codes: {503}));

    await dio.get<dynamic>('/x');
    final fallback = await dio.get<dynamic>('/x', options: _refresh());

    expect(fallback.isCacheFallback, isTrue);
    expect(() async {
      await dio.get<dynamic>('/y', options: _refresh());
    }(), throwsA(isA<DioException>()));
  });

  test('a status fails when the entry is missing', () async {
    final dio = _dio(
      ScriptedAdapter([failWith(DioExceptionType.connectionError)]),
      _offline(),
    );

    expect(dio.get<dynamic>('/x'), throwsA(isA<DioException>()));
  });

  test('with both settings off every error passes on', () async {
    final adapter = ScriptedAdapter([
      _cacheable(),
      failWith(DioExceptionType.connectionError),
    ]);
    final dio = _dio(adapter, CacheInterceptor());

    await dio.get<dynamic>('/x');

    expect(
      dio.get<dynamic>('/x', options: _refresh()),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionError,
        ),
      ),
    );
  });

  test('a cancel never falls back', () async {
    final adapter = ScriptedAdapter([
      _cacheable(),
      failWith(DioExceptionType.cancel),
    ]);
    final dio = _dio(adapter, _offline());

    await dio.get<dynamic>('/x');

    expect(
      dio.get<dynamic>('/x', options: _refresh()),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
  });

  test('an entry past its maxStale is not used', () async {
    final adapter = ScriptedAdapter([
      reply(200),
      failWith(DioExceptionType.connectionError),
    ]);
    final dio = _dio(adapter, _offline());

    await dio.get<dynamic>(
      '/x',
      options: Options()..cacheFor = const Duration(milliseconds: 100),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(
      dio.get<dynamic>('/x', options: _refresh()),
      throwsA(isA<DioException>()),
    );
  });

  test('the fallback prints a diagnostic without the query', () async {
    final lines = <String>[];
    final dio = _dio(
      ScriptedAdapter([
        _cacheable(),
        failWith(DioExceptionType.connectionError),
      ]),
      _offline(logPrint: lines.add),
    );

    await dio.get<dynamic>('/x?token=secret');
    await dio.get<dynamic>('/x?token=secret', options: _refresh());

    expect(
      lines.single,
      '[CacheInterceptor] Answered GET a.test/x from the cache after '
      'connectionError',
    );
  });

  test('an answer from the fallback returns its concurrency slot', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        _cacheable(),
        failWith(DioExceptionType.connectionError),
        _cacheable(),
      ]);
      final dio = _dio(
        adapter,
        _offline(),
        between: (_) => [
          ConcurrencyLimitInterceptor(
            config: const ConcurrencyConfig(perHost: 1),
          ),
        ],
      );
      final outcomes = <Object>[];
      void get(String path, [Options? options]) {
        dio
            .get<dynamic>(path, options: options)
            .then(outcomes.add, onError: outcomes.add)
            .ignore();
        async.elapse(Duration.zero);
      }

      get('/x');
      get('/x', _refresh());
      get('/y');

      expect(outcomes, hasLength(3));
      expect((outcomes[1] as Response<dynamic>).isCacheFallback, isTrue);
      expect(outcomes.last, isA<Response<dynamic>>());
      expect(adapter.requests, hasLength(3));
    });
  });
}
