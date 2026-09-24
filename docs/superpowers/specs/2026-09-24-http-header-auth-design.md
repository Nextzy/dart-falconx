# HTTP header provider, request ID, and token auth

**Date:** 2026-09-24
**Packages:** `dart_falconnect`
**Version:** 2.2.0. Every change adds API; nothing breaks.
**Builds on:** the client-config core (`2026-09-24-default-http-client-config-design.md`), which defines `HttpClientConfig`, the chain order, and `useToken`; and the JSON log (`2026-09-24-http-json-log-design.md`), which defines the `falconx.*` log fields.
**Roadmap:** the first of two specs in the `dart-falconx-client-extensions` phase. The platform adapter spec follows it.

## 1. Context

The config core left three areas of its original brief to this phase: a header provider, a request ID, and auth with a 401 refresh. The owner ruled that the three share one spec, because each stamps a header on the request and all three need the same slot in the chain. The platform adapter gets its own spec, since it changes `dio.httpClientAdapter` and never touches the chain.

Today an app that needs a token writes its own interceptor and places it in the custom slot. Four facts about the current code shape this design:

1. `CacheInterceptor` keys entries by the URL and `CacheConfig.keyHeaders`, whose default holds `authorization`. The token must be on the request before the cache runs.
2. dio 5.11.1 runs `onRequest`, `onResponse`, and `onError` in list order (`dio_mixin.dart`, the loops at lines 534, 564, and 577). An interceptor at the front of the chain therefore sees a 401 before `ConcurrencyLimitInterceptor` gives the request's slot back. If it resolves the error there, dio skips the rest of the error chain: the log never sees the 401, and the slot comes back only through the permit that a re-send shares in `RequestOptions.extra`.
3. `RetryInterceptor` already re-sends from `onError` with `dio.fetch`, after the concurrency limiter and the rate limiter have seen the error. A second re-sender placed beside it follows a pattern the chain already supports.
4. `isUseToken` already reaches `RequestOptions.extra` under `dart_falconnect.auth.useToken`, and `useToken` reads true when the key is absent. The key is a private constant, so a Retrofit endpoint turns the token off only by typing the string, and a typo sends the token without warning.

## 2. Goals and non-goals

**Goals**

- A Flutter app with a user login attaches its access token to every request that wants one. A 401 triggers one refresh, however many requests fail at once, and each failed request is sent again with the new token.
- The app owns token storage and the refresh call. The library knows neither the token format nor where the token lives.
- Headers that change at run time are computed for each request.
- One request ID follows an app request across every retry attempt and the re-send after a refresh, and the JSON log prints it.
- A Retrofit endpoint turns the token off with one annotation.
- An app that sets none of the new fields gets the same chain and sends the same requests as in 2.1.1.

**Non-goals**

- A token model, token storage, or an auth-state stream. The app owns them.
- A refresh before expiry inside the library. An app that wants one does it inside `accessToken()`.
- A refresh on any status other than 401.
- A default that sends no token, and a matching `@useToken` annotation (section 11).
- Request signing. An app signs in its own custom interceptor, which runs after the stamp and sees every stamped header.
- W3C `traceparent` or any other OpenTelemetry context. The owner dropped OpenTelemetry from the JSON log scope.
- The platform adapter, which has its own spec.
- The WebSocket engine.

## 3. Configuration API

`HttpClientConfig` gains three fields. Each defaults to null, which turns its feature off.

```dart
@freezed
abstract class HttpClientConfig with _$HttpClientConfig {
  const factory({
    // ... the fields of 2.1.1, unchanged ...

    /// Headers computed for each request; null turns them off.
    HeaderProvider? headerProvider,

    /// The request ID header; null turns it off.
    RequestIdConfig? requestId,

    /// Access token and 401 refresh; null turns them off.
    AuthConfig? auth,
  }) = _HttpClientConfig;
}
```

Two new freezed boxes:

