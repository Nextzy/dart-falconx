# Header Provider, Request ID, and Token Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a `BaseHttpClient` stamp a request ID, per-request headers, and an access token on every attempt, and refresh the token once on a 401 before sending each failed request again.

**Architecture:** Three new `HttpClientConfig` fields (`headerProvider`, `requestId`, `auth`) build two interceptors. `RequestStampInterceptor` sits first in the chain and writes the ID, the provider's headers, and the token. `TokenRefreshInterceptor` sits after the rate limiter and before `RetryInterceptor`, and re-sends through `dio.fetch` after a single-flight refresh. An `AuthSession` holds the state both share, and `configure` keeps it while the `auth` box is equal.

**Tech Stack:** Dart 3.13, dio 5.11.1, freezed 3, retrofit 4.10 with retrofit_generator 10.2.9, hashlib (through `dart_faltool`), package:test, melos.

**Spec:** `docs/superpowers/specs/2026-09-24-http-header-auth-design.md`

## Global Constraints

- Version 2.2.0. Every change adds API; nothing breaks. The owner bumps the version on `release/2.2.0`, merges, and tags; this plan never bumps, pushes, or tags.
- Every package stays pure Dart: no `package:flutter`, and no `dart:io`, `dart:html`, `dart:ffi`, or `dart:isolate` under `lib/`.
- Every model is freezed: `RequestIdConfig` and `AuthConfig` are `@freezed` boxes; `AuthSession` is a stateful service, not a model.
- Defaults: `headerProvider`, `requestId`, and `auth` are null; `RequestIdConfig.headerName` is `'X-Request-ID'` and a null `generate` makes a UUID v7; `AuthConfig.headerName` is `'Authorization'` and `scheme` is `'Bearer'`.
- `extra` keys: `dart_falconnect.requestId`, `dart_falconnect.headers.provided`, `dart_falconnect.auth.token`, `dart_falconnect.auth.resent`; `useTokenExtraKey` is `'dart_falconnect.auth.useToken'`.
- Chain order: `ImplyContentTypeInterceptor`, `RequestStampInterceptor`, custom `interceptors`, log, cache, concurrency, rate limit, `TokenRefreshInterceptor`, retry, cache fallback, exception handler.
- Only a 401 triggers a refresh. JSON log fields: `falconx.request.id` and `falconx.auth.resent`.
- No new dependency: UUID v7 comes from `uuid.v7()` of hashlib, which `dart_faltool` re-exports.
- Commit with `git add <paths>` then `git commit -m "..." -- <paths>`. No `Co-Authored-By` or AI attribution.
- A public API change updates `skills/dart-falconx-package/` on the same branch (Task 6).

## Review Focus

1. **The pretty log prints `extra` by default** (`PrettyLogConfig.request` is true): a raw token under `dart_falconnect.auth.token` would reach every app's console. Expected: the token never prints. Task 2 stores it in a wrapper whose `toString` is `REDACTED`; Task 4's pretty-log test pins it.
2. **A provider header and a request header whose names differ only in case** (`Accept-Language` against `accept-language`). Expected: the request's value wins. Task 2 test "a request header wins over the provider whatever its case".
3. **A retry attempt after logout** copies the old `Authorization` and recorded token from its earlier attempt. Expected: both are removed when `accessToken()` returns null. Task 2 test "a retry attempt drops the token once accessToken returns null".
4. **`accessToken()` throws while the refresh interceptor handles a 401.** Expected: the 401 passes on, with no refresh and no hang. Task 3 test "an accessToken that throws while handling a 401 passes the 401 on without a refresh".
5. **An app's `refresh()` calls its refresh endpoint through the same client and forgets `isUseToken: false`.** Expected: no deadlock, and the endpoint's own 401 starts no nested refresh. Task 3 group "zone guard".

## Provenance

Every code block below comes from a throwaway prototype cut from `develop` at `e453212`, then replayed task by task on a second throwaway branch; each task compiled and passed its tests on its own. Final gates on the replay: `melos run analyze` and `format` clean; `melos run build_runner:check` clean; VM tests falconnect 356 (1 skip, baseline 311), faltool 771, falmodel 71, falconx 1; `melos run test:platforms` passes, with falconnect at 360 under both dart2js and dart2wasm in Chrome. Mutation checks: switching `reject` to `next`, removing the zone guard, the failed-token check, the stale-token check, or the single-flight join each fails a named test. Both throwaway branches are deleted.

Prototype rulings, for owner review:

1. The token recorded in `extra` sits inside a private wrapper whose `toString()` returns `REDACTED` (Review Focus 1). The spec says only "record the token".
2. Spec section 12 says a failed re-send "makes exactly `maxAttempts` retry attempts, proving step 4". The prototype found that the count cannot tell `reject` from `next`: the inner `RetryInterceptor` leaves `retryAttempt > 0`, so the outer one passes the error either way. The Task 3 test counts the exception handler's calls instead: three with `reject`, four with `next`.
3. `accessToken()` that throws inside `TokenRefreshInterceptor` passes the 401 on without a refresh (Review Focus 4). The spec does not cover it.
4. The pretty log prints the ID only in the request title, as `*** Request <id> ***`.
5. `dart_falconnect/build.yaml` gains a `test/` pattern for the combining builder, and the root `CLAUDE.md` code-generation line says so.
6. Diagnostics carry the prefix `[AuthSession]`: `Refreshing the access token`, `Refresh succeeded`, `Refresh failed`, `Refresh threw: <error>`, `onAuthFailed threw: <error>`.

## Execution setup

```bash
cd "/Users/nonthawit/Data/NTD OS/projects/FalconX/dart-falconx"
git worktree add -b feature/header-auth .claude/worktrees/header-auth develop
cd .claude/worktrees/header-auth
dart pub get
```

Run every `dart` command below from `dart_falconnect/` inside the worktree unless a step says otherwise, and every `melos` or `git` command from the worktree root.

## File map

| File | Task | Responsibility |
|---|---|---|
| `dart_falconnect/lib/engine/https/config/request_id_config.dart` | 1 | `RequestIdConfig` box, `RequestIdGenerator` |
| `dart_falconnect/lib/engine/https/config/auth_config.dart` | 1 | `AuthConfig` box and its three callback typedefs |
| `dart_falconnect/lib/engine/https/config/http_client_config.dart` | 1 | `HeaderProvider` typedef; `headerProvider`, `requestId`, `auth` fields |
| `dart_falconnect/lib/engine/https/extensions/use_token_extensions.dart` | 1 | public `useTokenExtraKey`, Retrofit `noToken` |
| `dart_falconnect/lib/src/engine/https/interceptors/auth_extra.dart` | 2, 3 | unexported `extra` bookkeeping: stamped token, re-send marker |
| `dart_falconnect/lib/engine/https/interceptors/auth_session.dart` | 2 | shared refresh state, zone guard, `onAuthFailed` |
| `dart_falconnect/lib/engine/https/interceptors/request_stamp_interceptor.dart` | 2 | ID, provider headers, token; `requestId` extension |
| `dart_falconnect/lib/engine/https/interceptors/token_refresh_interceptor.dart` | 3 | 401 handling and re-send |
| `dart_falconnect/lib/engine/https/http_client.dart` | 2, 3 | builds and reuses the session and both interceptors |
| `dart_falconnect/lib/engine/https/interceptors/http_json_log_interceptor.dart`, `log_interceptor.dart` | 4 | request ID and re-send fields |
| `dart_falconnect/build.yaml`, `test/engine/https/retrofit/` | 5 | Retrofit fixture that proves `@noToken` |
| `skills/dart-falconx-package/`, `dart_falconnect/CLAUDE.md`, `CLAUDE.md` | 5, 6 | consumer skill and agent docs |

---

### Task 1: Config boxes and the public token key

**Files:**
- Create: `dart_falconnect/lib/engine/https/config/request_id_config.dart`
- Create: `dart_falconnect/lib/engine/https/config/auth_config.dart`
- Modify: `dart_falconnect/lib/engine/https/config/http_client_config.dart`
- Modify: `dart_falconnect/lib/engine/https/config/config.dart`
- Modify: `dart_falconnect/lib/engine/https/extensions/use_token_extensions.dart`
- Test: `dart_falconnect/test/engine/https/config/feature_boxes_test.dart`
- Generated: `dart_falconnect/lib/engine/https/config/generated/{auth_config,request_id_config,http_client_config}.freezed.dart`

**Interfaces:**
- Produces: `RequestIdConfig({String headerName = 'X-Request-ID', RequestIdGenerator? generate})`; `typedef RequestIdGenerator = String Function()`.
- Produces: `AuthConfig({required AccessTokenCallback accessToken, required RefreshCallback refresh, AuthFailedCallback? onAuthFailed, String headerName = 'Authorization', String scheme = 'Bearer'})`; `typedef AccessTokenCallback = FutureOr<String?> Function()`; `typedef RefreshCallback = Future<bool> Function()`; `typedef AuthFailedCallback = FutureOr<void> Function(DioException error)`.
- Produces: `typedef HeaderProvider = FutureOr<Map<String, String>> Function(RequestOptions options)`; `HttpClientConfig.headerProvider`, `.requestId`, `.auth`, all nullable.
- Produces: `const String useTokenExtraKey`; `const Extra noToken`; `RequestOptions.useToken` and `Options.useToken` now read `useTokenExtraKey`.

- [ ] **Step 1: Write the failing tests**

Insert these two tests in `feature_boxes_test.dart`, directly above `test('boxes compare by value', () {`:

```diff
diff --git a/dart_falconnect/test/engine/https/config/feature_boxes_test.dart b/dart_falconnect/test/engine/https/config/feature_boxes_test.dart
--- a/dart_falconnect/test/engine/https/config/feature_boxes_test.dart
+++ b/dart_falconnect/test/engine/https/config/feature_boxes_test.dart
@@ -44,6 +44,29 @@ void main() {
     expect(log.diagnostics, isTrue);
   });
 
+  test('request ID and auth boxes default to the documented values', () {
+    const id = RequestIdConfig();
+    expect(id.headerName, 'X-Request-ID');
+    expect(id.generate, isNull);
+
+    final auth = AuthConfig(accessToken: () => null, refresh: () async => true);
+    expect(auth.headerName, 'Authorization');
+    expect(auth.scheme, 'Bearer');
+    expect(auth.onAuthFailed, isNull);
+
+    const config = HttpClientConfig();
+    expect(config.headerProvider, isNull);
+    expect(config.requestId, isNull);
+    expect(config.auth, isNull);
+  });
+
+  test('noToken carries useTokenExtraKey set to false', () {
+    expect(useTokenExtraKey, 'dart_falconnect.auth.useToken');
+    expect(noToken.data, {useTokenExtraKey: false});
+    expect((RequestOptions()..extra = {...noToken.data}).useToken, isFalse);
+    expect(RequestOptions().useToken, isTrue);
+  });
+
   test('boxes compare by value', () {
     expect(_retry(2), const RetryConfig(maxAttempts: 2));
     expect(_retry(2).hashCode, const RetryConfig(maxAttempts: 2).hashCode);
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart test test/engine/https/config/feature_boxes_test.dart`
Expected: FAIL at compile time: `RequestIdConfig`, `AuthConfig`, `useTokenExtraKey`, and `noToken` are not defined, and `HttpClientConfig` has no `headerProvider`, `requestId`, or `auth` getter.

- [ ] **Step 3: Create `request_id_config.dart`**

`dart_falconnect/lib/engine/https/config/request_id_config.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/request_id_config.freezed.dart';

/// Makes a new request ID.
typedef RequestIdGenerator = String Function();

/// Request ID settings; a non-null box stamps an ID on every request.
///
/// Every retry attempt and every re-send after a token refresh carries the
/// ID of the first attempt. On the web, a custom header makes the browser
/// send a CORS preflight, so the server must list [headerName] in
/// `Access-Control-Allow-Headers`.
@freezed
abstract class RequestIdConfig with _$RequestIdConfig {
  /// Creates request ID settings.
  const factory({
    /// Header that carries the ID.
    @Default('X-Request-ID') String headerName,

    /// Makes a new ID; null makes a UUID v7.
    RequestIdGenerator? generate,
  }) = _RequestIdConfig;
}
```

- [ ] **Step 4: Create `auth_config.dart`**

`dart_falconnect/lib/engine/https/config/auth_config.dart`:

```dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/auth_config.freezed.dart';

/// Returns the current access token; null sends the request without one.
typedef AccessTokenCallback = FutureOr<String?> Function();

/// Refreshes the access token; returns true on success.
typedef RefreshCallback = Future<bool> Function();

/// Called when the app must sign in again.
typedef AuthFailedCallback = FutureOr<void> Function(DioException error);

/// Access token settings; a non-null box stamps the token and refreshes it
/// on a 401.
///
/// The app owns the token: [accessToken] reads it and [refresh] renews it.
/// After a refresh, the client reads the new token through [accessToken].
@freezed
abstract class AuthConfig with _$AuthConfig {
  /// Creates access token settings.
  const factory({
    /// Returns the current access token; null sends the request without
    /// one. An app that refreshes before expiry does it here.
    required AccessTokenCallback accessToken,

    /// Refreshes the token and returns true on success; false or a throw
    /// fails the refresh. A request sent from inside it never waits for
    /// the refresh and never refreshes.
    required RefreshCallback refresh,

    /// Called once per failed refresh, and when a re-sent request gets a
    /// 401 again. Not awaited; an error it throws goes to the diagnostics.
    AuthFailedCallback? onAuthFailed,

    /// Header that carries the token.
    @Default('Authorization') String headerName,

    /// Word placed before the token; an empty string sends the bare token.
    @Default('Bearer') String scheme,
  }) = _AuthConfig;
}
```

