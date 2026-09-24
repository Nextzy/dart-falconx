import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

/// Records every response it sees and passes it on.
class _ResponseSpy extends Interceptor {
  final List<Response<dynamic>> responses = [];

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    responses.add(response);
    handler.next(response);
  }
}

Dio _dio(ScriptedAdapter adapter, List<Interceptor> chain) =>
    Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter
      ..transformer = FoldingTransformer()
      ..interceptors.addAll(chain);

Options _tagged(int id) => Options(extra: {'id': id});

void main() {
  test('serves the cached response without a second network call', () async {
    final adapter = ScriptedAdapter([reply(200)]);
    final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter
      ..transformer = FoldingTransformer()
      ..interceptors.add(CacheInterceptor());

    final first = await dio.get<dynamic>('/x');
    final second = await dio.get<dynamic>('/x');

    expect(second.statusCode, 200);
    expect(second.data, first.data);
    expect([for (final request in adapter.requests) request.uri.path], ['/x']);
  });

  test('does not cache a non-GET response', () async {
    final adapter = ScriptedAdapter([reply(200)]);
    final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter
      ..transformer = FoldingTransformer()
      ..interceptors.add(CacheInterceptor());

    await dio.post<dynamic>('/x');
    await dio.post<dynamic>('/x');

    expect(adapter.requests, hasLength(2));
  });

  test('does not store a response with cache-control: no-store', () async {
    final adapter = ScriptedAdapter([
      reply(200, headers: {'cache-control': 'no-store'}),
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter
      ..transformer = FoldingTransformer()
      ..interceptors.add(CacheInterceptor());

    await dio.get<dynamic>('/x');
    await dio.get<dynamic>('/x');

    expect(adapter.requests, hasLength(2));
  });

  test(
    'bypasses the cache for a request with cache-control: no-cache',
    () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = adapter
        ..transformer = FoldingTransformer()
        ..interceptors.add(CacheInterceptor());
      final options = Options(headers: {'cache-control': 'no-cache'});

      await dio.get<dynamic>('/x', options: options);
      await dio.get<dynamic>('/x', options: options);

      expect(adapter.requests, hasLength(2));
    },
  );

  test('refetches once the response max-age has passed', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        reply(200, headers: {'cache-control': 'max-age=1'}),
      ]);
      final cache = CacheInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = adapter
        ..transformer = FoldingTransformer()
        ..interceptors.add(cache);

      final outcomes = <Object>[];
      dio.get<dynamic>('/x').then(outcomes.add, onError: outcomes.add).ignore();
      async.elapse(Duration.zero);

      // Still inside the 1-second lifetime: served from the cache.
      dio.get<dynamic>('/x').then(outcomes.add, onError: outcomes.add).ignore();
      async.elapse(Duration.zero);
      expect(adapter.requests, hasLength(1));

      async.elapse(const Duration(seconds: 2));
      cache.evictExpired();
      dio.get<dynamic>('/x').then(outcomes.add, onError: outcomes.add).ignore();
      async.elapse(Duration.zero);

      expect(adapter.requests, hasLength(2));
      expect(outcomes, hasLength(3));
    });
  });

  test('refetches once the Expires header is in the past', () {
    fakeAsync((async) {
      final expires = clock.now().add(const Duration(seconds: 1));
      final adapter = ScriptedAdapter([
        reply(200, headers: {'expires': expires.toIso8601String()}),
      ]);
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = adapter
        ..transformer = FoldingTransformer()
        ..interceptors.add(CacheInterceptor());

      dio.get<dynamic>('/x').ignore();
      async.elapse(Duration.zero);
      expect(adapter.requests, hasLength(1));

      async.elapse(const Duration(seconds: 2));
      dio.get<dynamic>('/x').ignore();
      async.elapse(Duration.zero);

      expect(adapter.requests, hasLength(2));
    });
  });

  test('evicts the oldest entry when the cache outgrows maxSize', () async {
    final adapter = ScriptedAdapter([reply(200)]);
    final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter
      ..transformer = FoldingTransformer()
      ..interceptors.add(
        CacheInterceptor(config: const CacheConfig(maxSize: 60)),
      );

    await dio.get<dynamic>('/a');
    await dio.get<dynamic>('/b');
    await dio.get<dynamic>('/b');
    await dio.get<dynamic>('/a');

    expect(
      [for (final request in adapter.requests) request.uri.path],
      ['/a', '/b', '/a'],
    );
  });

  test('clearCache drops every stored response', () async {
    final adapter = ScriptedAdapter([reply(200)]);
    final cache = CacheInterceptor();
    final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter
      ..transformer = FoldingTransformer()
      ..interceptors.add(cache);

    await dio.get<dynamic>('/x');
    await dio.get<dynamic>('/x');
    expect(adapter.requests, hasLength(1));

    cache.clearCache();
    await dio.get<dynamic>('/x');

    expect(adapter.requests, hasLength(2));
  });

  test('a hit carries the current request options and reaches response '
      'interceptors before and after the cache', () async {
    final before = _ResponseSpy();
    final after = _ResponseSpy();
    final adapter = ScriptedAdapter([
      reply(200, headers: {'x-a': '1'}),
    ]);
    final dio = _dio(adapter, [before, CacheInterceptor(), after]);

    await dio.get<dynamic>('/x', options: _tagged(1));
    final hit = await dio.get<dynamic>('/x', options: _tagged(2));

    expect(adapter.requests, hasLength(1));
    expect(hit.requestOptions.extra['id'], 2);
    expect(hit.statusCode, 200);
    expect(hit.data, {'status': 200});
    expect(hit.headers.value('x-a'), '1');
    expect(before.responses, hasLength(2));
    expect(after.responses, hasLength(2));
    expect(before.responses.last.requestOptions.extra['id'], 2);
    expect(after.responses.last.requestOptions.extra['id'], 2);
  });

  test(
    'isCacheHit is true for a hit and false for a network response',
    () async {
      final dio = _dio(ScriptedAdapter([reply(200)]), [CacheInterceptor()]);

      final network = await dio.get<dynamic>('/x');
      final hit = await dio.get<dynamic>('/x');

      expect(network.isCacheHit, isFalse);
      expect(hit.isCacheHit, isTrue);
    },
  );

  test('a hit does not renew its entry', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final dio = _dio(adapter, [
        CacheInterceptor(
          config: const CacheConfig(duration: Duration(minutes: 5)),
        ),
      ]);
      final hits = <bool>[];
      void read() {
        dio.get<dynamic>('/x').then((r) => hits.add(r.isCacheHit)).ignore();
        async.elapse(Duration.zero);
      }

      read();
      for (var minute = 1; minute <= 5; minute++) {
        async.elapse(const Duration(minutes: 1));
        read();
      }
      expect(adapter.requests, hasLength(1));

      async.elapse(const Duration(seconds: 1));
      read();

      expect(adapter.requests, hasLength(2));
      expect(hits, [false, true, true, true, true, true, false]);
    });
  });

  test('the stored entry never carries the hit marker', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final dio = _dio(adapter, [
        CacheInterceptor(
          config: const CacheConfig(duration: Duration(minutes: 1)),
        ),
      ]);
      final responses = <Response<dynamic>>[];
      void read() {
        dio.get<dynamic>('/x').then(responses.add).ignore();
        async.elapse(Duration.zero);
      }

      read();
      read();
      async.elapse(const Duration(minutes: 2));
      read();
      read();

      expect(adapter.requests, hasLength(2));
      expect(responses.map((r) => r.isCacheHit), [false, true, false, true]);
    });
  });

  test('a non-GET request is neither answered from nor stored in the '
      'cache', () async {
    final adapter = ScriptedAdapter([reply(200)]);
    final dio = _dio(adapter, [CacheInterceptor()]);

    await dio.post<dynamic>('/x');
    final second = await dio.post<dynamic>('/x');

    expect(adapter.requests, hasLength(2));
    expect(second.isCacheHit, isFalse);
  });
}