```dart
/// The request ID header.
@freezed
abstract class RequestIdConfig with _$RequestIdConfig {
  const factory({
    /// Header that carries the ID.
    @Default('X-Request-ID') String headerName,

    /// Makes a new ID; null makes a UUID v7 through hashlib.
    RequestIdGenerator? generate,
  }) = _RequestIdConfig;
}

/// Access token stamping and the 401 refresh.
@freezed
abstract class AuthConfig with _$AuthConfig {
  const factory({
    /// The current access token; null sends the request without one.
    required AccessTokenCallback accessToken,

    /// Refreshes the token and returns true on success; false or a throw
    /// fails the refresh.
    required RefreshCallback refresh,

    /// Called once per failed refresh, and when a re-sent request gets a
    /// 401 again.
    AuthFailedCallback? onAuthFailed,

    /// Header that carries the token.
    @Default('Authorization') String headerName,

    /// Word placed before the token; an empty string sends the bare token.
    @Default('Bearer') String scheme,
  }) = _AuthConfig;
}
```

Typedefs, exported beside the boxes:

```dart
typedef HeaderProvider =
    FutureOr<Map<String, String>> Function(RequestOptions options);
typedef RequestIdGenerator = String Function();
typedef AccessTokenCallback = FutureOr<String?> Function();
typedef RefreshCallback = Future<bool> Function();
typedef AuthFailedCallback = FutureOr<void> Function(DioException error);
```

`use_token_extensions.dart` makes its key public and adds a Retrofit annotation:

```dart
/// Key in `RequestOptions.extra` that turns the auth token off.
const String useTokenExtraKey = 'dart_falconnect.auth.useToken';

/// Retrofit annotation: the endpoint sends no token and never refreshes.
const Extra noToken = Extra({useTokenExtraKey: false});
```

A new extension reads the ID of a request: `FalconRequestIdExtensions on RequestOptions` with `String? get requestId`, null when the request has none.

An app configures all three like this:

```dart
DefaultHttpClient.instance.configure(
  HttpClientConfig(
    baseUrl: 'https://api.example.com',
    headerProvider: (options) => {'Accept-Language': locale.current},
    requestId: const RequestIdConfig(),
    auth: AuthConfig(
      accessToken: () => tokens.access,
      refresh: tokens.refresh,
      onAuthFailed: (error) => router.go('/login'),
    ),
  ),
);
```

Rules:

- `requestId` is off by default. On the web, a custom request header makes the browser send a CORS preflight, and the server must list the header in `Access-Control-Allow-Headers`. A default-on ID would break every web app whose server does not.
- `accessToken` returns `FutureOr`, because most stores read the token from memory, and a forced `Future` would add a microtask to every request.
- `refresh` returns a `bool` instead of a token. After a refresh, the library reads the token through `accessToken()` again, so the app's store stays the only source of the token.
- Freezed compares function fields by identity. `copyWith` keeps the same functions, so an unrelated `configure` keeps the interceptors. A configuration built with new closures rebuilds them (section 8).

## 4. `AuthSession`

`AuthSession` holds the state that both auth interceptors share. The client builds one from each `AuthConfig`; an app that builds its chain by hand passes one session to both interceptors.

```dart
class AuthSession {
  new(this.config, {this.logPrint});

  final AuthConfig config;
  final void Function(String message)? logPrint;
}
```

It keeps three pieces of state:

| State | Purpose |
|---|---|
| The running refresh, a `Future<bool>?` | Joins every 401 to one refresh, and lets the stamp hold new requests until it ends |
| The last failed token, a `String?` | Stops requests stamped with a token whose refresh already failed from refreshing again |
| A zone key | Marks code that runs inside `config.refresh()` (section 5.4) |

Its methods are public and documented as the contract both interceptors use:

- `bool get isInsideRefresh`: true inside the zone of a running `refresh()` call.
- `Future<void> waitForRefresh()`: completes when no refresh is running; completes at once inside the refresh zone.
- `Future<bool> refreshFor(String staleToken, DioException error)`: the single-flight refresh of section 6.2. It returns true when a token newer than `staleToken` is ready to use.

## 5. `RequestStampInterceptor`

`RequestStampInterceptor({RequestIdConfig? requestId, HeaderProvider? headerProvider, AuthSession? auth, required Dio dio})` stamps headers in `onRequest`, in the order of sections 5.1 to 5.3. It reads `dio.options.headers` to tell configured headers from per-request ones. The client builds it when at least one of `requestId`, `headerProvider`, or `auth` is set.

The stamp runs on every attempt. A retry attempt and a re-send pass through it again, so they carry the current token and fresh provider values.