- [ ] **Step 5: Add the three fields to `HttpClientConfig` and export the boxes**

```diff
diff --git a/dart_falconnect/lib/engine/https/config/http_client_config.dart b/dart_falconnect/lib/engine/https/config/http_client_config.dart
--- a/dart_falconnect/lib/engine/https/config/http_client_config.dart
+++ b/dart_falconnect/lib/engine/https/config/http_client_config.dart
@@ -1,7 +1,11 @@
+import 'dart:async';
+
+import 'package:dart_falconnect/engine/https/config/auth_config.dart';
 import 'package:dart_falconnect/engine/https/config/cache_config.dart';
 import 'package:dart_falconnect/engine/https/config/concurrency_config.dart';
 import 'package:dart_falconnect/engine/https/config/log_config.dart';
 import 'package:dart_falconnect/engine/https/config/rate_limit_config.dart';
+import 'package:dart_falconnect/engine/https/config/request_id_config.dart';
 import 'package:dart_falconnect/engine/https/config/retry_config.dart';
 import 'package:dart_falconnect/engine/https/interceptors/network_exception_handler_interceptor.dart';
 import 'package:dio/dio.dart';
@@ -9,6 +13,11 @@ import 'package:freezed_annotation/freezed_annotation.dart';
 
 part 'generated/http_client_config.freezed.dart';
 
+/// Returns headers for one request.
+typedef HeaderProvider = FutureOr<Map<String, String>> Function(
+  RequestOptions options,
+);
+
 /// Configuration of a `BaseHttpClient`: the dio options it owns and one box
 /// per feature. A null box turns its feature off.
 @freezed
@@ -67,6 +76,16 @@ abstract class HttpClientConfig with _$HttpClientConfig {
     /// Last interceptor of the chain; null means
     /// `DefaultNetworkExceptionHandlerInterceptor`.
     NetworkExceptionHandlerInterceptor? exceptionHandler,
+
+    /// Headers computed for each request; null turns them off. They
+    /// override [headers] and lose to the request's own headers.
+    HeaderProvider? headerProvider,
+
+    /// Request ID header; null turns it off.
+    RequestIdConfig? requestId,
+
+    /// Access token and 401 refresh; null turns them off.
+    AuthConfig? auth,
   }) = _HttpClientConfig;
 
   const new _();
```

```diff
diff --git a/dart_falconnect/lib/engine/https/config/config.dart b/dart_falconnect/lib/engine/https/config/config.dart
--- a/dart_falconnect/lib/engine/https/config/config.dart
+++ b/dart_falconnect/lib/engine/https/config/config.dart
@@ -1,7 +1,9 @@
+export 'auth_config.dart';
 export 'cache_config.dart';
 export 'concurrency_config.dart';
 export 'http_client_config.dart';
 export 'log_config.dart';
 export 'pause_config.dart';
 export 'rate_limit_config.dart';
+export 'request_id_config.dart';
 export 'retry_config.dart';
```

- [ ] **Step 6: Make the token key public and add `noToken`**

Replace the whole of `use_token_extensions.dart`:

`dart_falconnect/lib/engine/https/extensions/use_token_extensions.dart`:

````dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart' show Extra;

/// Key in `RequestOptions.extra` that turns the auth token off for one
/// request when its value is false.
const String useTokenExtraKey = 'dart_falconnect.auth.useToken';

/// Retrofit annotation: the endpoint sends no token and never refreshes.
///
/// ```dart
/// @GET('/public/news')
/// @noToken
/// Future<List<News>> news();
/// ```
const Extra noToken = Extra({useTokenExtraKey: false});

/// Whether a request carries the auth token, on [RequestOptions].
extension FalconAuthRequestOptionsExtensions on RequestOptions {
  /// Whether the auth interceptors stamp and refresh a token; true unless a
  /// request method was called with `isUseToken: false` or the endpoint
  /// carries [noToken].
  bool get useToken => extra[useTokenExtraKey] != false;
  set useToken(bool value) => extra = {...extra, useTokenExtraKey: value};
}

/// Whether a request carries the auth token, on [Options].
extension FalconAuthOptionsExtensions on Options {
  /// Whether the auth interceptors stamp and refresh a token; true when
  /// unset.
  bool get useToken => extra?[useTokenExtraKey] != false;
  set useToken(bool value) => extra = {...?extra, useTokenExtraKey: value};
}
````

- [ ] **Step 7: Generate the freezed code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `Built with build_runner`, writing `auth_config.freezed.dart`, `request_id_config.freezed.dart`, and an updated `http_client_config.freezed.dart` under `lib/engine/https/config/generated/`.

- [ ] **Step 8: Run the tests to verify they pass**

Run: `dart test test/engine/https/config/feature_boxes_test.dart && dart analyze`
Expected: `+5: All tests passed!` and `No issues found!`

- [ ] **Step 9: Commit**

```bash
P=dart_falconnect/lib/engine/https
git add $P/config $P/extensions/use_token_extensions.dart dart_falconnect/test/engine/https/config/feature_boxes_test.dart
git commit -m "feat(dart_falconnect): add the request ID and auth config boxes" -- $P/config $P/extensions/use_token_extensions.dart dart_falconnect/test/engine/https/config/feature_boxes_test.dart
```

---

### Task 2: `AuthSession` and `RequestStampInterceptor`

**Files:**
- Create: `dart_falconnect/lib/src/engine/https/interceptors/auth_extra.dart`
- Create: `dart_falconnect/lib/engine/https/interceptors/auth_session.dart`
- Create: `dart_falconnect/lib/engine/https/interceptors/request_stamp_interceptor.dart`
- Modify: `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`
- Modify: `dart_falconnect/lib/engine/https/http_client.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/request_stamp_interceptor_test.dart`
- Test: `dart_falconnect/test/engine/https/base_http_client_configure_test.dart`

**Interfaces:**
- Consumes: `RequestIdConfig`, `AuthConfig`, `HeaderProvider`, `HttpClientConfig.requestId/.headerProvider/.auth`, `RequestOptions.useToken` (Task 1).
- Produces: `class AuthSession { AuthSession(AuthConfig config, {void Function(String)? logPrint}); final AuthConfig config; bool get isInsideRefresh; Future<void> waitForRefresh(); bool isFailedToken(String token); Future<bool> refreshFor(String staleToken, DioException error); void fail(String token, DioException error); }`.
- Produces: `class RequestStampInterceptor extends Interceptor { RequestStampInterceptor({RequestIdConfig? requestId, HeaderProvider? headerProvider, AuthSession? auth, required Dio dio}); final AuthSession? auth; }`; `extension FalconRequestIdExtensions on RequestOptions { String? get requestId; }`.
- Produces (unexported, `lib/src/`): `extension AuthExtra on RequestOptions { String? get stampedToken; set stampedToken(String? token); }`.
- Produces: `BaseHttpClient` fields `_session` and `_stamp`, and `_buildStamp(previous, next, session)`; Task 3 adds the refresh interceptor beside them.

- [ ] **Step 1: Write the failing stamp tests**

Create `request_stamp_interceptor_test.dart`:

`dart_falconnect/test/engine/https/interceptors/request_stamp_interceptor_test.dart`:

```dart
import 'package:dart_falconnect/dart_falconnect.dart';
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
      },
    );

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
}
```

- [ ] **Step 2: Add the chain test to the configure tests**

Append this group at the end of `main()` in `base_http_client_configure_test.dart`:

```diff
diff --git a/dart_falconnect/test/engine/https/base_http_client_configure_test.dart b/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
--- a/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
+++ b/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
@@ -708,4 +708,20 @@ void main() {
 
     await expectLater(client.dio.get<dynamic>('/x'), completes);
   });
+  group('request stamp and token refresh', () {
+    test('a request ID or a header provider alone builds only the stamp', () {
+      final client = _Client(ScriptedAdapter([reply(200)]))
+        ..configure(const HttpClientConfig(requestId: RequestIdConfig()));
+      final withId = client.interceptors.map((i) => '${i.runtimeType}');
+      expect(withId, [
+        'ImplyContentTypeInterceptor',
+        'RequestStampInterceptor',
+        'DefaultNetworkExceptionHandlerInterceptor',
+      ]);
+
+      client.configure(HttpClientConfig(headerProvider: (_) => const {}));
+
+      expect(client.interceptors.map((i) => '${i.runtimeType}'), withId);
+    });
+  });
 }
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `dart test test/engine/https/interceptors/request_stamp_interceptor_test.dart test/engine/https/base_http_client_configure_test.dart`
Expected: FAIL. The stamp file fails to compile: `RequestStampInterceptor` is not defined, and `RequestOptions` has no `requestId` getter. The configure file compiles, and its new test fails because the chain holds no `RequestStampInterceptor`.

- [ ] **Step 4: Create the unexported `extra` bookkeeping**

`dart_falconnect/lib/src/engine/https/interceptors/auth_extra.dart`:

```dart
import 'package:dio/dio.dart';

const String _tokenKey = 'dart_falconnect.auth.token';

/// The token a request carried. `toString` hides it, because the pretty
/// log prints `extra`.
final class _StampedToken {
  const new(this.value);

  final String value;

  @override
  String toString() => 'REDACTED';
}

/// Auth bookkeeping the stamp and the refresh interceptor keep in
/// `RequestOptions.extra`. Retry attempts and re-sends copy it.
extension AuthExtra on RequestOptions {
  /// The token `RequestStampInterceptor` stamped; null when it stamped none.
  String? get stampedToken => switch (extra[_tokenKey]) {
    final _StampedToken token => token.value,
    _ => null,
  };

  set stampedToken(String? token) => extra = token == null
      ? ({...extra}..remove(_tokenKey))
      : {...extra, _tokenKey: _StampedToken(token)};
}
```

- [ ] **Step 5: Create `AuthSession`**

`dart_falconnect/lib/engine/https/interceptors/auth_session.dart`:

```dart
import 'dart:async';

import 'package:dart_falconnect/engine/https/config/auth_config.dart';
import 'package:dio/dio.dart';

/// State the two auth interceptors share: the running refresh, the token
/// whose refresh failed last, and the zone that marks code running inside
/// a refresh.
///
/// `BaseHttpClient` builds one session per `AuthConfig` and passes it to
/// `RequestStampInterceptor` and `TokenRefreshInterceptor`. A chain built
/// by hand passes one session to both.
class AuthSession {
  /// Creates a session for [config].
  new(this.config, {this.logPrint});

  /// The token callbacks and header settings.
  final AuthConfig config;

  /// Prints diagnostics; null prints nothing.
  final void Function(String message)? logPrint;

  /// Zone key that marks code running inside `config.refresh()`.
  final Object _zoneKey = Object();

  Future<bool>? _refreshing;
  String? _failedToken;

  /// Whether the caller runs inside this session's `config.refresh()`.
  bool get isInsideRefresh => Zone.current[_zoneKey] == true;

  /// Completes when no refresh is running, and at once inside a refresh.
  Future<void> waitForRefresh() async {
    final running = _refreshing;
    if (running == null || isInsideRefresh) return;
    await running;
  }

  /// Whether [token] is the token whose refresh failed last.
  bool isFailedToken(String token) => token == _failedToken;

  /// Refreshes once for every caller that arrives while a refresh runs.
  ///
  /// Returns true when the refresh succeeded. On failure, records
  /// [staleToken] as the last failed token and calls `onAuthFailed` with
  /// [error] once; callers that joined the refresh do not call it again.
  Future<bool> refreshFor(String staleToken, DioException error) {
    final running = _refreshing;
    if (running != null) return running;
    final refresh = _refresh(staleToken, error);
    _refreshing = refresh;
    unawaited(
      refresh.whenComplete(() {
        if (identical(_refreshing, refresh)) _refreshing = null;
      }),
    );
    return refresh;
  }

  /// Records [token] as the last failed token and calls `onAuthFailed`
  /// with [error], without awaiting it.
  void fail(String token, DioException error) {
    _failedToken = token;
    final onAuthFailed = config.onAuthFailed;
    if (onAuthFailed == null) return;
    unawaited(
      Future<void>.sync(() => onAuthFailed(error)).then<void>(
        (_) {},
        onError: (Object failure) => _log('onAuthFailed threw: $failure'),
      ),
    );
  }

  Future<bool> _refresh(String staleToken, DioException error) async {
    _log('Refreshing the access token');
    var refreshed = false;
    try {
      refreshed = await runZoned(config.refresh, zoneValues: {_zoneKey: true});
    } on Object catch (failure) {
      _log('Refresh threw: $failure');
    }
    if (refreshed) {
      _log('Refresh succeeded');
      return true;
    }
    _log('Refresh failed');
    fail(staleToken, error);
    return false;
  }

