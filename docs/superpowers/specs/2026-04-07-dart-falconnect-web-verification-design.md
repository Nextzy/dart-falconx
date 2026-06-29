# dart_falconnect Web Compatibility Verification

**Date:** 2026-04-07
**Status:** Approved — ready for implementation plan
**Scope:** `dart_falconnect` package

## Background

During a prior session we removed `export 'dart:io'` from the `lib.dart` preludes of `dart_falconnect` and `dart_falmodel` (commit `86f6bbb`) to move toward web-portable packages. A subsequent audit showed:

- No `.dart` file in `dart_falconnect/lib` imports `dart:io` directly.
- `BaseHttpClient` does not set `httpClientAdapter` — it relies on dio's default factory (`HttpClientAdapter()`), which auto-selects `IOHttpClientAdapter` on VM and `BrowserHttpClientAdapter` on web.
- `SocketClient` uses `WebSocketChannel.connect()` (auto-factory), not the VM-only `IOWebSocketChannel`.
- `HttpClientConfig` exposes no VM-only knobs (`badCertificateCallback`, proxy, `onHttpClientCreate` are all absent).
- `CacheInterceptor` is a custom in-memory cache — it does not use any file/disk backend from `dio_cache_interceptor`.
- `dart_falmodel`'s `exception_extensions.dart` still references `HttpException`, `HandshakeException`, `CertificateException`, `FileSystemException`, `IOException`, but these resolve via `package:universal_io/io.dart` which `dart_faltool` re-exports (line 28 of `dart_faltool/lib/dart_faltool.dart`) — `universal_io` provides web-safe stubs.

**Conclusion:** `dart_falconnect` is believed to be web-compatible already. This project is about **verification and documentation**, not refactoring.

## Goals

1. Prove web compatibility with an automated check that runs in CI.
2. Lock in the property so future changes cannot silently break web support.
3. Document the one known runtime caveat (`PerformanceInterceptor` timing fields).

## Non-goals

- No new platform-specific adapters (dio/web_socket_channel already handle this).
- No line-count reduction / architectural refactor of the `engine/` tree.
- No Flutter example app.
- No breaking changes to `RequestMetrics` fields.
- No SocketClient runtime smoke test on chrome (compile-check only — see Section 3).

## Deliverables

1. **Compile-time gate** — `dart compile js` succeeds against an entry point that touches every public engine type (HTTP / Socket / RPC) so tree-shaking cannot mask VM-only paths.
2. **Runtime smoke test** — a `@TestOn('browser')` test file that runs under `dart test -p chrome`, exercising HTTP client and JSON-RPC instantiation and basic call paths with mocks (no live network).
3. **Doc updates** — `RequestMetrics` fields that cannot be populated on web get doc comments; `dart_falconnect/CLAUDE.md` gets a new `## Web Support` section.
4. **Melos script** — `melos run verify:web` runs the compile check and the chrome test in sequence from the repo root.

## Architecture

### 3a. Compile-time entry point

**File:** `dart_falconnect/test/web/compile_smoke.dart`

A plain `main()` with no `package:test` import, so it can be fed directly to `dart compile js`. It must instantiate each public engine type (or subclass thereof) so the compiler walks the full graph:

- `HttpClientConfig.production()` / `.development()` / `.test()`
- A minimal `BaseHttpClient` subclass (or reference `BaseHttpClient` via a tear-off if abstract)
- `CacheInterceptor`, `RetryInterceptor`, `LogInterceptor`, `PerformanceInterceptor`, `RateLimitInterceptor`, `DefaultNetworkExceptionHandlerInterceptor`
- `DefaultJsonRpcService`
- `SocketClient` subclass reference
- `WebSocketChannel` (touched via `SocketClient` import chain)

**Verification command:**
```bash
dart compile js -o /tmp/dart_falconnect_web.js \
  dart_falconnect/test/web/compile_smoke.dart
```

Success = exit code 0. Output JS file is not inspected.

### 3b. Runtime smoke test

**File:** `dart_falconnect/test/web/engine_web_test.dart`

```dart
@TestOn('browser')
library;

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

void main() {
  group('dart_falconnect on web', () {
    test('HttpClientConfig factories build', () { ... });
    test('BaseHttpClient subclass instantiates with default adapter', () { ... });
    test('DefaultJsonRpcService serializes a request', () { ... });
    test('All interceptors instantiate', () { ... });
  });
}
```

- Mock-based — **no live network**.
- **No SocketClient runtime test** per Section 3 decision — compile-check in 3a is sufficient, since `WebSocketChannel.connect()` is an auto-factory. Avoids CI flakiness from needing a reachable WebSocket echo server.

**Verification command:**
```bash
cd dart_falconnect && dart test -p chrome test/web/engine_web_test.dart
```

### 3c. Melos script

Add to the root `pubspec.yaml` under `melos.scripts` (root is canonical per project convention — Melos scripts live in root `pubspec.yaml`, not `melos.yaml` or per-package):

```yaml
melos:
  scripts:
    verify:web:
      description: Verify dart_falconnect compiles and runs on web
      run: |
        cd dart_falconnect && \
        dart compile js -o /tmp/dart_falconnect_web.js test/web/compile_smoke.dart && \
        dart test -p chrome test/web/engine_web_test.dart
```

### 3d. Documentation updates

**`dart_falconnect/lib/engine/https/interceptors/performance_interceptor.dart`** — add doc comments to the five timing fields in `RequestMetrics`:

- `dnsLookupTime`
- `connectionTime`
- `tlsHandshakeTime`
- `timeToFirstByte`
- `downloadTime`

Comment text: `/// Always null on web — browsers do not expose XHR timing breakdowns to dio.`

**`dart_falconnect/CLAUDE.md`** — add a new section:

```markdown
## Web Support

This package is verified to compile and run on web. To verify:

```bash
melos run verify:web
```

**Known caveats on web:**
- `PerformanceInterceptor.RequestMetrics` timing fields (`dnsLookupTime`,
  `connectionTime`, `tlsHandshakeTime`, `timeToFirstByte`, `downloadTime`)
  are always `null` — browsers do not expose these to XHR.
- `SocketClient` has compile-check coverage only; runtime behavior on web
  is covered by `WebSocketChannel.connect()`'s auto-factory.
```

## Risks & mitigations

| # | Risk | Mitigation |
|---|------|------------|
| 1 | `dart compile js` fails on transitive dep (`universal_io`, `dartx`, `logger`, `ansicolor`) | Fix only if root cause is in `dart_falconnect`. If in `dart_faltool`/`dart_falmodel`, report as follow-up task and stop — do NOT expand scope. |
| 2 | `dart test -p chrome` requires browser runner setup | Already satisfied — `test: ^1.31.2` is in `dev_dependencies`. |
| 3 | `compile_smoke.dart` accidentally imports `package:test` | Enforce via review; the file must be a plain `main()`. |
| 4 | `ansicolor` may emit escape codes that look wrong in browser console | Acceptable — logging still works, just without color. No fix needed. |
| 5 | Mock setup for `BaseHttpClient` HTTP test is non-trivial | Use `dio`'s `HttpClientAdapter` mock or `MockAdapter` pattern. Scope this to happy-path instantiation + serialization only, not full request/response mocking. |

## Out-of-scope (explicit)

- Transitive fixes in `dart_faltool` / `dart_falmodel` — if Risk #1 fires, report and exit.
- Refactoring `PerformanceInterceptor` (486 lines) or any other large file.
- Removing any `RequestMetrics` field.
- Flutter `example/` app.
- Live network calls from CI.
