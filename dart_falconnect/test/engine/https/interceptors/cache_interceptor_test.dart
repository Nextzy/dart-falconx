import 'package:dart_falconnect/dart_falconnect.dart';
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

/// A memory store whose reads or writes fail, as a full disk would.
class _BrokenStore extends MemCacheStore {
  new({this.failGet = false, this.failSet = false});

  final bool failGet;
  final bool failSet;

  @override
  Future<CacheResponse?> get(String key) =>
      failGet ? Future.error(StateError('disk full')) : super.get(key);

  @override
  Future<void> set(CacheResponse response) =>
      failSet ? Future.error(StateError('disk full')) : super.set(response);
}

Dio _dio(HttpClientAdapter adapter, List<Interceptor> chain) =>
    Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter
      ..transformer = FoldingTransformer()
      ..interceptors.addAll(chain);

/// A 200 the server marks cacheable for a minute.
Reply _cacheable() => reply(200, headers: {'cache-control': 'max-age=60'});

Options _tagged(int id) => Options(extra: {'id': id});

Options _auth(String token) =>
    Options(headers: {'Authorization': 'Bearer $token'});

List<String> _paths(ScriptedAdapter adapter) => [
  for (final request in adapter.requests) request.uri.path,
];

void main() {
  group('following the server', () {
    test('serves a response marked cacheable without a second network '
        'call', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      final first = await dio.get<dynamic>('/x');
      final second = await dio.get<dynamic>('/x');

      expect(second.statusCode, 200);
      expect(second.data, first.data);
      expect(_paths(adapter), ['/x']);
    });

    test('does not store a response without cache headers', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      await dio.get<dynamic>('/x');
      final second = await dio.get<dynamic>('/x');

      expect(adapter.requests, hasLength(2));
      expect(second.isCacheHit, isFalse);
    });

    test('does not store a response with cache-control: no-store', () async {
      final adapter = ScriptedAdapter([
        reply(200, headers: {'cache-control': 'max-age=60, no-store'}),
      ]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      await dio.get<dynamic>('/x');
      await dio.get<dynamic>('/x');

      expect(adapter.requests, hasLength(2));
    });

    test('does not cache a non-GET response', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      await dio.post<dynamic>('/x');
      final second = await dio.post<dynamic>('/x');

      expect(adapter.requests, hasLength(2));
      expect(second.isCacheHit, isFalse);
    });

    test('reads an Expires HTTP-date', () async {
      final adapter = ScriptedAdapter([
        (options) => ResponseBody.fromString(
          '{}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
            'expires': [
              if (options.uri.path == '/past')
                'Wed, 21 Oct 2015 07:28:00 GMT'
              else
                'Fri, 01 Jan 2100 00:00:00 GMT',
            ],
          },
        ),
      ]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      for (final path in ['/past', '/past', '/future', '/future']) {
        await dio.get<dynamic>(path);
      }

      expect(_paths(adapter), ['/past', '/past', '/future']);
    });

    test('revalidates a stale entry with its ETag and answers a 304 with the '
        'stored body', () async {
      final adapter = ScriptedAdapter([
        reply(200, headers: {'cache-control': 'max-age=0', 'etag': '"v1"'}),
        reply(304),
      ]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      final first = await dio.get<dynamic>('/x');
      final revalidated = await dio.get<dynamic>('/x');

      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.headers['if-none-match'], '"v1"');
      expect(revalidated.statusCode, 200);
      expect(revalidated.data, first.data);
    });

    test('a streamed GET of a URL stored by another GET reaches the '
        'network', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      await dio.get<dynamic>(
        '/x',
        options: Options(responseType: ResponseType.bytes),
      );
      final streamed = await dio.get<ResponseBody>(
        '/x',
        options: Options(responseType: ResponseType.stream),
      );

      expect(streamed.data, isA<ResponseBody>());
      expect(adapter.requests, hasLength(2));
    });

    test('a streamed GET bypasses the cache, even when forced', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [
        CacheInterceptor(
          config: const CacheConfig(
            policy: CachePolicy.forceCache,
            maxStale: Duration(minutes: 1),
          ),
        ),
      ]);
      final stream = Options(responseType: ResponseType.stream);

      await dio.get<dynamic>('/x');
      final first = await dio.get<ResponseBody>('/x', options: stream);
      final second = await dio.get<ResponseBody>('/x', options: stream);

      expect(first.data, isA<ResponseBody>());
      expect(second.data, isA<ResponseBody>());
      expect(adapter.requests, hasLength(3));
    });

    test('a 304 to a request the app made conditional stays an error', () {
      final adapter = ScriptedAdapter([reply(304)]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      expect(
        dio.get<dynamic>(
          '/x',
          options: Options(headers: {'if-none-match': '"v1"'}),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.badResponse,
          ),
        ),
      );
    });
  });

  group('the answer', () {
    test('a hit carries the current request options and reaches response '
        'interceptors before and after the cache', () async {
      final before = _ResponseSpy();
      final after = _ResponseSpy();
      final adapter = ScriptedAdapter([
        reply(200, headers: {'cache-control': 'max-age=60', 'x-a': '1'}),
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

    test('isCacheHit is true for a hit and false for a network '
        'response', () async {
      final dio = _dio(ScriptedAdapter([_cacheable()]), [CacheInterceptor()]);

      final network = await dio.get<dynamic>('/x');
      final hit = await dio.get<dynamic>('/x');

      expect(network.isCacheHit, isFalse);
      expect(hit.isCacheHit, isTrue);
    });

    test('an app that edits a hit leaves the next hit unchanged', () async {
      final dio = _dio(ScriptedAdapter([_cacheable()]), [CacheInterceptor()]);

      final network = await dio.get<dynamic>('/x');
      (network.data as Map<String, dynamic>)['status'] = 'edited';
      network.headers.set('x-edited', '1');
      final hit = await dio.get<dynamic>('/x');
      expect(hit.data, {'status': 200});
      expect(hit.headers.value('x-edited'), isNull);
      (hit.data as Map<String, dynamic>)['status'] = 'edited';
      hit.headers.set('x-edited', '1');
      final next = await dio.get<dynamic>('/x');

      expect(next.data, {'status': 200});
      expect(next.headers.value('x-edited'), isNull);
    });
  });

  group('per-request settings', () {
    test('cacheFor stores a response without cache headers and drops it '
        'after the duration', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final dio = _dio(adapter, [CacheInterceptor()]);
      final options = Options()..cacheFor = const Duration(milliseconds: 600);

      await dio.get<dynamic>('/x', options: options);
      final hit = await dio.get<dynamic>('/x', options: options);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await dio.get<dynamic>('/x', options: options);

      expect(hit.isCacheHit, isTrue);
      expect(adapter.requests, hasLength(2));
    });

    test("a hit does not push back its entry's expiry", () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final dio = _dio(adapter, [CacheInterceptor()]);
      final options = Options()..cacheFor = const Duration(seconds: 1);

      await dio.get<dynamic>('/x', options: options);
      // Past half the lifetime, where the library would push expiry back.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final hit = await dio.get<dynamic>('/x', options: options);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await dio.get<dynamic>('/x', options: options);

      expect(hit.isCacheHit, isTrue);
      expect(adapter.requests, hasLength(2));
    });

    test('cacheFor never answers from an entry older than its '
        'duration', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      await dio.get<dynamic>('/x');
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final refetched = await dio.get<dynamic>(
        '/x',
        options: Options()..cacheFor = const Duration(milliseconds: 500),
      );
      final hit = await dio.get<dynamic>(
        '/x',
        options: Options()..cacheFor = const Duration(minutes: 1),
      );

      expect(refetched.isCacheHit, isFalse);
      expect(hit.isCacheHit, isTrue);
      expect(adapter.requests, hasLength(2));
    });

    test('cachePolicy noCache neither reads nor stores', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [CacheInterceptor()]);
      final noCache = Options()..cachePolicy = CachePolicy.noCache;

      await dio.get<dynamic>('/x', options: noCache);
      await dio.get<dynamic>('/x', options: noCache);
      await dio.get<dynamic>('/x');

      expect(adapter.requests, hasLength(3));
    });

    test('cachePolicy noCache drops the stored entry', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      await dio.get<dynamic>('/x');
      await dio.get<dynamic>(
        '/x',
        options: Options()..cachePolicy = CachePolicy.noCache,
      );
      final after = await dio.get<dynamic>('/x');

      expect(after.isCacheHit, isFalse);
      expect(adapter.requests, hasLength(3));
    });

    test('cachePolicy refresh fetches and stores the fresh answer', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      await dio.get<dynamic>('/x');
      final refreshed = await dio.get<dynamic>(
        '/x',
        options: Options()..cachePolicy = CachePolicy.refresh,
      );
      final hit = await dio.get<dynamic>('/x');

      expect(refreshed.isCacheHit, isFalse);
      expect(hit.isCacheHit, isTrue);
      expect(adapter.requests, hasLength(2));
    });

    test('cacheFor must be positive', () {
      expect(() => Options()..cacheFor = Duration.zero, throwsArgumentError);
      expect(
        () => RequestOptions()..cacheFor = const Duration(seconds: -1),
        throwsArgumentError,
      );
    });
  });

  group('the key', () {
    test('two users of one URL get separate entries', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      await dio.get<dynamic>('/me', options: _auth('alice'));
      final bob = await dio.get<dynamic>('/me', options: _auth('bob'));
      final alice = await dio.get<dynamic>('/me', options: _auth('alice'));

      expect(bob.isCacheHit, isFalse);
      expect(alice.isCacheHit, isTrue);
      expect(adapter.requests, hasLength(2));
    });

    test('a header outside keyHeaders shares the entry', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [CacheInterceptor()]);

      await dio.get<dynamic>('/x', options: Options(headers: {'x-trace': '1'}));
      await dio.get<dynamic>('/x', options: Options(headers: {'x-trace': '2'}));

      expect(adapter.requests, hasLength(1));
    });

    test('keyHeaders compare ignoring case', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [
        CacheInterceptor(config: const CacheConfig(keyHeaders: {'X-Tenant'})),
      ]);

      await dio.get<dynamic>(
        '/x',
        options: Options(headers: {'x-tenant': 'a'}),
      );
      await dio.get<dynamic>(
        '/x',
        options: Options(headers: {'X-TENANT': 'b'}),
      );

      expect(adapter.requests, hasLength(2));
    });
  });

  group('the store', () {
    test('a store passed in receives the entries and clearCache empties '
        'it', () async {
      final store = MemCacheStore();
      final cache = CacheInterceptor(config: CacheConfig(store: store));
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [cache]);

      await dio.get<dynamic>('/x');

      expect(cache.store, same(store));
      expect(await store.getFromPath(RegExp('/x')), hasLength(1));

      await cache.clearCache();
      await dio.get<dynamic>('/x');

      expect(adapter.requests, hasLength(2));
    });

    test('a store that fails to read lets the request reach the '
        'network', () async {
      final adapter = ScriptedAdapter([_cacheable()]);
      final dio = _dio(adapter, [
        CacheInterceptor(
          config: CacheConfig(store: _BrokenStore(failGet: true)),
        ),
      ]);

      final response = await dio.get<dynamic>('/x');

      expect(response.data, {'status': 200});
      expect(adapter.requests, hasLength(1));
    });

    test('a store that fails to write still hands over the response, and '
        'says so without the query', () async {
      final lines = <String>[];
      final dio = _dio(ScriptedAdapter([_cacheable()]), [
        CacheInterceptor(
          config: CacheConfig(store: _BrokenStore(failSet: true)),
          logPrint: lines.add,
        ),
      ]);

      final response = await dio.get<dynamic>('/x?token=secret');

      expect(response.statusCode, 200);
      expect(response.data, {'status': 200});
      expect(
        lines.single,
        '[CacheInterceptor] Skipped the cache for GET a.test/x after '
        'StateError',
      );
    });

    test('without a store it builds a memory store', () {
      expect(CacheInterceptor().store, isA<MemCacheStore>());
    });

    test('a small maxSize still builds a memory store, and a non-positive '
        'one throws', () {
      expect(
        CacheInterceptor(config: const CacheConfig(maxSize: 1024)).store,
        isA<MemCacheStore>(),
      );
      expect(
        () => CacheInterceptor(config: const CacheConfig(maxSize: 0)),
        throwsArgumentError,
      );
    });
  });

  group('the chain', () {
    test('a 304 whose entry vanished in flight fails as a bad response', () {
      fakeAsync((async) {
        final adapter = GatedAdapter();
        final cache = CacheInterceptor();
        final dio = _dio(adapter, [cache]);
        final outcomes = <Object>[];

        dio.get<dynamic>('/x').ignore();
        async.elapse(Duration.zero);
        adapter.requests.last.respond(
          200,
          headers: {'cache-control': 'max-age=0', 'etag': '"v1"'},
        );
        async.elapse(Duration.zero);
        dio
            .get<dynamic>('/x')
            .then(outcomes.add, onError: outcomes.add)
            .ignore();
        async.elapse(Duration.zero);
        cache.clearCache().ignore();
        async.elapse(Duration.zero);
        adapter.requests.last.respond(304);
        async.elapse(Duration.zero);

        expect(adapter.requests, hasLength(2));
        expect(
          outcomes.single,
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.badResponse)
              .having((e) => e.response?.statusCode, 'status', 304),
        );
      });
    });

    test('a 304 revalidation returns its concurrency slot', () {
      fakeAsync((async) {
        final adapter = GatedAdapter();
        final dio = _dio(adapter, [
          CacheInterceptor(),
          ConcurrencyLimitInterceptor(
            config: const ConcurrencyConfig(perHost: 1),
          ),
        ]);
        final outcomes = <Object>[];
        void get() {
          dio
              .get<dynamic>('/x')
              .then(outcomes.add, onError: outcomes.add)
              .ignore();
          async.elapse(Duration.zero);
        }

        get();
        adapter.requests.last.respond(
          200,
          headers: {'cache-control': 'max-age=0', 'etag': '"v1"'},
        );
        async.elapse(Duration.zero);
        get();
        adapter.requests.last.respond(304);
        async.elapse(Duration.zero);
        get();

        expect(outcomes, hasLength(2));
        expect(outcomes.every((o) => o is Response), isTrue);
        expect(adapter.requests, hasLength(3));
      });
    });
  });
}
