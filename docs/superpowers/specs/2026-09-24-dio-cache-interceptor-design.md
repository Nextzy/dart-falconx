# HTTP cache on dio_cache_interceptor

**Date:** 2026-09-24
**Packages:** `dart_falconnect`
**Version:** 2.1.0, released together with the server-mode JSON log (`2026-09-24-http-json-log-design.md`). dart_falconx has no consumers yet, so the owner accepts the source breaks of section 12.
**Branch:** `feature/cache`, cut from `feature/json-log` at `d42c893`; merged after `feature/json-log`.

## 1. Context

`CacheInterceptor` is a homegrown in-memory cache. The JSON log review found that a hit hands the app the same `data` and `headers` objects the cache stores, so an app that edits `response.data` edits the cache for every later reader. Checking it further found two more defects:

1. `_getCacheDuration` reads `Expires` with `DateTime.parse`, which cannot parse an HTTP-date such as `Wed, 21 Oct 2026 07:28:00 GMT`. Every real `Expires` header falls back to `CacheConfig.duration`, so a response the server marks as expiring in 10 seconds stays cached for 15 minutes. The existing test sends an ISO date and misses it.
2. `_generateCacheKey` returns `input.hashCode.toString()`. Two different URLs whose strings share a hash code share one entry, and the cache answers one with the other's response.

`dio_cache_interceptor` 4.0.7 is already a dependency of `dart_falconnect` and is re-exported by `dart_falconnect.dart` (`hide BaseRequest, BaseResponse, HttpDate`). It stores each body as bytes and decodes it again on every hit, parses HTTP-dates, keys entries by a UUID v5, revalidates with `ETag` and `Last-Modified`, and offers memory, file, Hive, Isar, Drift, Sembast, and ObjectBox stores. It is pure Dart with no `dart:io`, published by a verified publisher, with 442 likes and 160 pub points, and its last release was two months before this spec.

Reading its source (4.0.7, `http_cache_core` 1.1.4) found five behaviours that do not fit this package as is; the fifth and two store limits surfaced in the prototype behind the plan:

1. `CacheOptions.defaultCacheKeyBuilder` keys by URL alone. On a server where one client serves many users, user B would get user A's cached response.
2. The offline fallback in `onError` calls `handler.resolve(cacheResponse)`. dio's `ErrorInterceptorHandler.resolve` has no call-following flag, so every error interceptor after the cache is skipped, `ConcurrencyLimitInterceptor.onError` among them, and the request's slot is never returned. The fallback also runs before `RetryInterceptor`, so it answers on the first failure and skips every retry.
3. A stale entry with an `ETag`, a `Last-Modified`, or a `Date` makes the next request conditional. The server's `304` fails dio's default `validateStatus`, reaches `onError`, and the library resolves there too, so every successful revalidation leaks a slot, even with the offline fallback off.
4. Freshness reads `DateTime.now()`, not `clock.now()`, so `fakeAsync` cannot move a cache entry through time.
5. A hit whose request options carry `maxStale` pushes the entry's `maxStale` back (`_updateCacheResponse`), so an entry read often would never expire.

`MemCacheStore` also asserts `maxEntrySize < maxSize` and `maxEntrySize * 5 <= maxSize`.

## 2. Goals and non-goals

**Goals**

- Replace the homegrown cache with `dio_cache_interceptor` behind the existing `CacheConfig` box and `CacheInterceptor` name.
- Follow HTTP caching rules by default; let a request force caching for a set time.
- Keep one user's responses away from another's on a shared server client by default.
- Offer an offline fallback, off by default, that answers only after retries and never leaks a concurrency slot.
- Let an app swap the memory store for a persistent one.
- Work on Flutter apps, Flutter web, and pure-Dart servers.

**Non-goals**

- A shared cache across server instances. An app can write its own `CacheStore`, for example on Redis, and pass it in.
- Caching `POST`. `allowPostMethod` stays false.
- Encrypting stored entries (`CacheCipher`) and cache priorities (`CachePriority`). Both stay reachable through the library later; neither is in the box now.
- Caching requests at a CDN or gateway. Those cache inbound requests to the app's own server; this cache covers outbound calls the app makes.