### 5.1 Request ID

1. When `extra` holds an ID under `dart_falconnect.requestId`, use it. Retry attempts and re-sends copy `extra`, so they keep the ID of the first attempt.
2. Otherwise, when the request carries the `headerName` header, adopt that value as the ID.
3. Otherwise, call `generate`, or make a UUID v7 when it is null.
4. Write the ID to `extra` and to the header.

The provider of section 5.2 sees the ID in `options`.

### 5.2 Header provider

1. Call `headerProvider(options)` and await it.
2. For each returned key, write the value, unless the request set its own. A key counts as set by the request when the request's value differs from the value in `dio.options.headers` and the key is not listed under `dart_falconnect.headers.provided` in `extra`. dio compares header names ignoring case.
3. Record the written keys under `dart_falconnect.headers.provided`.

The precedence, from low to high, is the configured `headers`, the provider, and the request's own headers. Step 3 lets a retry attempt call the provider again and overwrite the values the provider wrote on the earlier attempt, such as a timestamp.

### 5.3 Auth header

This step runs only when `auth` is set and `options.useToken` is true.

1. When a refresh is running, wait for it through `waitForRefresh()`. A request that starts during a refresh then carries the new token instead of an old one that is certain to fail.
2. Call `accessToken()`.
3. When it returns null, send the request without the header. Remove the header and `dart_falconnect.auth.token` when present, since a retry attempt copies both from its earlier attempt.
4. Otherwise, write `headerName` as `'$scheme $token'`, or as the bare token when `scheme` is empty. The token overwrites any value set by the configuration, the provider, or the request. A request that sends its own `Authorization` sets `isUseToken: false`.
5. Record the token under `dart_falconnect.auth.token` in `extra`, for the comparison of section 6.2.

### 5.4 Refresh zone guard

`AuthSession` calls `config.refresh()` inside `runZoned` with a zone value under its zone key. Zone values follow the future chain of dio, so every request sent from inside `refresh()` runs in that zone. For such a request, step 1 of section 5.3 does not wait, and section 6.1 never refreshes.

Without the guard, an app whose `refresh()` calls its refresh endpoint through the same client, and forgets `isUseToken: false`, deadlocks: the refresh request waits for the refresh, and the refresh waits for the request. The docs still recommend `isUseToken: false` or a separate `Dio` for the refresh call.

### 5.5 Callback failures

When `generate`, `headerProvider`, or `accessToken` throws, the stamp calls `handler.reject(error, true)` with a `DioException` of type `unknown`. Its `error` is the thrown object, and its `message` names the callback. The flag lets the log and the exception handler see the error. No concurrency slot or rate-limit token is taken yet, and their `onError` does nothing without one.

dio 5.11.1 races every interceptor call against the request's `CancelToken` (`listenCancelForAsyncTask`, `dio_mixin.dart` line 774). A cancel while the stamp waits for a refresh or a callback therefore fails the request at once.

## 6. `TokenRefreshInterceptor`

`TokenRefreshInterceptor({required AuthSession session, required Dio dio})` handles a 401 in `onError`. The client places it after the rate limiter and before `RetryInterceptor` (section 7).

### 6.1 When it refreshes

The interceptor acts on an error only when every condition holds. Otherwise it calls `handler.next(err)`.

1. The response status is 401.
2. `options.useToken` is true.
3. The request carried a token: `dart_falconnect.auth.token` is set. A 401 on a request sent without a token, such as one sent after logout, passes on, so no refresh loop starts.
4. The request was not sent from inside the refresh zone.
5. The request is not a re-send: `dart_falconnect.auth.resent` is not set. A re-send that gets a 401 again records its token as the last failed token, calls `onAuthFailed`, and passes its error on.
6. The token the request carried is not the last failed token. Requests that were waiting with a token whose refresh just failed pass their 401 on, without a second refresh or a second `onAuthFailed`.

### 6.2 Steps

1. Call `accessToken()`. When it returns a token different from the one the request carried, another request has already refreshed; skip to step 3.
2. Call `session.refreshFor(token, err)`. It joins the running refresh, or starts one when none runs. Many 401s at once therefore cause one call to `config.refresh()`.
3. When the refresh succeeded, send the request again with `dio.fetch<dynamic>(original.copyWith(data: ..., extra: {...original.extra, 'dart_falconnect.auth.resent': true}))`. A `FormData` body is cloned, as `RetryInterceptor` clones it. The stamp runs again and writes the new token; the request ID stays, because it lives in `extra`.
4. When the re-send succeeds, call `handler.resolve(response)`. When it fails, call `handler.reject(error)` without the call-following flag.

