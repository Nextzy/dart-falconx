# dart_falconnect Web Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove `dart_falconnect` compiles and runs on web, lock it in via a `melos run verify:web` script, and document the one known runtime caveat.

**Architecture:** Verification-only. Add a compile-smoke entry point (`dart compile js`), a mock-based browser smoke test (`dart test -p chrome`), doc comments on `PerformanceInterceptor.RequestMetrics` fields that cannot be populated on web, a `## Web Support` section in `dart_falconnect/CLAUDE.md`, and a root Melos script combining the two checks.

**Tech Stack:** Dart SDK ≥3.9.0, `dio ^5.9.2`, `web_socket_channel ^3.0.3`, `test ^1.31.0`, Melos ^7.5.1. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-04-07-dart-falconnect-web-verification-design.md`

---

## File Map

| Path | Action | Responsibility |
|---|---|---|
| `dart_falconnect/test/web/compile_smoke.dart` | Create | Plain `main()` entry point that instantiates every public engine type so `dart compile js` walks the full graph. No `package:test` import. |
| `dart_falconnect/test/web/engine_web_test.dart` | Create | `@TestOn('browser')` smoke tests for HTTP/RPC/interceptors. Mock-based, no live network. |
| `dart_falconnect/test/web/_stub_http_client.dart` | Create | Minimal `BaseHttpClient` + `SocketClient` subclasses used by both smoke files. Single shared stub file to avoid duplication. |
| `dart_falconnect/lib/engine/https/interceptors/performance_interceptor.dart` | Modify | Add doc comments to 5 timing fields that are always null on web. |
| `dart_falconnect/CLAUDE.md` | Modify | Append `## Web Support` section. |
| `pubspec.yaml` (repo root) | Modify | Add `verify:web` Melos script. |

---

## Task 1: Create shared stub subclasses

`BaseHttpClient` and `SocketClient` are both abstract (`dart_falconnect/lib/engine/https/http_client.dart:11` and `dart_falconnect/lib/engine/sockets/socket_client.dart:3`), so both the compile smoke and the runtime test need concrete subclasses. Put them in one file.

**Files:**
- Create: `dart_falconnect/test/web/_stub_http_client.dart`

- [ ] **Step 1: Create the stub file**

```dart
// Minimal concrete subclasses for web verification.
// Used by compile_smoke.dart and engine_web_test.dart.
// Not a public API — filename starts with underscore.
import 'package:dart_falconnect/dart_falconnect.dart';

class StubHttpClient extends BaseHttpClient {
  StubHttpClient({required super.dio});
}

class StubSocketClient extends SocketClient {
  StubSocketClient(super.baseUrl);

  @override
  void setupConfig(SocketOptions configs) {
    // no-op — defaults from SocketClient are sufficient for smoke
  }
}
```

- [ ] **Step 2: Verify it analyzes**

Run:
```bash
cd dart_falconnect && dart analyze test/web/_stub_http_client.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add dart_falconnect/test/web/_stub_http_client.dart
git commit -m "test(falconnect): add StubHttpClient for web verification"
```

---

## Task 2: Write `compile_smoke.dart` entry point

Touches every public engine type so the dart2js tree-shaker cannot hide VM-only code paths. Must be a plain `main()` with **no `package:test` import** (otherwise `dart compile js` would need to compile the test runner).

**Files:**
- Create: `dart_falconnect/test/web/compile_smoke.dart`

- [ ] **Step 1: Write the smoke entry point**