## 3. Owner decisions (2026-09-24)

| # | Question | Decision |
|---|---|---|
| 1 | Where the cache runs | Apps and multi-user servers: the key includes `authorization` by default |
| 2 | A response without cache headers | Not cached by default (`CachePolicy.request`); a request can force caching |
| 3 | Offline fallback | Offered, off by default |
| 4 | Store | Memory by default; `CacheConfig.store` swaps it |
| 5 | Branch and release | `feature/cache` on top of `feature/json-log`; both ship as 2.1.0 |
| 6 | Approach | Wrap the library under our box (section 4 onward), not pass its `CacheOptions` through |

## 4. `CacheConfig`

```dart
@freezed
abstract class CacheConfig with _$CacheConfig {
  const factory({
    /// Default policy; `request` follows the server's cache headers.
    @Default(CachePolicy.request) CachePolicy policy,

    /// Drops an entry this long after it was stored, whatever its headers say.
    Duration? maxStale,

    /// Byte budget of the default memory store, evicted least recently used.
    @Default(50 * 1024 * 1024) int maxSize,

    /// Where entries live; null builds a `MemCacheStore` from [maxSize].
    CacheStore? store,

    /// Request headers that split one URL into separate entries, compared
    /// ignoring case. Removing `authorization` on a server that serves many
    /// users lets one user read another's cached responses.
    @Default({'authorization', 'accept', 'accept-language'}) Set<String> keyHeaders,

    /// Answers from the cache when a request fails without a response,
    /// after every retry.
    @Default(false) bool hitCacheOnNetworkFailure,

    /// Answers from the cache when a request fails with one of these
    /// statuses, after every retry.
    @Default(<int>{}) Set<int> hitCacheOnErrorCodes,
  }) = _CacheConfig;
}
```

- `duration` is removed. Its role splits between `policy`, `maxStale`, and the per-request `cacheFor` of section 5.
- The default store is `MemCacheStore(maxSize: maxSize, maxEntrySize: min(512000, maxSize ~/ 5))`: a response over 512,000 bytes, or over a fifth of `maxSize`, is not cached, and the docs say so. A `maxSize` that is not positive throws `ArgumentError`.
- A `store` passed in belongs to the app: the client never closes it.

## 5. Per-request settings

Extensions on `Options` and `RequestOptions`, following `disableRetry` and `retryNonIdempotent` in `retry_interceptor.dart`, with keys under `dart_falconnect.cache.`:

```dart
// Cache this endpoint for 5 minutes, whatever the server's headers say.
dio.get('/config', options: Options()..cacheFor = const Duration(minutes: 5));

// Skip the cached answer and store the fresh one (pull to refresh).
dio.get('/feed', options: Options()..cachePolicy = CachePolicy.refresh);

// Never read or write the cache for this request.
dio.get('/balance', options: Options()..cachePolicy = CachePolicy.noCache);
```

- `cacheFor: d` means `CachePolicy.forceCache` with `maxStale: d`. `forceCache` returns a stored entry whatever its freshness and stores a response whatever its headers, `no-store` included, so it always comes with a lifetime.
- An explicit `cachePolicy` wins over the policy `cacheFor` implies; `cacheFor` still sets `maxStale`.
- A negative or zero `cacheFor` throws `ArgumentError`.
- Both hooks of `CacheInterceptor` write the request's library `CacheOptions` into `extra[extraKey]`. The lookup in `onRequest` carries no `maxStale`, so a hit never pushes an entry's expiry back (section 1, item 5); the save in `onResponse` carries `cacheFor ?? config.maxStale`, which the library stamps on the stored entry.

## 6. `CacheInterceptor`

