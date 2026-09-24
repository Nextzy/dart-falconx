# Server-mode JSON HTTP Log Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `LogConfig.json()` and `HttpJsonLogInterceptor`, which log each HTTP attempt as one JSON line with OpenTelemetry field names; redact sensitive headers and query values in both log formats; and pass cache hits through every response interceptor.

**Architecture:** `LogConfig` becomes a sealed freezed union. Its unnamed factory stays the pretty log, and `LogConfig.json(...)` builds the new interceptor at the same chain position 2. Both logs stamp a start time into `RequestOptions.extra` and share internal redaction helpers in `lib/src/`. `CacheInterceptor` answers a hit with a response bound to the current request and `callFollowingResponseInterceptor: true`, and never stores a hit again.

**Tech Stack:** Dart 3.13 (the repository's `new(...)` constructor syntax), dio 5.11.1, freezed 4 with `freezed_annotation` 3.1, `package:test`, `fake_async`, melos 8. No new dependency.

**Spec:** `docs/superpowers/specs/2026-09-24-http-json-log-design.md`

**Provenance:** Every code block in Tasks 1 to 4 comes from a throwaway prototype built on `9147003` (branch `proto/json-log`) on 2026-09-24. There, `melos run analyze` and `melos run format` exited 0, `melos run test` passed (dart_falconnect 267 with 1 existing skip, dart_faltool 700, dart_falmodel 58, dart_falconx 1), `dart compile js test/web/compile_smoke.dart` exited 0, and `dart test -p chrome test/web` passed 8. Each task's RED line below is the failure the prototype recorded before its implementation existed. Task 2 also recorded that, without the no-re-store guard, `a hit does not renew its entry` fails. A script then replayed the code blocks of Tasks 1 to 4, taken from this plan's text alone, onto `develop` at `0a0b345`: the result matched the prototype line for line, and after `build_runner`, `dart analyze --fatal-infos` printed `No issues found!` and dart_falconnect passed 267 tests. The documentation task (5) was not prototyped.

## Global Constraints

- Work in worktree `.claude/worktrees/json-log` on branch `feature/json-log`, created from the `develop` commit that holds this plan.
- No new dependency in any `pubspec.yaml`.
- `dart_falconnect` compiles to the web: no `dart:io`, and no `int` shift or bitwise operator on a value that may exceed 32 bits (`truncateUtf8` masks single bytes only).
- Lints: `very_good_analysis`; `melos run analyze` runs with `--fatal-infos`; single quotes; 80 columns; exports in barrel files sorted alphabetically.
- Every model is freezed, in the repository's syntax. Generated files go to `generated/`. Run `dart run build_runner build --delete-conflicting-outputs` in `dart_falconnect` after changing `LogConfig`.
- Interceptor, config, and `lib/src/` files import the files they need directly, as their neighbours do; `http_client.dart` and `log_interceptor.dart` import `package:dart_falconnect/lib.dart`.
- Under `fakeAsync`, dio starts every request chain on a zero-length timer: advance with `async.elapse(Duration.zero)`, never `flushMicrotasks()`.
- Run `dart format` on every file you touch before committing.
- Commit with explicit paths: `git add` new files, then `git commit -m <msg> -- <paths>`. No `Co-Authored-By` line and no AI attribution in any commit message.
- Commit messages carry no `!`: the owner ships this as 2.1.0 with the one documented source break of spec section 11.
- Do not push, tag, or bump versions. The owner bumps to 2.1.0 on `release/2.1.0`.

## Review Focus

1. **A repeated or case-variant sensitive query key** (`?token=a&TOKEN=b`): every value must read `REDACTED`, not only the first. Pinned by Task 1 test `redacts a repeated and case-variant key every time`.
2. **A multi-byte body cut at `maxBodyBytes`** (Thai text): the cut must stay valid UTF-8 and within the limit. Pinned by Task 1 test `cuts Thai text at a character boundary within the limit`.
3. **A response fetched after its cache entry expired**: it must not read as a hit, so the stored entry must never carry the hit marker. Pinned by Task 2 test `the stored entry never carries the hit marker`.
4. **An error raised before the log saw the request** (a custom-slot interceptor rejecting with `reject(err, true)`): the JSON log must still print one line, with a zero duration, and not crash on the missing start time. Pinned by Task 3 test `an error raised before the log saw the request still prints one line with a zero duration`.
5. **A `logPrint` that throws** (a closed sink): the request must still complete; logging never fails a request. Pinned by Task 3 test `a printer that throws never fails the request`.

## Prototype rulings

The prototype decided these points where the spec is silent. They are part of the plan; the final review weighs them.

- Section 5.1: an error whose status is below 400 (a 3xx that `validateStatus` rejects) logs `WARN` with the status as `error.type`.
- Section 5.2: user info without a password (`user@host`) also becomes `REDACTED:REDACTED@host`; a listed parameter with no `=` becomes `name=REDACTED`; names compare in decoded form.
- Section 5.3: a null header value logs as `[]`; an `Iterable` value logs item by item. A null body omits its field. `FormData` logs as `{"fields":[names],"files":[file names]}`. A body `jsonEncode` rejects falls back to `toString()`. "Character" means Unicode code point.
- Section 4: `HttpJsonLogInterceptor` throws `ArgumentError` for a negative `maxBodyBytes`; the start key `logStartKey` lives in `lib/src/engine/https/interceptors/log_redaction.dart`; a throwing `logPrint` is caught and ignored.
- Section 5: `body` prints seconds with three decimals; `http.client.request.duration` keeps full precision.
- Section 7: the pretty log also redacts response headers and the redirect URL, to meet the success criterion that no listed header appears in either format. Colour follows the `ansicolor` global, which the class no longer writes; an instance cannot force colour on. The pretty duration prints in whole milliseconds, 0 when the log never saw the request, and the start time is stamped even when `enabled` is false.
- Section 8: `isCacheHit` and its private key live in `cache_interceptor.dart`; a hit shares the cached `headers` and `data` instances.

---
### Task 1: Redaction helpers and default redaction sets

**Files:**
- Modify: `dart_falconnect/lib/engine/https/config/log_config.dart` (add two public constants)
- Create: `dart_falconnect/lib/src/engine/https/interceptors/log_redaction.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/log_redaction_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: public `const Set<String> defaultRedactedHeaders` and `defaultRedactedQueryParameters` in `log_config.dart`; internal `const String redactedValue`, `bool matchesName(String name, Set<String> names)`, `String redactUrl(Uri uri, Set<String> queryParameters)`, `List<String> headerValues(Object? value)`, `List<String> logHeader(String name, Object? value, Set<String> redactHeaders)`, and `({String text, bool truncated}) truncateUtf8(String text, int maxBytes)` in `log_redaction.dart`.

- [ ] **Step 1: Write the failing tests**

Create `dart_falconnect/test/engine/https/interceptors/log_redaction_test.dart`:

```dart
import 'dart:convert';

import 'package:dart_falconnect/engine/https/config/log_config.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/log_redaction.dart';
import 'package:test/test.dart';

String _redact(
  String url, [
  Set<String> names = defaultRedactedQueryParameters,
]) => redactUrl(Uri.parse(url), names);

void main() {
  group('default redaction sets', () {
    test('list the sensitive headers', () {
      expect(defaultRedactedHeaders, {
        'authorization',
        'cookie',
        'proxy-authorization',
        'set-cookie',
        'x-api-key',
      });
    });

    test('list the sensitive query parameters, OpenTelemetry defaults '
        'included', () {
      expect(defaultRedactedQueryParameters, {
        'access_token',
        'api_key',
        'apikey',
        'awsaccesskeyid',
        'key',
        'password',
        'secret',
        'sig',
        'signature',
        'token',
        'x-amz-signature',
        'x-goog-signature',
      });
    });
  });

  group('matchesName', () {
    test('matches a listed name whatever its case', () {
      expect(matchesName('Authorization', defaultRedactedHeaders), isTrue);
      expect(matchesName('X-API-KEY', defaultRedactedHeaders), isTrue);
    });

    test('matches a listed name the app wrote in mixed case', () {
      expect(matchesName('x-tenant-secret', {'X-Tenant-Secret'}), isTrue);
    });

    test('does not match an unlisted name', () {
      expect(matchesName('accept', defaultRedactedHeaders), isFalse);
    });

    test('matches nothing in an empty set', () {
      expect(matchesName('authorization', const {}), isFalse);
    });
  });

  group('redactUrl', () {
    test('replaces the value of a listed parameter and keeps the rest in '
        'order', () {
      expect(
        _redact('https://a.test/x?page=2&token=abc&sort=name'),
        'https://a.test/x?page=2&token=REDACTED&sort=name',
      );
    });

    test('redacts a repeated and case-variant key every time', () {
      expect(
        _redact('https://a.test/x?token=a&TOKEN=b'),
        'https://a.test/x?token=REDACTED&TOKEN=REDACTED',
      );
    });

    test('redacts user info', () {
      expect(
        _redact('https://user:pass@a.test/x'),
        'https://REDACTED:REDACTED@a.test/x',
      );
    });

    test('redacts user info with no password', () {
      expect(
        _redact('https://user@a.test/x'),
        'https://REDACTED:REDACTED@a.test/x',
      );
    });

    test('matches a parameter name by its decoded form', () {
      expect(
        _redact('https://a.test/x?my%20secret=abc&my+secret=def', {
          'my secret',
        }),
        'https://a.test/x?my%20secret=REDACTED&my+secret=REDACTED',
      );
    });

    test('redacts a listed parameter that has no value', () {
      expect(
        _redact('https://a.test/x?token'),
        'https://a.test/x?token=REDACTED',
      );
    });

    test('keeps the encoding of unlisted parameters, the port, and the '
        'fragment', () {
      expect(
        _redact('https://a.test:8443/x?q=a%20b&key=k#top'),
        'https://a.test:8443/x?q=a%20b&key=REDACTED#top',
      );
    });

    test('leaves a URL with no query or user info unchanged', () {
      expect(_redact('https://a.test/x'), 'https://a.test/x');
    });

    test('redacts nothing with an empty set', () {
      expect(
        _redact('https://a.test/x?token=abc', const {}),
        'https://a.test/x?token=abc',
      );
    });
  });

  group('headerValues', () {
    test('wraps a single value in a list of strings', () {
      expect(headerValues('application/json'), ['application/json']);
      expect(headerValues(42), ['42']);
    });

    test('converts every item of a list', () {
      expect(headerValues(['a', 1]), ['a', '1']);
    });

    test('reads null as no value', () {
      expect(headerValues(null), isEmpty);
    });
  });

  group('logHeader', () {
    test('reads a listed header as REDACTED whatever its case', () {
      expect(logHeader('Authorization', 'Bearer t', defaultRedactedHeaders), [
        'REDACTED',
      ]);
    });

    test('keeps an unlisted header value', () {
      expect(logHeader('accept', ['a', 'b'], defaultRedactedHeaders), [
        'a',
        'b',
      ]);
    });
  });

  group('truncateUtf8', () {
    test('keeps a text within the limit', () {
      final result = truncateUtf8('hello', 5);

      expect(result.text, 'hello');
      expect(result.truncated, isFalse);
    });

    test('cuts ASCII text at the limit', () {
      final result = truncateUtf8('hello world', 5);

      expect(result.text, 'hello');
      expect(result.truncated, isTrue);
    });

    test('cuts Thai text at a character boundary within the limit', () {
      // Every Thai character is 3 UTF-8 bytes, so 10 bytes hold 3 of them.
      const thai = 'สวัสดีครับ';

      for (var limit = 1; limit < utf8.encode(thai).length; limit++) {
        final result = truncateUtf8(thai, limit);
        final bytes = utf8.encode(result.text);

        expect(bytes.length, lessThanOrEqualTo(limit), reason: 'limit $limit');
        expect(utf8.decode(bytes), result.text);
        expect(thai, startsWith(result.text));
        expect(result.truncated, isTrue);
      }
      expect(truncateUtf8(thai, 10).text, 'สวั');
    });

    test('cuts a four-byte character whole', () {
      final result = truncateUtf8('a😀b', 4);

      expect(result.text, 'a');
      expect(result.truncated, isTrue);
    });

    test('a limit of 0 keeps nothing', () {
      final result = truncateUtf8('a', 0);

      expect(result.text, isEmpty);
      expect(result.truncated, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/log_redaction_test.dart`
Expected: FAIL to compile with `Error when reading 'lib/src/engine/https/interceptors/log_redaction.dart': No such file or directory` and `Undefined name 'defaultRedactedQueryParameters'`.

- [ ] **Step 3: Add the constants and the helpers**

Apply this diff to `dart_falconnect/lib/engine/https/config/log_config.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/config/log_config.dart
+++ b/dart_falconnect/lib/engine/https/config/log_config.dart
@@ -2,6 +2,32 @@ import 'package:freezed_annotation/freezed_annotation.dart';
 
 part 'generated/log_config.freezed.dart';
 
+/// Headers both logs print as `REDACTED` by default; compared ignoring case.
+const Set<String> defaultRedactedHeaders = {
+  'authorization',
+  'cookie',
+  'proxy-authorization',
+  'set-cookie',
+  'x-api-key',
+};
+
+/// Query parameters whose values both logs print as `REDACTED` by default;
+/// compared ignoring case. Includes the OpenTelemetry `url.full` defaults.
+const Set<String> defaultRedactedQueryParameters = {
+  'access_token',
+  'api_key',
+  'apikey',
+  'awsaccesskeyid',
+  'key',
+  'password',
+  'secret',
+  'sig',
+  'signature',
+  'token',
+  'x-amz-signature',
+  'x-goog-signature',
+};
+
 /// HTTP logging settings; a non-null box adds `HttpLogInterceptor`.
 @freezed
 abstract class LogConfig with _$LogConfig {
```

Create `dart_falconnect/lib/src/engine/https/interceptors/log_redaction.dart`:

```dart
import 'dart:convert';

/// Value printed in place of a redacted header, query value, or user info.
const String redactedValue = 'REDACTED';

/// Whether [name] is in [names], ignoring case on both sides.
bool matchesName(String name, Set<String> names) {
  final lower = name.toLowerCase();
  return names.any((listed) => listed.toLowerCase() == lower);
}

/// Returns [uri] as a string with its user info and the values of the query
/// parameters named in [queryParameters] replaced by [redactedValue].
///
/// Other parameters keep their order and their encoding.
String redactUrl(Uri uri, Set<String> queryParameters) {
  if (uri.userInfo.isEmpty && (!uri.hasQuery || queryParameters.isEmpty)) {
    return uri.toString();
  }
  return uri
      .replace(
        userInfo: uri.userInfo.isEmpty ? null : '$redactedValue:$redactedValue',
        query: uri.hasQuery ? _redactQuery(uri.query, queryParameters) : null,
      )
      .toString();
}

/// A header value as the list of strings the semantic conventions require;
/// null has no value.
List<String> headerValues(Object? value) => switch (value) {
  null => const [],
  Iterable<Object?>() => [for (final item in value) '$item'],
  _ => ['$value'],
};

/// The logged value of header [name]: `["REDACTED"]` when [name] is in
/// [redactHeaders], else [headerValues] of [value].
List<String> logHeader(String name, Object? value, Set<String> redactHeaders) =>
    matchesName(name, redactHeaders)
    ? const [redactedValue]
    : headerValues(value);

/// Cuts [text] to at most [maxBytes] UTF-8 bytes at the last whole
/// character, and reports whether anything was cut.
({String text, bool truncated}) truncateUtf8(String text, int maxBytes) {
  final bytes = utf8.encode(text);
  if (bytes.length <= maxBytes) {
    return (text: text, truncated: false);
  }
  var end = maxBytes;
  // A byte of the form 10xxxxxx continues the character before it.
  while (end > 0 && bytes[end] & 0xC0 == 0x80) {
    end--;
  }
  return (text: utf8.decode(bytes.sublist(0, end)), truncated: true);
}

String _redactQuery(String query, Set<String> names) => query
    .split('&')
    .map((pair) {
      final equals = pair.indexOf('=');
      final rawName = equals < 0 ? pair : pair.substring(0, equals);
      return matchesName(Uri.decodeQueryComponent(rawName), names)
          ? '$rawName=$redactedValue'
          : pair;
    })
    .join('&');
```

- [ ] **Step 4: Run the tests and the analyzer**

Run: `cd dart_falconnect && dart format lib test && dart test test/engine/https/interceptors/log_redaction_test.dart && dart analyze --fatal-infos && dart test`
Expected: 25 tests pass in the new file; `No issues found!`; the whole suite passes.

- [ ] **Step 5: Commit**

```bash
git add dart_falconnect/lib/src/engine/https/interceptors/log_redaction.dart dart_falconnect/test/engine/https/interceptors/log_redaction_test.dart
git commit -m "feat(dart_falconnect): add log redaction helpers and default redaction sets" -- dart_falconnect/lib/engine/https/config/log_config.dart dart_falconnect/lib/src/engine/https/interceptors/log_redaction.dart dart_falconnect/test/engine/https/interceptors/log_redaction_test.dart
```

---

### Task 2: Cache hits pass every response interceptor

**Files:**
- Modify: `dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/cache_interceptor_test.dart` (new), `concurrency_limit_interceptor_test.dart`, `token_bucket_rate_limit_interceptor_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `extension FalconCacheHitResponseExtensions on Response<dynamic>` with `bool get isCacheHit`, exported through `interceptors.dart`. A hit is a new `Response` bound to the current request's `options`, resolved with `callFollowingResponseInterceptor: true`, and never stored again.

- [ ] **Step 1: Write the failing tests**

Create `dart_falconnect/test/engine/https/interceptors/cache_interceptor_test.dart`:

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

Dio _dio(ScriptedAdapter adapter, List<Interceptor> chain) =>
    Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter
      ..interceptors.addAll(chain);

Options _tagged(int id) => Options(extra: {'id': id});

void main() {
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
```

Apply this diff to `dart_falconnect/test/engine/https/interceptors/concurrency_limit_interceptor_test.dart` (a cache hit passes the limiter without moving a counter):

```diff
--- a/dart_falconnect/test/engine/https/interceptors/concurrency_limit_interceptor_test.dart
+++ b/dart_falconnect/test/engine/https/interceptors/concurrency_limit_interceptor_test.dart
@@ -85,6 +85,20 @@ class _ResendOnce extends Interceptor {
   }
 }
 
+/// Records every response it sees and passes it on.
+class _ResponseSpy extends Interceptor {
+  final List<Response<dynamic>> responses = [];
+
+  @override
+  void onResponse(
+    Response<dynamic> response,
+    ResponseInterceptorHandler handler,
+  ) {
+    responses.add(response);
+    handler.next(response);
+  }
+}
+
 void main() {
   test('forwards synchronously and builds nothing without a limit', () {
     final limiter = ConcurrencyLimitInterceptor();
@@ -425,6 +439,38 @@ void main() {
     });
   });
 
+  test('a cache hit passes onResponse without moving a counter or freeing '
+      'a held slot', () {
+    fakeAsync((async) {
+      final adapter = GatedAdapter();
+      final limiter = ConcurrencyLimitInterceptor(
+        config: const ConcurrencyConfig(perHost: 1),
+      );
+      final spy = _ResponseSpy();
+      final dio = _dio(adapter, (_) => [CacheInterceptor(), limiter, spy]);
+      final outcomes = <Object>[];
+
+      _get(dio, '/x', outcomes);
+      _settle(async);
+      adapter.requests.single.respond(200);
+      _settle(async);
+      _get(dio, '/y', outcomes);
+      _settle(async);
+      _get(dio, '/x', outcomes);
+      _settle(async);
+      _get(dio, '/z', outcomes);
+      _settle(async);
+
+      expect(spy.responses.map((r) => r.isCacheHit), [false, true]);
+      expect(_urls(adapter.inFlight), ['https://a.test/y']);
+      final stats = limiter.getStatistics();
+      expect(stats.forwarded, 2);
+      expect(stats.rejected, 0);
+      expect(stats.activeByHost, {'a.test': 1});
+      expect(stats.waitingByHost, {'a.test': 1});
+    });
+  });
+
   test('dispose cancels waiters and leaves requests in flight alone', () {
     fakeAsync((async) {
       final adapter = GatedAdapter();
```

Apply this diff to `dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart` (a cache hit passes the token bucket without moving a counter):

```diff
--- a/dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart
+++ b/dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart
@@ -1,6 +1,7 @@
 import 'dart:async';
 
 import 'package:dart_falconnect/engine/https/config/config.dart';
+import 'package:dart_falconnect/engine/https/interceptors/cache_interceptor.dart';
 import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
 import 'package:dart_falconnect/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart';
 import 'package:dart_faltool/dart_faltool.dart'
@@ -9,6 +10,8 @@ import 'package:dio/dio.dart';
 import 'package:fake_async/fake_async.dart';
 import 'package:test/test.dart';
 
+import '_scripted_adapter.dart';
+
 /// Records what the interceptor does with each request, standing in for the
 /// rest of the Dio chain.
 class _RecordingHandler extends RequestInterceptorHandler {
@@ -93,6 +96,20 @@ void _fail(
   _SilentErrorHandler(),
 );
 
+/// Records every response it sees and passes it on.
+class _ResponseSpy extends Interceptor {
+  final List<Response<dynamic>> responses = [];
+
+  @override
+  void onResponse(
+    Response<dynamic> response,
+    ResponseInterceptorHandler handler,
+  ) {
+    responses.add(response);
+    handler.next(response);
+  }
+}
+
 void _send(
   TokenBucketRateLimitInterceptor interceptor,
   _Log log, {
@@ -732,6 +749,37 @@ void main() {
     });
   });
 
+  test('a cache hit passes onResponse without moving a counter', () {
+    fakeAsync((async) {
+      final interceptor = TokenBucketRateLimitInterceptor(
+        config: const TokenBucketRateLimitConfig(
+          perHost: [
+            TokenBucketPolicy(permits: 1, per: Duration(minutes: 1), burst: 1),
+          ],
+        ),
+      );
+      final spy = _ResponseSpy();
+      final adapter = ScriptedAdapter([reply(200)]);
+      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
+        ..httpClientAdapter = adapter
+        ..interceptors.addAll([CacheInterceptor(), interceptor, spy]);
+
+      dio.get<dynamic>('/x').ignore();
+      async.elapse(Duration.zero);
+      dio.get<dynamic>('/x').ignore();
+      async.elapse(Duration.zero);
+
+      expect(spy.responses.map((r) => r.isCacheHit), [false, true]);
+      expect(adapter.requests, hasLength(1));
+      final stats = interceptor.getStatistics();
+      expect(stats.forwarded, 1);
+      expect(stats.rejected, 0);
+      expect(stats.waitingByHost, {'a.test': 0});
+      expect(stats.pausedUntilByHost, isEmpty);
+      interceptor.dispose();
+    });
+  });
+
   test('host tiers and global tiers apply together', () {
     fakeAsync((async) {
       final interceptor = TokenBucketRateLimitInterceptor(
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/cache_interceptor_test.dart test/engine/https/interceptors/concurrency_limit_interceptor_test.dart test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart`
Expected: FAIL to compile with `The getter 'isCacheHit' isn't defined for the type 'Response<dynamic>'.` With only the getter added, the behaviour tests fail: `cache_interceptor_test.dart` `Expected: <2> Actual: <1>` (the hit kept the first request's options), and the concurrency and token bucket cases `Expected: [false, true] Actual: [false]` (the hit skipped their `onResponse`).

- [ ] **Step 3: Change the interceptor**

Apply this diff to `dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart
@@ -4,6 +4,16 @@ import 'package:dart_falconnect/engine/https/config/cache_config.dart';
 import 'package:dart_faltool/dart_faltool.dart' show clock;
 import 'package:dio/dio.dart';
 
+/// Key in `Response.extra` that marks a response answered from the cache.
+const String _cacheHitKey = 'dart_falconnect.cacheHit';
+
+/// Tells a response answered by [CacheInterceptor] apart from one fetched
+/// from the network.
+extension FalconCacheHitResponseExtensions on Response<dynamic> {
+  /// Whether [CacheInterceptor] answered this response from its cache.
+  bool get isCacheHit => extra[_cacheHitKey] == true;
+}
+
 /// Response cache entry.
 ///
 /// Store and read the [timestamp] in the same clock zone: the age is
@@ -35,6 +45,11 @@ class CacheEntry {
 /// This interceptor implements a simple in-memory cache for GET
 /// requests with configurable cache duration and size limits.
 ///
+/// A hit is a new [Response] bound to the current request's options and
+/// marked `isCacheHit`; it passes every response interceptor of the chain,
+/// and is never stored again, so an entry expires on time however often it
+/// is read.
+///
 /// Time is read through `clock.now()`: store and read cache entries in
 /// the same clock zone, including eviction ordering, which sorts
 /// timestamps stamped by that zone.
@@ -73,9 +88,8 @@ class CacheInterceptor extends Interceptor {
     final cachedEntry = _cache[cacheKey];
     if (cachedEntry != null && !cachedEntry.isExpired) {
       _log('Cache hit for: ${options.method} ${options.uri}');
-
-      // Return cached response
-      return handler.resolve(cachedEntry.response);
+      // true runs every response interceptor, those before the cache too.
+      return handler.resolve(_hit(cachedEntry.response, options), true);
     }
 
     // Remove expired entry
@@ -92,6 +106,11 @@ class CacheInterceptor extends Interceptor {
     Response<dynamic> response,
     ResponseInterceptorHandler handler,
   ) {
+    // Storing a hit again would renew its lifetime, so it would never expire.
+    if (response.isCacheHit) {
+      return handler.next(response);
+    }
+
     // Only cache successful GET requests
     if (response.requestOptions.method != 'GET' ||
         response.statusCode == null ||
@@ -120,6 +139,18 @@ class CacheInterceptor extends Interceptor {
     handler.next(response);
   }
 
+  /// Builds the answer to [options] from a [cached] response, bound to the
+  /// current request and marked as a hit.
+  Response<dynamic> _hit(Response<dynamic> cached, RequestOptions options) =>
+      Response<dynamic>(
+        data: cached.data,
+        headers: cached.headers,
+        requestOptions: options,
+        statusCode: cached.statusCode,
+        statusMessage: cached.statusMessage,
+        extra: {...cached.extra, _cacheHitKey: true},
+      );
+
   /// Generates a unique cache key for a request.
   String _generateCacheKey(RequestOptions options) {
     final url = options.uri.toString();
```

- [ ] **Step 4: Run the tests and the analyzer**

Run: `cd dart_falconnect && dart format lib test && dart test test/engine/https/interceptors/cache_interceptor_test.dart test/engine/https/interceptors/concurrency_limit_interceptor_test.dart test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart && dart analyze --fatal-infos && dart test`
Expected: the three files pass (65 tests); `No issues found!`; the whole suite passes.

- [ ] **Step 5: Commit**

```bash
git add dart_falconnect/test/engine/https/interceptors/cache_interceptor_test.dart
git commit -m "fix(dart_falconnect): pass cache hits through every response interceptor" -- dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart dart_falconnect/test/engine/https/interceptors/cache_interceptor_test.dart dart_falconnect/test/engine/https/interceptors/concurrency_limit_interceptor_test.dart dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart
```

---

### Task 3: `LogConfig` union and `HttpJsonLogInterceptor`

**Files:**
- Modify: `dart_falconnect/lib/engine/https/config/log_config.dart`, `dart_falconnect/lib/engine/https/http_client.dart`, `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`, `dart_falconnect/lib/src/engine/https/interceptors/log_redaction.dart`
- Create: `dart_falconnect/lib/engine/https/interceptors/http_json_log_interceptor.dart`
- Create (generated): `dart_falconnect/lib/engine/https/config/generated/log_config.freezed.dart` (regenerated)
- Test: `dart_falconnect/test/engine/https/interceptors/http_json_log_interceptor_test.dart` (new), `dart_falconnect/test/engine/https/config/log_config_test.dart` (new), `base_http_client_configure_test.dart`, `config/feature_boxes_test.dart`, `test/web/compile_smoke.dart`, `test/web/engine_web_test.dart`

**Interfaces:**
- Consumes: the helpers and constants of Task 1; `isCacheHit` of Task 2; `isLocalRateLimit` and `retryAttempt` (existing).
- Produces: `sealed class LogConfig` with variants `PrettyLogConfig` (`LogConfig(...)`) and `JsonLogConfig` (`LogConfig.json(...)`); `redactHeaders`, `redactQueryParameters`, `logPrint`, and `diagnostics` on both. `HttpJsonLogInterceptor({JsonLogConfig config = const JsonLogConfig()})`. Internal `const String logStartKey = 'dart_falconnect.log.start'` in `log_redaction.dart`. `BaseHttpClient` builds the log by variant and prints diagnostics as JSON lines for a `JsonLogConfig`. The pretty branch keeps today's parameters until Task 4.

- [ ] **Step 1: Write the failing tests**

Create `dart_falconnect/test/engine/https/interceptors/http_json_log_interceptor_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

/// Rejects every request before the log sees it, as a custom-slot
/// interceptor placed first in the chain would.
class _RejectFirst extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'refused',
      ),
      true,
    );
  }
}

/// Has no JSON form, so a body holding it falls back to `toString()`.
class _Opaque {
  @override
  String toString() => 'opaque-value';
}

/// A JSON log printing into [lines].
HttpJsonLogInterceptor _log(
  List<Object?> lines, {
  bool requestHeaders = false,
  bool responseHeaders = false,
  bool requestBody = false,
  bool responseBody = false,
  int maxBodyBytes = 4096,
}) => HttpJsonLogInterceptor(
  config: JsonLogConfig(
    requestHeaders: requestHeaders,
    responseHeaders: responseHeaders,
    requestBody: requestBody,
    responseBody: responseBody,
    maxBodyBytes: maxBodyBytes,
    logPrint: lines.add,
  ),
);

Dio _dio(
  HttpClientAdapter adapter,
  List<Interceptor> Function(Dio) chain, {
  String baseUrl = 'https://a.test',
}) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter;
  dio.interceptors.addAll(chain(dio));
  return dio;
}

/// Sends one request, runs it to the end, and returns the decoded lines.
List<Map<String, Object?>> _run(
  List<Reply> script,
  HttpJsonLogInterceptor Function(List<Object?> lines) log, {
  String path = '/x',
  Options? options,
  Object? data,
  String method = 'GET',
}) {
  final lines = <Object?>[];
  fakeAsync((async) {
    final dio = _dio(ScriptedAdapter(script), (_) => [log(lines)]);
    dio
        .request<dynamic>(
          path,
          data: data,
          options: (options ?? Options()).copyWith(method: method),
        )
        .ignore();
    async.elapse(Duration.zero);
  });
  return _decode(lines);
}

List<Map<String, Object?>> _decode(List<Object?> lines) => [
  for (final line in lines) jsonDecode(line! as String) as Map<String, Object?>,
];

void main() {
  group('the line', () {
    test('prints one JSON line per attempt with the core fields in order', () {
      final lines = <Object?>[];
      _run([reply(200)], (_) => _log(lines));

      expect(lines, hasLength(1));
      expect(lines.single, isNot(contains('\n')));
      final line = _decode(lines).single;
      expect(line.keys, [
        'timestamp',
        'severity_text',
        'body',
        'http.request.method',
        'url.full',
        'server.address',
        'server.port',
        'http.response.status_code',
        'http.client.request.duration',
      ]);
      expect(line['http.request.method'], 'GET');
      expect(line['url.full'], 'https://a.test/x');
      expect(line['server.address'], 'a.test');
      expect(line['server.port'], 443);
      expect(line['http.response.status_code'], 200);
      expect(line['body'], 'GET https://a.test/x 200 0.000s');
      expect(DateTime.parse(line['timestamp']! as String).isUtc, isTrue);
    });

    test('upper-cases the method', () {
      final line = _run([reply(200)], _log, method: 'post').single;

      expect(line['http.request.method'], 'POST');
    });

    test('a request retried twice prints three lines with their resend '
        'count', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        final dio = _dio(
          ScriptedAdapter([reply(500), reply(500), reply(200)]),
          (dio) => [
            _log(lines),
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
        dio.get<dynamic>('/x').ignore();
        async.elapse(const Duration(seconds: 1));
      });

      final decoded = _decode(lines);
      expect(decoded.map((l) => l['http.response.status_code']), [
        500,
        500,
        200,
      ]);
      expect(decoded.map((l) => l['http.request.resend_count']), [null, 1, 2]);
      expect(decoded.first.containsKey('http.request.resend_count'), isFalse);
    });

    test('the duration is the time the attempt took', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        final adapter = GatedAdapter();
        _dio(adapter, (_) => [_log(lines)]).get<dynamic>('/x').ignore();
        async.elapse(const Duration(milliseconds: 250));
        adapter.requests.single.respond(200);
        async.elapse(Duration.zero);
      });

      final line = _decode(lines).single;
      expect(line['http.client.request.duration'], 0.25);
      expect(line['body'], 'GET https://a.test/x 200 0.250s');
    });

    test('an error raised before the log saw the request still prints one '
        'line with a zero duration', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        _dio(
          ScriptedAdapter([reply(200)]),
          (_) => [_RejectFirst(), _log(lines)],
        ).get<dynamic>('/x').ignore();
        async.elapse(Duration.zero);
      });

      final line = _decode(lines).single;
      expect(line['http.client.request.duration'], 0.0);
      expect(line['error.type'], 'unknown');
    });

    test('a printer that throws never fails the request', () async {
      final dio = _dio(
        ScriptedAdapter([reply(200)]),
        (_) => [
          HttpJsonLogInterceptor(
            config: JsonLogConfig(logPrint: (_) => throw StateError('sink')),
          ),
        ],
      );

      final response = await dio.get<dynamic>('/x');

      expect(response.statusCode, 200);
    });

    test('a null printer prints to stdout', () async {
      final printed = <String>[];
      await runZoned(
        () => _dio(
          ScriptedAdapter([reply(200)]),
          (_) => [HttpJsonLogInterceptor()],
        ).get<dynamic>('/x'),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => printed.add(line),
        ),
      );

      expect(printed, hasLength(1));
      expect(jsonDecode(printed.single), containsPair('severity_text', 'INFO'));
    });

    test('a negative maxBodyBytes is rejected', () {
      expect(
        () => HttpJsonLogInterceptor(
          config: const JsonLogConfig(maxBodyBytes: -1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('severity and error.type', () {
    for (final (status, severity) in [
      (200, 'INFO'),
      (404, 'WARN'),
      (500, 'ERROR'),
    ]) {
      test('status $status is $severity', () {
        final line = _run([reply(status)], _log).single;

        expect(line['severity_text'], severity);
        expect(line['http.response.status_code'], status);
        if (status < 400) {
          expect(line.containsKey('error.type'), isFalse);
        } else {
          expect(line['error.type'], '$status');
          expect(line['body'], 'GET https://a.test/x $status 0.000s');
        }
      });
    }

    test('a 3xx that validateStatus rejects is WARN with its status', () {
      final line = _run(
        [reply(302)],
        _log,
        options: Options(followRedirects: false),
      ).single;

      expect(line['severity_text'], 'WARN');
      expect(line['error.type'], '302');
    });

    test('a 4xx that validateStatus accepts is still WARN', () {
      final line = _run(
        [reply(404)],
        _log,
        options: Options(validateStatus: (_) => true),
      ).single;

      expect(line['severity_text'], 'WARN');
      expect(line['error.type'], '404');
    });

    test('a connection error is ERROR with the exception type name', () {
      final line = _run([
        failWith(DioExceptionType.connectionError),
      ], _log).single;

      expect(line['severity_text'], 'ERROR');
      expect(line['error.type'], 'connectionError');
      expect(line.containsKey('http.response.status_code'), isFalse);
      expect(line['body'], 'GET https://a.test/x connectionError 0.000s');
    });

    test('a cancel is INFO', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        final token = CancelToken();
        _dio(
          GatedAdapter(),
          (_) => [_log(lines)],
        ).get<dynamic>('/x', cancelToken: token).ignore();
        async.elapse(Duration.zero);
        token.cancel();
        async.elapse(Duration.zero);
      });

      final line = _decode(lines).single;
      expect(line['severity_text'], 'INFO');
      expect(line['error.type'], 'cancel');
    });
  });

  group('URL redaction', () {
    test('redacts user info and a listed parameter, keeps the rest', () {
      final line = _run(
        [reply(200)],
        _log,
        path: 'https://me:pw@a.test/x?page=2&Token=abc',
      ).single;

      const url = 'https://REDACTED:REDACTED@a.test/x?page=2&Token=REDACTED';
      expect(line['url.full'], url);
      expect(line['body'], 'GET $url 200 0.000s');
    });
  });

  group('headers', () {
    test('opted-in headers appear lower case as lists, listed ones '
        'redacted', () {
      final line = _run(
        [
          reply(200, headers: {'Set-Cookie': 's=1', 'X-Trace': 't'}),
        ],
        (lines) => _log(lines, requestHeaders: true, responseHeaders: true),
        options: Options(
          headers: {'AUTHORIZATION': 'Bearer secret', 'X-Tenant': 'acme'},
        ),
      ).single;

      expect(line['http.request.header.authorization'], ['REDACTED']);
      expect(line['http.request.header.x-tenant'], ['acme']);
      expect(line['http.response.header.set-cookie'], ['REDACTED']);
      expect(line['http.response.header.x-trace'], ['t']);
      expect(jsonEncode(line), isNot(contains('secret')));
    });

    test('headers and bodies are absent by default', () {
      final line = _run(
        [reply(200)],
        _log,
        method: 'POST',
        data: {'a': 1},
        options: Options(headers: {'x-a': '1'}),
      ).single;

      expect(
        line.keys.where(
          (key) =>
              key.startsWith('http.request.header.') ||
              key.startsWith('http.response.header.') ||
              key.startsWith('falconx.request.body') ||
              key.startsWith('falconx.response.body'),
        ),
        isEmpty,
      );
    });
  });

  group('bodies', () {
    test('opted-in bodies appear as strings', () {
      final line = _run(
        [reply(200)],
        (lines) => _log(lines, requestBody: true, responseBody: true),
        method: 'POST',
        data: {'name': 'a'},
      ).single;

      expect(line['falconx.request.body'], '{"name":"a"}');
      expect(line['falconx.response.body'], '{"status":200}');
      expect(line.containsKey('falconx.request.body.truncated'), isFalse);
    });

    test('a long body is cut at a character boundary and flagged', () {
      final line = _run(
        [reply(200)],
        (lines) => _log(lines, requestBody: true, maxBodyBytes: 10),
        method: 'POST',
        data: 'สวัสดีครับ',
      ).single;

      expect(line['falconx.request.body'], 'สวั');
      expect(line['falconx.request.body.truncated'], isTrue);
    });

    test('a body jsonEncode rejects falls back to toString()', () {
      final line = _run(
        [reply(200)],
        (lines) => _log(lines, requestBody: true),
        method: 'POST',
        data: {'value': _Opaque()},
      ).single;

      expect(line['falconx.request.body'], '{value: opaque-value}');
    });

    test('a FormData body lists its field and file names', () {
      final line = _run(
        [reply(200)],
        (lines) => _log(lines, requestBody: true),
        method: 'POST',
        data: FormData.fromMap({
          'name': 'secret-value',
          'avatar': MultipartFile.fromString('x', filename: 'me.png'),
        }),
      ).single;

      expect(
        line['falconx.request.body'],
        '{"fields":["name"],"files":["me.png"]}',
      );
    });

    test('a stream response body is not read', () {
      final line = _run(
        [reply(200)],
        (lines) => _log(lines, responseBody: true),
        options: Options(responseType: ResponseType.stream),
      ).single;

      expect(line['falconx.response.body'], '<stream>');
    });
  });

  group('FalconX flags', () {
    test('a local 429 is flagged', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        final bucket = TokenBucketRateLimitInterceptor(
          config: const TokenBucketRateLimitConfig(
            perHost: [TokenBucketPolicy(permits: 1, per: Duration(minutes: 1))],
            queueRequests: false,
          ),
        );
        final dio = _dio(
          ScriptedAdapter([reply(200)]),
          (_) => [_log(lines), bucket],
        );
        dio.get<dynamic>('/1').ignore();
        async.elapse(Duration.zero);
        dio.get<dynamic>('/2').ignore();
        async.elapse(Duration.zero);
        bucket.dispose();
      });

      final decoded = _decode(lines);
      expect(decoded.first.containsKey('falconx.rate_limit.local'), isFalse);
      expect(decoded.last['falconx.rate_limit.local'], isTrue);
      expect(decoded.last['http.response.status_code'], 429);
      expect(decoded.last['severity_text'], 'WARN');
    });

    test('a cache hit is flagged', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        final dio = _dio(
          ScriptedAdapter([reply(200)]),
          (_) => [_log(lines), CacheInterceptor()],
        );
        dio.get<dynamic>('/x').ignore();
        async.elapse(Duration.zero);
        dio.get<dynamic>('/x').ignore();
        async.elapse(Duration.zero);
      });

      final decoded = _decode(lines);
      expect(decoded.first.containsKey('falconx.cache.hit'), isFalse);
      expect(decoded.last['falconx.cache.hit'], isTrue);
      expect(decoded.last['body'], 'GET https://a.test/x 200 0.000s (cache)');
    });
  });
}
```

Create `dart_falconnect/test/engine/https/config/log_config_test.dart`:

```dart
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

String _variant(LogConfig config) => switch (config) {
  PrettyLogConfig() => 'pretty',
  JsonLogConfig() => 'json',
};

void main() {
  test('LogConfig() is the pretty variant with the defaults of 2.0.0', () {
    expect(const LogConfig(), isA<PrettyLogConfig>());

    const config = LogConfig() as PrettyLogConfig;
    expect(config.request, isTrue);
    expect(config.requestHeader, isTrue);
    expect(config.requestBody, isTrue);
    expect(config.responseHeader, isFalse);
    expect(config.responseBody, isTrue);
    expect(config.error, isTrue);
  });

  test('LogConfig.json() logs no header or body by default', () {
    expect(const LogConfig.json(), isA<JsonLogConfig>());

    const config = LogConfig.json() as JsonLogConfig;
    expect(config.requestHeaders, isFalse);
    expect(config.responseHeaders, isFalse);
    expect(config.requestBody, isFalse);
    expect(config.responseBody, isFalse);
    expect(config.maxBodyBytes, 4096);
  });

  test('a switch over both variants is exhaustive', () {
    expect(
      [_variant(const LogConfig()), _variant(const LogConfig.json())],
      ['pretty', 'json'],
    );
  });

  test('the shared fields read through the LogConfig type', () {
    for (final config in const <LogConfig>[LogConfig(), LogConfig.json()]) {
      expect(config.redactHeaders, defaultRedactedHeaders);
      expect(config.redactQueryParameters, defaultRedactedQueryParameters);
      expect(config.logPrint, isNull);
      expect(config.diagnostics, isTrue);
    }
  });

  test('variants compare by value', () {
    expect(const LogConfig.json(), const JsonLogConfig());
    expect(
      const LogConfig.json(maxBodyBytes: 10),
      isNot(const LogConfig.json()),
    );
    expect(const LogConfig(), isNot(const LogConfig.json()));
    expect(
      const LogConfig(redactHeaders: {'x-a'}),
      const LogConfig(redactHeaders: {'x-a'}),
    );
  });
}
```

Apply this diff to `dart_falconnect/test/engine/https/base_http_client_configure_test.dart`:

```diff
--- a/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
+++ b/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
@@ -1,3 +1,5 @@
+import 'dart:convert';
+
 import 'package:dart_falconnect/dart_falconnect.dart';
 import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
 import 'package:fake_async/fake_async.dart';
@@ -370,6 +372,108 @@ void main() {
     });
   });
 
+  group('log variants', () {
+    test('switching the log between pretty, JSON, and null rebuilds only '
+        'the log', () {
+      final client = _Client(ScriptedAdapter([reply(200)]))
+        ..configure(
+          const HttpClientConfig(
+            log: LogConfig(),
+            rateLimit: RateLimitConfig.tokenBucket(global: [_policy]),
+            retry: RetryConfig(),
+          ),
+        );
+      addTearDown(client.dispose);
+      final limiter = client.interceptors
+          .whereType<TokenBucketRateLimitInterceptor>()
+          .single;
+      final retry = client.interceptors.whereType<RetryInterceptor>().single;
+
+      client.configure(
+        client.currentConfig.copyWith(log: const LogConfig.json()),
+      );
+
+      expect(client.interceptors.whereType<HttpLogInterceptor>(), isEmpty);
+      final json = client.interceptors.whereType<HttpJsonLogInterceptor>();
+      expect(json, hasLength(1));
+      expect(client.interceptors.elementAt(1), same(json.single));
+      expect(
+        client.interceptors.whereType<TokenBucketRateLimitInterceptor>().single,
+        same(limiter),
+      );
+      expect(
+        client.interceptors.whereType<RetryInterceptor>().single,
+        same(retry),
+      );
+
+      client.configure(client.currentConfig.copyWith(log: null));
+
+      expect(client.interceptors.whereType<HttpJsonLogInterceptor>(), isEmpty);
+      expect(
+        client.interceptors.whereType<TokenBucketRateLimitInterceptor>().single,
+        same(limiter),
+      );
+    });
+
+    test('a limiter diagnostic prints as a JSON line in JSON mode', () {
+      fakeAsync((async) {
+        final lines = <Object?>[];
+        final client = _Client(ScriptedAdapter([reply(200)]))
+          ..configure(
+            HttpClientConfig(
+              baseUrl: 'https://a.test',
+              log: LogConfig.json(logPrint: lines.add),
+              rateLimit: const RateLimitConfig.tokenBucket(
+                perHost: [
+                  TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
+                ],
+                queueRequests: false,
+              ),
+            ),
+          );
+        client.dio.get<dynamic>('/1').ignore();
+        async.elapse(Duration.zero);
+        client.dio.get<dynamic>('/2').ignore();
+        async.elapse(Duration.zero);
+        client.dispose();
+
+        final decoded = [
+          for (final line in lines)
+            jsonDecode(line! as String) as Map<String, Object?>,
+        ];
+        final debug = decoded.where((l) => l['severity_text'] == 'DEBUG');
+        expect(debug.single.keys, ['timestamp', 'severity_text', 'body']);
+        expect(
+          debug.single['body'],
+          '[TokenBucketRateLimitInterceptor] Rate limit queue full for a.test',
+        );
+        expect(decoded.where((l) => l.containsKey('url.full')), hasLength(2));
+      });
+    });
+
+    test('a JSON log with diagnostics off prints no diagnostic', () {
+      fakeAsync((async) {
+        final lines = <Object?>[];
+        final client = _Client(ScriptedAdapter([reply(500)]))
+          ..configure(
+            HttpClientConfig(
+              baseUrl: 'https://a.test',
+              log: LogConfig.json(logPrint: lines.add, diagnostics: false),
+              retry: const RetryConfig(
+                maxAttempts: 1,
+                delay: Duration(milliseconds: 1),
+              ),
+            ),
+          );
+        client.dio.get<dynamic>('/x').ignore();
+        async.elapse(const Duration(seconds: 1));
+
+        expect(lines, hasLength(2));
+        expect(lines, everyElement(contains('"url.full"')));
+      });
+    });
+  });
+
   group('addInterceptors and setupBaseUrl', () {
     test('addInterceptors puts the interceptor in the custom slot, where it '
         'sees errors and survives configure', () async {
```

Apply this diff to `dart_falconnect/test/engine/https/config/feature_boxes_test.dart` (migration row 1: `responseHeader` is read through `PrettyLogConfig`):

```diff
--- a/dart_falconnect/test/engine/https/config/feature_boxes_test.dart
+++ b/dart_falconnect/test/engine/https/config/feature_boxes_test.dart
@@ -37,7 +37,7 @@ void main() {
     expect(performance.maxMetricsHistory, 1000);
     expect(performance.collectDetailedTimings, isTrue);
 
-    const log = LogConfig();
+    const log = PrettyLogConfig();
     expect(log.responseHeader, isFalse);
     expect(log.logPrint, isNull);
     expect(log.diagnostics, isTrue);
```

Apply this diff to `dart_falconnect/test/web/compile_smoke.dart`:

```diff
--- a/dart_falconnect/test/web/compile_smoke.dart
+++ b/dart_falconnect/test/web/compile_smoke.dart
@@ -35,6 +35,8 @@ void main() {
   _sink(TokenBucketRateLimitInterceptor());
   _sink(RetryAfterPauseInterceptor());
   _sink(HttpLogInterceptor());
+  _sink(HttpJsonLogInterceptor());
+  _sink(const HttpClientConfig(log: LogConfig.json()));
   _sink(DefaultNetworkExceptionHandlerInterceptor());
 
   // JSON-RPC
```

Apply this diff to `dart_falconnect/test/web/engine_web_test.dart`:

```diff
--- a/dart_falconnect/test/web/engine_web_test.dart
+++ b/dart_falconnect/test/web/engine_web_test.dart
@@ -1,6 +1,8 @@
 @TestOn('browser')
 library;
 
+import 'dart:convert';
+
 import 'package:dart_falconnect/dart_falconnect.dart';
 import 'package:dart_falmodel/dart_falmodel.dart' show parseRetryAfter;
 import 'package:test/test.dart';
@@ -40,9 +42,25 @@ void main() {
       expect(TokenBucketRateLimitInterceptor(), isNotNull);
       expect(RetryAfterPauseInterceptor(), isNotNull);
       expect(HttpLogInterceptor(), isNotNull);
+      expect(HttpJsonLogInterceptor(), isNotNull);
       expect(DefaultNetworkExceptionHandlerInterceptor(), isNotNull);
     });
 
+    test('HttpJsonLogInterceptor prints one JSON line on web', () async {
+      final lines = <Object?>[];
+      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
+        ..httpClientAdapter = ScriptedAdapter([reply(200)]);
+      dio.interceptors.add(
+        HttpJsonLogInterceptor(config: JsonLogConfig(logPrint: lines.add)),
+      );
+
+      await dio.get<dynamic>('/x?token=t');
+
+      final line = jsonDecode(lines.single! as String) as Map<String, Object?>;
+      expect(line['url.full'], 'https://a.test/x?token=REDACTED');
+      expect(line['http.response.status_code'], 200);
+    });
+
     test('parseRetryAfter reads an HTTP-date on web', () {
       expect(
         parseRetryAfter(
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/http_json_log_interceptor_test.dart test/engine/https/config/log_config_test.dart test/engine/https/base_http_client_configure_test.dart`
Expected: FAIL to compile with `Type 'HttpJsonLogInterceptor' not found.`, `Method not found: 'JsonLogConfig'.`, and `Couldn't find constructor 'LogConfig.json'.`

- [ ] **Step 3: Turn `LogConfig` into a union**

Apply this diff to `dart_falconnect/lib/engine/https/config/log_config.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/config/log_config.dart
+++ b/dart_falconnect/lib/engine/https/config/log_config.dart
@@ -28,10 +28,13 @@ const Set<String> defaultRedactedQueryParameters = {
   'x-goog-signature',
 };
 
-/// HTTP logging settings; a non-null box adds `HttpLogInterceptor`.
+/// HTTP logging settings: a multi-line console log for apps, or one JSON
+/// line per attempt for servers. A non-null box adds the matching log
+/// interceptor at position 2 of the chain.
 @freezed
-abstract class LogConfig with _$LogConfig {
-  /// Creates logging settings. Defaults match `HttpLogInterceptor()`.
+sealed class LogConfig with _$LogConfig {
+  /// Multi-line console log; builds `HttpLogInterceptor`. Defaults match
+  /// `HttpLogInterceptor()`.
   const factory({
     /// Logs the request line and options.
     @Default(true) bool request,
@@ -51,10 +54,51 @@ abstract class LogConfig with _$LogConfig {
     /// Logs errors.
     @Default(true) bool error,
 
+    /// Headers printed as `REDACTED`, compared ignoring case.
+    @Default(defaultRedactedHeaders) Set<String> redactHeaders,
+
+    /// Query parameters whose values print as `REDACTED`, compared ignoring
+    /// case.
+    @Default(defaultRedactedQueryParameters) Set<String> redactQueryParameters,
+
     /// Printer for HTTP logs and diagnostics; null prints to the console.
     void Function(Object? object)? logPrint,
 
     /// Whether interceptors print their diagnostics through [logPrint].
     @Default(true) bool diagnostics,
-  }) = _LogConfig;
+  }) = PrettyLogConfig;
+
+  /// One JSON line per attempt, OpenTelemetry field names; builds
+  /// `HttpJsonLogInterceptor`. Headers and bodies are off by default.
+  const factory json({
+    /// Adds each request header as `http.request.header.<name>`.
+    @Default(false) bool requestHeaders,
+
+    /// Adds each response header as `http.response.header.<name>`.
+    @Default(false) bool responseHeaders,
+
+    /// Adds the request body as `falconx.request.body`.
+    @Default(false) bool requestBody,
+
+    /// Adds the response body as `falconx.response.body`.
+    @Default(false) bool responseBody,
+
+    /// Most UTF-8 bytes of a logged body; a longer body is cut and flagged.
+    @Default(4096) int maxBodyBytes,
+
+    /// Headers logged as `["REDACTED"]`, compared ignoring case. Bodies are
+    /// never redacted.
+    @Default(defaultRedactedHeaders) Set<String> redactHeaders,
+
+    /// Query parameters whose values log as `REDACTED`, compared ignoring
+    /// case.
+    @Default(defaultRedactedQueryParameters) Set<String> redactQueryParameters,
+
+    /// Printer for HTTP logs and diagnostics; null prints to stdout.
+    void Function(Object? object)? logPrint,
+
+    /// Whether interceptors print their diagnostics through [logPrint], as
+    /// JSON lines inside a `BaseHttpClient`.
+    @Default(true) bool diagnostics,
+  }) = JsonLogConfig;
 }
```

- [ ] **Step 4: Add the start key, the interceptor, and the export**

Apply this diff to `dart_falconnect/lib/src/engine/https/interceptors/log_redaction.dart`:

```diff
--- a/dart_falconnect/lib/src/engine/https/interceptors/log_redaction.dart
+++ b/dart_falconnect/lib/src/engine/https/interceptors/log_redaction.dart
@@ -1,5 +1,9 @@
 import 'dart:convert';
 
+/// Key in `RequestOptions.extra` holding the start time of the attempt,
+/// shared by both HTTP logs.
+const String logStartKey = 'dart_falconnect.log.start';
+
 /// Value printed in place of a redacted header, query value, or user info.
 const String redactedValue = 'REDACTED';
 
```

Create `dart_falconnect/lib/engine/https/interceptors/http_json_log_interceptor.dart`:

```dart
import 'dart:convert';

import 'package:dart_falconnect/engine/https/config/log_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/cache_interceptor.dart';
import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falconnect/engine/https/interceptors/retry_interceptor.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/log_redaction.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:dio/dio.dart';

/// Logs each HTTP attempt as one JSON line with OpenTelemetry field names,
/// for a server whose stdout feeds a log aggregator.
///
/// `onRequest` stamps the start time; `onResponse` and `onError` print the
/// line and pass the request on, so it never resolves or rejects. Placed
/// before `RetryInterceptor`, as `BaseHttpClient` places it at position 2,
/// it prints one line per attempt, and the duration includes the time spent
/// in the limiters' queues. An attempt that failed before this interceptor
/// saw it logs a duration of 0.
///
/// Sensitive headers and query values print as `REDACTED`; bodies, when
/// enabled, are never redacted.
class HttpJsonLogInterceptor extends Interceptor {
  /// Creates a JSON log.
  ///
  /// Throws an [ArgumentError] when `config.maxBodyBytes` is negative.
  new({this.config = const JsonLogConfig()}) {
    if (config.maxBodyBytes < 0) {
      throw ArgumentError.value(
        config.maxBodyBytes,
        'maxBodyBytes',
        'must not be negative',
      );
    }
  }

  /// Which headers and bodies to add, and what to redact.
  final JsonLogConfig config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // A new map: extra may be const.
    options.extra = {...options.extra, logStartKey: clock.now()};
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _print(response.requestOptions, response, null);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _print(err.requestOptions, err.response, err.type);
    handler.next(err);
  }

  /// Prints the line of one attempt. A printer that throws is ignored, so
  /// logging never fails a request.
  void _print(
    RequestOptions options,
    Response<dynamic>? response,
    DioExceptionType? errorType,
  ) {
    final line = jsonEncode(_fields(options, response, errorType));
    try {
      final printer = config.logPrint;
      if (printer != null) {
        printer(line);
      } else {
        // The JSON log writes to stdout when the config sets no printer.
        // ignore: avoid_print
        print(line);
      }
    } on Object {
      // A broken log sink must not turn a finished request into a failure.
    }
  }

  Map<String, Object?> _fields(
    RequestOptions options,
    Response<dynamic>? response,
    DioExceptionType? errorType,
  ) {
    final now = clock.now();
    final start = options.extra[logStartKey];
    final duration = start is DateTime ? now.difference(start) : Duration.zero;
    final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
    final status = response?.statusCode;
    final outcome = _outcome(status, errorType);
    final method = options.method.toUpperCase();
    final url = redactUrl(options.uri, config.redactQueryParameters);
    final cacheHit = response?.isCacheHit ?? false;
    final resendCount = options.retryAttempt;
    return {
      'timestamp': now.toUtc().toIso8601String(),
      'severity_text': outcome.severity,
      'body':
          '$method $url ${outcome.errorType ?? status} '
          '${seconds.toStringAsFixed(3)}s${cacheHit ? ' (cache)' : ''}',
      'http.request.method': method,
      'url.full': url,
      'server.address': options.uri.host,
      'server.port': options.uri.port,
      'http.response.status_code': ?status,
      'error.type': ?outcome.errorType,
      'http.client.request.duration': seconds,
      if (resendCount > 0) 'http.request.resend_count': resendCount,
      if (cacheHit) 'falconx.cache.hit': true,
      if (response?.isLocalRateLimit ?? false) 'falconx.rate_limit.local': true,
      if (config.requestHeaders) ..._headers('request', options.headers),
      if (config.responseHeaders && response != null)
        ..._headers('response', response.headers.map),
      if (config.requestBody) ..._body('request', options.data),
      if (config.responseBody && response != null)
        ..._body(
          'response',
          options.responseType == ResponseType.stream
              ? '<stream>'
              : response.data,
        ),
    };
  }

  /// `http.<side>.header.<lower-case name>` for each header, redacted.
  Map<String, List<String>> _headers(
    String side,
    Map<String, Object?> headers,
  ) => {
    for (final MapEntry(:key, :value) in headers.entries)
      'http.$side.header.${key.toLowerCase()}': logHeader(
        key,
        value,
        config.redactHeaders,
      ),
  };

  /// `falconx.<side>.body` and its truncation flag; nothing for no body.
  Map<String, Object> _body(String side, Object? data) {
    if (data == null) return const {};
    final cut = truncateUtf8(_bodyText(data), config.maxBodyBytes);
    return {
      'falconx.$side.body': cut.text,
      if (cut.truncated) 'falconx.$side.body.truncated': true,
    };
  }

  /// Severity and `error.type` of an attempt; a status decides when there
  /// is one, else the exception type.
  static ({String severity, String? errorType}) _outcome(
    int? status,
    DioExceptionType? errorType,
  ) {
    if (status != null) {
      if (status >= 500) return (severity: 'ERROR', errorType: '$status');
      // A status below 400 that validateStatus rejected is still a failure.
      if (status >= 400 || errorType != null) {
        return (severity: 'WARN', errorType: '$status');
      }
      return (severity: 'INFO', errorType: null);
    }
    return switch (errorType) {
      null => (severity: 'INFO', errorType: null),
      DioExceptionType.cancel => (severity: 'INFO', errorType: 'cancel'),
      _ => (severity: 'ERROR', errorType: errorType.name),
    };
  }

  static String _bodyText(Object data) {
    if (data is String) return data;
    if (data is FormData) {
      return jsonEncode({
        'fields': [for (final field in data.fields) field.key],
        'files': [
          for (final file in data.files) file.value.filename ?? file.key,
        ],
      });
    }
    if (data is Map || data is List) {
      try {
        return jsonEncode(data);
        // jsonEncode wraps whatever a toJson throws in an Error.
      } on Object {
        return data.toString();
      }
    }
    return data.toString();
  }
}
```

Apply this diff to `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/interceptors.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/interceptors.dart
@@ -1,6 +1,7 @@
 export 'cache_interceptor.dart';
 export 'concurrency_limit_interceptor.dart';
 export 'default_network_exception_handler_interceptor.dart';
+export 'http_json_log_interceptor.dart';
 export 'local_rate_limit.dart';
 export 'log_interceptor.dart';
 export 'network_exception_handler_interceptor.dart';
```

- [ ] **Step 5: Build the log by variant in `BaseHttpClient`**

Apply this diff to `dart_falconnect/lib/engine/https/http_client.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/http_client.dart
+++ b/dart_falconnect/lib/engine/https/http_client.dart
@@ -31,7 +31,7 @@ abstract class BaseHttpClient implements RequestApiService {
       DefaultNetworkExceptionHandlerInterceptor();
 
   HttpClientConfig? _config;
-  HttpLogInterceptor? _log;
+  Interceptor? _log;
   PerformanceInterceptor? _performance;
   CacheInterceptor? _cache;
   ConcurrencyLimitInterceptor? _concurrency;
@@ -362,7 +362,12 @@ abstract class BaseHttpClient implements RequestApiService {
     return build(after);
   }
 
-  HttpLogInterceptor _buildLog(LogConfig box) {
+  Interceptor _buildLog(LogConfig box) => switch (box) {
+    PrettyLogConfig() => _buildPrettyLog(box),
+    JsonLogConfig() => HttpJsonLogInterceptor(config: box),
+  };
+
+  HttpLogInterceptor _buildPrettyLog(PrettyLogConfig box) {
     final log = HttpLogInterceptor(
       request: box.request,
       requestHeader: box.requestHeader,
@@ -401,17 +406,26 @@ abstract class BaseHttpClient implements RequestApiService {
     _dio.options.validateStatus = next.validateStatus ?? _defaultValidateStatus;
   }
 
-  /// Prints an interceptor diagnostic through the current log box.
+  /// Prints an interceptor diagnostic through the current log box, as a
+  /// JSON line when the box is a [JsonLogConfig].
   void _diagnostic(String message) {
     final log = _config?.log;
     if (log == null || !log.diagnostics) return;
+    final line = switch (log) {
+      PrettyLogConfig() => message,
+      JsonLogConfig() => jsonEncode({
+        'timestamp': clock.now().toUtc().toIso8601String(),
+        'severity_text': 'DEBUG',
+        'body': message,
+      }),
+    };
     final printer = log.logPrint;
     if (printer != null) {
-      printer(message);
+      printer(line);
     } else {
       // Diagnostics go to the console when the config sets no printer.
       // ignore: avoid_print
-      print(message);
+      print(line);
     }
   }
 }
```

- [ ] **Step 6: Generate code**

Run: `cd dart_falconnect && dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/engine/https/config/generated/log_config.freezed.dart` is rewritten with `PrettyLogConfig` and `JsonLogConfig`.

- [ ] **Step 7: Run the tests, the analyzer, and the web compile**

Run: `cd dart_falconnect && dart format lib test && dart test test/engine/https/interceptors/http_json_log_interceptor_test.dart test/engine/https/config test/engine/https/base_http_client_configure_test.dart && dart analyze --fatal-infos && dart test && dart compile js test/web/compile_smoke.dart -o /tmp/json-log-smoke.js`
Expected: the JSON log file passes 25 tests; `No issues found!`; the whole suite passes; `dart compile js` exits 0.

- [ ] **Step 8: Commit**

```bash
git add dart_falconnect/lib/engine/https/interceptors/http_json_log_interceptor.dart dart_falconnect/test/engine/https/interceptors/http_json_log_interceptor_test.dart dart_falconnect/test/engine/https/config/log_config_test.dart
git commit -m "feat(dart_falconnect): add the server-mode JSON HTTP log" -- dart_falconnect/lib/engine/https/config dart_falconnect/lib/engine/https/http_client.dart dart_falconnect/lib/engine/https/interceptors/http_json_log_interceptor.dart dart_falconnect/lib/engine/https/interceptors/interceptors.dart dart_falconnect/lib/src/engine/https/interceptors/log_redaction.dart dart_falconnect/test/engine/https dart_falconnect/test/web
```

---

### Task 4: Pretty log fixes

**Files:**
- Modify: `dart_falconnect/lib/engine/https/interceptors/log_interceptor.dart`, `dart_falconnect/lib/engine/https/http_client.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/http_log_interceptor_test.dart` (new), `base_http_client_configure_test.dart`

**Interfaces:**
- Consumes: `logStartKey`, `redactedValue`, `matchesName`, and `redactUrl` of Tasks 1 and 3; `PrettyLogConfig.redactHeaders` and `redactQueryParameters` of Task 3.
- Produces: `HttpLogInterceptor` gains `redactHeaders` and `redactQueryParameters` (constructor parameters and public fields, defaulting to the public constants), no longer writes `ansiColorDisabled`, and prints `statusCode` and `duration` for every response and error. `BaseHttpClient` passes the box's redaction sets.

- [ ] **Step 1: Write the failing tests**

Create `dart_falconnect/test/engine/https/interceptors/http_log_interceptor_test.dart`:

```dart
import 'package:ansicolor/ansicolor.dart';
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

/// Runs one request through a pretty log built by [log] and returns the
/// printed lines; [answer] settles the gated request after [elapsed].
List<String> _run(
  HttpLogInterceptor Function(void Function(Object?) print) log, {
  String path = '/x',
  Options? options,
  void Function(GatedRequest request)? answer,
  Duration elapsed = Duration.zero,
}) {
  final lines = <String>[];
  fakeAsync((async) {
    final adapter = GatedAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(log((line) => lines.add('$line')));
    dio.get<dynamic>(path, options: options).ignore();
    async.elapse(elapsed);
    (answer ?? (request) => request.respond(200))(adapter.requests.single);
    async.elapse(Duration.zero);
  });
  return lines;
}

void main() {
  late bool colorDisabled;

  setUp(() {
    colorDisabled = ansiColorDisabled;
    ansiColorDisabled = true;
  });

  tearDown(() => ansiColorDisabled = colorDisabled);

  group('colour', () {
    for (final (enabled, global) in [(true, true), (false, false)]) {
      test('the constructor leaves ansiColorDisabled at $global '
          '(enabled: $enabled)', () {
        ansiColorDisabled = global;

        HttpLogInterceptor(enabled: enabled);

        expect(ansiColorDisabled, global);
      });
    }

    test('a disabled instance prints nothing', () {
      final lines = _run(
        (print) => HttpLogInterceptor(enabled: false, logPrint: print),
      );

      expect(lines, isEmpty);
    });
  });

  group('redaction', () {
    test('a listed request header prints REDACTED whatever its case', () {
      final lines = _run(
        (print) => HttpLogInterceptor(logPrint: print),
        options: Options(
          headers: {'AUTHORIZATION': 'Bearer secret', 'X-Tenant': 'acme'},
        ),
      );

      expect(lines, contains(' AUTHORIZATION: REDACTED'));
      expect(lines, contains(' X-Tenant: acme'));
      expect(lines.join('\n'), isNot(contains('secret')));
    });

    test('an empty set prints every header as is', () {
      final lines = _run(
        (print) => HttpLogInterceptor(redactHeaders: const {}, logPrint: print),
        options: Options(headers: {'Authorization': 'Bearer secret'}),
      );

      expect(lines, contains(' Authorization: Bearer secret'));
    });

    test('a listed response header prints REDACTED', () {
      final lines = _run(
        (print) => HttpLogInterceptor(responseHeader: true, logPrint: print),
        answer: (request) =>
            request.respond(200, headers: {'set-cookie': 'session=secret'}),
      );

      expect(lines, contains(' set-cookie: REDACTED'));
      expect(lines.join('\n'), isNot(contains('session=secret')));
    });

    test('every URL line redacts user info and listed query values', () {
      final lines = _run(
        (print) => HttpLogInterceptor(logPrint: print),
        path: 'https://me:pw@a.test/x?page=2&token=abc',
      );

      const url =
          'URL: https://REDACTED:REDACTED@a.test/x?page=2&token=REDACTED';
      expect(lines.where((line) => line.startsWith('URL:')), [url, url]);
      expect(lines.join('\n'), isNot(contains('abc')));
    });

    test('custom query parameter names replace the defaults', () {
      final lines = _run(
        (print) => HttpLogInterceptor(
          redactQueryParameters: const {'tenant'},
          logPrint: print,
        ),
        path: '/x?tenant=acme&token=abc',
      );

      expect(
        lines,
        contains('URL: https://a.test/x?tenant=REDACTED&token=abc'),
      );
    });
  });

  group('status and duration', () {
    test('a response prints its status and duration with responseHeader '
        'off', () {
      final lines = _run(
        (print) => HttpLogInterceptor(logPrint: print),
        elapsed: const Duration(milliseconds: 250),
      );

      expect(lines, contains('statusCode: 200'));
      expect(lines, contains('duration: 250ms'));
    });

    test('an error response prints its status and duration', () {
      final lines = _run(
        (print) => HttpLogInterceptor(logPrint: print),
        elapsed: const Duration(milliseconds: 40),
        answer: (request) => request.respond(404),
      );

      expect(lines, contains('statusCode: 404'));
      expect(lines, contains('duration: 40ms'));
    });

    test('an error without a response prints its duration', () {
      final lines = <String>[];
      fakeAsync((async) {
        final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
          ..httpClientAdapter = ScriptedAdapter([
            failWith(DioExceptionType.connectionError),
          ])
          ..interceptors.add(
            HttpLogInterceptor(logPrint: (l) => lines.add('$l')),
          );
        dio.get<dynamic>('/x').ignore();
        async.elapse(Duration.zero);
      });

      expect(lines, contains('duration: 0ms'));
      expect(lines.where((line) => line.startsWith('statusCode')), isEmpty);
    });
  });
}
```

Apply this diff to `dart_falconnect/test/engine/https/base_http_client_configure_test.dart`:

```diff
--- a/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
+++ b/dart_falconnect/test/engine/https/base_http_client_configure_test.dart
@@ -415,6 +415,32 @@ void main() {
       );
     });
 
+    test('the pretty log takes the redaction sets of its box', () async {
+      final lines = <Object?>[];
+      final client = _Client(ScriptedAdapter([reply(200)]))
+        ..configure(
+          HttpClientConfig(
+            baseUrl: 'https://a.test',
+            headers: const {'X-Tenant': 'acme'},
+            log: LogConfig(
+              redactHeaders: const {'x-tenant'},
+              redactQueryParameters: const {'page'},
+              logPrint: lines.add,
+            ),
+          ),
+        );
+
+      await client.dio.get<dynamic>('/x?page=2');
+
+      // Colour codes wrap header values; drop them to read the text.
+      final printed = lines
+          .join('\n')
+          .replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
+      expect(printed, contains('X-Tenant: REDACTED'));
+      expect(printed, contains('https://a.test/x?page=REDACTED'));
+      expect(printed, isNot(contains('acme')));
+    });
+
     test('a limiter diagnostic prints as a JSON line in JSON mode', () {
       fakeAsync((async) {
         final lines = <Object?>[];
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/http_log_interceptor_test.dart test/engine/https/base_http_client_configure_test.dart`
Expected: FAIL to compile with `No named parameter with the name 'redactHeaders'.` With the parameter stubbed, the configure test `the pretty log takes the redaction sets of its box` fails with `Expected: contains 'X-Tenant: REDACTED'`.

- [ ] **Step 3: Change the pretty log**

Apply this diff to `dart_falconnect/lib/engine/https/interceptors/log_interceptor.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/log_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/log_interceptor.dart
@@ -1,17 +1,21 @@
 import 'package:dart_falconnect/lib.dart';
+import 'package:dart_falconnect/src/engine/https/interceptors/log_redaction.dart';
 
-/// [LogInterceptor] is used to print logs during network requests.
-/// It's better to add [LogInterceptor] to the tail of the
-/// interceptors queue, otherwise the changes made in the
-/// interceptors behind A will not be printed out.
-/// This is because the execution of interceptors is in the order
-/// of addition.
+/// Prints each request, response, and error over several console lines,
+/// for a developer watching an app's console.
+///
+/// `BaseHttpClient` places it at position 2 of the chain, after the app's
+/// own interceptors, so it sees what they changed. Every response and
+/// error prints its status and duration. The URL, request headers, and
+/// response headers print redacted: see [redactHeaders] and
+/// [redactQueryParameters].
 class HttpLogInterceptor extends Interceptor {
   /// Creates an [HttpLogInterceptor].
   ///
   /// Each boolean flag controls which parts of the request/response cycle are
   /// logged. [logPrint] defaults to a chunked console printer that avoids
-  /// truncation on long payloads.
+  /// truncation on long payloads. Colour follows `ansiColorDisabled`, which
+  /// this class never writes.
   new({
     this.enabled = true,
     this.request = true,
@@ -20,10 +24,10 @@ class HttpLogInterceptor extends Interceptor {
     this.responseHeader = false,
     this.responseBody = true,
     this.error = true,
+    this.redactHeaders = defaultRedactedHeaders,
+    this.redactQueryParameters = defaultRedactedQueryParameters,
     this.logPrint = _logPrintLong,
-  }) {
-    ansiColorDisabled = !enabled;
-  }
+  });
 
   final AnsiPen _title = AnsiPen()..white(bold: true);
   final AnsiPen _error = AnsiPen()..red(bold: true);
@@ -50,6 +54,13 @@ class HttpLogInterceptor extends Interceptor {
   /// Print error message
   bool error;
 
+  /// Headers printed as `REDACTED`, compared ignoring case.
+  Set<String> redactHeaders;
+
+  /// Query parameters whose values print as `REDACTED`, compared ignoring
+  /// case.
+  Set<String> redactQueryParameters;
+
   /// Log printer; defaults print log to console.
   /// In flutter, you'd better use debugPrint.
   /// you can also write log in a file, for example:
@@ -66,10 +77,11 @@ class HttpLogInterceptor extends Interceptor {
 
   @override
   void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
+    // A new map: extra may be const.
+    options.extra = {...options.extra, logStartKey: clock.now()};
     if (enabled) {
       logPrint(_title('*** Request ***'));
-      _printKV('URL', options.uri);
-      //options.headers;
+      _printKV('URL', _url(options.uri));
 
       if (request) {
         _printKV('method', _title(options.method));
@@ -87,7 +99,14 @@ class HttpLogInterceptor extends Interceptor {
       if (requestHeader) {
         logPrint('headers:');
         options.headers.forEach(
-          (key, v) => _printKV(' $key', _title(v?.toString() ?? '')),
+          (key, v) => _printKV(
+            ' $key',
+            _title(
+              matchesName(key, redactHeaders)
+                  ? redactedValue
+                  : v?.toString() ?? '',
+            ),
+          ),
         );
       }
       if (requestBody) {
@@ -138,13 +157,15 @@ class HttpLogInterceptor extends Interceptor {
     if (enabled) {
       if (error) {
         logPrint(_error('*** DioError ***:'));
-        logPrint('URL: ${err.requestOptions.uri}');
+        logPrint('URL: ${_url(err.requestOptions.uri)}');
         logPrint('$err');
         final response = err.response;
         if (response != null) {
           _printResponse(response);
+        } else {
+          _printKV('duration', _duration(err.requestOptions));
+          logPrint('');
         }
-        logPrint('');
       }
     }
 
@@ -153,16 +174,20 @@ class HttpLogInterceptor extends Interceptor {
 
   void _printResponse(Response<dynamic> response) {
     if (enabled) {
-      _printKV('URL', response.requestOptions.uri);
+      _printKV('URL', _url(response.requestOptions.uri));
+      _printKV('statusCode', response.statusCode ?? 0);
+      _printKV('duration', _duration(response.requestOptions));
       if (responseHeader) {
-        _printKV('statusCode', response.statusCode ?? 0);
         if (response.isRedirect) {
-          _printKV('redirect', response.realUri);
+          _printKV('redirect', _url(response.realUri));
         }
 
         logPrint('headers:');
         response.headers.forEach(
-          (key, v) => _printKV(' $key', v.join('\r\n\t')),
+          (key, v) => _printKV(
+            ' $key',
+            matchesName(key, redactHeaders) ? redactedValue : v.join('\r\n\t'),
+          ),
         );
       }
       if (responseBody) {
@@ -181,6 +206,17 @@ class HttpLogInterceptor extends Interceptor {
     }
   }
 
+  String _url(Uri uri) => redactUrl(uri, redactQueryParameters);
+
+  /// Milliseconds since `onRequest`; 0 when this log never saw the request.
+  String _duration(RequestOptions options) {
+    final start = options.extra[logStartKey];
+    final elapsed = start is DateTime
+        ? clock.now().difference(start)
+        : Duration.zero;
+    return '${elapsed.inMilliseconds}ms';
+  }
+
   void _printKV(String key, Object? v) {
     if (enabled) {
       logPrint('$key: $v');
```

Apply this diff to `dart_falconnect/lib/engine/https/http_client.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/http_client.dart
+++ b/dart_falconnect/lib/engine/https/http_client.dart
@@ -375,6 +375,8 @@ abstract class BaseHttpClient implements RequestApiService {
       responseHeader: box.responseHeader,
       responseBody: box.responseBody,
       error: box.error,
+      redactHeaders: box.redactHeaders,
+      redactQueryParameters: box.redactQueryParameters,
     );
     final printer = box.logPrint;
     if (printer != null) log.logPrint = printer;
```

- [ ] **Step 4: Run the tests and the analyzer**

Run: `cd dart_falconnect && dart format lib test && dart test test/engine/https/interceptors/http_log_interceptor_test.dart test/engine/https/base_http_client_configure_test.dart && dart analyze --fatal-infos && dart test`
Expected: both files pass (38 tests); `No issues found!`; the whole suite passes (267 with 1 existing skip).

- [ ] **Step 5: Commit**

```bash
git add dart_falconnect/test/engine/https/interceptors/http_log_interceptor_test.dart
git commit -m "fix(dart_falconnect): redact the pretty HTTP log and print status and duration" -- dart_falconnect/lib/engine/https/interceptors/log_interceptor.dart dart_falconnect/lib/engine/https/http_client.dart dart_falconnect/test/engine/https/interceptors/http_log_interceptor_test.dart dart_falconnect/test/engine/https/base_http_client_configure_test.dart
```

---

### Task 5: Documentation

**Files:**
- Modify: `skills/dart-falconx-package/references/http.md`, `skills/dart-falconx-package/SKILL.md`, `dart_falconnect/CLAUDE.md`
- No change: `CLAUDE.md` (root) names no interceptor; it points at `http.md`.

**Interfaces:**
- Consumes: the public API of Tasks 1 to 4.
- Produces: docs that match the source (the skill maintenance rule in `CLAUDE.md`).

Edit the files as they are on the branch; `dart_falconnect/CLAUDE.md` was restructured on 2026-09-24 (`0a0b345`), so match its current wording. After editing a padded markdown table, re-pad every row so the columns line up.

- [ ] **Step 1: Update the box table and the interceptor catalog in `http.md`**

In `## Configure a client`, replace the `LogConfig` row of the box table with these two rows:

```markdown
| `LogConfig(...)` | `HttpLogInterceptor`; `diagnostics` also prints interceptor diagnostics | request, headers, and bodies on; response headers off; sensitive headers and query values redacted |
| `LogConfig.json(...)` | `HttpJsonLogInterceptor`, one JSON line per attempt (see "Server logging") | headers and bodies off; sensitive headers and query values redacted |
```

In `## Interceptor catalog`, replace the `HttpLogInterceptor` row and add the `HttpJsonLogInterceptor` row after it:

```markdown
| `HttpLogInterceptor` | `(enabled, request, requestHeader, requestBody, responseHeader, responseBody, error, redactHeaders, redactQueryParameters, logPrint)` | ANSI-coloured chunked printing; prints the status and duration of every response and error; redacts listed headers and query values; logs requests and responses from anywhere in the chain, errors only when placed before `RetryInterceptor` and the exception handler |
| `HttpJsonLogInterceptor` | `(config: JsonLogConfig(requestHeaders: false, responseHeaders: false, requestBody: false, responseBody: false, maxBodyBytes: 4096, redactHeaders:, redactQueryParameters:, logPrint:))` | one JSON line per attempt with OpenTelemetry field names (see "Server logging"); never resolves or rejects; a throwing `logPrint` is ignored |
```

In the `CacheInterceptor` row, append to the behaviour cell: `; a hit passes every response interceptor, bound to the current request, and reads response.isCacheHit` (with `response.isCacheHit` in backticks).

In `## Helpers`, add a bullet: ``- `response.isCacheHit` marks a response answered by `CacheInterceptor`.``

- [ ] **Step 2: Add the server logging section to `http.md`**

Insert this section immediately before `## Client and server deployment`:

````markdown
## Server logging

On a server, turn on the JSON log. Each HTTP attempt becomes one JSON line on stdout, with OpenTelemetry field names, so any log aggregator can read it.

```dart
DefaultHttpClient.instance.configure(
  HttpClientConfig(
    baseUrl: Env.apiBaseUrl,
    log: const LogConfig.json(),
    retry: const RetryConfig(),
  ),
);
```

```json
{"timestamp":"2026-09-24T07:12:03.184Z","severity_text":"WARN","body":"GET https://api.example.com/users/7?token=REDACTED 404 0.184s","http.request.method":"GET","url.full":"https://api.example.com/users/7?token=REDACTED","server.address":"api.example.com","server.port":443,"http.response.status_code":404,"error.type":"404","http.client.request.duration":0.184}
```

| Field | Value |
|---|---|
| `timestamp` | completion time of the attempt, ISO 8601 UTC |
| `severity_text` | `INFO` below 400 and on cancel; `WARN` for 4xx; `ERROR` for 5xx and errors without a response |
| `body` | `<method> <url> <status or error type> <seconds>s`, plus ` (cache)` on a hit |
| `http.request.method`, `url.full`, `server.address`, `server.port` | from the request; `url.full` redacted |
| `http.response.status_code` | when a response exists |
| `error.type` | the status as a string, or the `DioExceptionType` name such as `connectionTimeout` |
| `http.client.request.duration` | seconds, including time spent in the limiters' queues |
| `http.request.resend_count` | on retries |
| `falconx.cache.hit`, `falconx.rate_limit.local` | `true` on a cache hit, and on a 429 built by a limiter |

- Opt in to more with `LogConfig.json(requestHeaders: true, responseHeaders: true, requestBody: true, responseBody: true, maxBodyBytes: 4096)`. Headers appear as `http.request.header.<name>` lists; bodies as `falconx.request.body` and `falconx.response.body`, cut at `maxBodyBytes` UTF-8 bytes with a `.truncated` flag. Bodies are never redacted: turn them on only where they carry no personal data.
- `redactHeaders` (default `defaultRedactedHeaders`) and `redactQueryParameters` (default `defaultRedactedQueryParameters`) apply to both log formats and compare names ignoring case. Extend them: `redactHeaders: {...defaultRedactedHeaders, 'x-tenant-secret'}`.
- A retried request prints one line per attempt. Limiter diagnostics print as JSON lines with `severity_text` `DEBUG` while `diagnostics` is on.
- A `logPrint` that throws is ignored; logging never fails a request.
- An OpenTelemetry Collector's `filelog` receiver with a `json_parser` operator turns each line into a log record; the Datadog agent and Cloud Logging read JSON on stdout too. Cloud Logging without a Collector does not map `severity_text` to its own `severity`.
- Switch formats at run time with `client.configure(client.currentConfig.copyWith(log: const LogConfig.json()))`; the limiters keep their state.
````

- [ ] **Step 3: Add the 2.1.0 migration note to `http.md`**

Append at the end of the file:

````markdown
## Migrating to 2.1.0

- `LogConfig` is a sealed union: `LogConfig(...)` is `PrettyLogConfig`, and `LogConfig.json(...)` is `JsonLogConfig`. Code that reads or copies `request`, `requestHeader`, `requestBody`, `responseHeader`, `responseBody`, or `error` through the `LogConfig` type must match `PrettyLogConfig` first. This is the one source break of 2.1.0:

  ```dart
  if (config.log case final PrettyLogConfig log) {
    client.configure(config.copyWith(log: log.copyWith(responseBody: false)));
  }
  ```

- A cache hit now passes every response interceptor, and its `requestOptions` are the current request's. A custom interceptor that counts responses counts hits too; tell them apart with `response.isCacheHit`.
- Both logs redact sensitive headers and query values by default. Pass `redactHeaders: const {}` and `redactQueryParameters: const {}` to see them in development.
- `HttpLogInterceptor` no longer writes the global `ansiColorDisabled`. Set it yourself if other code relied on that side effect.
- `HttpLogInterceptor` prints the status and duration of every response and error.
````

- [ ] **Step 4: Update `SKILL.md`**

- In the capability table, the `Client configuration` row's second cell becomes: `` `HttpClientConfig` boxes (`LogConfig`, or `LogConfig.json` for a server), `configure`, `currentConfig`, `setupBaseUrl` ``.
- In the `Interceptors` row, add `` `HttpJsonLogInterceptor` `` right after `` `HttpLogInterceptor` ``.
- In the interceptor order line, replace `` `HttpLogInterceptor`, `` with `` `HttpLogInterceptor` or `HttpJsonLogInterceptor`, ``.
- Re-pad the capability table.

- [ ] **Step 5: Update `dart_falconnect/CLAUDE.md`**

- In `## HTTP (engine/https/)`, append to the `HttpClientConfig` bullet: ``A `LogConfig()` box builds `HttpLogInterceptor`; a `LogConfig.json()` box builds `HttpJsonLogInterceptor`.``
- In `## Interceptor chain`, in the order sentence, replace `` `HttpLogInterceptor` `` with `` `HttpLogInterceptor` or `HttpJsonLogInterceptor` ``.
- In the interceptor table, set the `HttpLogInterceptor` role to `ANSI-colored multi-line log; redacts listed headers and query values`; add a row `HttpJsonLogInterceptor` with role `one JSON line per attempt with OpenTelemetry field names, for servers`; set the `CacheInterceptor` role to ``in-memory cache of GET responses; a hit passes every response interceptor and reads `isCacheHit` ``. Re-pad the table.
- In the "Unexported helpers" bullet, add ``the log redaction helpers and the log start key in `lib/src/engine/https/interceptors/log_redaction.dart` ``.

- [ ] **Step 6: Check the docs against the source**

Run: `grep -n "HttpJsonLogInterceptor\|LogConfig.json\|isCacheHit" skills/dart-falconx-package/SKILL.md skills/dart-falconx-package/references/http.md dart_falconnect/CLAUDE.md`
Expected: matches in all three files.
Run: `grep -n "defaultRedactedHeaders\|redactQueryParameters\|maxBodyBytes" dart_falconnect/lib/engine/https/config/log_config.dart`
Expected: each name the docs use exists in the source.

- [ ] **Step 7: Commit**

```bash
git commit -m "docs: document the server-mode JSON log, redaction, and the 2.1.0 migration" -- skills/dart-falconx-package dart_falconnect/CLAUDE.md
```

---

### Task 6: Final gates (controller)

- [ ] **Step 1: Run every gate from the worktree root**

```bash
melos run analyze
melos run format
melos run test
cd dart_falconnect && dart compile js test/web/compile_smoke.dart -o /tmp/json-log-smoke.js && dart test -p chrome test/web && cd ..
```

Expected: every command exits 0; tests dart_falconnect 267 (1 existing skip), dart_faltool 700, dart_falmodel 58, dart_falconx 1; Chrome 8.

- [ ] **Step 2: Check the spec's success criteria**

Walk spec section 16 line by line and point each at a passing test or a command above. Walk spec section 13 and confirm each file changed.

- [ ] **Step 3: Request the whole-branch review**

Use superpowers:requesting-code-review on `feature/json-log` against `develop`, on the most capable model. Give the reviewer this plan's Review Focus and Prototype rulings. Fix Critical and Important findings through a new commit per fix, each with a test that failed first.

- [ ] **Step 4: Hand over**

Report the branch, the commit list, the gate results, the review findings and their fixes, and the rulings. The owner merges `feature/json-log` into `develop`, bumps the version to 2.1.0 on `release/2.1.0`, and tags 2.1.0.