Step 4 skips `RetryInterceptor`, the cache fallback, and the exception handler of the outer chain, because the re-send already passed through all three in its own chain. Passing the error on with `next` instead would let the outer `RetryInterceptor` retry an error whose attempts the inner one already spent. A re-send's error can carry `retryAttempt` 0, for example when `Retry-After` exceeds `maxDelay`, and the outer interceptor would then start a new loop.

The re-send passes through the whole chain. It takes a new concurrency slot, since the first attempt's slot came back when its error passed `ConcurrencyLimitInterceptor`, and it takes a new rate-limit token, since it is a new request on the wire.

### 6.3 Failure

When `config.refresh()` returns false or throws:

1. The call that started the refresh records the token as the last failed token and calls `onAuthFailed(err)` once. Calls that joined the refresh do not call it.
2. `onAuthFailed` is not awaited. When it throws or its future fails, the error goes to the diagnostic printer and never reaches a request.
3. Every request waiting on the refresh passes its own 401 on with `handler.next(err)`.

A thrown refresh error goes to the diagnostic printer; callers see the 401.

### 6.4 Edge cases

| Case | Behaviour |
|---|---|
| A `Stream` body | The refresh runs, so later requests carry the new token; the 401 passes on, because a stream cannot be read twice |
| A cancel while waiting for the refresh | The request fails at once with a cancel error; the refresh continues for the others |
| A 401 on a `RetryInterceptor` attempt | The attempt runs its own chain, so the `TokenRefreshInterceptor` of that chain handles it |
| A retryable error | Passes on to `RetryInterceptor`; the refresh interceptor acts only on a 401 |

## 7. Chain order

| # | Interceptor | Present when |
|---|---|---|
| 0 | `ImplyContentTypeInterceptor` | Always; dio's default |
| 1 | `RequestStampInterceptor` | `requestId`, `headerProvider`, or `auth` is set |
| 2 | `interceptors` (custom slot) | Always; may be empty |
| 3 | `HttpLogInterceptor` or `HttpJsonLogInterceptor` | `log` is set |
| 4 | `CacheInterceptor` | `cache` is set |
| 5 | `ConcurrencyLimitInterceptor` | `concurrency` is set |
| 6 | `TokenBucketRateLimitInterceptor` or `RetryAfterPauseInterceptor` | `rateLimit` is not `none` |
| 7 | `TokenRefreshInterceptor` | `auth` is set |
| 8 | `RetryInterceptor` | `retry` is set |
| 9 | the cache fallback | its box enables it |
| 10 | exception handler | Always |

- The stamp comes first so that the log prints the stamped headers, the cache keys entries by the token, and a custom interceptor, such as a request signer, sees every stamped header.
- The refresh comes after the concurrency limiter and the rate limiter, so a 401 attempt releases its slot and passes the log like any other failure.
- The refresh comes before `RetryInterceptor`, so a 401 is refreshed once and never enters the retry loop.
- An app that sets none of the three fields gets the chain of 2.1.1.

## 8. `configure` and reuse

- The client keeps its `AuthSession` while the `auth` box is equal. A change to `requestId` or `headerProvider` rebuilds only the stamp, which receives the same session, so a running refresh and the last failed token survive.
- The client rebuilds `TokenRefreshInterceptor` and the session when `auth` changes. A refresh running in the old session finishes, and its re-sends pass through the chain current when they start. This is the contract `RetryInterceptor` already follows: every attempt uses the chain that is current when the attempt starts.
- Neither interceptor owns a timer, so `dispose()` does not change.

## 9. Logging

- `HttpJsonLogInterceptor` adds `falconx.request.id` when the request has an ID, and `falconx.auth.resent: true` on the line of a re-send.
- `HttpLogInterceptor` prints the request ID in the first line of each request.
- Both logs already redact `authorization` by default.
- `AuthSession` sends refresh start, success, and failure, and a failing `onAuthFailed`, to the client's diagnostic printer. In JSON mode, each becomes a JSON line, as other diagnostics do.