  void _log(String message) => logPrint?.call('[AuthSession] $message');
}
```

- [ ] **Step 6: Create `RequestStampInterceptor`**

`dart_falconnect/lib/engine/https/interceptors/request_stamp_interceptor.dart`:

```dart
import 'dart:async';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/config/request_id_config.dart';
import 'package:dart_falconnect/engine/https/extensions/use_token_extensions.dart';
import 'package:dart_falconnect/engine/https/interceptors/auth_session.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/auth_extra.dart';
import 'package:dart_faltool/dart_faltool.dart' show uuid;
import 'package:dio/dio.dart';

const String _requestIdKey = 'dart_falconnect.requestId';
const String _providedKey = 'dart_falconnect.headers.provided';

/// The request ID on [RequestOptions].
extension FalconRequestIdExtensions on RequestOptions {
  /// The ID `RequestStampInterceptor` gave this request; null when it has
  /// none.
  String? get requestId => switch (extra[_requestIdKey]) {
    final String id => id,
    _ => null,
  };
}

/// Stamps the request ID, the provider's headers, and the access token on
/// every attempt, in that order.
///
/// `BaseHttpClient` places it first, so the log prints the stamped
/// headers, `CacheInterceptor` keys entries by the token, and the app's own
/// interceptors see every stamped header. It runs again on each retry
/// attempt and re-send, which then carry the current token and fresh
/// provider values while keeping the first attempt's ID.
///
/// A callback that throws fails the request with a `DioException` of type
/// `unknown` whose `error` is the thrown object.
class RequestStampInterceptor extends Interceptor {
  /// Creates a stamp. [dio] supplies the configured headers, which the
  /// provider's headers override.
  new({this.requestId, this.headerProvider, this.auth, required this.dio});

  /// Request ID settings; null stamps no ID.
  final RequestIdConfig? requestId;

  /// Headers computed per request; null stamps none.
  final HeaderProvider? headerProvider;

  /// The token session; null stamps no token.
  final AuthSession? auth;

  /// The client's Dio, whose `options.headers` are the configured headers.
  final Dio dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var step = 'RequestIdConfig.generate';
    try {
      _stampId(options);
      step = 'HttpClientConfig.headerProvider';
      await _stampProvided(options);
      step = 'AuthConfig.accessToken';
      await _stampToken(options);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
          message: '$step threw: $error',
        ),
        true,
      );
      return;
    }
    handler.next(options);
  }

  void _stampId(RequestOptions options) {
    final box = requestId;
    if (box == null) return;
    final id =
        options.requestId ??
        options.headers[box.headerName]?.toString() ??
        (box.generate ?? uuid.v7)();
    options
      ..extra = {...options.extra, _requestIdKey: id}
      ..headers[box.headerName] = id;
  }

  Future<void> _stampProvided(RequestOptions options) async {
    final provider = headerProvider;
    if (provider == null) return;
    final values = await provider(options);
    final earlier = switch (options.extra[_providedKey]) {
      final Set<String> keys => keys,
      _ => const <String>{},
    };
    final configured = dio.options.headers;
    final written = <String>{};
    for (final MapEntry(:key, :value) in values.entries) {
      final name = key.toLowerCase();
      final current = options.headers[key];
      final setByRequest =
          current != null &&
          current != configured[key] &&
          !earlier.contains(name);
      if (setByRequest) continue;
      options.headers[key] = value;
      written.add(name);
    }
    options.extra = {...options.extra, _providedKey: written};
  }

  Future<void> _stampToken(RequestOptions options) async {
    final session = auth;
    if (session == null || !options.useToken) return;
    await session.waitForRefresh();
    final token = await session.config.accessToken();
    final name = session.config.headerName;
    if (token == null) {
      options
        ..headers.remove(name)
        ..stampedToken = null;
      return;
    }
    final scheme = session.config.scheme;
    options
      ..headers[name] = scheme.isEmpty ? token : '$scheme $token'
      ..stampedToken = token;
  }
}
```

- [ ] **Step 7: Export both and build them in `configure`**

```diff
diff --git a/dart_falconnect/lib/engine/https/interceptors/interceptors.dart b/dart_falconnect/lib/engine/https/interceptors/interceptors.dart
--- a/dart_falconnect/lib/engine/https/interceptors/interceptors.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/interceptors.dart
@@ -1,3 +1,4 @@
+export 'auth_session.dart';
 export 'cache_interceptor.dart';
 export 'concurrency_limit_interceptor.dart';
 export 'default_network_exception_handler_interceptor.dart';
@@ -6,6 +7,7 @@ export 'local_rate_limit.dart';
 export 'log_interceptor.dart';
 export 'models/models.dart';
 export 'network_exception_handler_interceptor.dart';
+export 'request_stamp_interceptor.dart';
 export 'retry_after_pause_interceptor.dart';
 export 'retry_interceptor.dart';
 export 'token_bucket_rate_limit_interceptor.dart';
```

```diff
diff --git a/dart_falconnect/lib/engine/https/http_client.dart b/dart_falconnect/lib/engine/https/http_client.dart
--- a/dart_falconnect/lib/engine/https/http_client.dart
+++ b/dart_falconnect/lib/engine/https/http_client.dart
@@ -3,7 +3,8 @@ import 'package:dart_falconnect/lib.dart';
 /// Base class of every HTTP client in FalconX: one [Dio] configured by one
 /// [HttpClientConfig].
 ///
-/// The client orders the interceptor chain itself: the config's own
+/// The client orders the interceptor chain itself: the request stamp when
+/// `requestId`, `headerProvider`, or `auth` is set, the config's own
 /// `interceptors`, then log, cache, concurrency limit, rate limit, retry,
 /// the cache's offline fallback when its box enables it, and the exception
 /// handler last. [configure] applies a new
