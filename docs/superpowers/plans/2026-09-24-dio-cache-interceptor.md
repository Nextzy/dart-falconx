# HTTP Cache on dio_cache_interceptor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the homegrown `CacheInterceptor` with a wrapper over `dio_cache_interceptor` 4.0.7 behind `CacheConfig`: HTTP caching by default, per-request `cacheFor` and `cachePolicy`, per-user keys, an opt-in offline fallback that answers after the last retry, and no leaked concurrency slot.

**Architecture:** `CacheInterceptor` holds a private `DioCacheInterceptor` and delegates `onRequest` and `onResponse`, writing per-request `CacheOptions` into `extra[extraKey]`. A lookup carries no `maxStale`, so a hit never pushes an entry's expiry back. A handler wrapper makes a request the library made conditional accept `304`, so revalidation stays on the response path, and `onError` never delegates. The offline fallback is a second interceptor, `cache.fallback`, that `BaseHttpClient` places after `RetryInterceptor`; `RetryInterceptor` marks the error it passes on after its last attempt, so the fallback skips nested attempts. `BaseHttpClient` keeps the memory store across a `configure` that leaves the entries valid.

**Tech Stack:** Dart 3.13 (the repository's `new(...)` constructor syntax), dio 5.11.1, dio_cache_interceptor 4.0.7 with http_cache_core 1.1.4 (already a dependency), hashlib through `dart_faltool`, freezed 4, `package:test`, `fake_async`, melos 8. No new dependency.

**Spec:** `docs/superpowers/specs/2026-09-24-dio-cache-interceptor-design.md`

**Provenance:** Every code block in Tasks 1 to 3 comes from a throwaway prototype built on `feature/cache` at `93aa8d0` (branch `proto/cache`) on 2026-09-24. There, `melos run analyze`, `melos run format`, `melos run build_runner:check`, and `melos run test:platforms` exited 0, `melos run test` passed (dart_falconnect 300 with 1 existing skip, dart_faltool 771, dart_falmodel 71, dart_falconx 1), and `test:platforms` passed dart_falconnect 304 in Chrome under both dart2js and dart2wasm. The prototype was then replayed one task at a time on a fresh branch from `93aa8d0`: after Task 1, dart_falconnect passed 288; after Task 2, 297; after Task 3, 300; and the replay matched the prototype file for file. Finally a script replayed the code blocks of Tasks 1 to 3, taken from this plan's text alone, onto `93aa8d0`: after `build_runner`, `dart format` changed no file, `dart analyze --fatal-infos` printed `No issues found!`, dart_falconnect passed 300, and the tree matched the Task 3 replay line for line. Each task's RED line below is the failure the replay recorded before the task's implementation existed. Five mutations were checked against the tests, and each failed the named test: a sliding `maxStale` on lookups (`a hit does not push back its entry's expiry`), no `304` acceptance (`revalidates a stale entry ...` and `a 304 revalidation returns its concurrency slot`), a key without headers (`two users of one URL get separate entries`), no store reuse (`a changed cache setting keeps the stored entries`), and a fallback that ignores the retry marker (`a network failure after every retry answers from the cache`). The documentation task (4) was not prototyped.

## Global Constraints

- Work in worktree `.claude/worktrees/cache` on branch `feature/cache`, cut from `feature/json-log` at `d42c893`; the spec is `93aa8d0` and this plan the commit after it.
- No new dependency in any `pubspec.yaml`.
- Every package stays pure Dart: no `dart:io` under `lib/`; the key digest uses hashlib's `sha256`, which runs on the web.
- Lints: `very_good_analysis`; run `dart analyze --fatal-infos`; single quotes; 80 columns; exports in barrel files sorted alphabetically.
- Every model is freezed, in the repository's syntax. Generated files go to `generated/`. Run `dart run build_runner build` in `dart_falconnect` after changing `CacheConfig`, and `melos run build_runner:check` before the final gates.
- Interceptor, config, and `lib/src/` files import the files they need directly, as their neighbours do.
- Give every test `Dio` answered by `ScriptedAdapter` or `GatedAdapter` a `FoldingTransformer`. Under `fakeAsync`, advance with `async.elapse(Duration.zero)`, never `flushMicrotasks()`.
- `dio_cache_interceptor` reads `DateTime.now()`, not `clock.now()`: test expiry with short real waits, outside `fakeAsync`.
- Run `dart format` on every file you touch before committing.
- Commit with explicit paths: `git add` new files, `git rm` deleted ones, then `git commit -m <msg> -- <paths>`. No `Co-Authored-By` line, no AI attribution, and no `!` in any commit message.
- Do not push, merge, tag, or bump versions. The owner merges `feature/json-log` first, then `feature/cache`, bumps to 2.1.0 on `release/2.1.0`, and tags.

## Review Focus

1. **Two users of one URL on a shared server client** (different `Authorization` values): they must never share an entry. Pinned by Task 1 test `two users of one URL get separate entries`.
2. **An app that edits a hit's `data` or `headers`**: the next hit must be unchanged. Pinned by Task 1 test `an app that edits a hit leaves the next hit unchanged`.
3. **A hot `cacheFor` endpoint read again and again**: it must still expire on time; the library would push `maxStale` back on every hit. Pinned by Task 1 test `a hit does not push back its entry's expiry`.
4. **A `304` revalidation and an offline answer under a concurrency limit**: the slot must come back. Pinned by Task 1 test `a 304 revalidation returns its concurrency slot` and Task 2 test `an answer from the fallback returns its concurrency slot`.
5. **An offline fallback in a chain with `RetryInterceptor`**: it must answer only after the last retry, never inside the first nested attempt. Pinned by Task 2 test `a network failure after every retry answers from the cache`.

## Prototype rulings

The prototype decided these points where the spec is silent or its first draft was wrong; the spec was amended to match in the same commit as this plan. The final review weighs them.

- Section 6: a lookup's `CacheOptions` carry no `maxStale`; only a save does. The library's `_updateCacheResponse` pushes an entry's `maxStale` back on every hit, so without this a `cacheFor` entry read often would never expire.
- Section 6: both hooks always write the request's `CacheOptions` into `extra[extraKey]`, so a retry's copied `extra` never carries a save's `maxStale` into a lookup.
- Section 6.1: `RetryInterceptor` marks the error it passes on after its last attempt (`dart_falconnect.retry.final` in `extra`, through `lib/src/engine/https/interceptors/retry_attempts.dart`), and the fallback passes on the error of an attempt whose loop may still retry. A nested attempt's error runs the rest of the chain, the fallback included, before the loop decides.
- Section 6.1: the fallback uses its own predicate (no status: `hitCacheOnNetworkFailure`; a status: `hitCacheOnErrorCodes` contains it) instead of the library's `isCacheCheckAllowed`, which also accepts `304`. It answers `GET` only, never a cancel, and a store that throws leaves the original error.
- Section 4: the default memory store's per-entry limit is `min(512000, maxSize ~/ 5)`, because `MemCacheStore` asserts `maxEntrySize * 5 <= maxSize`; a `maxSize` that is not positive throws `ArgumentError`.
- Section 6: after a `304` revalidation the response reads `isCacheHit` false, as the library marks a validated response as from the network; a fallback answer reads both `isCacheHit` and `isCacheFallback` true.
- Section 6: diagnostics read `[CacheInterceptor] Hit for GET <host><path>` and `[CacheInterceptor] Answered GET <host><path> from the cache after <status or DioExceptionType name>`.

---

### Task 1: `CacheInterceptor` on `dio_cache_interceptor`

**Files:**
- Modify (replace): `dart_falconnect/lib/engine/https/config/cache_config.dart`, `dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart`
- Modify: `dart_falconnect/lib/engine/https/interceptors/models/models.dart`
- Delete: `dart_falconnect/lib/engine/https/interceptors/models/cache_entry.dart`, `dart_falconnect/lib/engine/https/interceptors/models/generated/cache_entry.freezed.dart`
- Regenerate: `dart_falconnect/lib/engine/https/config/generated/cache_config.freezed.dart`
- Test (replace): `dart_falconnect/test/engine/https/interceptors/cache_interceptor_test.dart`
- Test (modify): `concurrency_limit_interceptor_test.dart`, `token_bucket_rate_limit_interceptor_test.dart`, `http_json_log_interceptor_test.dart`, `interceptor_diagnostics_test.dart` (all in `test/engine/https/interceptors/`), `test/engine/https/config/feature_boxes_test.dart`, `test/engine/https/base_http_client_configure_test.dart`, `test/web/engine_web_test.dart`

**Interfaces:**
- Consumes: from `dio_cache_interceptor`: `CacheOptions`, `CachePolicy`, `CacheStore`, `MemCacheStore`, `DioCacheInterceptor`, `extraKey`, `extraFromNetworkKey`, `conditionalRequestHeaders`; `sha256` from `dart_faltool`.
- Produces: `CacheConfig({CachePolicy policy = CachePolicy.request, Duration? maxStale, int maxSize = 50 * 1024 * 1024, CacheStore? store, Set<String> keyHeaders = {'authorization', 'accept', 'accept-language'}})`; `CacheInterceptor({CacheConfig config = const CacheConfig(), void Function(String message)? logPrint})` with `final CacheStore store` and `Future<void> clearCache()`, and private `_options({required CachePolicy policy, required Duration? maxStale})`, `_key({required Uri url, Map<String, String>? headers, Object? body})`, `static String _describe(RequestOptions)`, `static bool _hasConditions(RequestOptions)`, `void _log(String)` that Task 2 reuses; `CachePolicy? cachePolicy` and `Duration? cacheFor` on `Options` and `RequestOptions`; `FalconCacheHitResponseExtensions.isCacheHit`. `evictExpired()` and `CacheEntry` are removed. `BaseHttpClient` still builds `CacheInterceptor(config: box, logPrint: _diagnostic)` unchanged until Task 3.

- [ ] **Step 1: Write the failing tests**

Replace `dart_falconnect/test/engine/https/interceptors/cache_interceptor_test.dart` with:

```dart
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

      await dio.get<dynamic>('/x');
      final hit = await dio.get<dynamic>('/x');
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
      final options = Options()..cacheFor = const Duration(milliseconds: 300);

      await dio.get<dynamic>('/x', options: options);
      final hit = await dio.get<dynamic>('/x', options: options);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await dio.get<dynamic>('/x', options: options);

      expect(hit.isCacheHit, isTrue);
      expect(adapter.requests, hasLength(2));
    });

    test("a hit does not push back its entry's expiry", () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final dio = _dio(adapter, [CacheInterceptor()]);
      final options = Options()..cacheFor = const Duration(milliseconds: 400);

      await dio.get<dynamic>('/x', options: options);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final hit = await dio.get<dynamic>('/x', options: options);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await dio.get<dynamic>('/x', options: options);

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
```

Apply this diff to the other tests. Under the new default policy a reply without cache headers is not stored, so every test that relies on a hit sends `cache-control: max-age=60`; the box defaults and the hit diagnostic change; the web gate serves a hit:

```diff
--- a/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
+++ b/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
@@ -496,14 +496,18 @@ void main() {
     test(
       'a printer that throws fails no request through a diagnostic',
       () async {
-        final client = _Client(ScriptedAdapter([reply(200)]))
-          ..configure(
-            HttpClientConfig(
-              baseUrl: 'https://a.test',
-              log: LogConfig.json(logPrint: (_) => throw StateError('sink')),
-              cache: const CacheConfig(),
-            ),
-          );
+        final client =
+            _Client(
+              ScriptedAdapter([
+                reply(200, headers: {'cache-control': 'max-age=60'}),
+              ]),
+            )..configure(
+              HttpClientConfig(
+                baseUrl: 'https://a.test',
+                log: LogConfig.json(logPrint: (_) => throw StateError('sink')),
+                cache: const CacheConfig(),
+              ),
+            );
 
         final network = await client.dio.get<dynamic>('/x');
         final hit = await client.dio.get<dynamic>('/x');
--- a/dart_falconnect/test/engine/https/config/feature_boxes_test.dart
+++ b/dart_falconnect/test/engine/https/config/feature_boxes_test.dart
@@ -17,8 +17,11 @@ void main() {
     expect(retry.onRetry, isNull);
 
     const cache = CacheConfig();
-    expect(cache.duration, const Duration(minutes: 15));
+    expect(cache.policy, CachePolicy.request);
+    expect(cache.maxStale, isNull);
     expect(cache.maxSize, 50 * 1024 * 1024);
+    expect(cache.store, isNull);
+    expect(cache.keyHeaders, {'authorization', 'accept', 'accept-language'});
 
     const pause = PauseConfig();
     expect(pause.maxPauseWait, const Duration(seconds: 10));
--- a/dart_falconnect/test/engine/https/interceptors/concurrency_limit_interceptor_test.dart
+++ b/dart_falconnect/test/engine/https/interceptors/concurrency_limit_interceptor_test.dart
@@ -421,7 +421,9 @@ void main() {
 
   test('a cache hit, with CacheInterceptor first, takes no slot', () {
     fakeAsync((async) {
-      final adapter = ScriptedAdapter([reply(200)]);
+      final adapter = ScriptedAdapter([
+        reply(200, headers: {'cache-control': 'max-age=60'}),
+      ]);
       final limiter = ConcurrencyLimitInterceptor(
         config: const ConcurrencyConfig(perHost: 1),
       );
@@ -453,7 +455,10 @@ void main() {
 
       _get(dio, '/x', outcomes);
       _settle(async);
-      adapter.requests.single.respond(200);
+      adapter.requests.single.respond(
+        200,
+        headers: {'cache-control': 'max-age=60'},
+      );
       _settle(async);
       _get(dio, '/y', outcomes);
       _settle(async);
--- a/dart_falconnect/test/engine/https/interceptors/http_json_log_interceptor_test.dart
+++ b/dart_falconnect/test/engine/https/interceptors/http_json_log_interceptor_test.dart
@@ -484,7 +484,9 @@ void main() {
       final lines = <Object?>[];
       fakeAsync((async) {
         final dio = _dio(
-          ScriptedAdapter([reply(200)]),
+          ScriptedAdapter([
+            reply(200, headers: {'cache-control': 'max-age=60'}),
+          ]),
           (_) => [_log(lines), CacheInterceptor()],
         );
         dio.get<dynamic>('/x').ignore();
--- a/dart_falconnect/test/engine/https/interceptors/interceptor_diagnostics_test.dart
+++ b/dart_falconnect/test/engine/https/interceptors/interceptor_diagnostics_test.dart
@@ -29,18 +29,18 @@ void main() {
     });
   });
 
-  test('CacheInterceptor prints a hit through logPrint', () async {
+  test('CacheInterceptor prints a hit through logPrint, without the '
+      'query', () async {
     final lines = <String>[];
-    final dio = _dio([reply(200)]);
+    final dio = _dio([
+      reply(200, headers: {'cache-control': 'max-age=60'}),
+    ]);
     dio.interceptors.add(CacheInterceptor(logPrint: lines.add));
 
-    await dio.get<dynamic>('/x');
-    await dio.get<dynamic>('/x');
+    await dio.get<dynamic>('/x?token=secret');
+    await dio.get<dynamic>('/x?token=secret');
 
-    expect(
-      lines.where((line) => line.startsWith('[CacheInterceptor] Cache hit')),
-      hasLength(1),
-    );
+    expect(lines, ['[CacheInterceptor] Hit for GET a.test/x']);
   });
 
   test('an interceptor without logPrint prints nothing', () {
--- a/dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart
+++ b/dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart
@@ -759,7 +759,9 @@ void main() {
         ),
       );
       final spy = _ResponseSpy();
-      final adapter = ScriptedAdapter([reply(200)]);
+      final adapter = ScriptedAdapter([
+        reply(200, headers: {'cache-control': 'max-age=60'}),
+      ]);
       final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
         ..httpClientAdapter = adapter
         ..transformer = FoldingTransformer()
--- a/dart_falconnect/test/web/engine_web_test.dart
+++ b/dart_falconnect/test/web/engine_web_test.dart
@@ -44,6 +44,23 @@ void main() {
       expect(DefaultNetworkExceptionHandlerInterceptor(), isNotNull);
     });
 
+    test('CacheInterceptor serves a hit on web', () async {
+      final adapter = ScriptedAdapter([
+        reply(200, headers: {'cache-control': 'max-age=60'}),
+      ]);
+      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
+        ..httpClientAdapter = adapter
+        ..interceptors.add(CacheInterceptor());
+      final options = Options(headers: {'Authorization': 'Bearer t'});
+
+      await dio.get<dynamic>('/x', options: options);
+      final hit = await dio.get<dynamic>('/x', options: options);
+
+      expect(hit.isCacheHit, isTrue);
+      expect(hit.data, {'status': 200});
+      expect(adapter.requests, hasLength(1));
+    });
+
     test('HttpJsonLogInterceptor prints one JSON line on web', () async {
       final lines = <Object?>[];
       final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/cache_interceptor_test.dart test/engine/https/config/feature_boxes_test.dart test/engine/https/interceptors/interceptor_diagnostics_test.dart`
Expected: FAIL to compile, with `The setter 'cacheFor' isn't defined for the type 'Options'.`, `The setter 'cachePolicy' isn't defined for the type 'Options'.`, `The getter 'store' isn't defined for the type 'CacheInterceptor'.`, and `The getter 'policy' isn't defined for the type 'CacheConfig'.`

- [ ] **Step 3: Replace the box and the interceptor**

Replace `dart_falconnect/lib/engine/https/config/cache_config.dart` with:

```dart
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart'
    show CachePolicy, CacheStore;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/cache_config.freezed.dart';

/// Response cache settings; a non-null box adds `CacheInterceptor`.
@freezed
abstract class CacheConfig with _$CacheConfig {
  /// Creates cache settings. By default the cache follows the server's
  /// cache headers and keeps entries in memory.
  const factory({
    /// Default policy; [CachePolicy.request] follows the server's cache
    /// headers and stores nothing a response does not mark cacheable.
    @Default(CachePolicy.request) CachePolicy policy,

    /// Drops an entry this long after it was stored, whatever its headers
    /// say; null keeps an entry as long as its headers allow.
    Duration? maxStale,

    /// Byte budget of the default memory store, evicted least recently
    /// used; must be positive. A single response over 512,000 bytes, or
    /// over a fifth of this budget, is not stored.
    @Default(50 * 1024 * 1024) int maxSize,

    /// Where entries live; null builds a `MemCacheStore` of [maxSize]
    /// bytes. The client never closes a store passed here.
    CacheStore? store,

    /// Request headers that split one URL into separate entries, compared
    /// ignoring case. On a server that serves many users, keep
    /// `authorization` here, or one user reads another's cached responses.
    @Default({'authorization', 'accept', 'accept-language'})
    Set<String> keyHeaders,
  }) = _CacheConfig;
}
```

Replace `dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart` with:

```dart
import 'dart:math';

import 'package:dart_falconnect/engine/https/config/cache_config.dart';
import 'package:dart_faltool/dart_faltool.dart' show sha256;
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

const String _policyKey = 'dart_falconnect.cache.policy';
const String _forKey = 'dart_falconnect.cache.for';

/// Tells a response answered by [CacheInterceptor] apart from one fetched
/// from the network.
extension FalconCacheHitResponseExtensions on Response<dynamic> {
  /// Whether [CacheInterceptor] answered this response from its store,
  /// without a network round trip.
  bool get isCacheHit => extra[extraFromNetworkKey] == false;
}

/// Per-request cache settings on [RequestOptions].
extension FalconCacheRequestOptionsExtensions on RequestOptions {
  /// Policy for this request; null uses `CacheConfig.policy`, or
  /// [CachePolicy.forceCache] when [cacheFor] is set.
  CachePolicy? get cachePolicy => extra[_policyKey] as CachePolicy?;
  set cachePolicy(CachePolicy? value) => extra = {...extra, _policyKey: value};

  /// Caches this request's response for this long, whatever the server's
  /// headers say. Must be positive.
  Duration? get cacheFor => extra[_forKey] as Duration?;
  set cacheFor(Duration? value) =>
      extra = {...extra, _forKey: _checkCacheFor(value)};
}

/// Per-request cache settings on [Options].
extension FalconCacheOptionsExtensions on Options {
  /// Policy for this request; null uses `CacheConfig.policy`, or
  /// [CachePolicy.forceCache] when [cacheFor] is set.
  CachePolicy? get cachePolicy => extra?[_policyKey] as CachePolicy?;
  set cachePolicy(CachePolicy? value) => extra = {...?extra, _policyKey: value};

  /// Caches this request's response for this long, whatever the server's
  /// headers say. Must be positive.
  Duration? get cacheFor => extra?[_forKey] as Duration?;
  set cacheFor(Duration? value) =>
      extra = {...?extra, _forKey: _checkCacheFor(value)};
}

Duration? _checkCacheFor(Duration? value) {
  if (value != null && value <= Duration.zero) {
    throw ArgumentError.value(value, 'cacheFor', 'must be positive');
  }
  return value;
}

/// Caches `GET` responses on `dio_cache_interceptor`.
///
/// By default it follows the server's cache headers: it stores what a
/// response marks cacheable, answers from [store] while an entry is fresh,
/// and revalidates a stale entry with `If-None-Match` or
/// `If-Modified-Since`. A request can force caching with `cacheFor`.
///
/// A hit is a new [Response] decoded from stored bytes and bound to the
/// current request; it passes every response interceptor of the chain.
/// Entries are keyed by the URL and the headers of `CacheConfig.keyHeaders`.
///
/// Place it before `ConcurrencyLimitInterceptor`, so a hit takes no slot.
class CacheInterceptor extends Interceptor {
  /// Creates a cache on [config]; with no `config.store`, entries live in a
  /// new `MemCacheStore` of `config.maxSize` bytes.
  ///
  /// Throws an [ArgumentError] when `config.maxSize` is not positive.
  new({this.config = const CacheConfig(), this.logPrint})
    : store = config.store ?? _memoryStore(config.maxSize);

  /// Policy, key, store, and offline settings.
  final CacheConfig config;

  /// Prints diagnostics; null prints nothing.
  final void Function(String message)? logPrint;

  /// The store entries live in.
  final CacheStore store;

  late final DioCacheInterceptor _cache = DioCacheInterceptor(
    options: _options(policy: config.policy, maxStale: null),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // A lookup carries no maxStale: the library would push an entry's
    // deletion back on every hit, and an entry must expire on time.
    // A new map: the library writes into extra, which may be unmodifiable.
    options.extra = {
      ...options.extra,
      extraKey: _requestOptions(options, save: false),
    };
    _cache.onRequest(
      options,
      _RevalidatingHandler(
        handler,
        hadConditions: _hasConditions(options),
        onHit: () => _log('Hit for ${_describe(options)}'),
      ),
    );
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    options.extra = {
      ...options.extra,
      extraKey: _requestOptions(options, save: true),
    };
    _cache.onResponse(response, handler);
  }

  // The library resolves inside onError, which skips every later error
  // interceptor; 304 revalidation runs on the response path instead.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) =>
      handler.next(err);

  /// Deletes every entry of [store].
  Future<void> clearCache() => store.clean();

  CacheOptions _options({
    required CachePolicy policy,
    required Duration? maxStale,
  }) => CacheOptions(
    store: store,
    policy: policy,
    maxStale: maxStale,
    keyBuilder: _key,
  );

  /// The library options of one request. Only a save carries maxStale, which
  /// the library stamps on the entry it stores.
  CacheOptions _requestOptions(RequestOptions options, {required bool save}) {
    final cacheFor = options.cacheFor;
    return _options(
      policy:
          options.cachePolicy ??
          (cacheFor != null ? CachePolicy.forceCache : config.policy),
      maxStale: save ? cacheFor ?? config.maxStale : null,
    );
  }

  /// The store key: a digest of the URL and the listed headers the request
  /// carries, so header values such as tokens never sit in a key.
  String _key({required Uri url, Map<String, String>? headers, Object? body}) {
    final values = {
      for (final MapEntry(:key, :value) in (headers ?? const {}).entries)
        key.toLowerCase(): value,
    };
    final names = [for (final name in config.keyHeaders) name.toLowerCase()]
      ..sort();
    final input = StringBuffer('$url');
    for (final name in names) {
      final value = values[name];
      if (value != null) input.write('\n$name: $value');
    }
    return sha256.string(input.toString()).hex();
  }

  /// The library's default per-entry limit. The memory store also needs an
  /// entry limit of at most a fifth of its total size.
  static const int _maxEntrySize = 512000;

  static MemCacheStore _memoryStore(int maxSize) {
    if (maxSize <= 0) {
      throw ArgumentError.value(maxSize, 'maxSize', 'must be positive');
    }
    return MemCacheStore(
      maxSize: maxSize,
      maxEntrySize: min(_maxEntrySize, maxSize ~/ 5),
    );
  }

  // The query may hold a secret, so diagnostics never print it.
  static String _describe(RequestOptions options) =>
      '${options.method} ${options.uri.host}${options.uri.path}';

  static bool _hasConditions(RequestOptions options) =>
      conditionalRequestHeaders.any(options.headers.containsKey);

  void _log(String message) => logPrint?.call('[CacheInterceptor] $message');
}

/// Forwards to the real handler. A request the library made conditional
/// accepts `304`, so revalidation stays on the response path, where every
/// interceptor, `ConcurrencyLimitInterceptor` included, sees a response.
class _RevalidatingHandler extends RequestInterceptorHandler {
  new(this._handler, {required this.hadConditions, required this.onHit});

  final RequestInterceptorHandler _handler;

  /// Whether the app itself made the request conditional.
  final bool hadConditions;
  final void Function() onHit;

  @override
  void next(RequestOptions requestOptions) {
    if (!hadConditions && CacheInterceptor._hasConditions(requestOptions)) {
      final accept = requestOptions.validateStatus;
      requestOptions.validateStatus = (status) =>
          status == 304 || accept(status);
    }
    _handler.next(requestOptions);
  }

  @override
  void resolve(
    Response<dynamic> response, [
    bool callFollowingResponseInterceptor = false,
  ]) {
    onHit();
    _handler.resolve(response, callFollowingResponseInterceptor);
  }

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) => _handler.reject(error, callFollowingErrorInterceptor);
}
```

Delete the `CacheEntry` model and apply this diff to its barrel:

```bash
git rm dart_falconnect/lib/engine/https/interceptors/models/cache_entry.dart dart_falconnect/lib/engine/https/interceptors/models/generated/cache_entry.freezed.dart
```

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/models/models.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/models/models.dart
@@ -1,3 +1,2 @@
-export 'cache_entry.dart';
 export 'concurrency_limit_statistics.dart';
 export 'token_bucket_rate_limit_statistics.dart';
```

- [ ] **Step 4: Generate code**

Run: `cd dart_falconnect && dart run build_runner build`
Expected: `lib/engine/https/config/generated/cache_config.freezed.dart` is rewritten with `policy`, `maxStale`, `maxSize`, `store`, and `keyHeaders`.

- [ ] **Step 5: Run the tests, the analyzer, and the web gate**

Run: `cd dart_falconnect && dart format lib test && dart test test/engine/https/interceptors/cache_interceptor_test.dart && dart analyze --fatal-infos && dart test && dart test -p chrome test/engine/https/interceptors/cache_interceptor_test.dart test/web && dart test -p chrome -c dart2wasm test/engine/https/interceptors/cache_interceptor_test.dart test/web`
Expected: the cache file passes 22 tests; `No issues found!`; the whole suite passes (288 with 1 existing skip); both Chrome runs pass.

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(dart_falconnect): cache HTTP responses on dio_cache_interceptor" -- dart_falconnect/lib/engine/https/config dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart dart_falconnect/lib/engine/https/interceptors/models dart_falconnect/test/engine/https dart_falconnect/test/web
```

---

### Task 2: Offline fallback after the last retry

**Files:**
- Modify: `dart_falconnect/lib/engine/https/config/cache_config.dart`, `dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart`, `dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart`
- Create: `dart_falconnect/lib/src/engine/https/interceptors/retry_attempts.dart`
- Regenerate: `dart_falconnect/lib/engine/https/config/generated/cache_config.freezed.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/cache_fallback_test.dart` (new), `test/engine/https/config/feature_boxes_test.dart`, `test/web/compile_smoke.dart`

**Interfaces:**
- Consumes: Task 1's `CacheInterceptor` with `store`, `_key`, `_options`, `_describe`, `_log`; `retryAttempt` on `RequestOptions` (existing).
- Produces: `CacheConfig.hitCacheOnNetworkFailure` (`bool`, default false) and `CacheConfig.hitCacheOnErrorCodes` (`Set<int>`, default empty); `late final Interceptor fallback` on `CacheInterceptor`, backed by a private `_CacheFallback`; `isCacheFallback` on `FalconCacheHitResponseExtensions`; internal `DioException finalRetryError(DioException err)` and `bool isOpenRetryAttempt(RequestOptions options)`. `RetryInterceptor` passes every error it gives up on through `finalRetryError`.

- [ ] **Step 1: Write the failing tests**

Create `dart_falconnect/test/engine/https/interceptors/cache_fallback_test.dart`:

```dart
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
```

Apply this diff to the box defaults and the compile gate:

```diff
--- a/dart_falconnect/test/engine/https/config/feature_boxes_test.dart
+++ b/dart_falconnect/test/engine/https/config/feature_boxes_test.dart
@@ -22,6 +22,8 @@ void main() {
     expect(cache.maxSize, 50 * 1024 * 1024);
     expect(cache.store, isNull);
     expect(cache.keyHeaders, {'authorization', 'accept', 'accept-language'});
+    expect(cache.hitCacheOnNetworkFailure, isFalse);
+    expect(cache.hitCacheOnErrorCodes, isEmpty);
 
     const pause = PauseConfig();
     expect(pause.maxPauseWait, const Duration(seconds: 10));
--- a/dart_falconnect/test/web/compile_smoke.dart
+++ b/dart_falconnect/test/web/compile_smoke.dart
@@ -25,6 +25,7 @@ void main() {
 
   // All interceptors
   _sink(CacheInterceptor());
+  _sink(CacheInterceptor().fallback);
   _sink(
     ConcurrencyLimitInterceptor(
       config: const ConcurrencyConfig(global: 16, perHost: 4),
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/cache_fallback_test.dart test/engine/https/config/feature_boxes_test.dart`
Expected: FAIL to compile, with `The getter 'isCacheFallback' isn't defined for the type 'Response<dynamic>'.`, `The getter 'fallback' isn't defined for the type 'CacheInterceptor'.`, and `No named parameter with the name 'hitCacheOnNetworkFailure'.` With the fallback built but without the retry marker, `a network failure after every retry answers from the cache` fails with `Expected: an object with length of <4>` and `Which: has length of <3>`: the fallback answered inside the first nested attempt.

- [ ] **Step 3: Add the offline settings**

Apply this diff to `dart_falconnect/lib/engine/https/config/cache_config.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/config/cache_config.dart
+++ b/dart_falconnect/lib/engine/https/config/cache_config.dart
@@ -32,5 +32,13 @@ abstract class CacheConfig with _$CacheConfig {
     /// `authorization` here, or one user reads another's cached responses.
     @Default({'authorization', 'accept', 'accept-language'})
     Set<String> keyHeaders,
+
+    /// Answers from the cache when a request fails without a response,
+    /// after every retry.
+    @Default(false) bool hitCacheOnNetworkFailure,
+
+    /// Answers from the cache when a request fails with one of these
+    /// statuses, after every retry.
+    @Default(<int>{}) Set<int> hitCacheOnErrorCodes,
   }) = _CacheConfig;
 }
```

- [ ] **Step 4: Mark the retry loop's final error**

Create `dart_falconnect/lib/src/engine/https/interceptors/retry_attempts.dart`:

```dart
import 'package:dart_falconnect/engine/https/interceptors/retry_interceptor.dart';
import 'package:dio/dio.dart';

const String _finalKey = 'dart_falconnect.retry.final';

/// Marks [err] as the error `RetryInterceptor` passes on after its last
/// attempt, and returns it.
DioException finalRetryError(DioException err) {
  final options = err.requestOptions;
  options.extra = {...options.extra, _finalKey: true};
  return err;
}

/// Whether [options] belong to a retry attempt whose loop may still send
/// another: its error passes the rest of the chain inside the loop, before
/// `RetryInterceptor` decides.
bool isOpenRetryAttempt(RequestOptions options) =>
    options.retryAttempt > 0 && options.extra[_finalKey] != true;
```

Apply this diff to `dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart
@@ -4,6 +4,7 @@ import 'dart:math';
 import 'package:dart_falconnect/engine/https/config/retry_config.dart';
 import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
 import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
+import 'package:dart_falconnect/src/engine/https/interceptors/retry_attempts.dart';
 import 'package:dart_falmodel/networks/https/retry_after.dart';
 import 'package:dart_faltool/dart_faltool.dart' show clock;
 import 'package:dio/dio.dart';
@@ -141,7 +142,7 @@ class RetryInterceptor extends Interceptor {
         clock.now().difference(started),
       );
       if (delay == null) {
-        handler.next(current);
+        handler.next(finalRetryError(current));
         return;
       }
       config.onRetry?.call(current, attempt, delay);
@@ -150,7 +151,7 @@ class RetryInterceptor extends Interceptor {
         '${original.method} ${original.uri}',
       );
       if (!await _wait(delay, original.cancelToken)) {
-        handler.next(current);
+        handler.next(finalRetryError(current));
         return;
       }
       final RequestOptions options;
@@ -158,7 +159,7 @@ class RetryInterceptor extends Interceptor {
         options = _attemptOptions(original, attempt);
       } on Object {
         // A FormData whose files cannot be read again.
-        handler.next(current);
+        handler.next(finalRetryError(current));
         return;
       }
       try {
```

- [ ] **Step 5: Add the fallback**

Apply this diff to `dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart
@@ -1,19 +1,25 @@
 import 'dart:math';
 
 import 'package:dart_falconnect/engine/https/config/cache_config.dart';
+import 'package:dart_falconnect/src/engine/https/interceptors/retry_attempts.dart';
 import 'package:dart_faltool/dart_faltool.dart' show sha256;
 import 'package:dio/dio.dart';
 import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
 
 const String _policyKey = 'dart_falconnect.cache.policy';
 const String _forKey = 'dart_falconnect.cache.for';
+const String _fallbackKey = 'dart_falconnect.cache.fallback';
 
 /// Tells a response answered by [CacheInterceptor] apart from one fetched
 /// from the network.
 extension FalconCacheHitResponseExtensions on Response<dynamic> {
   /// Whether [CacheInterceptor] answered this response from its store,
-  /// without a network round trip.
+  /// without a network round trip, or through [CacheInterceptor.fallback].
   bool get isCacheHit => extra[extraFromNetworkKey] == false;
+
+  /// Whether [CacheInterceptor.fallback] answered this response after the
+  /// request failed.
+  bool get isCacheFallback => extra[_fallbackKey] == true;
 }
 
 /// Per-request cache settings on [RequestOptions].
@@ -62,7 +68,8 @@ Duration? _checkCacheFor(Duration? value) {
 /// current request; it passes every response interceptor of the chain.
 /// Entries are keyed by the URL and the headers of `CacheConfig.keyHeaders`.
 ///
-/// Place it before `ConcurrencyLimitInterceptor`, so a hit takes no slot.
+/// Place it before `ConcurrencyLimitInterceptor`, so a hit takes no slot,
+/// and place [fallback] after `RetryInterceptor`.
 class CacheInterceptor extends Interceptor {
   /// Creates a cache on [config]; with no `config.store`, entries live in a
   /// new `MemCacheStore` of `config.maxSize` bytes.
@@ -80,6 +87,12 @@ class CacheInterceptor extends Interceptor {
   /// The store entries live in.
   final CacheStore store;
 
+  /// Answers failed `GET` requests from [store]; place it after
+  /// `RetryInterceptor`, so it answers only after the last retry. It passes
+  /// every error on unless `hitCacheOnNetworkFailure` or
+  /// `hitCacheOnErrorCodes` is set.
+  late final Interceptor fallback = _CacheFallback(this);
+
   late final DioCacheInterceptor _cache = DioCacheInterceptor(
     options: _options(policy: config.policy, maxStale: null),
   );
@@ -117,7 +130,7 @@ class CacheInterceptor extends Interceptor {
   }
 
   // The library resolves inside onError, which skips every later error
-  // interceptor; 304 revalidation runs on the response path instead.
+  // interceptor; the fallback and 304 revalidation live elsewhere.
   @override
   void onError(DioException err, ErrorInterceptorHandler handler) =>
       handler.next(err);
@@ -164,6 +177,42 @@ class CacheInterceptor extends Interceptor {
     return sha256.string(input.toString()).hex();
   }
 
+  /// Answers [err] from [store], or returns null to pass it on.
+  Future<Response<dynamic>?> _fallbackFor(DioException err) async {
+    final options = err.requestOptions;
+    if (err.type == DioExceptionType.cancel ||
+        options.method.toUpperCase() != 'GET') {
+      return null;
+    }
+    final status = err.response?.statusCode;
+    final allowed = status == null
+        ? config.hitCacheOnNetworkFailure
+        : config.hitCacheOnErrorCodes.contains(status);
+    if (!allowed) return null;
+    try {
+      final headers = Map<String, String>.of(options.getFlattenHeaders())
+        ..removeWhere((name, _) => conditionalRequestHeaders.contains(name));
+      final entry = await store.get(_key(url: options.uri, headers: headers));
+      if (entry == null || entry.isStaled()) return null;
+      final full = await entry.readContent(
+        _options(policy: config.policy, maxStale: null),
+        readHeaders: true,
+        readBody: true,
+      );
+      final response = full.toResponse(options);
+      response.extra[_fallbackKey] = true;
+      _log(
+        'Answered ${_describe(options)} from the cache after '
+        '${status ?? err.type.name}',
+      );
+      return response;
+      // A broken store must not replace the request's own error.
+      // ignore: avoid_catches_without_on_clauses
+    } catch (_) {
+      return null;
+    }
+  }
+
   /// The library's default per-entry limit. The memory store also needs an
   /// entry limit of at most a fifth of its total size.
   static const int _maxEntrySize = 512000;
@@ -225,3 +274,23 @@ class _RevalidatingHandler extends RequestInterceptorHandler {
     bool callFollowingErrorInterceptor = false,
   ]) => _handler.reject(error, callFollowingErrorInterceptor);
 }
+
+/// The offline fallback of [CacheInterceptor.fallback].
+class _CacheFallback extends Interceptor {
+  new(this._cache);
+
+  final CacheInterceptor _cache;
+
+  @override
+  Future<void> onError(
+    DioException err,
+    ErrorInterceptorHandler handler,
+  ) async {
+    // A retry attempt's error passes here inside the retry loop; only the
+    // error the loop passes on after its last attempt may fall back.
+    if (isOpenRetryAttempt(err.requestOptions)) return handler.next(err);
+    final response = await _cache._fallbackFor(err);
+    if (response == null) return handler.next(err);
+    handler.resolve(response);
+  }
+}
```

- [ ] **Step 6: Generate code, then run the tests and the analyzer**

Run: `cd dart_falconnect && dart run build_runner build && dart format lib test && dart test test/engine/https/interceptors/cache_fallback_test.dart test/engine/https/interceptors/retry_interceptor_test.dart && dart analyze --fatal-infos && dart test`
Expected: the fallback file passes 9 tests and the retry file stays green; `No issues found!`; the whole suite passes (297 with 1 existing skip).

- [ ] **Step 7: Commit**

```bash
git add dart_falconnect/lib/src/engine/https/interceptors/retry_attempts.dart dart_falconnect/test/engine/https/interceptors/cache_fallback_test.dart
git commit -m "feat(dart_falconnect): answer failed requests from the cache after the last retry" -- dart_falconnect/lib/engine/https/config dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart dart_falconnect/lib/src/engine/https/interceptors/retry_attempts.dart dart_falconnect/test/engine/https dart_falconnect/test/web
```

---

### Task 3: `BaseHttpClient` places the fallback and keeps the store

**Files:**
- Modify: `dart_falconnect/lib/engine/https/http_client.dart`
- Test: `dart_falconnect/test/engine/https/base_http_client_configure_test.dart`

**Interfaces:**
- Consumes: `CacheInterceptor.store`, `CacheInterceptor.fallback`, `CacheInterceptor.config`, and the `CacheConfig` fields of Tasks 1 and 2.
- Produces: the chain `interceptors → log → CacheInterceptor → concurrency limit → rate limit → retry → cache.fallback (only when hitCacheOnNetworkFailure or hitCacheOnErrorCodes is set) → exception handler`; a rebuilt `CacheInterceptor` gets the old `store` when the new and old boxes both have no `store` and the same `maxSize`.

- [ ] **Step 1: Write the failing tests**

Apply this diff to `dart_falconnect/test/engine/https/base_http_client_configure_test.dart`:

```diff
--- a/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
+++ b/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
@@ -93,6 +93,99 @@ void main() {
       ]);
     });
 
+    test('places the cache fallback after RetryInterceptor when the box '
+        'enables it', () {
+      final client = _Client(ScriptedAdapter([reply(200)]))
+        ..configure(
+          const HttpClientConfig(
+            cache: CacheConfig(hitCacheOnNetworkFailure: true),
+            retry: RetryConfig(),
+          ),
+        );
+      addTearDown(client.dispose);
+      final cache = client.interceptors.whereType<CacheInterceptor>().single;
+
+      expect(client.interceptors.map((i) => '${i.runtimeType}'), [
+        'ImplyContentTypeInterceptor',
+        'CacheInterceptor',
+        'RetryInterceptor',
+        '_CacheFallback',
+        'DefaultNetworkExceptionHandlerInterceptor',
+      ]);
+      expect(client.interceptors.elementAt(3), same(cache.fallback));
+
+      client.configure(
+        client.currentConfig.copyWith(
+          cache: const CacheConfig(hitCacheOnErrorCodes: {503}),
+        ),
+      );
+
+      expect(
+        client.interceptors.map((i) => '${i.runtimeType}'),
+        contains('_CacheFallback'),
+      );
+    });
+
+    test('a changed cache setting keeps the stored entries', () async {
+      final adapter = ScriptedAdapter([
+        reply(200, headers: {'cache-control': 'max-age=60'}),
+      ]);
+      final client = _Client(adapter)
+        ..configure(
+          const HttpClientConfig(
+            baseUrl: 'https://a.test',
+            cache: CacheConfig(),
+          ),
+        );
+      addTearDown(client.dispose);
+      await client.dio.get<dynamic>('/x');
+      final before = client.interceptors.whereType<CacheInterceptor>().single;
+
+      client.configure(
+        client.currentConfig.copyWith(
+          cache: const CacheConfig(maxStale: Duration(hours: 1)),
+        ),
+      );
+      final after = client.interceptors.whereType<CacheInterceptor>().single;
+      final hit = await client.dio.get<dynamic>('/x');
+
+      expect(after, isNot(same(before)));
+      expect(after.store, same(before.store));
+      expect(hit.isCacheHit, isTrue);
+      expect(adapter.requests, hasLength(1));
+    });
+
+    test('a changed maxSize or store starts an empty cache', () async {
+      final adapter = ScriptedAdapter([
+        reply(200, headers: {'cache-control': 'max-age=60'}),
+      ]);
+      final client = _Client(adapter)
+        ..configure(
+          const HttpClientConfig(
+            baseUrl: 'https://a.test',
+            cache: CacheConfig(),
+          ),
+        );
+      addTearDown(client.dispose);
+      await client.dio.get<dynamic>('/x');
+
+      client.configure(
+        client.currentConfig.copyWith(cache: const CacheConfig(maxSize: 1024)),
+      );
+      await client.dio.get<dynamic>('/x');
+      final store = MemCacheStore();
+      client.configure(
+        client.currentConfig.copyWith(cache: CacheConfig(store: store)),
+      );
+      await client.dio.get<dynamic>('/x');
+
+      expect(adapter.requests, hasLength(3));
+      expect(
+        client.interceptors.whereType<CacheInterceptor>().single.store,
+        same(store),
+      );
+    });
+
     test('keeps an unchanged box and rebuilds a changed one', () {
       final client = _Client(ScriptedAdapter([reply(200)]))
         ..configure(
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_falconnect && dart test test/engine/https/base_http_client_configure_test.dart`
Expected: FAIL: `places the cache fallback after RetryInterceptor when the box enables it` with `Which: at location [3] is 'DefaultNetworkExceptionHandlerInterceptor' instead of '_CacheFallback'`, and `a changed cache setting keeps the stored entries` with `Expected: same instance as <Instance of 'MemCacheStore'>`.

- [ ] **Step 3: Wire the fallback and the store into `configure`**

Apply this diff to `dart_falconnect/lib/engine/https/http_client.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/http_client.dart
+++ b/dart_falconnect/lib/engine/https/http_client.dart
@@ -5,7 +5,8 @@ import 'package:dart_falconnect/lib.dart';
 ///
 /// The client orders the interceptor chain itself: the config's own
 /// `interceptors`, then log, cache, concurrency limit, rate limit, retry,
-/// and the exception handler last. [configure] applies a new
+/// the cache's offline fallback when its box enables it, and the exception
+/// handler last. [configure] applies a new
 /// configuration to requests that start after it returns; requests already
 /// running finish on the configuration they started with. Interceptors
 /// whose box is unchanged are kept, with their state.
@@ -67,8 +68,14 @@ abstract class BaseHttpClient implements RequestApiService {
       previous?.cache,
       config.cache,
       _cache,
-      (box) => CacheInterceptor(config: box, logPrint: _diagnostic),
+      (box) => CacheInterceptor(
+        config: _keepStore(box, previous?.cache),
+        logPrint: _diagnostic,
+      ),
     );
+    final cacheFallback = cache != null && _hasFallback(cache.config)
+        ? cache.fallback
+        : null;
     final concurrency = _keepOrBuild(
       previous?.concurrency,
       config.concurrency,
@@ -96,6 +103,7 @@ abstract class BaseHttpClient implements RequestApiService {
         ?concurrency,
         ?rateLimit,
         ?retry,
+        ?cacheFallback,
         config.exceptionHandler ?? _defaultExceptionHandler,
       ]);
     _config = config;
@@ -341,6 +349,23 @@ abstract class BaseHttpClient implements RequestApiService {
         .catchWhenError(catchError);
   }
 
+  /// [box], carrying the current cache's memory store when only settings
+  /// that leave the stored entries valid changed since [before].
+  CacheConfig _keepStore(CacheConfig box, CacheConfig? before) {
+    final current = _cache;
+    if (current == null ||
+        before == null ||
+        box.store != null ||
+        before.store != null ||
+        box.maxSize != before.maxSize) {
+      return box;
+    }
+    return box.copyWith(store: current.store);
+  }
+
+  static bool _hasFallback(CacheConfig box) =>
+      box.hitCacheOnNetworkFailure || box.hitCacheOnErrorCodes.isNotEmpty;
+
   /// Keeps [current] when its box did not change, else builds a new one.
   static I? _keepOrBuild<B extends Object, I extends Object>(
     B? before,
```

- [ ] **Step 4: Run the tests and the analyzer**

Run: `cd dart_falconnect && dart format lib test && dart test test/engine/https/base_http_client_configure_test.dart && dart analyze --fatal-infos && dart test`
Expected: the configure file passes; `No issues found!`; the whole suite passes (300 with 1 existing skip).

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(dart_falconnect): place the cache fallback after retry and keep the cache store across configure" -- dart_falconnect/lib/engine/https/http_client.dart dart_falconnect/test/engine/https/base_http_client_configure_test.dart
```

---

### Task 4: Documentation

**Files:**
- Modify: `skills/dart-falconx-package/references/http.md`, `skills/dart-falconx-package/SKILL.md`, `dart_falconnect/CLAUDE.md`
- No change: `CLAUDE.md` (root) names no interceptor.

**Interfaces:**
- Consumes: the public API of Tasks 1 to 3.
- Produces: docs that match the source (the skill maintenance rule in the root `CLAUDE.md`). The skill describes the current surface only: no migration or changelog section.

Edit the files as they stand on the branch. After editing a padded markdown table, re-pad every row so the columns line up.

- [ ] **Step 1: Update the box table, the chain bullet, and the model paragraph in `http.md`**

In `## Configure a client`, replace the `CacheConfig` row of the box table with:

```markdown
| `CacheConfig` | `CacheInterceptor`, plus `cache.fallback` after `RetryInterceptor` when the offline fallback is on | follows the server's cache headers (`CachePolicy.request`); 50 MB memory store; entries keyed by the URL plus `authorization`, `accept`, and `accept-language`; offline fallback off |
```

In the bullet that starts ``- The client orders the chain:``, replace ``retry, then `exceptionHandler` `` with ``retry, the cache's offline fallback when its box enables it, then `exceptionHandler` ``.

In the paragraph that starts ``The public model classes behind the interceptors``, drop `` `CacheEntry`, `` from the list.

- [ ] **Step 2: Update the interceptor catalog and the interceptor order in `http.md`**

Replace the `CacheInterceptor` catalog row with:

```markdown
| `CacheInterceptor` | `(config: CacheConfig(policy: CachePolicy.request, maxStale:, maxSize: 50 MB, store:, keyHeaders: {authorization, accept, accept-language}, hitCacheOnNetworkFailure: false, hitCacheOnErrorCodes: {}), logPrint:)` | `dio_cache_interceptor` underneath; follows `Cache-Control`, `Expires`, `ETag`, and `Last-Modified`; a hit is decoded fresh from stored bytes, bound to the current request, passes every response interceptor, and reads `response.isCacheHit`; `store`, `clearCache()`, `fallback` (see "Caching") |
```

In `## Interceptor order`, change the hand-built chain to:

```dart
final cache = CacheInterceptor();
dio.interceptors.addAll([
  cache,
  ConcurrencyLimitInterceptor(
    config: const ConcurrencyConfig(global: 16, perHost: 4),
  ),
  TokenBucketRateLimitInterceptor(), // or RetryAfterPauseInterceptor, never both
  RetryInterceptor(dio: dio),
  cache.fallback, // answers only when the box enables the offline fallback
  DefaultNetworkExceptionHandlerInterceptor(),
]);
```

At the end of the bullet that starts ``- `CacheInterceptor` comes first:``, append: ``The cache's `fallback` goes after `RetryInterceptor`: it answers a failed request from the cache only after the last retry, and after `ConcurrencyLimitInterceptor.onError` has returned the slot.``

- [ ] **Step 3: Add the caching section to `http.md`**

Insert this section immediately before `## Rate limiting`:

````markdown
## Caching

`CacheConfig()` follows the server: a `GET` response is stored only when its headers allow it (`Cache-Control: max-age`, `Expires`, `ETag`, or `Last-Modified`), a fresh entry answers without the network, and a stale one is revalidated with `If-None-Match` or `If-Modified-Since`. A `304` answers with the stored body. A response without cache headers is never stored.

```dart
// Cache this endpoint for 5 minutes, whatever the server's headers say.
dio.get('/config', options: Options()..cacheFor = const Duration(minutes: 5));

// Skip the cached answer and store the fresh one (pull to refresh).
dio.get('/feed', options: Options()..cachePolicy = CachePolicy.refresh);

// Never read or write the cache for this request.
dio.get('/balance', options: Options()..cachePolicy = CachePolicy.noCache);
```

- `cacheFor` must be positive. It forces the cache for that request, `no-store` included, and the entry expires that long after it was stored however often it is read. `CacheConfig(policy: CachePolicy.forceCache, maxStale: ...)` does the same for every request.
- `keyHeaders` (default `authorization`, `accept`, `accept-language`) split one URL into separate entries, compared ignoring case. On a server that serves many users through one client, keep `authorization` in the set, or one user reads another's cached responses.
- A hit is decoded again from stored bytes, so editing `response.data` never changes the cache. A response over 512,000 bytes, or over a fifth of `maxSize`, is not stored in the default memory store.
- Diagnostics print the method, host, and path of a hit, never the query.

| Where | Store | Note |
|---|---|---|
| Flutter mobile and desktop | the default memory store, or `FileCacheStore`, `HiveCacheStore`, `IsarCacheStore`, `DriftCacheStore` from their own packages through `CacheConfig(store: ...)` | a persistent store keeps entries across launches |
| Flutter web | memory, Hive, Isar | `FileCacheStore` does nothing on web; the browser keeps its own HTTP cache underneath |
| Server (dart_frog, CLI) | memory | one cache per process; `maxSize` bounds memory |

The client never closes a store passed in. Changing `policy`, `maxStale`, `keyHeaders`, or the offline settings through `configure` keeps the entries; changing `store` or `maxSize` starts an empty cache.

**Offline fallback.** `CacheConfig(hitCacheOnNetworkFailure: true)` answers a `GET` that failed without a response from the stored entry, and `hitCacheOnErrorCodes: 503` does the same for the listed statuses. Both are off by default. The answer comes only after the last retry, reads `response.isCacheFallback` and `response.isCacheHit`, skips an entry past its `maxStale`, and never answers a cancel. The log shows the last attempt's error; the fallback prints a diagnostic. For offline-first screens, prefer `DatasourceBoundState`, which keeps models in the app's own store.
````

- [ ] **Step 4: Update the helpers in `http.md`**

Replace the bullet that starts ``- `response.isCacheHit` marks`` with:

```markdown
- `response.isCacheHit` marks a response answered from the cache without a network round trip, and `response.isCacheFallback` one answered by the offline fallback; a response interceptor that counts responses sees hits too, so check it there. A `304` revalidation reads `isCacheHit` false.
```

- [ ] **Step 5: Update `SKILL.md`**

In the interceptor order line, replace ``, `RetryInterceptor`, then the exception handler`` with ``, `RetryInterceptor`, the cache's offline fallback when enabled, then the exception handler``.

- [ ] **Step 6: Update `dart_falconnect/CLAUDE.md`**

- In `## Interceptor chain`, in the order sentence, replace `` `RetryInterceptor` → exception handler`` with `` `RetryInterceptor` → the cache fallback, when its box enables it → exception handler``.
- In the interceptor table, set the `CacheInterceptor` role to ``wraps `dio_cache_interceptor`: HTTP caching by server headers, keyed by URL and `keyHeaders`; `fallback` answers failures after retries``. Re-pad the table.
- In the "Unexported helpers" bullet, add ``the retry loop's final-error marker in `lib/src/engine/https/interceptors/retry_attempts.dart` ``.
- In `## Gotchas`, add: ``- `dio_cache_interceptor` reads `DateTime.now()`, not `clock`: test cache expiry with short real waits, outside `fakeAsync`.``

- [ ] **Step 7: Check the docs against the source**

Run: `grep -n "cacheFor\|isCacheFallback\|keyHeaders\|fallback" skills/dart-falconx-package/references/http.md skills/dart-falconx-package/SKILL.md dart_falconnect/CLAUDE.md`
Expected: matches in all three files.
Run: `grep -rn "CacheEntry\|evictExpired\|duration: 15 min" skills dart_falconnect/CLAUDE.md`
Expected: no output.

- [ ] **Step 8: Commit**

```bash
git commit -m "docs: document the dio_cache_interceptor cache, cacheFor, keyHeaders, and the offline fallback" -- skills/dart-falconx-package dart_falconnect/CLAUDE.md
```

---

### Task 5: Final gates (controller)

- [ ] **Step 1: Run every gate from the worktree root**

```bash
melos run analyze
melos run format
melos run build_runner:check
melos run test
melos run test:platforms
```

Expected: every command exits 0; tests dart_falconnect 300 (1 existing skip), dart_faltool 771, dart_falmodel 71, dart_falconx 1; `test:platforms` compiles to js, wasm, and exe and passes every package in Chrome under dart2js and dart2wasm, dart_falconnect with 304.

- [ ] **Step 2: Check the spec's success criteria**

Walk spec section 15 line by line and point each at a passing test or a command above. Walk spec section 11 and confirm each file changed.

- [ ] **Step 3: Request the whole-branch review**

Use superpowers:requesting-code-review on `feature/cache` against `feature/json-log`, on the most capable model. Give the reviewer this plan's Review Focus and Prototype rulings. Fix Critical and Important findings through a new commit per fix, each with a test that failed first.

- [ ] **Step 4: Hand over**

Report the branch, the commit list, the gate results, the review findings and their fixes, and the rulings. The owner merges `feature/json-log` into `develop`, then `feature/cache`, bumps the version to 2.1.0 on `release/2.1.0`, and tags 2.1.0.