```dart
// Compile-time smoke for dart_falconnect on web.
//
// Run:
//   dart compile js -o /tmp/out.js \
//     dart_falconnect/test/web/compile_smoke.dart
//
// Success = exit code 0. No runtime execution.
// If dart2js fails, dart_falconnect has a VM-only code path.
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/engine/https/interceptors/cache_interceptor.dart';
import 'package:dart_falconnect/engine/https/interceptors/log_interceptor.dart';
import 'package:dart_falconnect/engine/https/interceptors/performance_interceptor.dart';
import 'package:dart_falconnect/engine/https/interceptors/rate_limit_interceptor.dart';
import 'package:dart_falconnect/engine/https/interceptors/retry_interceptor.dart';

import '_stub_http_client.dart';

// Prevents the compiler from tree-shaking the touched types.
// The list is read into a side-effect sink so nothing gets
// marked as unused.
void _sink(Object? o) {
  if (identical(o, const Object())) print(o);
}

void main() {
  // HTTP config factories
  _sink(HttpClientConfig.production());
  _sink(HttpClientConfig.development());
  _sink(HttpClientConfig.test());

  // HTTP client
  final dio = Dio();
  _sink(StubHttpClient(dio: dio));

  // All interceptors
  final cfg = HttpClientConfig.development();
  _sink(CacheInterceptor(config: cfg));
  _sink(RetryInterceptor(config: cfg));
  _sink(PerformanceInterceptor(config: cfg));
  _sink(RateLimitInterceptor(config: cfg));
  _sink(FalconLogInterceptor());
  _sink(DefaultNetworkExceptionHandlerInterceptor());

  // JSON-RPC
  _sink(DefaultJsonRpcService(dio: dio));

  // WebSocket — touch type only, do NOT call connect().
  // connect() at import time would hang the smoke; we only
  // need the compiler to walk the type graph.
  _sink(StubSocketClient.new);
}
```

- [ ] **Step 2: Verify interceptor constructor names**

Before running the compile, confirm the interceptor class names and constructor params match what you wrote above. Run:

```bash
grep -n "^class " dart_falconnect/lib/engine/https/interceptors/*.dart
grep -n "^class " dart_falconnect/lib/engine/rpc/*.dart
```

Expected: every class name referenced in Step 1 must appear. If any name differs (e.g., `FalconLogInterceptor` might actually be `LogInterceptor`), update `compile_smoke.dart` to match and re-verify. Also confirm `DefaultJsonRpcService` takes `{required Dio dio}` — if not, adjust.

- [ ] **Step 3: Run `dart compile js`**

Run:
```bash
cd dart_falconnect && dart compile js -o /tmp/dart_falconnect_web.js test/web/compile_smoke.dart
```

Expected: exit code 0 with a message like `Compiled ... to JavaScript: /tmp/dart_falconnect_web.js`.

If it fails:
- If the error is in `dart_falconnect` code → fix inline and re-run.
- If the error is in `dart_faltool` / `dart_falmodel` / a third-party package → **STOP**. Per spec Risk #1: report the root cause, do not expand scope. Create a follow-up note in the commit message and leave the plan here for the user to decide.

- [ ] **Step 4: Commit**

```bash
git add dart_falconnect/test/web/compile_smoke.dart
git commit -m "test(falconnect): add web compile smoke entry point"
```

---

## Task 3: Write browser runtime smoke test

Mock-based. No live network. Only covers HTTP client instantiation, interceptor construction, and JSON-RPC request serialization. SocketClient is intentionally excluded per spec (compile-check only).

**Files:**
- Create: `dart_falconnect/test/web/engine_web_test.dart`

- [ ] **Step 1: Write the failing test file**