@@ -32,6 +33,8 @@ abstract class BaseHttpClient implements RequestApiService {
       DefaultNetworkExceptionHandlerInterceptor();
 
   HttpClientConfig? _config;
+  AuthSession? _session;
+  RequestStampInterceptor? _stamp;
   Interceptor? _log;
   CacheInterceptor? _cache;
   ConcurrencyLimitInterceptor? _concurrency;
@@ -63,6 +66,13 @@ abstract class BaseHttpClient implements RequestApiService {
     // value it rejects throws here, before this client changes.
     config.applyTo(Dio());
     final previous = _config;
+    final session = _keepOrBuild(
+      previous?.auth,
+      config.auth,
+      _session,
+      (box) => AuthSession(box, logPrint: _diagnostic),
+    );
+    final stamp = _buildStamp(previous, config, session);
     final log = _keepOrBuild(previous?.log, config.log, _log, _buildLog);
     final cache = _keepOrBuild(
       previous?.cache,
@@ -97,6 +107,7 @@ abstract class BaseHttpClient implements RequestApiService {
     _dio.interceptors
       ..clear()
       ..addAll([
+        ?stamp,
         ...config.interceptors,
         ?log,
         ?cache,
@@ -107,6 +118,8 @@ abstract class BaseHttpClient implements RequestApiService {
         config.exceptionHandler ?? _defaultExceptionHandler,
       ]);
     _config = config;
+    _session = session;
+    _stamp = stamp;
     _log = log;
     _cache = cache;
     _concurrency = concurrency;
@@ -378,6 +391,33 @@ abstract class BaseHttpClient implements RequestApiService {
     return build(after);
   }
 
+  /// The stamp for [next]: none when it stamps nothing, the current one
+  /// when its inputs are unchanged, else a new one.
+  RequestStampInterceptor? _buildStamp(
+    HttpClientConfig? previous,
+    HttpClientConfig next,
+    AuthSession? session,
+  ) {
+    if (next.requestId == null &&
+        next.headerProvider == null &&
+        session == null) {
+      return null;
+    }
+    final current = _stamp;
+    if (current != null &&
+        previous?.requestId == next.requestId &&
+        previous?.headerProvider == next.headerProvider &&
+        identical(current.auth, session)) {
+      return current;
+    }
+    return RequestStampInterceptor(
+      requestId: next.requestId,
+      headerProvider: next.headerProvider,
+      auth: session,
+      dio: _dio,
+    );
+  }
+
   Interceptor _buildLog(LogConfig box) => switch (box) {
     PrettyLogConfig() => _buildPrettyLog(box),
     JsonLogConfig() => HttpJsonLogInterceptor(config: box),
```

- [ ] **Step 8: Run the tests to verify they pass**

Run: `dart test test/engine/https/interceptors/request_stamp_interceptor_test.dart test/engine/https/base_http_client_configure_test.dart && dart analyze`
Expected: `+49: All tests passed!` (17 stamp tests, 32 configure tests) and `No issues found!`

- [ ] **Step 9: Run the whole package**

Run: `dart test`
Expected: `+331 ~1: All tests passed!`

- [ ] **Step 10: Commit**

```bash
S=dart_falconnect/lib/src/engine/https/interceptors/auth_extra.dart
I=dart_falconnect/lib/engine/https/interceptors
T=dart_falconnect/test/engine/https
git add $S $I/auth_session.dart $I/request_stamp_interceptor.dart $I/interceptors.dart dart_falconnect/lib/engine/https/http_client.dart $T/interceptors/request_stamp_interceptor_test.dart $T/base_http_client_configure_test.dart
git commit -m "feat(dart_falconnect): stamp the request ID, provider headers, and token" -- $S $I/auth_session.dart $I/request_stamp_interceptor.dart $I/interceptors.dart dart_falconnect/lib/engine/https/http_client.dart $T/interceptors/request_stamp_interceptor_test.dart $T/base_http_client_configure_test.dart
```

---

### Task 3: `TokenRefreshInterceptor`

**Files:**
- Create: `dart_falconnect/lib/engine/https/interceptors/token_refresh_interceptor.dart`
- Modify: `dart_falconnect/lib/src/engine/https/interceptors/auth_extra.dart`
- Modify: `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`
- Modify: `dart_falconnect/lib/engine/https/http_client.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/token_refresh_interceptor_test.dart`
- Test: `dart_falconnect/test/engine/https/base_http_client_configure_test.dart`

**Interfaces:**
- Consumes: `AuthSession.isInsideRefresh`, `.isFailedToken`, `.refreshFor`, `.fail`, `.config` (Task 2); `AuthExtra.stampedToken` (Task 2).
- Produces: `class TokenRefreshInterceptor extends Interceptor { TokenRefreshInterceptor({required AuthSession session, required Dio dio}); final AuthSession session; final Dio dio; }`.
- Produces (unexported): `AuthExtra.isAuthResend` (bool) and `AuthExtra.authResend()` (returns `RequestOptions` marked as a re-send, with a cloned `FormData`). Task 4's JSON log reads `isAuthResend`.

- [ ] **Step 1: Write the failing refresh tests**

Create `token_refresh_interceptor_test.dart`:

`dart_falconnect/test/engine/https/interceptors/token_refresh_interceptor_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
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

/// A server that answers 200 to the current token and 401 to any other.
///
/// [statusFor] overrides the answer for a request.
class _Server implements HttpClientAdapter {
  new(this.tokens, {this.statusFor});

  final _Tokens tokens;
  final int? Function(RequestOptions options)? statusFor;
  final List<RequestOptions> requests = [];

  /// Completes once the server has answered [count] requests.
  Future<void> answered(int count) async {
    while (requests.length < count) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    requests.add(options);
    final status =
        statusFor?.call(options) ??
        (options.headers['authorization'] == 'Bearer ${tokens.server}'
            ? 200
            : 401);
    return reply(status)(options);
  }

  @override
  void close({bool force = false}) {}
}

/// The app's token store: `current` is what the app holds, `server` what
/// the server accepts. A refresh copies `server` into `current`.
class _Tokens {
  String? current = 'old';
  String server = 'new';
  int reads = 0;
  int refreshes = 0;
  int failures = 0;

  /// Completed by a test to let a running refresh finish.
  Completer<void>? gate;

  /// What the next refresh returns.
  bool succeeds = true;

  Future<bool> refresh() async {
    refreshes++;
    await gate?.future;
    if (succeeds) current = server;
    return succeeds;
  }

  String? read() {
    reads++;
    return current;
  }

  /// Completes once `accessToken` has been read [count] times.
  Future<void> readTimes(int count) async {
    while (reads < count) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  AuthConfig config({RefreshCallback? refresh}) => AuthConfig(
    accessToken: read,
    refresh: refresh ?? this.refresh,
    onAuthFailed: (_) => failures++,
  );
}

Future<DioException> _failure(Future<Object?> request) => request.then(
  (_) => fail('the request succeeded'),
  onError: (Object error) => error as DioException,
);

void main() {
  group('refresh', () {
    test('many 401s at once share one refresh, and every request is sent '
        'again with the new token', () async {
      final tokens = _Tokens()..gate = Completer<void>();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final requests = [
        for (var i = 0; i < 5; i++) client.dio.get<dynamic>('/x'),
      ];
      // Five stamps and five 401s have read the token: every request now
      // waits in the refresh interceptor.
      await tokens.readTimes(10);
      tokens.gate!.complete();
      final responses = await Future.wait(requests);

      expect(tokens.refreshes, 1);
      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(
        server.requests.skip(5).map((r) => r.headers['authorization']),
        everyElement('Bearer new'),
      );
      expect(server.requests, hasLength(10));
    });

    test('a 401 that arrives after another refresh is sent again without '
        'refreshing', () async {
      final tokens = _Tokens();
      final gated = GatedAdapter();
      final client = _Client(gated, HttpClientConfig(auth: tokens.config()));

      final first = client.dio.get<dynamic>('/x');
      final second = client.dio.get<dynamic>('/x');
      while (gated.requests.length < 2) {
        await Future<void>.delayed(Duration.zero);
      }
      gated.requests[0].respond(401);
      while (gated.requests.length < 3) {
        await Future<void>.delayed(Duration.zero);
      }
      gated.requests[2].respond(200);
      await first;
      gated.requests[1].respond(401);
      while (gated.requests.length < 4) {
        await Future<void>.delayed(Duration.zero);
      }
      gated.requests[3].respond(200);
      await second;

      expect(tokens.refreshes, 1);
      expect(gated.requests[1].options.headers['authorization'], 'Bearer old');
      expect(gated.requests[3].options.headers['authorization'], 'Bearer new');
    });

    test('a request that starts during a refresh waits and carries the new '
        'token', () async {
      final tokens = _Tokens()..gate = Completer<void>();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final first = client.dio.get<dynamic>('/x');
      await server.answered(1);
      await Future<void>.delayed(Duration.zero);
      final later = client.dio.get<dynamic>('/y');
      await Future<void>.delayed(Duration.zero);
      expect(server.requests, hasLength(1));
      tokens.gate!.complete();
      await Future.wait([first, later]);

      final toY = server.requests.where((r) => r.path == '/y');
      expect(toY.single.headers['authorization'], 'Bearer new');
      expect(tokens.refreshes, 1);
    });
  });

  group('failure', () {
    test('a refresh that returns false calls onAuthFailed once, and every '
        'waiting request fails with its 401', () async {
      final tokens = _Tokens()
        ..succeeds = false
        ..gate = Completer<void>();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final failures = [
        for (var i = 0; i < 3; i++) _failure(client.dio.get<dynamic>('/x')),
      ];
      await tokens.readTimes(6);
      tokens.gate!.complete();
      final errors = await Future.wait(failures);

      expect(errors.map((e) => e.response?.statusCode), everyElement(401));
      expect(tokens.refreshes, 1);
      expect(tokens.failures, 1);
      expect(server.requests, hasLength(3));
    });

    test('a later 401 with the token that failed causes no refresh and no '
        'second onAuthFailed', () async {
      final tokens = _Tokens()..succeeds = false;
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      await _failure(client.dio.get<dynamic>('/x'));
      await _failure(client.dio.get<dynamic>('/x'));

      expect(tokens.refreshes, 1);
      expect(tokens.failures, 1);
    });

    test('a refresh that throws fails like one that returns false, and the '
        'diagnostics say so', () async {
      final lines = <Object?>[];
      final tokens = _Tokens();
      final server = _Server(tokens);
      final client = _Client(
        server,
        HttpClientConfig(
          log: LogConfig(logPrint: lines.add, request: false),
          auth: tokens.config(refresh: () async => throw StateError('down')),
        ),
      );

      final error = await _failure(client.dio.get<dynamic>('/x'));

      expect(error.response?.statusCode, 401);
      expect(tokens.failures, 1);
      expect(lines, contains(startsWith('[AuthSession] Refresh threw')));
    });

    test('a re-send that gets a 401 again calls onAuthFailed and does not '
        'refresh again', () async {
      final tokens = _Tokens();
      final server = _Server(tokens, statusFor: (_) => 401);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final error = await _failure(client.dio.get<dynamic>('/x'));

      expect(error.response?.statusCode, 401);
      expect(tokens.refreshes, 1);
      expect(tokens.failures, 1);
      expect(server.requests, hasLength(2));
    });

    test('a 401 on a request sent without a token passes on', () async {
      final tokens = _Tokens()..current = null;
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final error = await _failure(client.dio.get<dynamic>('/x'));

      expect(error.response?.statusCode, 401);
      expect(tokens.refreshes, 0);
      expect(tokens.failures, 0);
    });

    test('an accessToken that throws while handling a 401 passes the 401 on '
        'without a refresh', () async {
      final tokens = _Tokens();
      final server = _Server(tokens);
      var reads = 0;
      final client = _Client(
        server,
        HttpClientConfig(
          auth: AuthConfig(
            accessToken: () =>
                ++reads == 1 ? tokens.current : throw StateError('locked'),
            refresh: tokens.refresh,
          ),
        ),
      );

      final error = await _failure(client.dio.get<dynamic>('/x'));

      expect(error.response?.statusCode, 401);
      expect(tokens.refreshes, 0);
    });

    test('a throwing onAuthFailed goes to the diagnostics and leaves the '
        '401 unchanged', () async {
      final lines = <Object?>[];
      final tokens = _Tokens()..succeeds = false;
      final server = _Server(tokens);
      final client = _Client(
        server,
        HttpClientConfig(
          log: LogConfig(logPrint: lines.add, request: false),
          auth: AuthConfig(
            accessToken: () => tokens.current,
            refresh: tokens.refresh,
            onAuthFailed: (_) => throw StateError('router gone'),
          ),
        ),
      );

      final error = await _failure(client.dio.get<dynamic>('/x'));
      await Future<void>.delayed(Duration.zero);

      expect(error.response?.statusCode, 401);
      expect(lines, contains(startsWith('[AuthSession] onAuthFailed threw')));
    });
  });

  group('bodies and cancels', () {
    test('a Stream body refreshes and passes its 401 on', () async {
      final tokens = _Tokens();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final error = await _failure(
        client.dio.post<dynamic>(
          '/x',
          data: Stream.value(utf8.encode('{}')),
          options: Options(headers: {Headers.contentLengthHeader: 2}),
        ),
      );

      expect(error.response?.statusCode, 401);
      expect(tokens.refreshes, 1);
      expect(tokens.current, 'new');
      expect(server.requests, hasLength(1));
    });

    test('a FormData body is cloned for the re-send', () async {
      final tokens = _Tokens();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final response = await client.dio.post<dynamic>(
        '/x',
        data: FormData.fromMap({'a': '1'}),
      );

      expect(response.statusCode, 200);
      expect(server.requests, hasLength(2));
      expect(server.requests[1].data, isA<FormData>());
      expect(server.requests[1].data, isNot(same(server.requests[0].data)));
    });

    test('a cancel while waiting for the refresh fails that request at once; '
        'the refresh completes for the others', () async {
      final tokens = _Tokens()..gate = Completer<void>();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));
      final cancel = CancelToken();

      final cancelled = _failure(
        client.dio.get<dynamic>('/a', cancelToken: cancel),
      );
      final other = client.dio.get<dynamic>('/b');
      await server.answered(2);
      await Future<void>.delayed(Duration.zero);
      cancel.cancel();
      final error = await cancelled;
      tokens.gate!.complete();
      final response = await other;

      expect(error.type, DioExceptionType.cancel);
      expect(response.statusCode, 200);
      expect(server.requests.where((r) => r.path == '/a'), hasLength(1));
    });
  });

  group('the chain', () {
    test('a failed re-send skips the outer retry and exception handler, which '
        'it already passed', () async {
      final handled = <int?>[];
      final tokens = _Tokens();
      final server = _Server(
        tokens,
        statusFor: (o) =>
            o.headers['authorization'] == 'Bearer new' ? 500 : 401,
      );
      final client = _Client(
        server,
        HttpClientConfig(
          auth: tokens.config(),
          retry: const RetryConfig(maxAttempts: 2, delay: Duration.zero),
          exceptionHandler: _CountingHandler(handled),
        ),
      );

      final error = await _failure(client.dio.get<dynamic>('/x'));

      expect(error.response?.statusCode, 500);
      expect(server.requests, hasLength(4));
      expect(handled, [500, 500, 500]);
    });

    test('the re-send takes a new slot and a new token and leaves none '
        'held', () async {
      final tokens = _Tokens();
      final server = _Server(tokens);
      final client = _Client(
        server,
        HttpClientConfig(
          auth: tokens.config(),
          concurrency: const ConcurrencyConfig(global: 1),
          rateLimit: const RateLimitConfig.tokenBucket(
            global: [TokenBucketPolicy(permits: 10, per: Duration(minutes: 1))],
          ),
        ),
      );
      addTearDown(client.dispose);

      await client.dio.get<dynamic>('/x');

      final concurrency = client.interceptors
          .whereType<ConcurrencyLimitInterceptor>()
          .single
          .getStatistics();
      final rateLimit = client.interceptors
          .whereType<TokenBucketRateLimitInterceptor>()
          .single
          .getStatistics();
      expect(concurrency.globalActive, 0);
      expect(concurrency.forwarded, 2);
      expect(rateLimit.forwarded, 2);
    });
  });

  group('zone guard', () {
    test('a refresh that calls the same client with the token does not '
        'deadlock', () async {
      final tokens = _Tokens();
      late final _Client client;
      final server = _Server(
        tokens,
        statusFor: (o) => o.path == '/refresh' ? 200 : null,
      );
      client = _Client(
        server,
        HttpClientConfig(
          auth: tokens.config(
            refresh: () async {
              tokens.refreshes++;
              await client.dio.get<dynamic>('/refresh');
              tokens.current = tokens.server;
              return true;
            },
          ),
        ),
      );

      final response = await client.dio
          .get<dynamic>('/x')
          .timeout(const Duration(seconds: 5));

      expect(response.statusCode, 200);
      expect(tokens.refreshes, 1);
    });

    test('a 401 from inside the refresh starts no nested refresh', () async {
      final tokens = _Tokens();
      late final _Client client;
      final server = _Server(tokens);
      client = _Client(
        server,
        HttpClientConfig(
          auth: tokens.config(
            refresh: () async {
              tokens.refreshes++;
              await client.dio.get<dynamic>('/refresh');
              return true;
            },
          ),
        ),
      );

      final error = await _failure(
        client.dio.get<dynamic>('/x').timeout(const Duration(seconds: 5)),
      );

      expect(error.response?.statusCode, 401);
      expect(tokens.refreshes, 1);
      expect(tokens.failures, 1);
    });
  });
}

/// An exception handler that records the status of every error it sees.
class _CountingHandler extends DefaultNetworkExceptionHandlerInterceptor {
  new(this.handled);

  final List<int?> handled;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handled.add(err.response?.statusCode);
    super.onError(err, handler);
  }
}
```

- [ ] **Step 2: Add the chain and reuse tests**

```diff
diff --git a/dart_falconnect/test/engine/https/base_http_client_configure_test.dart b/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
--- a/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
+++ b/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
@@ -1,3 +1,4 @@
+import 'dart:async';
 import 'dart:convert';
 
 import 'package:dart_falconnect/dart_falconnect.dart';
@@ -709,6 +710,40 @@ void main() {
     await expectLater(client.dio.get<dynamic>('/x'), completes);
   });
   group('request stamp and token refresh', () {
+    AuthConfig auth() =>
+        AuthConfig(accessToken: () => 't', refresh: () async => true);
+
+    test('the stamp comes first and the refresh after the rate limiter', () {
+      final custom = _ErrorSpy();
+      final client = _Client(ScriptedAdapter([reply(200)]))
+        ..configure(
+          HttpClientConfig(
+            interceptors: [custom],
+            log: const LogConfig(),
+            cache: const CacheConfig(),
+            concurrency: const ConcurrencyConfig(global: 4),
+            rateLimit: const RateLimitConfig.pauseOnly(),
+            retry: const RetryConfig(),
+            requestId: const RequestIdConfig(),
+            auth: auth(),
+          ),
+        );
+      addTearDown(client.dispose);
+
+      expect(client.interceptors.map((i) => '${i.runtimeType}'), [
+        'ImplyContentTypeInterceptor',
+        'RequestStampInterceptor',
+        '_ErrorSpy',
+        'HttpLogInterceptor',
+        'CacheInterceptor',
+        'ConcurrencyLimitInterceptor',
+        'RetryAfterPauseInterceptor',
+        'TokenRefreshInterceptor',
+        'RetryInterceptor',
+        'DefaultNetworkExceptionHandlerInterceptor',
+      ]);
+    });
+
     test('a request ID or a header provider alone builds only the stamp', () {
       final client = _Client(ScriptedAdapter([reply(200)]))
         ..configure(const HttpClientConfig(requestId: RequestIdConfig()));
@@ -723,5 +758,71 @@ void main() {
 
       expect(client.interceptors.map((i) => '${i.runtimeType}'), withId);
     });
+
+    test('an unchanged auth box keeps its session; new closures build a new '
+        'one', () {
+      final client = _Client(ScriptedAdapter([reply(200)]))
+        ..configure(HttpClientConfig(auth: auth()));
+      RequestStampInterceptor stamp() =>
+          client.interceptors.whereType<RequestStampInterceptor>().single;
+      TokenRefreshInterceptor refresh() =>
+          client.interceptors.whereType<TokenRefreshInterceptor>().single;
+      final firstStamp = stamp();
+      final firstRefresh = refresh();
+
+      client.configure(client.currentConfig.copyWith(log: const LogConfig()));
+      expect(stamp(), same(firstStamp));
+
+      client.configure(
+        client.currentConfig.copyWith(requestId: const RequestIdConfig()),
+      );
+      expect(stamp(), isNot(same(firstStamp)));
+      expect(stamp().auth, same(firstRefresh.session));
+      expect(refresh(), same(firstRefresh));
+
+      client.configure(client.currentConfig.copyWith(auth: auth()));
+      expect(refresh(), isNot(same(firstRefresh)));
+      expect(refresh().session, isNot(same(firstRefresh.session)));
+      expect(stamp().auth, same(refresh().session));
+    });
+
+    test('a refresh that runs across a configure finishes once, and its '
+        're-send passes the new chain', () async {
+      var token = 'old';
+      var refreshes = 0;
+      final started = Completer<void>();
+      final gate = Completer<void>();
+      final adapter = ScriptedAdapter([reply(401), reply(200)]);
+      final client = _Client(adapter)
+        ..configure(
+          HttpClientConfig(
+            auth: AuthConfig(
+              accessToken: () => token,
+              refresh: () async {
+                refreshes++;
+                started.complete();
+                await gate.future;
+                token = 'new';
+                return true;
+              },
+            ),
+          ),
+        );
+
+      final request = client.dio.get<dynamic>('/x');
+      await started.future;
+      client.configure(
+        client.currentConfig.copyWith(
+          requestId: RequestIdConfig(generate: () => 'id-1'),
+        ),
+      );
+      gate.complete();
+      final response = await request;
+
+      expect(response.statusCode, 200);
+      expect(refreshes, 1);
+      expect(adapter.requests[1].headers['authorization'], 'Bearer new');
+      expect(adapter.requests[1].headers['x-request-id'], 'id-1');
+    });
   });
 }
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `dart test test/engine/https/interceptors/token_refresh_interceptor_test.dart test/engine/https/base_http_client_configure_test.dart`
Expected: FAIL. The configure file fails to compile, because `TokenRefreshInterceptor` is not defined. The refresh file compiles, and 15 of its 17 tests fail: a request that expects a re-send gets `Status code: 401`, or a count reads `Expected: <1> Actual: <0>`. The two tests that expect a 401 to pass on already pass.

- [ ] **Step 4: Add the re-send bookkeeping**

```diff
diff --git a/dart_falconnect/lib/src/engine/https/interceptors/auth_extra.dart b/dart_falconnect/lib/src/engine/https/interceptors/auth_extra.dart
--- a/dart_falconnect/lib/src/engine/https/interceptors/auth_extra.dart
+++ b/dart_falconnect/lib/src/engine/https/interceptors/auth_extra.dart
@@ -1,6 +1,7 @@
 import 'package:dio/dio.dart';
 
 const String _tokenKey = 'dart_falconnect.auth.token';
+const String _resentKey = 'dart_falconnect.auth.resent';
 
 /// The token a request carried. `toString` hides it, because the pretty
 /// log prints `extra`.
@@ -25,4 +26,18 @@ extension AuthExtra on RequestOptions {
   set stampedToken(String? token) => extra = token == null
       ? ({...extra}..remove(_tokenKey))
       : {...extra, _tokenKey: _StampedToken(token)};
+
+  /// Whether `TokenRefreshInterceptor` sent this request again after a
+  /// refresh.
+  bool get isAuthResend => extra[_resentKey] == true;
+
+  /// A copy of these options marked as a re-send, with a `FormData` body
+  /// cloned so it can be sent again.
+  RequestOptions authResend() {
+    final body = data;
+    return copyWith(
+      data: body is FormData ? body.clone() : body,
+      extra: {...extra, _resentKey: true},
+    );
+  }
 }
```

- [ ] **Step 5: Create `TokenRefreshInterceptor`**

`dart_falconnect/lib/engine/https/interceptors/token_refresh_interceptor.dart`:

```dart
import 'dart:async';

import 'package:dart_falconnect/engine/https/extensions/use_token_extensions.dart';
import 'package:dart_falconnect/engine/https/interceptors/auth_session.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/auth_extra.dart';
import 'package:dio/dio.dart';

/// Refreshes the access token on a 401 and sends the request again.
///
/// It acts only on a 401 to a request that carried a token stamped by
/// `RequestStampInterceptor` of the same [session], whose `useToken` is
/// true, that is not a re-send, not sent from inside the refresh, and whose
/// token did not already fail to refresh. Any other error passes on.
///
/// Many 401s at once share one refresh. A request whose token is already
/// older than the current one is sent again without a refresh. The re-send
/// passes the whole chain, taking a new concurrency slot and rate-limit
/// token; its response resolves the request, and its error rejects it
/// without the rest of this chain, which the re-send already passed.
///
/// `BaseHttpClient` places it after the rate limiter and before
/// `RetryInterceptor`, so a 401 attempt gives its slot back and reaches the
/// log like any failure, and never enters the retry loop.
class TokenRefreshInterceptor extends Interceptor {
  /// Creates a refresh interceptor. [dio] sends the re-sends.
  new({required this.session, required this.dio});

  /// The session shared with the stamp.
  final AuthSession session;

  /// The Dio that sends each re-send.
  final Dio dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final token = options.stampedToken;
    if (err.response?.statusCode != 401 ||
        !options.useToken ||
        token == null ||
        session.isInsideRefresh ||
        session.isFailedToken(token)) {
      handler.next(err);
      return;
    }
    if (options.isAuthResend) {
      session.fail(token, err);
      handler.next(err);
      return;
    }
    if (!await _hasNewerToken(token, err)) {
      handler.next(err);
      return;
    }
    if (options.data is Stream || (options.cancelToken?.isCancelled ?? false)) {
      handler.next(err);
      return;
    }
    final RequestOptions resend;
    try {
      resend = options.authResend();
    } on Object {
      // A FormData whose files cannot be read again.
      handler.next(err);
      return;
    }
    try {
      // dynamic keeps the caller's responseType; any other type argument
      // makes dio overwrite it.
      handler.resolve(await dio.fetch<dynamic>(resend));
    } on DioException catch (error) {
      handler.reject(error);
    }
  }

  /// Whether a token newer than [token] is ready: another request already
  /// refreshed, or this call's refresh succeeded.
  Future<bool> _hasNewerToken(String token, DioException err) async {
    final String? current;
    try {
      current = await session.config.accessToken();
    } on Object {
      return false;
    }
    if (current != null && current != token) return true;
    return session.refreshFor(token, err);
  }
}
```

- [ ] **Step 6: Export it and place it after the rate limiter**

```diff
diff --git a/dart_falconnect/lib/engine/https/interceptors/interceptors.dart b/dart_falconnect/lib/engine/https/interceptors/interceptors.dart
--- a/dart_falconnect/lib/engine/https/interceptors/interceptors.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/interceptors.dart
@@ -11,3 +11,4 @@ export 'request_stamp_interceptor.dart';
 export 'retry_after_pause_interceptor.dart';
 export 'retry_interceptor.dart';
 export 'token_bucket_rate_limit_interceptor.dart';
+export 'token_refresh_interceptor.dart';
```

```diff
diff --git a/dart_falconnect/lib/engine/https/http_client.dart b/dart_falconnect/lib/engine/https/http_client.dart
--- a/dart_falconnect/lib/engine/https/http_client.dart
+++ b/dart_falconnect/lib/engine/https/http_client.dart
@@ -5,9 +5,9 @@ import 'package:dart_falconnect/lib.dart';
 ///
 /// The client orders the interceptor chain itself: the request stamp when
 /// `requestId`, `headerProvider`, or `auth` is set, the config's own
-/// `interceptors`, then log, cache, concurrency limit, rate limit, retry,
-/// the cache's offline fallback when its box enables it, and the exception
-/// handler last. [configure] applies a new
+/// `interceptors`, then log, cache, concurrency limit, rate limit, token
+/// refresh, retry, the cache's offline fallback when its box enables it,
+/// and the exception handler last. [configure] applies a new
 /// configuration to requests that start after it returns; requests already
 /// running finish on the configuration they started with. Interceptors
 /// whose box is unchanged are kept, with their state.
@@ -35,6 +35,7 @@ abstract class BaseHttpClient implements RequestApiService {
   HttpClientConfig? _config;
   AuthSession? _session;
   RequestStampInterceptor? _stamp;
+  TokenRefreshInterceptor? _refresh;
   Interceptor? _log;
   CacheInterceptor? _cache;
   ConcurrencyLimitInterceptor? _concurrency;
@@ -73,6 +74,11 @@ abstract class BaseHttpClient implements RequestApiService {
       (box) => AuthSession(box, logPrint: _diagnostic),
     );
     final stamp = _buildStamp(previous, config, session);
+    final refresh = session == null
+        ? null
+        : identical(session, _session) && _refresh != null
+        ? _refresh
+        : TokenRefreshInterceptor(session: session, dio: _dio);
     final log = _keepOrBuild(previous?.log, config.log, _log, _buildLog);
     final cache = _keepOrBuild(
       previous?.cache,
@@ -113,6 +119,7 @@ abstract class BaseHttpClient implements RequestApiService {
         ?cache,
         ?concurrency,
         ?rateLimit,
+        ?refresh,
         ?retry,
         ?cacheFallback,
         config.exceptionHandler ?? _defaultExceptionHandler,
@@ -120,6 +127,7 @@ abstract class BaseHttpClient implements RequestApiService {
     _config = config;
     _session = session;
     _stamp = stamp;
+    _refresh = refresh;
     _log = log;
     _cache = cache;
     _concurrency = concurrency;
```

- [ ] **Step 7: Run the tests to verify they pass**

Run: `dart test test/engine/https/interceptors/token_refresh_interceptor_test.dart test/engine/https/base_http_client_configure_test.dart && dart analyze`
Expected: `+52: All tests passed!` (17 refresh tests, 35 configure tests) and `No issues found!`

- [ ] **Step 8: Check that the key tests catch their bug**

Make each change below, run the named test with `dart test test/engine/https/interceptors/token_refresh_interceptor_test.dart -N "<name>"`, confirm it FAILS, then undo the change with `git checkout -- <file>` before the next one.

| Change | File | Test name | Failure |
|---|---|---|---|
| `handler.reject(error);` becomes `handler.next(error);` | `token_refresh_interceptor.dart` | `a failed re-send` | `Actual: [500, 500, 500, 500]` |
| delete `if (running != null) return running;` | `auth_session.dart` | `many 401s at once` | `Expected: <1> Actual: <5>` |
| `running == null \|\| isInsideRefresh` becomes `running == null` | `auth_session.dart` | `does not deadlock` | `TimeoutException after 0:00:05` |
| `session.isFailedToken(token)) {` becomes `false) {` | `token_refresh_interceptor.dart` | `a later 401 with the token` | a second refresh |
| delete `if (current != null && current != token) return true;` | `token_refresh_interceptor.dart` | `arrives after another refresh` | a second refresh |

Run: `git status --short`
Expected: no change left in `lib/`.

- [ ] **Step 9: Run the whole package**

Run: `dart test`
Expected: `+351 ~1: All tests passed!`

- [ ] **Step 10: Commit**

```bash
S=dart_falconnect/lib/src/engine/https/interceptors/auth_extra.dart
I=dart_falconnect/lib/engine/https/interceptors
T=dart_falconnect/test/engine/https
git add $S $I/token_refresh_interceptor.dart $I/interceptors.dart dart_falconnect/lib/engine/https/http_client.dart $T/interceptors/token_refresh_interceptor_test.dart $T/base_http_client_configure_test.dart
git commit -m "feat(dart_falconnect): refresh the token once on a 401 and send the request again" -- $S $I/token_refresh_interceptor.dart $I/interceptors.dart dart_falconnect/lib/engine/https/http_client.dart $T/interceptors/token_refresh_interceptor_test.dart $T/base_http_client_configure_test.dart
```

---

### Task 4: Request ID and re-send in both logs

**Files:**
- Modify: `dart_falconnect/lib/engine/https/interceptors/http_json_log_interceptor.dart`
- Modify: `dart_falconnect/lib/engine/https/interceptors/log_interceptor.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/request_stamp_interceptor_test.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/token_refresh_interceptor_test.dart`

**Interfaces:**
- Consumes: `RequestOptions.requestId` (Task 2), `AuthExtra.isAuthResend` (Task 3).
- Produces: JSON fields `falconx.request.id` (string, when the request has an ID) and `falconx.auth.resent` (`true` on a re-send); the pretty request title `*** Request <id> ***`.

- [ ] **Step 1: Write the failing log tests**

```diff
diff --git a/dart_falconnect/test/engine/https/interceptors/request_stamp_interceptor_test.dart b/dart_falconnect/test/engine/https/interceptors/request_stamp_interceptor_test.dart
--- a/dart_falconnect/test/engine/https/interceptors/request_stamp_interceptor_test.dart
+++ b/dart_falconnect/test/engine/https/interceptors/request_stamp_interceptor_test.dart
@@ -357,4 +357,25 @@ void main() {
       expect(adapter.requests, isEmpty);
     });
   });
+  group('logs', () {
+    test('the pretty log prints the request ID in the request title and '
+        'never the token', () async {
+      final lines = <Object?>[];
+      final client = _Client(
+        ScriptedAdapter([reply(200)]),
+        HttpClientConfig(
+          log: LogConfig(logPrint: lines.add, requestHeader: true),
+          requestId: RequestIdConfig(generate: () => 'id-1'),
+          auth: _auth(() => 'secret-token'),
+        ),
+      );
+
+      await client.dio.get<dynamic>('/x');
+
+      final text = lines.join('\n');
+      expect(text, contains('*** Request id-1 ***'));
+      expect(text, contains('dart_falconnect.auth.token: REDACTED'));
+      expect(text, isNot(contains('secret-token')));
+    });
+  });
 }
```

```diff
diff --git a/dart_falconnect/test/engine/https/interceptors/token_refresh_interceptor_test.dart b/dart_falconnect/test/engine/https/interceptors/token_refresh_interceptor_test.dart
--- a/dart_falconnect/test/engine/https/interceptors/token_refresh_interceptor_test.dart
+++ b/dart_falconnect/test/engine/https/interceptors/token_refresh_interceptor_test.dart
@@ -420,6 +420,31 @@ void main() {
       expect(concurrency.forwarded, 2);
       expect(rateLimit.forwarded, 2);
     });
+
+    test('the JSON log prints both attempts with one request ID', () async {
+      final lines = <Object?>[];
+      final tokens = _Tokens();
+      final server = _Server(tokens);
+      final client = _Client(
+        server,
+        HttpClientConfig(
+          log: LogConfig.json(logPrint: lines.add, diagnostics: false),
+          requestId: RequestIdConfig(generate: () => 'id-1'),
+          auth: tokens.config(),
+        ),
+      );
+
+      await client.dio.get<dynamic>('/x');
+
+      final fields = [
+        for (final line in lines) jsonDecode(line! as String) as Map,
+      ];
+      expect(fields, hasLength(2));
+      expect(fields.map((f) => f['falconx.request.id']), ['id-1', 'id-1']);
+      expect(fields[0]['http.response.status_code'], 401);
+      expect(fields[0], isNot(contains('falconx.auth.resent')));
+      expect(fields[1]['falconx.auth.resent'], isTrue);
+    });
   });
 
   group('zone guard', () {
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart test test/engine/https/interceptors/request_stamp_interceptor_test.dart test/engine/https/interceptors/token_refresh_interceptor_test.dart -N "log"`
Expected: FAIL, two tests. The pretty-log test prints `*** Request ***` where it expects `*** Request id-1 ***`; the JSON test gets `[null, null]` where it expects `['id-1', 'id-1']`.

- [ ] **Step 3: Add the fields to the JSON log**

```diff
diff --git a/dart_falconnect/lib/engine/https/interceptors/http_json_log_interceptor.dart b/dart_falconnect/lib/engine/https/interceptors/http_json_log_interceptor.dart
--- a/dart_falconnect/lib/engine/https/interceptors/http_json_log_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/http_json_log_interceptor.dart
@@ -3,7 +3,9 @@ import 'dart:convert';
 import 'package:dart_falconnect/engine/https/config/log_config.dart';
 import 'package:dart_falconnect/engine/https/interceptors/cache_interceptor.dart';
 import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
+import 'package:dart_falconnect/engine/https/interceptors/request_stamp_interceptor.dart';
 import 'package:dart_falconnect/engine/https/interceptors/retry_interceptor.dart';
+import 'package:dart_falconnect/src/engine/https/interceptors/auth_extra.dart';
 import 'package:dart_falconnect/src/engine/https/interceptors/log_redaction.dart';
 import 'package:dart_faltool/dart_faltool.dart' show clock;
 import 'package:dio/dio.dart';
@@ -129,6 +131,8 @@ class HttpJsonLogInterceptor extends Interceptor {
       'error.type': ?outcome.errorType,
       'http.client.request.duration': seconds,
       if (resendCount > 0) 'http.request.resend_count': resendCount,
+      'falconx.request.id': ?options.requestId,
+      if (options.isAuthResend) 'falconx.auth.resent': true,
       if (cacheHit) 'falconx.cache.hit': true,
       if (response?.isLocalRateLimit ?? false) 'falconx.rate_limit.local': true,
       if (config.requestHeaders) ..._headers('request', options.headers),
```

- [ ] **Step 4: Put the ID in the pretty request title**

```diff
diff --git a/dart_falconnect/lib/engine/https/interceptors/log_interceptor.dart b/dart_falconnect/lib/engine/https/interceptors/log_interceptor.dart
--- a/dart_falconnect/lib/engine/https/interceptors/log_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/log_interceptor.dart
@@ -80,7 +80,8 @@ class HttpLogInterceptor extends Interceptor {
     // A new map: extra may be const.
     options.extra = {...options.extra, logStartKey: clock.now()};
     if (enabled) {
-      logPrint(_title('*** Request ***'));
+      final id = options.requestId;
+      logPrint(_title(id == null ? '*** Request ***' : '*** Request $id ***'));
       _printKV('URL', _url(options.uri));
 
       if (request) {
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `dart test && dart analyze`
Expected: `+353 ~1: All tests passed!` and `No issues found!`

- [ ] **Step 6: Commit**

```bash
I=dart_falconnect/lib/engine/https/interceptors
T=dart_falconnect/test/engine/https/interceptors
git add $I/http_json_log_interceptor.dart $I/log_interceptor.dart $T/request_stamp_interceptor_test.dart $T/token_refresh_interceptor_test.dart
git commit -m "feat(dart_falconnect): log the request ID and mark the re-send after a refresh" -- $I/http_json_log_interceptor.dart $I/log_interceptor.dart $T/request_stamp_interceptor_test.dart $T/token_refresh_interceptor_test.dart
```

---

### Task 5: Retrofit fixture for `@noToken`

**Files:**
- Modify: `dart_falconnect/build.yaml`
- Create: `dart_falconnect/test/engine/https/retrofit/no_token_api.dart`
- Create: `dart_falconnect/test/engine/https/retrofit/no_token_api_test.dart`
- Generated: `dart_falconnect/test/engine/https/retrofit/generated/no_token_api.g.dart`
- Modify: `CLAUDE.md` (repository root)

**Interfaces:**
- Consumes: `noToken`, `useTokenExtraKey` (Task 1); the stamp (Task 2).

- [ ] **Step 1: Write the fixture and its test**

Create `no_token_api.dart`:

`dart_falconnect/test/engine/https/retrofit/no_token_api.dart`:

```dart
import 'package:dart_falconnect/dart_falconnect.dart';

part 'generated/no_token_api.g.dart';

/// A Retrofit API that proves `@noToken` and `@Extras()` reach the auth
/// interceptors through generated code.
@RestApi()
abstract class NoTokenApi {
  factory(Dio dio) = _NoTokenApi;

  @GET('/public')
  @noToken
  Future<void> public();

  @GET('/private')
  Future<void> private();

  @GET('/extras')
  Future<void> withExtras(@Extras() Map<String, dynamic> extras);
}
```

Create `no_token_api_test.dart`:

`dart_falconnect/test/engine/https/retrofit/no_token_api_test.dart`:

```dart
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

import '../interceptors/_scripted_adapter.dart';
import 'no_token_api.dart';

class _Client extends BaseHttpClient {
  new(HttpClientAdapter adapter)
    : super(
        dio: Dio()
          ..httpClientAdapter = adapter
          ..transformer = FoldingTransformer(),
        config: HttpClientConfig(
          auth: AuthConfig(accessToken: () => 't1', refresh: () async => false),
        ),
      );
}

void main() {
  late ScriptedAdapter adapter;
  late NoTokenApi api;

  setUp(() {
    adapter = ScriptedAdapter([reply(200)]);
    api = NoTokenApi(_Client(adapter).dio);
  });

  test('an endpoint without an annotation sends the token', () async {
    await api.private();

    expect(adapter.requests.single.headers['authorization'], 'Bearer t1');
  });

  test('@noToken sends no token', () async {
    await api.public();

    expect(adapter.requests.single.headers, isNot(contains('authorization')));
    expect(adapter.requests.single.useToken, isFalse);
  });

  test('@Extras() with useTokenExtraKey false sends no token', () async {
    await api.withExtras({useTokenExtraKey: false});

    expect(adapter.requests.single.headers, isNot(contains('authorization')));
  });
}
```

- [ ] **Step 2: Run the generator and the test to verify they fail**

Run: `dart run build_runner build --delete-conflicting-outputs && dart test test/engine/https/retrofit`
Expected: the build writes no `generated/no_token_api.g.dart`, because the combining builder maps only `lib/` paths, and the test fails to load: `Error when reading 'test/engine/https/retrofit/generated/no_token_api.g.dart': No such file or directory`.

- [ ] **Step 3: Map `test/` paths in the combining builder**

```diff
diff --git a/dart_falconnect/build.yaml b/dart_falconnect/build.yaml
--- a/dart_falconnect/build.yaml
+++ b/dart_falconnect/build.yaml
@@ -9,6 +9,7 @@ targets:
         options:
           build_extensions:
             'lib/{{path}}/{{file}}.dart': 'lib/{{path}}/generated/{{file}}.g.dart'
+            'test/{{path}}/{{file}}.dart': 'test/{{path}}/generated/{{file}}.g.dart'
       freezed:
         enabled: true
         options:
```

- [ ] **Step 4: Generate and run the test to verify it passes**

Run: `dart run build_runner build --delete-conflicting-outputs && dart test test/engine/https/retrofit && dart analyze`
Expected: `test/engine/https/retrofit/generated/no_token_api.g.dart` exists and contains `final _extra = <String, dynamic>{'dart_falconnect.auth.useToken': false};` for `public()`; `+3: All tests passed!`; `No issues found!`

- [ ] **Step 5: Record the new generated path in the root `CLAUDE.md`**

```diff
diff --git a/CLAUDE.md b/CLAUDE.md
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -74,7 +74,7 @@ Scripts live under the `melos:` key of the root `pubspec.yaml` (there is no `mel
 
 ### Code generation
 
-- Generated files land in `lib/{{path}}/generated/{{file}}.g.dart` or `.freezed.dart`, per each package's `build.yaml`.
+- Generated files land in `lib/{{path}}/generated/{{file}}.g.dart` or `.freezed.dart`, per each package's `build.yaml`. `dart_falconnect` also generates Retrofit test fixtures into `test/{{path}}/generated/{{file}}.g.dart`.
 - Run `melos run build_runner` after editing a `@freezed` or `@JsonSerializable` class, and `melos run build_runner:check` before committing.
 
 ## Gotchas
```

- [ ] **Step 6: Commit**

```bash
R=dart_falconnect/test/engine/https/retrofit
git add dart_falconnect/build.yaml $R CLAUDE.md
git commit -m "test(dart_falconnect): prove @noToken through a generated Retrofit fixture" -- dart_falconnect/build.yaml $R CLAUDE.md
```

---

### Task 6: Consumer skill, package docs, and final gates

**Files:**
- Modify: `skills/dart-falconx-package/references/http.md`
- Modify: `skills/dart-falconx-package/SKILL.md`
- Modify: `dart_falconnect/CLAUDE.md`

**Interfaces:**
- Consumes: every public name of Tasks 1 to 4.

- [ ] **Step 1: Update `references/http.md`**

````diff
diff --git a/skills/dart-falconx-package/references/http.md b/skills/dart-falconx-package/references/http.md
--- a/skills/dart-falconx-package/references/http.md
+++ b/skills/dart-falconx-package/references/http.md
@@ -46,7 +46,11 @@ final prod = HttpClientConfig(
     perHost: [TokenBucketPolicy(permits: 100, per: const Duration(minutes: 1))],
   ),
   retry: const RetryConfig(),
-  interceptors: [AuthInterceptor(tokenStore)],
+  auth: AuthConfig(
+    accessToken: tokenStore.read,
+    refresh: tokenStore.refresh,
+    onAuthFailed: (_) => router.go('/login'),
+  ),
 );
 
 void main() {
@@ -72,9 +76,11 @@ client.setupBaseUrl('https://staging.api.example.com');
 | `ConcurrencyConfig`                                              | `ConcurrencyLimitInterceptor`                                                                      | every scope unlimited                                                                                                                                                                |
 | `RateLimitConfig.none()`, `.pauseOnly(...)`, `.tokenBucket(...)` | nothing, `RetryAfterPauseInterceptor`, or `TokenBucketRateLimitInterceptor`; never both limiters   | `none()`                                                                                                                                                                             |
 | `RetryConfig`                                                    | `RetryInterceptor`                                                                                 | 3 attempts, 1 s base delay, 30 s cap, 60 s deadline                                                                                                                                  |
+| `RequestIdConfig`                                                | the ID step of `RequestStampInterceptor` (see "Auth and request headers")                         | `X-Request-ID`, UUID v7                                                                                                                                                              |
+| `AuthConfig`                                                     | the token step of `RequestStampInterceptor`, plus `TokenRefreshInterceptor`                        | `Authorization: Bearer <token>`                                                                                                                                                      |
 
 - `LogConfig` is a sealed union of `PrettyLogConfig` (`LogConfig(...)`) and `JsonLogConfig` (`LogConfig.json(...)`). `request`, `requestHeader`, `responseHeader`, and `error` exist only on the pretty variant, so match it before reading or copying them: `if (config.log case final PrettyLogConfig log) client.configure(config.copyWith(log: log.copyWith(responseHeader: true)));`.
-- The client orders the chain: your `interceptors`, log, cache, concurrency limit, rate limit, retry, the cache's offline fallback when its box enables it, then `exceptionHandler` (null means `DefaultNetworkExceptionHandlerInterceptor`).
+- The client orders the chain: `RequestStampInterceptor` when `requestId`, `headerProvider`, or `auth` is set, your `interceptors`, log, cache, concurrency limit, rate limit, `TokenRefreshInterceptor` when `auth` is set, retry, the cache's offline fallback when its box enables it, then `exceptionHandler` (null means `DefaultNetworkExceptionHandlerInterceptor`).
 - `configure` owns `baseUrl`, the three timeouts, `contentType`, redirects, `validateStatus` (null means dio's default, 2xx only), and the header keys of `headers` and `userAgent`. Other `dio.options` fields, and headers you set by hand, survive it.
 - Add interceptors with `addInterceptors` or the config, never with `dio.interceptors.add(...)`: `configure` rebuilds the list.
 - When the client switches base URLs, give Retrofit APIs no absolute `baseUrl`, neither as the factory argument nor in `@RestApi(baseUrl:)`. An absolute one wins over `dio.options.baseUrl`.
@@ -82,6 +88,46 @@ client.setupBaseUrl('https://staging.api.example.com');
 - The next attempt of a request that was retrying across a `configure` passes the new chain, with its old retry settings.
 - Call `dispose()` at the end of a test or a CLI. A Flutter app never needs it.
 
+## Auth and request headers
+
+Three `HttpClientConfig` fields stamp headers on every attempt, in this order, before your `interceptors` run. Each is null, and off, by default.
+
+```dart
+DefaultHttpClient.instance.configure(
+  HttpClientConfig(
+    baseUrl: Env.apiBaseUrl,
+    headerProvider: (options) => {'Accept-Language': locale.current},
+    requestId: const RequestIdConfig(),
+    auth: AuthConfig(
+      accessToken: () => tokenStore.access,        // FutureOr<String?>
+      refresh: tokenStore.refresh,                 // Future<bool>
+      onAuthFailed: (error) => router.go('/login'),
+    ),
+  ),
+);
+```
+
+- `requestId` stamps one ID per request under `headerName` (default `X-Request-ID`): a UUID v7, or `generate()`. Every retry attempt and the re-send after a refresh keep the first attempt's ID; a request that sets the header keeps its own value. Read it with `requestOptions.requestId`. On the web, a custom header makes the browser send a CORS preflight, so the server must list it in `Access-Control-Allow-Headers`. Never add it to `CacheConfig.keyHeaders`, or every request misses the cache.
+- `headerProvider` runs for every attempt and may be async. Its headers override `headers` and lose to headers the request sets itself; on a retry it runs again and overwrites the values it wrote before.
+- `auth` writes `Authorization: Bearer <accessToken()>` (`headerName` and `scheme` change it; `scheme: ''` sends the bare token). It overwrites any `Authorization` the request set; to send your own, pass `isUseToken: false`. A null token sends no header. The app owns the token: refresh before expiry inside `accessToken()` if you want it.
+- On a 401 to a request that carried a token, `TokenRefreshInterceptor` calls `refresh()` once for every request failing at the same time, then sends each again with the new token. A request whose token is already older than the current one is sent again without a refresh, and a request that starts during a refresh waits for it.
+- When `refresh()` returns false or throws, `onAuthFailed` runs once and every waiting request fails with its 401, mapped as any 401. A re-send that gets a 401 again also calls `onAuthFailed`. Later 401s with the same failed token neither refresh nor call it again. `onAuthFailed` is not awaited.
+- Requests sent from inside `refresh()` never wait for the refresh and never refresh, so calling your refresh endpoint through the same client does not deadlock. Still send it with `isUseToken: false` or a separate `Dio`.
+- A `Stream` body refreshes but is not sent again. A `FormData` body is cloned for the re-send.
+- Retrofit requests get all of this through the client's `dio`. Turn the token off on an endpoint with `@noToken`, or per call with `@Extras()`:
+
+```dart
+@GET('/public/news')
+@noToken
+Future<List<NewsDto>> news();
+
+@GET('/feed')
+Future<List<NewsDto>> feed(@Extras() Map<String, dynamic> extras);
+// api.feed({useTokenExtraKey: false});
+```
+
+- `AuthConfig` holds functions, which compare by identity. `copyWith` keeps them, so an unrelated `configure` keeps the running refresh; a config built with new closures builds a new `AuthSession` and forgets the failed token.
+
 ## Custom client: subclass `BaseHttpClient`
 
 Write one client class per external system, and pass its configuration to the super constructor:
@@ -130,7 +176,7 @@ Every method takes `converter: (Map<String, dynamic> json) => T` and returns `Fu
 | `postFormData<T>`, `putFormData<T>`   | `data: FormData?`                                       | same                                                                                         |
 | `delete<T>`                           | `data: BaseRequestBody?`                                | `queryParameters`, `cancelToken`                                                             |
 
-Every method accepts a converter that may be async. `catchError: (DioException e, StackTrace? st) => T?` returns a fallback value, and returning `null` rethrows the original error; a failure with no response, such as a timeout or a lost connection, recovers too. A body that is not a JSON object, or a converter that throws, fails with a `DioException` whose `error` is `CommonException(type: InputErrorType.invalidFormat)`, and `catchError` sees it. `isUseToken: false` sets `requestOptions.useToken` to false for your auth interceptor; `useToken` reads true when unset, Retrofit requests included.
+Every method accepts a converter that may be async. `catchError: (DioException e, StackTrace? st) => T?` returns a fallback value, and returning `null` rethrows the original error; a failure with no response, such as a timeout or a lost connection, recovers too. A body that is not a JSON object, or a converter that throws, fails with a `DioException` whose `error` is `CommonException(type: InputErrorType.invalidFormat)`, and `catchError` sees it. `isUseToken: false` sets `requestOptions.useToken` to false, so the auth interceptors neither stamp nor refresh a token; `useToken` reads true when unset, Retrofit requests included, and `@noToken` turns it off there.
 
 ```dart
 final res = await client.get<UserDto>('/users/$id', converter: UserDto.fromJson);
@@ -141,6 +187,9 @@ final user = res.data;
 
 | Class                                       | Constructor                                                                                                                                                                                                         | Behaviour                                                                                                                                                                                                                                                                                                                                                                         |
 |---------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
+| `RequestStampInterceptor`                   | `(requestId:, headerProvider:, auth:, dio:)` | stamps the request ID, the provider's headers, and the token on every attempt; a throwing callback fails the request with a `DioException` of type `unknown` naming the callback |
+| `TokenRefreshInterceptor`                   | `(session:, dio:)` | on a 401 to a request that carried a token: one refresh for all concurrent 401s, then a re-send through the whole chain; resolves with the re-send's response or rejects with its error |
+| `AuthSession`                               | `(config, logPrint:)` | not an interceptor: the refresh state both auth interceptors share; pass one session to both in a hand-built chain |
 | `RetryInterceptor`                          | `(config: RetryConfig(maxAttempts: 3, delay: 1 s, maxDelay: 30 s, maxDuration: 60 s, onRetry:), dio:, logPrint:, random:)`                                                                                          | loops up to `retryAttempts ?? config.maxAttempts`; 429 and `connectionTimeout` for every method; timeouts, connection errors, 408/409/5xx only for idempotent methods unless `retryNonIdempotent`; `Retry-After` on 429/503 (not retried above `maxDelay`), else full jitter; stops at `config.maxDuration`; never retries cancels, local 429s, `Stream` bodies, bad certificates |
 | `CacheInterceptor`                          | `(config: CacheConfig(policy: CachePolicy.request, maxStale:, maxSize: 50 MB, store:, keyHeaders: {authorization, accept, accept-language}, hitCacheOnNetworkFailure: false, hitCacheOnErrorCodes: {}), logPrint:)` | `dio_cache_interceptor` underneath; follows `Cache-Control`, `Expires`, `ETag`, and `Last-Modified`; a hit is decoded fresh from stored bytes, bound to the current request, passes every response interceptor, and reads `response.isCacheHit`; `store`, `clearCache()`, `fallback` (see "Caching")                                                                              |
 | `ConcurrencyLimitInterceptor`               | `(config: ConcurrencyConfig(global:, perHost:, hosts:, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500), logPrint:)`                                                                                 | most requests in flight per host and in total, on `resilience` `Bulkhead`; a null limit means none; full queue → local 429 with `BulkheadRejectedException` and no `Retry-After`; a retry or re-send reuses its request's slot; `getStatistics()`, `dispose()`                                                                                                                    |
@@ -163,12 +212,15 @@ The public model classes behind the interceptors (`ConcurrencyLimitStatistics`,
 
 ```dart
 final cache = CacheInterceptor();
+final session = AuthSession(authConfig);
 dio.interceptors.addAll([
+  RequestStampInterceptor(auth: session, dio: dio),
   cache,
   ConcurrencyLimitInterceptor(
     config: const ConcurrencyConfig(global: 16, perHost: 4),
   ),
   TokenBucketRateLimitInterceptor(), // or RetryAfterPauseInterceptor, never both
+  TokenRefreshInterceptor(session: session, dio: dio),
   RetryInterceptor(dio: dio),
   cache.fallback, // answers only when the box enables the offline fallback
   DefaultNetworkExceptionHandlerInterceptor(),
@@ -178,7 +230,9 @@ dio.interceptors.addAll([
 - `CacheInterceptor` comes first: a cache hit answers in `onRequest` before the limiters see the request, so it takes no concurrency slot and spends no token. The hit still passes every response interceptor, where the limiters find no slot to give back. Any interceptor that answers in `onRequest`, such as a cache or a mock, goes before `ConcurrencyLimitInterceptor`; placed after it, every answer it gives with a plain `resolve` keeps a slot forever. The cache's `fallback` goes after `RetryInterceptor`: it answers a failed request from the cache only after the last retry, and after `ConcurrencyLimitInterceptor.onError` has returned the slot.
 - `ConcurrencyLimitInterceptor` comes before the rate limiter: the slot is taken before the tokens, so the token ceiling holds on the wire and the pause gate sees every request. A request holds its slot while the rate limiter holds it, so set `perHost` below `global`, for example 4 and 16, so one slow or paused host cannot take every global slot.
 - The rate limiter comes before `RetryInterceptor`: dio runs `onError` in list order, so the limiter sees a server 429 and starts the pause before the retry is sent. The retry then passes the pause gate, and the total wait is the longer of the retry delay and the pause, never their sum.
-- An interceptor that re-sends from `onError`, such as an auth refresh, goes in your `interceptors` inside a `BaseHttpClient`, which places it before `ConcurrencyLimitInterceptor`. There the re-send reuses its request's slot, as long as the interceptor ends the error phase by the slot-safety rule below. In a chain you build by hand, it may also go after `ConcurrencyLimitInterceptor`.
+- `RequestStampInterceptor` comes first, so the log prints the stamped headers, the cache keys entries by the token, and your interceptors see every stamped header.
+- `TokenRefreshInterceptor` comes after the rate limiter and before `RetryInterceptor`: the 401 attempt gives its slot back and reaches the log like any failure, the re-send takes a new slot and a new token, and a 401 never enters the retry loop. It rejects a failed re-send without the rest of the chain, which the re-send already passed.
+- Use `auth` rather than your own refresh interceptor. One of your own that re-sends from `onError` goes in your `interceptors`, which a `BaseHttpClient` places before `ConcurrencyLimitInterceptor`. There the re-send reuses its request's slot, as long as the interceptor ends the error phase by the slot-safety rule below.
 - **Slot safety.** dio has no "request finished" hook, so `ConcurrencyLimitInterceptor` gives a slot back only when its own `onResponse` or `onError` runs, or when the request's `CancelToken` cancels. Keep both reachable:
   - Interceptors after it end `onRequest` with `handler.next(...)`, `handler.resolve(response, true)`, or `handler.reject(err, true)`. A plain `resolve` or `reject` skips the limiter's `onResponse` and `onError` (a cancel-type reject is safe). An auth interceptor that rejects when it has no token must pass `true`.
   - Interceptors before it end `onResponse` and `onError` with `handler.next(...)` or `handler.reject(err, true)`. A business-error interceptor that turns a 200 into a `DioException` must pass `true`, or go after the limiter. `handler.resolve(...)` in their `onError` is safe only with the response of a re-send of the same `RequestOptions`, which gives the slot back itself.
@@ -318,6 +372,8 @@ DefaultHttpClient.instance.configure(
 | `http.client.request.duration` | seconds, including time spent in the limiters' queues |
 | `http.request.resend_count` | on retries |
 | `falconx.cache.hit`, `falconx.rate_limit.local` | `true` on a cache hit, and on a 429 built by a limiter |
+| `falconx.request.id` | the request ID, when `requestId` is set |
+| `falconx.auth.resent` | `true` on the re-send after a token refresh |
 
 - Opt in to more with `LogConfig.json(requestHeaders: true, responseHeaders: true, requestBody: true, responseBody: true, maxBodyBytes: 4096)`. Headers appear as `http.request.header.<name>` lists; bodies as `falconx.request.body` and `falconx.response.body`, cut at `maxBodyBytes` UTF-8 bytes with a `.truncated` flag. Bodies are never redacted: turn them on only where they carry no personal data.
 - `redactHeaders` (default `defaultRedactedHeaders`) and `redactQueryParameters` (default `defaultRedactedQueryParameters`) apply to both log formats and compare names ignoring case. Extend them: `redactHeaders: {...defaultRedactedHeaders, 'x-tenant-secret'}`. Pass `const {}` to turn one off, for example in development.
````

- [ ] **Step 2: Update `SKILL.md`**

```diff
diff --git a/skills/dart-falconx-package/SKILL.md b/skills/dart-falconx-package/SKILL.md
--- a/skills/dart-falconx-package/SKILL.md
+++ b/skills/dart-falconx-package/SKILL.md
@@ -35,8 +35,9 @@ Retrofit, Freezed, and JsonSerializable codegen runs in the consumer project: `d
 |-------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|-----------------------------|
 | Typed REST client                               | Retrofit `@RestApi` on `DefaultHttpClient.instance.dio` or a `BaseHttpClient` subclass                                                                                                                                                                                                                                                                                                                     | dart_falconnect             | `references/http.md`        |
 | Converter-based HTTP                            | `BaseHttpClient.get/post/postFormData/patch/put/putFormData/delete` with `converter:`                                                                                                                                                                                                                                                                                                                      | dart_falconnect             | `references/http.md`        |
+| Auth token, 401 refresh, request headers        | `HttpClientConfig(auth: AuthConfig(...), requestId: RequestIdConfig(), headerProvider: ...)`; Retrofit `@noToken`, `useTokenExtraKey`                                                                                                                                                                                                                                                                          | dart_falconnect             | `references/http.md`        |
 | Client configuration                            | `HttpClientConfig` boxes (`LogConfig`, or `LogConfig.json` for a server), `configure`, `currentConfig`, `setupBaseUrl`                                                                                                                                                                                                                                                                                     | dart_falconnect             | `references/http.md`        |
-| Interceptors                                    | `RetryInterceptor`, `CacheInterceptor`, `ConcurrencyLimitInterceptor`, `TokenBucketRateLimitInterceptor`, `RetryAfterPauseInterceptor`, `HttpLogInterceptor`, `HttpJsonLogInterceptor`, `NetworkExceptionHandlerInterceptor`, `HttpClientConfig`; each takes its own config box                                                                                                                            | dart_falconnect             | `references/http.md`        |
+| Interceptors                                    | `RequestStampInterceptor`, `TokenRefreshInterceptor` (sharing an `AuthSession`), `RetryInterceptor`, `CacheInterceptor`, `ConcurrencyLimitInterceptor`, `TokenBucketRateLimitInterceptor`, `RetryAfterPauseInterceptor`, `HttpLogInterceptor`, `HttpJsonLogInterceptor`, `NetworkExceptionHandlerInterceptor`, `HttpClientConfig`; each takes its own config box                                                                                                                            | dart_falconnect             | `references/http.md`        |
 | WebSocket streams                               | `SocketClient`, `SocketBoundResource.asStream`, `SocketLogInterceptor`                                                                                                                                                                                                                                                                                                                                     | dart_falconnect             | `references/websocket.md`   |
 | JSON-RPC 2.0                                    | `JsonRpcService` / `DefaultJsonRpcService`: `request`, `notify`, `batch` returning `BatchJsonRpcItem`                                                                                                                                                                                                                                                                                                      | dart_falconnect             | `references/json-rpc.md`    |
 | Local-first repository                          | `DatasourceBoundState.asResultStream` and siblings                                                                                                                                                                                                                                                                                                                                                         | dart_falconnect             | `references/models.md`      |
@@ -65,7 +66,7 @@ Retrofit, Freezed, and JsonSerializable codegen runs in the consumer project: `d
 - `NetworkException` carries a `NetworkErrorType`; the general hierarchy uses `DefaultErrorType` enums. Do not mix them.
 - Hidden symbols: `dart_faltool` hides `dartx` `IterableAll`, `IterableAppend`, `IterableNumAverageExtension`, `IterableNumSumExtension`, `IterablePartition`, `IterableZip`, `MapOrEmpty`, `NumCoerceInRangeExtension`, `StringCapitalizeExtension` and `fpdart` `State`, `Task`. `dart_falconnect` hides Retrofit `Headers`, `Parser`, `CacheControl`; `import 'package:retrofit/retrofit.dart'` directly for `@Headers`.
 - `BaseRequestBody` subclasses must implement `Map<String, Object?> toJson()`; the HTTP methods call it.
-- Interceptor order (`BaseHttpClient` assembles it): your `interceptors`, `HttpLogInterceptor` or `HttpJsonLogInterceptor`, `CacheInterceptor`, `ConcurrencyLimitInterceptor`, the rate limiter, `RetryInterceptor`, the cache's offline fallback when enabled, then the exception handler. An auth refresh goes in your `interceptors`, where its re-send reuses its request's slot; error loggers go before `RetryInterceptor`. Interceptors after `ConcurrencyLimitInterceptor` end `onRequest`, and interceptors before it end `onResponse` and `onError`, with `next` or the call-following flag (`reject(err, true)`), or the slot leaks. See `references/http.md`. Dio's own `LogInterceptor` is a different class.
+- Interceptor order (`BaseHttpClient` assembles it): `RequestStampInterceptor` when `requestId`, `headerProvider`, or `auth` is set, your `interceptors`, `HttpLogInterceptor` or `HttpJsonLogInterceptor`, `CacheInterceptor`, `ConcurrencyLimitInterceptor`, the rate limiter, `TokenRefreshInterceptor` when `auth` is set, `RetryInterceptor`, the cache's offline fallback when enabled, then the exception handler. Use `auth` instead of writing a refresh interceptor; error loggers go before `RetryInterceptor`. Interceptors after `ConcurrencyLimitInterceptor` end `onRequest`, and interceptors before it end `onResponse` and `onError`, with `next` or the call-following flag (`reject(err, true)`), or the slot leaks. See `references/http.md`. Dio's own `LogInterceptor` is a different class.
 - JSON-RPC batch responses silently drop items without an `id`.
 - Kept for compatibility: `NetworkNotImplementException` (501, missing "ed") and both `NetworkAuthenticationException` and `UnauthorizedException` for 401.
 - `dart_falmodel` alone does not re-export `dio`; import it yourself for `Response` / `RequestOptions`.
```

- [ ] **Step 3: Update `dart_falconnect/CLAUDE.md`**

```diff
diff --git a/dart_falconnect/CLAUDE.md b/dart_falconnect/CLAUDE.md
--- a/dart_falconnect/CLAUDE.md
+++ b/dart_falconnect/CLAUDE.md
@@ -9,15 +9,17 @@
 ## HTTP (`engine/https/`)
 
 - `BaseHttpClient` implements `RequestApiService`. `configure()` keeps each interceptor whose config box is unchanged, with its state, and rebuilds the rest. Every request method funnels into one private `_request()` that chains `.mapJson(converter).catchWhenError(catchError)`.
-- `HttpClientConfig` (freezed) holds the Dio options it owns plus one box per feature, with no presets. A null `log`, `cache`, `concurrency`, or `retry` box turns that feature off. `rateLimit` defaults to `RateLimitConfig.none()`; its `pauseOnly` variant builds `RetryAfterPauseInterceptor`, and `tokenBucket` builds `TokenBucketRateLimitInterceptor`. A `LogConfig()` box builds `HttpLogInterceptor`; a `LogConfig.json()` box builds `HttpJsonLogInterceptor`.
+- `HttpClientConfig` (freezed) holds the Dio options it owns plus one box per feature, with no presets. A null `log`, `cache`, `concurrency`, or `retry` box turns that feature off. `rateLimit` defaults to `RateLimitConfig.none()`; its `pauseOnly` variant builds `RetryAfterPauseInterceptor`, and `tokenBucket` builds `TokenBucketRateLimitInterceptor`. A `LogConfig()` box builds `HttpLogInterceptor`; a `LogConfig.json()` box builds `HttpJsonLogInterceptor`. A `requestId` box, a `headerProvider` function, or an `auth` box builds `RequestStampInterceptor`; an `auth` box also builds an `AuthSession`, kept while the box is equal, and `TokenRefreshInterceptor`.
 - `extensions/response_extensions.dart` provides `mapJson()`, `unwrapResponse()`, and `catchWhenError()` on response futures, plus `copyWith()` and `transformData()` on `Response<dynamic>?`.
 
 ## Interceptor chain
 
-`BaseHttpClient.configure` assembles the chain in this order: the config's `interceptors` → `HttpLogInterceptor` or `HttpJsonLogInterceptor` → `CacheInterceptor` → `ConcurrencyLimitInterceptor` → rate limiter → `RetryInterceptor` → the cache fallback, when its box enables it → exception handler.
+`BaseHttpClient.configure` assembles the chain in this order: `RequestStampInterceptor` → the config's `interceptors` → `HttpLogInterceptor` or `HttpJsonLogInterceptor` → `CacheInterceptor` → `ConcurrencyLimitInterceptor` → rate limiter → `TokenRefreshInterceptor` → `RetryInterceptor` → the cache fallback, when its box enables it → exception handler.
 
 | Interceptor                                 | Role                                                                                                                                    |
 |---------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
+| `RequestStampInterceptor`                   | stamps the request ID, the header provider's headers, and the access token on every attempt                                             |
+| `TokenRefreshInterceptor`                   | on a 401, one refresh shared through `AuthSession`, then a re-send through the whole chain                                              |
 | `HttpLogInterceptor`                        | ANSI-colored multi-line log; redacts listed headers and query values                                                                    |
 | `HttpJsonLogInterceptor`                    | one JSON line per attempt with OpenTelemetry field names, for servers                                                                   |
 | `CacheInterceptor`                          | wraps `dio_cache_interceptor`: HTTP caching by server headers, keyed by URL and `keyHeaders`; `fallback` answers failures after retries |
@@ -29,7 +31,7 @@
 | `DefaultNetworkExceptionHandlerInterceptor` | rejects every error unchanged                                                                                                           |
 
 - The cache, concurrency, rate-limit, and retry interceptors take their config box plus an optional `logPrint`.
-- Unexported helpers: the pause core in `lib/src/engine/https/interceptors/retry_after_pause.dart`, the host-key rule in `lib/src/engine/https/interceptors/host_key.dart`, the log redaction helpers and the log start key in `lib/src/engine/https/interceptors/log_redaction.dart`, the retry loop's final-error marker in `lib/src/engine/https/interceptors/retry_attempts.dart`, and `watchCancel` in `lib/src/engine/https/cancel_watch.dart`.
+- Unexported helpers: the pause core in `lib/src/engine/https/interceptors/retry_after_pause.dart`, the host-key rule in `lib/src/engine/https/interceptors/host_key.dart`, the log redaction helpers and the log start key in `lib/src/engine/https/interceptors/log_redaction.dart`, the retry loop's final-error marker in `lib/src/engine/https/interceptors/retry_attempts.dart`, the auth bookkeeping in `extra` in `lib/src/engine/https/interceptors/auth_extra.dart`, and `watchCancel` in `lib/src/engine/https/cancel_watch.dart`.
 - Export a new interceptor from `interceptors/interceptors.dart`; that barrel also exports `local_rate_limit.dart`, which tells a client-made 429 from a server 429.
 - Interceptor model classes live in `interceptors/models/` as freezed classes (generated output in `models/generated/`); `getStatistics()` returns immutable snapshots, never live interceptor state.
 
```

- [ ] **Step 4: Check the docs against the code**

Run from the worktree root:

```bash
for name in RequestIdConfig AuthConfig HeaderProvider AuthSession RequestStampInterceptor TokenRefreshInterceptor useTokenExtraKey noToken requestId; do
  printf '%s ' "$name"; grep -rl "$name" dart_falconnect/lib | grep -v generated | head -1
done
```

Expected: every name prints a file under `dart_falconnect/lib/`.

- [ ] **Step 5: Run every gate**

Run from the worktree root:

```bash
melos run format
melos run analyze
melos run build_runner:check
melos run test
melos run test:platforms
```

Expected: every command ends in `SUCCESS`; `melos run test` shows falconnect `+356 ~1`, faltool `+771`, falmodel `+71`, falconx `+1`; `test:platforms` shows falconnect `+360 ~1` under dart2js and again under dart2wasm.

- [ ] **Step 6: Commit**

```bash
git add skills/dart-falconx-package dart_falconnect/CLAUDE.md
git commit -m "docs: document the header provider, request ID, and token auth" -- skills/dart-falconx-package dart_falconnect/CLAUDE.md
```

- [ ] **Step 7: Hand over**

Do not push, merge, or tag. Report the branch `feature/header-auth`, its six commits, and the gate results. The owner fast-forwards `develop`, bumps the version to 2.2.0 on `release/2.2.0`, and tags.
