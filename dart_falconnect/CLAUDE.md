# dart_falconnect

## Entry points

- `dart_falconnect.dart`: public API; re-exports Dio, Retrofit, `web_socket_channel`, `dio_cache_interceptor`, and `engine/engine.dart`.
- `lib/src/src.dart`: internal prelude; re-exports `dart:async`, `dart:convert`, `ansicolor`, `dart_falmodel`, `dart_faltool`, `freezed_annotation`, and `dart_falconnect.dart`.
- Import `package:dart_falconnect/src/src.dart` in a new file, except beside files that import each dependency by path: everything under `engine/https/config/` and `lib/src/` other than `src.dart` itself, and most of `engine/https/interceptors/`.

## HTTP (`engine/https/`)

- `BaseHttpClient` implements `RequestApiService`. `configure()` keeps each interceptor whose config box is unchanged, with its state, and rebuilds the rest. Every request method funnels into one private `_request()` that chains `.mapJson(converter).catchWhenError(catchError)`.
- `HttpClientConfig` (freezed) holds the Dio options it owns plus one box per feature, with no presets. A null `log`, `cache`, `concurrency`, or `retry` box turns that feature off. `rateLimit` defaults to `RateLimitConfig.none()`; its `pauseOnly` variant builds `RetryAfterPauseInterceptor`, and `tokenBucket` builds `TokenBucketRateLimitInterceptor`. A `LogConfig()` box builds `HttpLogInterceptor`; a `LogConfig.json()` box builds `HttpJsonLogInterceptor`. A `requestId` box, a `headerProvider` function, or an `auth` box builds `RequestStampInterceptor`; an `auth` box also builds an `AuthSession`, kept while the box is equal, and `TokenRefreshInterceptor`. An `ioAdapter` box on dart:io, or a `webAdapter` box on the web, replaces `dio.httpClientAdapter`; `configure` closes an adapter it replaces with `force: false`, never closes one it did not build, and restores the original when the box returns to null.
- `extensions/response_extensions.dart` provides `mapJson()`, `unwrapResponse()`, and `catchWhenError()` on response futures, plus `copyWith()` and `transformData()` on `Response<dynamic>?`.

## Interceptor chain

`BaseHttpClient.configure` assembles the chain in this order: `RequestStampInterceptor` → the config's `interceptors` → `HttpLogInterceptor` or `HttpJsonLogInterceptor` → `CacheInterceptor` → `ConcurrencyLimitInterceptor` → rate limiter → `TokenRefreshInterceptor` → `RetryInterceptor` → the cache fallback, when its box enables it → exception handler.

| Interceptor                                 | Role                                                                                                                                    |
|---------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `RequestStampInterceptor`                   | stamps the request ID, the header provider's headers, and the access token on every attempt                                             |
| `TokenRefreshInterceptor`                   | on a 401, one refresh shared through `AuthSession`, then a re-send through the whole chain                                              |
| `HttpLogInterceptor`                        | ANSI-colored multi-line log; redacts listed headers and query values                                                                    |
| `HttpJsonLogInterceptor`                    | one JSON line per attempt with OpenTelemetry field names, for servers                                                                   |
| `CacheInterceptor`                          | wraps `dio_cache_interceptor`: HTTP caching by server headers, keyed by URL and `keyHeaders`; `fallback` answers failures after retries |
| `ConcurrencyLimitInterceptor`               | caps requests in flight per host and in total on `resilience` `Bulkhead`s                                                               |
| `TokenBucketRateLimitInterceptor`           | token buckets from `TokenBucketPolicy` lists plus a per-host pause on a 429 or 503 `Retry-After`                                        |
| `RetryAfterPauseInterceptor`                | the pause alone; never chain it beside `TokenBucketRateLimitInterceptor`                                                                |
| `RetryInterceptor`                          | backoff retries bounded by `RetryConfig`; idempotent methods only, except on 429 and `connectionTimeout`                                |
| `NetworkExceptionHandlerInterceptor`        | abstract; routes errors to `onClientError`, `onServerError`, or `onNonStandardError` by status range                                    |
| `DefaultNetworkExceptionHandlerInterceptor` | rejects every error unchanged                                                                                                           |