```dart
class CacheInterceptor extends Interceptor {
  new({this.config = const CacheConfig(), this.logPrint});

  final CacheConfig config;
  final void Function(String message)? logPrint;

  /// The store entries live in: `config.store`, or the memory store built from `config.maxSize`.
  CacheStore get store;

  /// Answers failed requests from the cache after retries; place it after
  /// `RetryInterceptor`. It passes every error on when the offline fallback is off.
  Interceptor get fallback;

  /// Deletes every entry.
  Future<void> clearCache();
}
```

- It holds one private `DioCacheInterceptor` built from `CacheOptions(store: store, policy: config.policy, keyBuilder: _key)`. The library never sees the offline settings, and per-request options follow section 5.
- `onRequest` copies `options.extra` into a new map, because the library writes into it and `extra` may be unmodifiable. It applies section 5, then delegates. It wraps the handler so that, when the library forwards the request with `If-None-Match` or `If-Modified-Since`, that request also accepts `304` in its `validateStatus`. The `304` then reaches the library's `onResponse`, which answers with the stored body, and every response interceptor, `ConcurrencyLimitInterceptor` included, sees a response.
- `onResponse` delegates.
- `onError` does not delegate; it passes the error on. The library's `onError` only serves the offline fallback and the `304` path, and both now live elsewhere.
- The key is `sha256` (hashlib, re-exported by `dart_faltool`) over the URL and, for each name of `keyHeaders` in sorted lower-case order that the request carries, a `name: value` line. The digest keeps header values, such as a bearer token, out of the store's keys.
- Diagnostics through `logPrint`: a hit and an offline answer print the method, host, and path, never the query, which may hold a listed secret.
- A hit is a new `Response` built from stored bytes, bound to the current request's options, and resolved with `callFollowingResponseInterceptor: true`. After a `304` revalidation the response reads `isCacheHit` false, as the library marks a validated response as from the network.
- `response.isCacheHit` stays on `FalconCacheHitResponseExtensions` and reads the library's marker, `extra[extraFromNetworkKey] == false`.
- `clearCache()` calls `store.clean()`. `evictExpired()` is removed: the memory store evicts by size, and `maxStale` drops old entries.
- The `CacheEntry` model is removed.

### 6.1 The offline fallback

`fallback` returns an internal interceptor bound to the same store and key builder.

- It acts only when `hitCacheOnNetworkFailure` or `hitCacheOnErrorCodes` is set, only on a `GET`, and never on a cancel. Its predicate is its own: an error without a status needs `hitCacheOnNetworkFailure`, and one with a status needs that status in `hitCacheOnErrorCodes`. The library's `isCacheCheckAllowed` also accepts `304`, which belongs to section 6. A store that throws leaves the original error.
- It loads the entry with the request's key, skips an entry past its `maxStale`, and resolves with `toResponse(err.requestOptions)`, marked `extra['dart_falconnect.cache.fallback'] = true`.
- `response.isCacheFallback` reads that marker; `isCacheHit` is also true for such a response.
- Placed after `RetryInterceptor`, it runs after `ConcurrencyLimitInterceptor.onError` has returned the slot. A retry attempt is a nested `dio.fetch` whose error runs the rest of the chain, the fallback included, before the retry loop decides. So `RetryInterceptor` marks the error it passes on after its last attempt (`extra['dart_falconnect.retry.final']`, through `lib/src/engine/https/interceptors/retry_attempts.dart`), and the fallback passes on the error of an attempt whose loop may still retry.
- The log saw the last attempt's error before the fallback answered; the fallback prints a diagnostic, which is a `DEBUG` JSON line in JSON mode.

## 7. `BaseHttpClient`

Chain, with ② only when the box enables the offline fallback:

```
interceptors → log → CacheInterceptor ① → concurrency limit → rate limit → retry → cache.fallback ② → exception handler
```

- ① keeps position 3, before the limiters, so a hit takes no slot and spends no token.
- A changed box rebuilds `CacheInterceptor`. When the new box has no `store` and the same `maxSize` as the old one, the client passes the old interceptor's `store` into the new one (`box.copyWith(store: old.store)` for construction only), so changing `policy`, `maxStale`, `keyHeaders`, or the offline settings keeps the entries.
- `dispose()` does not close the store.

