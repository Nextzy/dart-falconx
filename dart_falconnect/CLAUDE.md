# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

`dart_falconnect` is the **top-layer network implementation package** in the FalconX monorepo. It provides HTTP, WebSocket, and JSON-RPC clients built on Dio and web_socket_channel. It depends on `dart_falmodel` (models/exceptions) and `dart_faltool` (utilities).

## Development Commands

```bash
# Install dependencies (from monorepo root)
melos get

# Code generation (required after modifying @freezed, @JsonSerializable, @retrofit files)
cd dart_falconnect
dart run build_runner build -d

# Run tests (unit_test.dart is a stub; real tests live under test/web/ — see Web Support)
dart test

# Analyze and format
dart analyze
dart format .
dart fix --apply
```

## Architecture

### Entry Points

- `dart_falconnect.dart` — Public API: re-exports Dio, Retrofit, web_socket_channel, dio_cache_interceptor, and `engine/engine.dart`
- `lib.dart` — Internal import: re-exports `dart:async`, `dart:convert`, plus `ansicolor`, `dart_falmodel`, `dart_faltool`, `freezed_annotation`, and `dart_falconnect.dart`. All internal files import this single file

### Three Network Engines

**HTTP (`engine/https/`)**
- `BaseHttpClient` — Abstract class wrapping Dio. Subclasses override `setupOptions()` and `setupInterceptors()`. All HTTP methods (GET/POST/PUT/PATCH/DELETE) require a `converter` function for type-safe JSON→T conversion. Uses `_performRequest()` internally which chains `.mapJson(converter).catchWhenError(catchError)`
- `RequestApiService` — Interface that `BaseHttpClient` implements
- `HttpClientConfig` — Configuration with factory constructors: `.production()`, `.development()`, `.test()`
- Response extensions (`extensions/response_extensions.dart`) provide `mapJson()`, `unwrapResponse()`, `catchWhenError()`, and `copyWith()`/`transformData()` on `Response<dynamic>?`

**WebSocket (`engine/sockets/`)**
- `SocketClient` — Abstract class with auto-reconnection, retry logic, and `PublishSubject<SocketResponse>` for stream-based responses. Auto-creates channel on first `request()` call
- `SocketBoundResource` — Transforms socket streams into `Result<EntityType>` with optional response processing and local persistence
- Has its own exception hierarchy: `SocketException`, `SocketRetryException`, `SocketOperationNotFoundException`
- Has its own interceptor system (`SocketInterceptor`, `SocketLogInterceptor`) separate from Dio interceptors

**JSON-RPC (`engine/rpc/`)**
- `JsonRpcService` — Abstract class for JSON-RPC 2.0 over HTTP (uses Dio). Provides `request()` (expects result), `notify()` (fire-and-forget), `notifySync()` (returns `FutureOr<void>`), and `batch()` (multiple calls)
- `DefaultJsonRpcService` — Concrete `JsonRpcService` implementation with no additional logic
- Error responses throw `JsonRpcErrorResponse`; missing `result` field throws `StateError`
- Batch responses return `List<BatchJsonRpcItem>` — sealed class with `resolve`/`map`/`responseOrNull`/`errorOrNull` convenience API

### Datasource Bound State (`engine/datasource_bound_state.dart`)

Repository pattern implementation with three strategies:
- `asLocalResultStream` / `asLocalResultFuture` — Local DB only
- `asRemoteResultStream` / `asRemoteResultFuture` — Remote API only
- `asResultStream` — Combined: loads local first, optionally fetches remote based on `shouldFetch()` predicate

All return `Result<DataType>` (success/failure union from dart_falmodel). When `ResponseType != DataType`, `processResponse` is required (enforced by assertion).

### HTTP Interceptor Chain

Seven interceptors available (barrel: `interceptors/interceptors.dart`):
1. `CacheInterceptor` — Response caching via dio_cache_interceptor
2. `RetryInterceptor` — Exponential backoff with jitter, respects `Retry-After` header, retries on 5xx/408/429/409/timeouts
3. `NetworkExceptionHandlerInterceptor` — Abstract: routes errors to `onClientError()`/`onServerError()`/`onNonStandardError()` based on status code ranges
4. `DefaultNetworkExceptionHandlerInterceptor` — Concrete: rejects all errors (no custom handling)
5. `PerformanceInterceptor` — Request timing
6. `RateLimitInterceptor` — Rate limiting
7. `LogInterceptor` — Request/response logging with ANSI colors

When adding new interceptors, add the export to `interceptors/interceptors.dart` (alphabetically sorted per lint rules).

### Key Patterns

- **Internal imports**: All files use `import 'package:dart_falconnect/lib.dart'` — never import individual files directly
- **No `dart:io` dependency**: `lib.dart` does not re-export `dart:io`; the package is portable to web. If you need `File`/`Platform`/`HttpClient`, import from `package:universal_io/io.dart` (via `dart_faltool`)
- **Converter-required API**: Every HTTP method requires a `converter: (Map<String, dynamic>) → T` parameter — there is no raw response API
- **`BaseRequestBody`**: POST/PUT/PATCH/DELETE data parameter type (from dart_falmodel), requires `.toJson()`
- **Error propagation**: `catchWhenError` resolves with the error handler's return value; if no handler, errors are rethrown as-is

## Gotchas

- `RateLimiter` in `utils/` is a placeholder (all code commented out) — do not use or reference it
- `test/unit_test.dart` is a stub with an empty test; the real tests are the web verification gates under `test/web/`
- `NetworkExceptionHandlerInterceptor` uses `err.toException()` extension method (from dart_falmodel) to convert `DioException` to `NetworkException`
- WebSocket uses RxDart's `PublishSubject` (not `ReplaySubject` despite the variable name `_replaySubject`)
- Generated files go to `lib/{{path}}/generated/` subdirectories per `build.yaml` configuration

## Web Support

This package is verified to compile and run on web. Two gates (run from `dart_falconnect/`):

```bash
# 1. Compile-time: every public engine type compiles to JavaScript
dart compile js test/web/compile_smoke.dart -o /tmp/compile_smoke.js

# 2. Runtime: instantiate HTTP client, interceptors, JSON-RPC service in a real browser (mocked, no network)
dart test -p chrome test/web/engine_web_test.dart
```

**Known caveats on web:**
- `PerformanceInterceptor.RequestMetrics` timing fields (`dnsLookupTime`, `connectionTime`, `tlsHandshakeTime`, `timeToFirstByte`, `downloadTime`) are always `null` — browsers do not expose XHR timing breakdowns to dio.
- `SocketClient` has compile-check coverage only; runtime behavior on web is delegated to `WebSocketChannel.connect()`'s auto-factory (VM → `IOWebSocketChannel`, web → `HtmlWebSocketChannel`).
- Dio's `httpClientAdapter` is left as the auto factory so it resolves to `BrowserHttpClientAdapter` on web automatically. Do **not** import `package:dio/io.dart` or set `IOHttpClientAdapter` directly — that would break web.