```dart
@TestOn('browser')
library;

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/engine/https/interceptors/cache_interceptor.dart';
import 'package:dart_falconnect/engine/https/interceptors/log_interceptor.dart';
import 'package:dart_falconnect/engine/https/interceptors/performance_interceptor.dart';
import 'package:dart_falconnect/engine/https/interceptors/rate_limit_interceptor.dart';
import 'package:dart_falconnect/engine/https/interceptors/retry_interceptor.dart';
import 'package:test/test.dart';

import '_stub_http_client.dart';

void main() {
  group('dart_falconnect on web', () {
    test('HttpClientConfig factories build without throwing', () {
      expect(HttpClientConfig.production(), isNotNull);
      expect(HttpClientConfig.development(), isNotNull);
      expect(HttpClientConfig.test(), isNotNull);
    });

    test('BaseHttpClient subclass instantiates with default adapter', () {
      final dio = Dio();
      final client = StubHttpClient(dio: dio);
      expect(client.dio, same(dio));
      // dio.httpClientAdapter is the auto factory; on web
      // this resolves to BrowserHttpClientAdapter at runtime.
      expect(dio.httpClientAdapter, isNotNull);
    });

    test('All HTTP interceptors instantiate on web', () {
      final cfg = HttpClientConfig.development();
      expect(CacheInterceptor(config: cfg), isNotNull);
      expect(RetryInterceptor(config: cfg), isNotNull);
      expect(PerformanceInterceptor(config: cfg), isNotNull);
      expect(RateLimitInterceptor(config: cfg), isNotNull);
      expect(DefaultNetworkExceptionHandlerInterceptor(), isNotNull);
    });

    test('DefaultJsonRpcService builds on web', () {
      final dio = Dio();
      final rpc = DefaultJsonRpcService(dio: dio);
      expect(rpc, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Verify names against Task 2**

Every class referenced here must match the names you verified in Task 2 Step 2. If you adjusted names there, apply the same changes here.

- [ ] **Step 3: Run on chrome**

Run:
```bash
cd dart_falconnect && dart test -p chrome test/web/engine_web_test.dart
```

Expected: all 4 tests PASS.

If chrome runner is missing, install with:
```bash
dart pub global activate test
```

If tests fail because a class name or constructor signature differs, fix inline and re-run.

- [ ] **Step 4: Commit**

```bash
git add dart_falconnect/test/web/engine_web_test.dart
git commit -m "test(falconnect): add browser smoke test for engine"
```

---

## Task 4: Document `RequestMetrics` web caveat

Add doc comments to the 5 timing fields that cannot be populated on web. This is pure text edit, no behavior change.

**Files:**
- Modify: `dart_falconnect/lib/engine/https/interceptors/performance_interceptor.dart` (lines 21–37)

- [ ] **Step 1: Replace the 5 field doc comments**

Old (current lines 21–37):

```dart
  /// Time spent in DNS lookup.
  Duration? dnsLookupTime;

  /// Time spent establishing connection.
  Duration? connectionTime;

  /// Time spent in TLS handshake.
  Duration? tlsHandshakeTime;

  /// Time spent sending the request.
  Duration? requestTime;

  /// Time spent waiting for first byte.
  Duration? timeToFirstByte;

  /// Time spent downloading response.
  Duration? downloadTime;
```

New:

```dart
  /// Time spent in DNS lookup.
  ///
  /// Always `null` on web — browsers do not expose XHR timing
  /// breakdowns to dio.
  Duration? dnsLookupTime;

  /// Time spent establishing connection.
  ///
  /// Always `null` on web — browsers do not expose XHR timing
  /// breakdowns to dio.
  Duration? connectionTime;

  /// Time spent in TLS handshake.
  ///
  /// Always `null` on web — browsers do not expose XHR timing
  /// breakdowns to dio.
  Duration? tlsHandshakeTime;

  /// Time spent sending the request.
  Duration? requestTime;

  /// Time spent waiting for first byte.
  ///
  /// Always `null` on web — browsers do not expose XHR timing
  /// breakdowns to dio.
  Duration? timeToFirstByte;

  /// Time spent downloading response.
  ///
  /// Always `null` on web — browsers do not expose XHR timing
  /// breakdowns to dio.
  Duration? downloadTime;
```

Note: `requestTime` is intentionally NOT annotated — request-send duration IS measurable on web (end of request — start of request).

- [ ] **Step 2: Analyze to confirm no syntax break**

Run:
```bash
cd dart_falconnect && dart analyze lib/engine/https/interceptors/performance_interceptor.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add dart_falconnect/lib/engine/https/interceptors/performance_interceptor.dart
git commit -m "docs(falconnect): mark RequestMetrics fields null-on-web"
```

---

## Task 5: Add `## Web Support` section to `dart_falconnect/CLAUDE.md`

**Files:**
- Modify: `dart_falconnect/CLAUDE.md` (append to end, after current final line)

- [ ] **Step 1: Append the Web Support section**

Append exactly this block (keep one blank line before it):