A 401 that is refreshed and re-sent prints two lines with the same `falconx.request.id`: the 401 attempt, then the re-send.

## 10. Errors seen by the caller

| Situation | The caller gets |
|---|---|
| The refresh fails | The request's 401, mapped by the exception handler exactly as a 401 is mapped in 2.1.1 |
| A re-send fails | The re-send's error, as its own chain left it |
| A stamp callback throws | A `DioException` of type `unknown`; `error` holds the thrown object |
| A cancel while waiting for a refresh | dio's cancel error |

An app that already handles a 401 needs no change.

## 11. Retrofit

Retrofit requests call `_dio.fetch` on the client's `Dio`, so they pass through both interceptors. They receive the request ID, the provider headers, the token, and the refresh with no extra setup. A re-send resolves the future Retrofit awaits.

An endpoint turns the token off with the annotation of section 3, or at run time with `@Extras()`:

```dart
@RestApi()
abstract class NewsApi {
  factory NewsApi(Dio dio) = _NewsApi;

  @GET('/public/news')
  @noToken
  Future<List<News>> news();

  @GET('/feed')
  Future<List<News>> feed(@Extras() Map<String, Object?> extras);
}

api.feed({useTokenExtraKey: false});
```

`retrofit_generator` reads method annotations through `TypeChecker.annotationsOf`, which evaluates constant annotations, so a `const` variable of type `Extra` works as an annotation. A generated fixture test proves it (section 12).

The spec adds no `@useToken` annotation. `useToken` reads true when the key is absent, so such an annotation would change nothing, and a reader could take its absence to mean "no token". It becomes useful only together with a default that sends no token, which is a non-goal.

## 12. Testing plan

TDD. Tests use a real `Dio` with a scripted adapter; timing tests run under `fakeAsync`.

**Stamp**

- A retried request (503, then 200) carries one ID on both attempts; a request that sets its own ID keeps it; a custom `generate` is used; with `requestId` null, no header is sent.
- Header precedence: configured headers lose to the provider, and the provider loses to the request's headers; a retry attempt calls the provider again and overwrites the provider's earlier values; the provider sees the request ID.
- Auth header: `Bearer` by default, the bare token with `scheme: ''`, a custom `headerName`, no header when `accessToken()` returns null, and no header with `isUseToken: false`.
- A generated Retrofit fixture proves that `@noToken` and `@Extras()` with `useTokenExtraKey: false` turn the token off.
- A throwing callback reaches the caller and the JSON log as a `DioException` of type `unknown`, and the concurrency statistics show no active request afterwards.
- Zone guard: a `refresh()` that calls the same client without `isUseToken: false` completes, and its own 401 starts no nested refresh.

**Refresh**

- Five requests that get a 401 at once cause one `refresh()` call, and all five are re-sent with the new token and succeed.
- A 401 that arrives after another request finished the refresh is re-sent without a refresh.
- A refresh that returns false, and one that throws: `onAuthFailed` runs once, and every waiting request gets the 401 exception. A later 401 carrying the same token causes no refresh and no second `onAuthFailed`.
- A re-send that gets a 401 again calls `onAuthFailed` and does not refresh.
- A 401 on a request sent without a token passes on without a refresh.
- A `Stream` body refreshes and passes the 401 on; a `FormData` body is cloned for the re-send.
- A cancel while waiting for the refresh fails that request at once, and the refresh still completes for the others.
- A re-send that gets a 500 with `retry` on makes exactly `maxAttempts` retry attempts, proving section 6.2 step 4.
- After a refresh and re-send, the concurrency statistics show no active request, and the rate limiter has spent two tokens.
- The JSON log prints two lines with the same `falconx.request.id`, the second with `falconx.auth.resent: true`.
- The cache keys entries by the stamped token.
- A throwing `onAuthFailed` is reported to the diagnostic printer and does not change the request's error.

**Configure and platforms**

- Changing `requestId` while a refresh runs keeps the session: one refresh, and the re-send succeeds. Changing `auth` builds a new session.
- The chain holds the interceptors of section 7, in that order, for each combination of the three fields.
- The UUID v7 generator and the zone guard pass under dart2js and dart2wasm in Chrome. A v7 ID holds a 48-bit timestamp, and the web truncates bitwise operations to 32 bits.
- Gates: `melos run analyze`, `format`, `test`, `build_runner:check`, and `test:platforms`.