## 8. Interceptors that see the new cache

| Interceptor | Effect |
|---|---|
| `HttpLogInterceptor`, `HttpJsonLogInterceptor` | A hit still passes their `onResponse` with `isCacheHit`, so `falconx.cache.hit` is unchanged. A revalidation logs the `304` the server sent. An offline answer logs the last error only |
| `ConcurrencyLimitInterceptor` | A hit takes no slot. A revalidated `304` returns its slot in `onResponse`. An offline answer comes after its `onError` |
| `TokenBucketRateLimitInterceptor`, `RetryAfterPauseInterceptor` | A hit spends no token; a revalidation is a network request and spends one |
| `RetryInterceptor` | A `304` is a response, not an error, so it is never retried |

## 9. Platforms

| Where | Stores | Note |
|---|---|---|
| Flutter mobile and desktop | memory; `FileCacheStore`, `HiveCacheStore`, `IsarCacheStore`, `DriftCacheStore`, and others through their own packages | The app adds a store package itself |
| Flutter web | memory, Hive, Isar | `FileCacheStore` does nothing on web; the browser keeps its own HTTP cache underneath |
| Server (dart_frog, CLI) | memory | One cache per process; `keyHeaders` keeps users apart; `maxSize` bounds memory |

## 10. Testing plan

TDD with a real `Dio`, the scripted adapter, and `FoldingTransformer`. Freshness reads the wall clock (section 1, item 4), so an expiry test uses a real wait of a few hundred milliseconds instead of `fakeAsync`.

**`test/engine/https/interceptors/cache_interceptor_test.dart` (rewritten)**

- A hit makes no network call, carries the current request's options, reaches response interceptors before and after the cache, and reads `isCacheHit`; a network response reads false.
- An app that edits a hit's `data` does not change the next hit.
- `policy: request`: no cache headers means no entry; `max-age` means an entry; `no-store` means none.
- `Expires` as an HTTP-date is honoured.
- `cacheFor` stores a response without headers and drops it after the duration; `cachePolicy: noCache` skips the cache; `refresh` fetches and stores.
- Two requests to one URL with different `Authorization` values make two network calls; the same value makes one.
- A `store` passed in receives the entries; `clearCache()` empties it.
- A stale entry with an `ETag` sends `If-None-Match`, and the server's `304` answers with the stored body.

**`test/engine/https/interceptors/cache_fallback_test.dart` (new)**

- With `hitCacheOnNetworkFailure`, a connection error after retries answers from the cache with `isCacheFallback`, and the adapter saw the first request plus every retry.
- With `hitCacheOnErrorCodes: {503}`, a 503 falls back and a 500 fails.
- With both off, errors pass through.
- Slot safety: under `ConcurrencyLimitConfig(perHost: 1)`, a request answered by the fallback, and a request revalidated by a `304`, each leave the slot free for the next request.

**Existing tests**

- `reply(200)` without headers no longer caches under the default policy. The JSON log's `a cache hit is flagged`, the concurrency and token bucket cache-hit cases, and every configure test that relies on a hit add `cache-control: max-age=60` to the reply.
- `base_http_client_configure_test.dart`: the fallback appears after `RetryInterceptor` only when enabled; a changed `policy` keeps the stored entries; a changed `store` starts empty.
- `test/web/compile_smoke.dart` and `test/web/engine_web_test.dart` build `CacheInterceptor` with its memory store; the Chrome gates run under dart2js and dart2wasm.

## 11. Documentation

The skill describes the current surface only, with no migration section.

| File | Change |
|---|---|
| `skills/dart-falconx-package/references/http.md` | The `CacheConfig` box row and the `CacheInterceptor` catalog row; a "Caching" section: the default policy, `cacheFor` and `cachePolicy`, the `keyHeaders` warning, stores by platform, the offline fallback and where `fallback` goes in a hand-built chain; the chain order line |
| `skills/dart-falconx-package/SKILL.md` | The chain order line |
| `dart_falconnect/CLAUDE.md` | The chain order and the `CacheInterceptor` role; the models bullet drops `CacheEntry` |