```markdown

## Web Support

This package is verified to compile and run on web. To verify:

```bash
melos run verify:web
```

This runs two gates:
1. `dart compile js` against `test/web/compile_smoke.dart` — ensures every public engine type compiles to JavaScript.
2. `dart test -p chrome test/web/engine_web_test.dart` — instantiates HTTP client, interceptors, and JSON-RPC service in a real browser (mocked, no network).

**Known caveats on web:**
- `PerformanceInterceptor.RequestMetrics` timing fields (`dnsLookupTime`, `connectionTime`, `tlsHandshakeTime`, `timeToFirstByte`, `downloadTime`) are always `null` — browsers do not expose XHR timing breakdowns to dio.
- `SocketClient` has compile-check coverage only; runtime behavior on web is delegated to `WebSocketChannel.connect()`'s auto-factory (VM → `IOWebSocketChannel`, web → `HtmlWebSocketChannel`).
- Dio's `httpClientAdapter` is left as the auto factory so it resolves to `BrowserHttpClientAdapter` on web automatically. Do **not** import `package:dio/io.dart` or set `IOHttpClientAdapter` directly — that would break web.
```

- [ ] **Step 2: Commit**

```bash
git add dart_falconnect/CLAUDE.md
git commit -m "docs(falconnect): document web support and caveats"
```

---

## Task 6: Add `verify:web` Melos script

**Files:**
- Modify: `pubspec.yaml` (repo root, under `melos.scripts`)

- [ ] **Step 1: Append the script**

In the root `pubspec.yaml`, under `melos.scripts`, add the `verify:web` entry after the existing `build_runner` entry (preserving the existing scripts exactly):

```yaml
    verify:web:
      description: Verify dart_falconnect compiles and runs on web
      run: |
        cd dart_falconnect && \
        dart compile js -o /tmp/dart_falconnect_web.js test/web/compile_smoke.dart && \
        dart test -p chrome test/web/engine_web_test.dart
```

After editing, the `melos.scripts` block should look like:

```yaml
melos:
  scripts:
    get:
      description: Get dependencies for all packages
      run: dart pub get
      exec:
        concurrency: 1

    upgrade:
      description: Upgrade dependencies in all packages
      run: dart pub upgrade
      exec:
        concurrency: 1

    outdated:
      description: Check outdated dependencies
      run: dart pub outdated
      exec:
        concurrency: 1

    build_runner:
      description: Run build_runner in all packages
      run: dart run build_runner build -d
      exec:
        concurrency: 1

    verify:web:
      description: Verify dart_falconnect compiles and runs on web
      run: |
        cd dart_falconnect && \
        dart compile js -o /tmp/dart_falconnect_web.js test/web/compile_smoke.dart && \
        dart test -p chrome test/web/engine_web_test.dart
```

- [ ] **Step 2: Run the script end-to-end**

Run:
```bash
melos run verify:web
```

Expected:
1. Compile step prints `Compiled .../compile_smoke.dart to JavaScript: /tmp/dart_falconnect_web.js`
2. Test step prints 4 passing tests
3. Script exits 0

If it fails, diagnose:
- Compile error → scope check again, apply the Risk #1 rule from spec
- Test fail → likely a class-name mismatch from Task 2/3; fix inline
- `melos: command not found` → run `dart pub global activate melos` first

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml
git commit -m "build: add melos verify:web script for dart_falconnect"
```

---

## Task 7: Final verification pass

Run everything one more time on a clean tree to make sure the plan is reproducible, then push.

- [ ] **Step 1: Run the full script**

```bash
melos run verify:web
```

Expected: exits 0, 4 tests pass.

- [ ] **Step 2: Run the full analyzer for dart_falconnect**

```bash
cd dart_falconnect && dart analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Review git log**

```bash
git log --oneline -8
```

Expected: 6 new commits from this plan (Tasks 1, 2, 3, 4, 5, 6) on top of the spec commit.

- [ ] **Step 4: Push** (only if user has explicitly authorized pushing)

```bash
git push origin develop
```

Skip this step unless authorized. Otherwise stop and report that the branch is ready to push.

---

## Rollback / abort criteria

Stop the plan and report to the user if ANY of these trigger:

1. Task 2 Step 3 fails with a root cause in `dart_faltool` or `dart_falmodel` (spec Risk #1).
2. `dart test -p chrome` cannot be made to work on this machine (e.g., no Chrome available and no way to install).
3. A class name / constructor signature drift from what this plan assumed requires more than 3 inline fixes — that signals the plan itself is stale and should be rewritten.

In all three cases: commit what IS done, summarize findings in the final commit message, and hand back to the user.