## 13. Documentation

Per the skill maintenance rule, in the same change:

| File | Change |
|---|---|
| `skills/dart-falconx-package/references/http.md` | An "Auth and request headers" section: the three fields, the precedence rule, the refresh flow of section 6, the zone guard, and the Retrofit usage of section 11. The box table gains `requestId` and `auth`; the interceptor catalog gains both interceptors; the chain order becomes section 7. |
| `skills/dart-falconx-package/SKILL.md` | The client-configuration and interceptor rows; `useTokenExtraKey` and `noToken`. |
| `dart_falconnect/CLAUDE.md` | The chain order line and the interceptor table. |

## 14. Implementation logistics

- Work in a git worktree on branch `feature/header-auth` from the `develop` commit that holds this spec.
- Run `dart run build_runner build --delete-conflicting-outputs` in `dart_falconnect` after changing the freezed boxes.
- The Retrofit fixture lives under `dart_falconnect/test/`. The `source_gen|combining_builder` entry of `dart_falconnect/build.yaml` maps only `lib/` paths, so it gains a `test/{{path}}/{{file}}.dart` pattern; the plan confirms with a build that the fixture generates.
- UUID v7 comes from `uuid.v7()` of hashlib, which `dart_faltool` re-exports; no new dependency.
- Export new public files from the barrels in alphabetical order.
- Commit with `git commit -- <paths>`. No `Co-Authored-By` or AI attribution.
- Do not push or tag. The owner bumps the version to 2.2.0 on `release/2.2.0`, merges, and tags.

## 15. Risks

| Risk | Mitigation |
|---|---|
| `refresh()` calls the same client and deadlocks | The zone guard of section 5.4 and its test |
| A burst of 401s starts many refreshes | The single-flight refresh and its five-request test |
| Requests waiting with a failed token refresh again, or call `onAuthFailed` many times | The last failed token of section 6.1 |
| The outer `RetryInterceptor` retries a re-send's error again | `reject` without the call-following flag, and its test |
| A re-send leaks a concurrency slot | The refresh sits after the limiter; the statistics test |
| The request ID header breaks a web app through CORS | Off by default; the docs name the preflight rule |
| A new closure in each `configure` drops a running refresh | Documented in section 8 and in the skill |
| An app lists the request ID header in `CacheConfig.keyHeaders`, so every request misses | The docs warn against it |

## 16. Success criteria

- An app with `auth` set sends its token on every request whose `useToken` is true, and a burst of 401s causes one refresh followed by a successful re-send of each request.
- A failed refresh calls `onAuthFailed` once, and every waiting request fails with its 401.
- A Retrofit endpoint annotated `@noToken` sends no token.
- With `requestId` set, every attempt of a request carries one ID, and the JSON log prints it.
- An app that sets none of the three fields sends the same requests through the same chain as in 2.1.1.
- `melos run analyze`, `melos run test`, `melos run build_runner:check`, and `melos run test:platforms` pass.
- Every file in section 13 matches the code.

## 17. Details decided in this spec, for owner review

The brainstorm settled the design; these points were chosen while writing and are open to change at review.

1. The `extra` keys are `dart_falconnect.requestId`, `dart_falconnect.headers.provided`, `dart_falconnect.auth.token`, and `dart_falconnect.auth.resent`.
2. `AuthSession` is public, with public `isInsideRefresh`, `waitForRefresh`, and `refreshFor`, so a hand-built chain can share one session between both interceptors.
3. `RequestStampInterceptor` takes the client's `Dio` to read `dio.options.headers`, as `RetryInterceptor` takes it to send attempts.
4. `onAuthFailed` receives the 401 `DioException` and is not awaited.
5. The stale-token check compares the raw token from `accessToken()`, not the header value.
6. The last failed token holds one value, replaced at the next failure.
7. A `Stream` body still triggers the refresh, and its 401 passes on.
8. The pretty log prints the request ID in the first line of each request.
9. The JSON fields are `falconx.request.id` and `falconx.auth.resent`.
10. The default ID is the lowercase canonical UUID v7 string that hashlib returns.