## 12. Source breaks in 2.1.0 (for the release notes)

| # | Change | Action |
|---|---|---|
| 1 | `CacheConfig.duration` is removed; `policy`, `maxStale`, `store`, `keyHeaders`, `hitCacheOnNetworkFailure`, and `hitCacheOnErrorCodes` are added | Use `cacheFor` on the requests that must cache, or `policy: CachePolicy.forceCache` with `maxStale` for every request |
| 2 | A response without cache headers is no longer cached by default | Same as row 1 |
| 3 | `CacheInterceptor.clearCache()` returns `Future<void>`; `evictExpired()` is removed | Await `clearCache()`; drop `evictExpired()` |
| 4 | The `CacheEntry` model is removed | Read `CacheResponse` from `store` if needed |
| 5 | A request with a stale entry may carry `If-None-Match` or `If-Modified-Since` | Nothing; a `304` answers with the stored body |
| 6 | Cache diagnostics print the method, host, and path only | Nothing |

## 13. Implementation logistics

- Work in worktree `.claude/worktrees/cache` on `feature/cache`.
- No new dependency: `dio_cache_interceptor` and `hashlib` (through `dart_faltool`) are already in place.
- Run `dart run build_runner build` in `dart_falconnect` after changing `CacheConfig`, and `melos run build_runner:check` before committing.
- Commit with `git commit -- <paths>`, no `Co-Authored-By`, no AI attribution, and no `!`.
- Do not push, tag, or bump versions.

## 14. Risks

| Risk | Mitigation |
|---|---|
| A later library release changes the `304` or fallback behaviour this wrapper works around | The slot-safety tests of section 10 fail first; the dependency stays on `^4.0.7` |
| An app edits `keyHeaders` and leaks responses between users | The field's doc and the "Caching" section warn; the default is safe |
| `cacheFor` stores a `no-store` response | It is an explicit per-request choice, and `maxStale` bounds it |
| A response over 512,000 bytes is silently not cached | Documented; a persistent store without that limit can be passed in |
| Expiry tests take real time | A few hundred milliseconds per test, in one file |

## 15. Success criteria

- An app that edits a hit's `data` never changes a later hit.
- An `Expires` HTTP-date and an `ETag` revalidation work.
- Two users with different `Authorization` values never share an entry by default.
- The offline fallback answers only after retries, and neither the fallback nor a `304` revalidation leaks a concurrency slot.
- The JSON log still flags hits with `falconx.cache.hit`.
- `melos run analyze`, `melos run test`, `melos run build_runner:check`, and `melos run test:platforms` pass.
- Every file of section 11 matches the code.

## 16. Details decided in this spec, for owner review

1. The key is a `sha256` digest of the URL plus the listed headers present, so tokens never sit in store keys.
2. `keyHeaders` defaults to `authorization`, `accept`, and `accept-language`, the set the homegrown cache used.
3. A request forwarded with conditional headers accepts `304` through its own `validateStatus`, so revalidation stays on the response path.
4. `CacheInterceptor.onError` never delegates to the library.
5. The offline fallback skips an entry past its `maxStale`.
6. `cacheFor` must be positive; an explicit `cachePolicy` beats the policy `cacheFor` implies.
7. Changing the box keeps the entries unless `store` or `maxSize` changes.
8. The client never closes a store, since it may be the app's.
9. `store` and `fallback` are public getters, so a hand-built chain can place the fallback and an app can inspect the store.
10. Diagnostics never print a query string.
11. The per-entry limit is `min(512000, maxSize ~/ 5)`, the most the memory store accepts.
12. A lookup carries no `maxStale`; only a save stamps it.
13. `RetryInterceptor` marks its final error so the fallback answers only after the last retry.
14. The fallback's predicate is its own, not the library's `isCacheCheckAllowed`.