- The cache, concurrency, rate-limit, and retry interceptors take their config box plus an optional `logPrint`.
- Unexported helpers: the pause core in `lib/src/engine/https/interceptors/retry_after_pause.dart`, the host-key rule in `lib/src/engine/https/interceptors/host_key.dart`, the log redaction helpers and the log start key in `lib/src/engine/https/interceptors/log_redaction.dart`, the retry loop's final-error marker in `lib/src/engine/https/interceptors/retry_attempts.dart`, the auth bookkeeping in `extra` in `lib/src/engine/https/interceptors/auth_extra.dart`, `watchCancel` in `lib/src/engine/https/cancel_watch.dart`, and the platform adapters, the pinning connector, and the SPKI reader in `lib/src/engine/https/adapter/`.
- Export a new interceptor from `interceptors/interceptors.dart`; that barrel also exports `local_rate_limit.dart`, which tells a client-made 429 from a server 429.
- Interceptor model classes live in `interceptors/models/` as freezed classes (generated output in `models/generated/`); `getStatistics()` returns immutable snapshots, never live interceptor state.

## WebSocket (`engine/sockets/`)

- `SocketClient` opens its channel on the first `request()` and emits responses through a `PublishSubject<SocketResponse>`.
- `SocketBoundResource` turns a socket stream into `Result<EntityType>`, with optional response processing and local persistence.
- Socket errors: `SocketException` and its subclasses `SocketRetryException` and `SocketOperationNotFound`.
- Socket interceptors: `SocketInterceptor` and `SocketLogInterceptor`.

## JSON-RPC (`engine/rpc/`)

- `JsonRpcService` offers `request()` (expects a result), `notify()` (fire-and-forget), `notifySync()` (returns `FutureOr<void>`), and `batch()`.
- `request()` throws `JsonRpcErrorResponse` on an error response and `StateError` when `result` is missing.
- Each `BatchJsonRpcItem` exposes `resolve`, `map`, `responseOrNull`, and `errorOrNull`.

## Datasource bound state (`engine/datasource_bound_state.dart`)

Every `DatasourceBoundState` strategy returns `Result<DsType>`:

| Source                                              | Methods                                        |
|-----------------------------------------------------|------------------------------------------------|
| Local only                                          | `asLocalResultStream`, `asLocalResultFuture`   |
| Remote only                                         | `asRemoteResultStream`, `asRemoteResultFuture` |
| Local first, then remote when `shouldFetch` is true | `asResultStream`                               |

- Pass `processResponse` whenever `ResponseType` differs from `DsType`; an assertion enforces it.

## Conventions

- No raw-response method exists: a `JsonResponseConverter<T>` receives the decoded `Map<String, dynamic>`.
- Type the `data` of POST, PUT, PATCH, and DELETE as `BaseRequestBody` (from `dart_falmodel`), which requires `toJson()`.
- Error propagation: `catchWhenError` recovers a `DioException` with the fallback's value; a missing fallback, a null result, or any other error rethrows the original. A `String` body reaches the converter as `{'result': body}`; any other body that is not a JSON object, or a converter that throws, fails with a `DioException` holding `CommonException(type: InputErrorType.invalidFormat)`.

## Gotchas

- A freezed model importing `dart_faltool` with `show` (e.g. `show clock`) makes json_serializable silently skip JSON generation: import it fully so `JsonKey`/converters resolve.
- `TokenBucketRateLimitInterceptor` refill timers outlive the last request: in `testWidgets`, call `dispose()` in the test body, since `addTearDown` runs too late; on a server, build one instance per process.
- Interceptor tests live in `test/engine/https/interceptors/` and run under `fakeAsync`; other engine tests live under `test/engine/`, and the web gate under `test/web/`.
- Give every test Dio answered by `ScriptedAdapter` or `GatedAdapter` a `FoldingTransformer` (`test/engine/https/interceptors/_scripted_adapter.dart`): under `fakeAsync` on dart2js, Dio's `await for` body read awaits a root-zone future that `fakeAsync` never flushes, and the response stalls.
- `dio_cache_interceptor` reads `DateTime.now()`, not `clock`: test cache expiry with short real waits, outside `fakeAsync`.
- `NetworkExceptionHandlerInterceptor` converts a `DioException` to a `NetworkException` through `err.toException()` from `dart_falmodel`.
- `SocketClient._replaySubject` holds a `PublishSubject`: a late listener misses earlier responses.
- Wait on a `CancelToken` through `watchCancel`, never `cancelToken.whenCancel.then(...)`: a `Future` listener cannot be removed, so a long-lived token collects one per finished wait.

## Web caveats

- `SocketClient` has compile-check coverage only; at runtime `WebSocketChannel.connect()` picks the browser or `dart:io` socket through `package:web_socket`.
- Import `package:dio/io.dart` only in `lib/src/engine/https/adapter/platform_adapter_io.dart` and `package:dio/browser.dart` only in `platform_adapter_web.dart`, both behind the conditional export of `platform_adapter.dart`; everywhere else, leave `httpClientAdapter` to `configure`.
- `dio_web_adapter` counts the time a request waits in the browser's own connection queue toward `connectTimeout`.
