# Configurable HTTP clients (client-config core)

**Date:** 2026-09-24
**Packages:** `dart_falconnect`, `dart_faltool`
**Version:** no bump. Every package is already 2.0.0.
**Series:** the first spec of the `dart-falconx-client-config` phase. It builds on SP1 (`2026-09-23-token-bucket-rate-limit-design.md`), SP2 (`2026-09-23-token-bucket-429-pause-design.md`), and SP3 (`2026-09-23-concurrency-limit-design.md`). Owner ruling 2026-09-24: 2.0.0 is held until this spec lands, so users migrate once. Breaking changes are allowed until the tag.
**Contract:** the SP1, SP2, and SP3 specs describe what exists. Section 14 lists every change this spec makes to them.

## 1. Context

`DefaultHttpClient.instance` has fixed options: JSON content type, 20 s connect and receive timeouts, and one `DefaultNetworkExceptionHandlerInterceptor`. An app that needs anything else must subclass `BaseHttpClient` and assemble the interceptor chain by hand. Code readings on 2026-09-23 and 2026-09-24 found these gaps:

1. `HttpClientConfig` is not exported. `https.dart` does not export `config/`, yet six interceptors require the class in their constructors.
2. `DefaultNetworkExceptionHandlerInterceptor` calls `handler.reject` for every error, which skips every later interceptor (dio 5.11.1, `ErrorInterceptorHandler.reject`). `addInterceptors` appends after it, so an interceptor added at run time never sees an error.
3. `applyTo` sets `validateStatus` to `status < 500`. A 4xx then arrives in `onResponse`, so 408, 409, and 429 never reach `RetryInterceptor` and `onClientError` never runs. SP2 left this fix to this phase.
4. Four fields are never read: `maxConnectionsPerHost`, `idleConnectionTimeout`, `validateCertificates`, and `logBodies`.
5. Every interceptor takes the whole `HttpClientConfig`, and all six read `enableLogging`.
6. Retrofit-generated code reads `dio.options.baseUrl` on every call, but an absolute `baseUrl` given to the API factory or to `@RestApi(baseUrl:)` wins (`retrofit_generator` 10.2.11, `_combineBaseUrls`). The skill's own example passes one, so switching the base URL on the client has no effect for that API.
7. `BaseHttpClient` configures dio through two hooks, `setupOptions` and `setupInterceptors`. They run once inside its constructor, before subclass fields are set. Each subclass orders the chain by hand, and nothing can change the configuration afterwards.
8. `catchWhenError` resolves with null data when the fallback returns null, although its doc says the error is rethrown.
9. `catchWhenError` crashes with a null-check error when the failure has no response, such as a timeout or a lost connection: `transformData` calls `this!` on null. Its JSON-RPC and Retrofit variants resolve with a plain `Response` where a `JsonRpcResponse` or an `HttpResponse` is expected, which by the types fails at run time.
10. `mapJson` casts the body to a map. A top-level JSON array, or an empty JSON body that dio decodes to null, throws a `TypeError`; so does any exception from the converter. Neither is a `DioException`, so `catchError` never sees them.
11. The seven request methods repeat the same forwarding and docs. `get` accepts an async converter and the others do not; `queryParameters` rejects null values; `isUseToken` is accepted and dropped.

## 2. Goals and non-goals

**Goals**

- Configure any `BaseHttpClient`, `DefaultHttpClient.instance` included, when it is built, and change it at any time, without overriding hooks.
- A change applies to requests that start after `configure` returns. Requests already running finish on the configuration they started with.
- A change rebuilds only the interceptors whose settings changed. Token buckets, 429 pauses, concurrency slots, cache entries, and performance statistics survive an unrelated change, such as turning logging on.
- One configuration type: `HttpClientConfig`, restructured into freezed per-feature boxes. Every interceptor takes only its own box.
- The client fixes the chain order. The app cannot misorder it.
- An app that never calls `configure` keeps today's behaviour.
- Fix the error-recovery and response-mapping bugs of gaps 8 to 10.
- Reduce the request methods of `BaseHttpClient` to one request path with consistent signatures.

**Non-goals**

- Platform adapter options: connection pool size, idle timeout, certificate pinning, proxy, and `withCredentials`. They belong to the `dart-falconx-client-extensions` phase.
- Auth with 401 refresh, `isUseToken`, a header provider, and a request ID. Same phase.
- Tracking, draining, or migrating running requests at a switch.
- Configuration presets. `production()`, `development()`, and `test()` are removed; apps define their own configurations.
- A second custom slot after `ConcurrencyLimitInterceptor` for interceptors that re-send from `onError`. The auth spec decides.
- Guarding against `dio.interceptors.add(...)` called directly. Documented only.
- Parsing top-level JSON arrays with the converter-based methods. Endpoints that return a list use Retrofit, the recommended path.
- New `HEAD` or `download` methods.
- The hooks of the WebSocket engine (`SocketClient.setupConfig` and `setupInterceptors`). Only the HTTP engine changes.

## 3. `HttpClientConfig`

`HttpClientConfig` becomes a freezed class. It holds the dio options and one box per feature. A null box turns its feature off.

```dart
@freezed
abstract class HttpClientConfig with _$HttpClientConfig {
  const HttpClientConfig._();

  const factory({
    @Default('') String baseUrl,
    @Default(Duration(seconds: 20)) Duration connectTimeout,
    @Default(Duration(seconds: 20)) Duration receiveTimeout,
    Duration? sendTimeout,
    @Default(Headers.jsonContentType) String contentType,
    @Default(<String, String>{}) Map<String, String> headers,
    String? userAgent,
    @Default(true) bool followRedirects,
    @Default(5) int maxRedirects,
    ValidateStatus? validateStatus,
    LogConfig? log,
    PerformanceConfig? performance,
    CacheConfig? cache,
    ConcurrencyConfig? concurrency,
    @Default(RateLimitConfig.none()) RateLimitConfig rateLimit,
    RetryConfig? retry,
    @Default(<Interceptor>[]) List<Interceptor> interceptors,
    NetworkExceptionHandlerInterceptor? exceptionHandler,
  }) = _HttpClientConfig;

  void applyTo(Dio dio) { ... }
}
```

| Field | Default | Notes |
|---|---|---|
| `baseUrl` | `''` | |
| `connectTimeout`, `receiveTimeout` | 20 s | Was 30 s in the old class; 20 s matches today's `DefaultHttpClient`. |
| `sendTimeout` | null | No limit, as today. |
| `contentType` | `Headers.jsonContentType` | Today's `DefaultHttpClient` value. |
| `headers` | empty | |
| `userAgent` | null | Sets `User-Agent` when not null. |
| `followRedirects`, `maxRedirects` | true, 5 | |
| `validateStatus` | null | Null leaves dio's default: only 2xx succeeds. |
| `log`, `performance`, `cache`, `concurrency`, `retry` | null | Off. |
| `rateLimit` | `RateLimitConfig.none()` | No limit. |
| `interceptors` | empty | The custom slot (section 9). |
| `exceptionHandler` | null | Null means `DefaultNetworkExceptionHandlerInterceptor`. |

- `applyTo(dio)` stays public for code that holds a bare `Dio`. It writes the fields this config owns (section 8) onto `dio.options` and merges `headers` into the existing header map, as today. It no longer forces `validateStatus`; it sets one only when the field is not null.
- The class has no JSON methods.

**Removed fields**

| Old field | Now |
|---|---|
| `maxRetryAttempts`, `retryDelay`, `maxRetryDelay`, `maxRetryDuration` | `RetryConfig` |
| `enableCache`, `maxCacheSize`, `cacheDuration` | `CacheConfig`; a null box means off |
| `enablePerformanceMonitoring` | `PerformanceConfig`; a null box means off |
| `enableLogging` | `LogConfig.diagnostics` and the `logPrint` parameter (section 10) |
| `defaultHeaders` | `headers` |
| `maxConnectionsPerHost`, `idleConnectionTimeout`, `validateCertificates` | Removed; the adapter spec reintroduces what it needs |
| `logBodies` | Removed; `LogConfig.requestBody` and `responseBody` cover it |
| `production()`, `development()`, `test()` | Removed |

## 4. Feature boxes

Every box is a freezed class with `==`, `hashCode`, and `copyWith`. Defaults come from the current constructors, so a box built with no arguments behaves like today's interceptor built with no arguments.

| Box | Fields and defaults | Builds |
|---|---|---|
| `LogConfig` | `request` true, `requestHeader` true, `requestBody` true, `responseHeader` false, `responseBody` true, `error` true, `void Function(Object?)? logPrint` null, `diagnostics` true | `HttpLogInterceptor` |
| `PerformanceConfig` | `maxMetricsHistory` 1000, `collectDetailedTimings` true | `PerformanceInterceptor` |
| `CacheConfig` | `duration` 15 min, `maxSize` 50 MB | `CacheInterceptor` |
| `ConcurrencyConfig` | `int? global` null, `int? perHost` null, `Map<String, int?> hosts` empty, `queueRequests` true, `maxQueueSize` 50, `maxGlobalQueueSize` 500 | `ConcurrencyLimitInterceptor` |
| `RetryConfig` | `maxAttempts` 3, `delay` 1 s, `maxDelay` 30 s, `maxDuration` 60 s, `RetryCallback? onRetry` null | `RetryInterceptor` |
| `PauseConfig` | `maxPauseWait` 10 s, `maxPause` 10 min, `Duration? defaultPause` 5 s | Used inside `RateLimitConfig` |

`RateLimitConfig` is a sealed freezed union, following the `JsonRpcResponse` pattern. The two limiters must never share a chain (SP2), and the union makes that impossible.

```dart
@freezed
sealed class RateLimitConfig with _$RateLimitConfig {
  const factory none() = NoRateLimitConfig;

  const factory pauseOnly({
    @Default(PauseConfig()) PauseConfig pause,
    @Default(50) int maxQueueSize,
  }) = PauseOnlyRateLimitConfig;

  const factory tokenBucket({
    @Default(<TokenBucketPolicy>[]) List<TokenBucketPolicy> global,
    @Default(<TokenBucketPolicy>[]) List<TokenBucketPolicy> perHost,
    @Default(<String, List<TokenBucketPolicy>>{})
    Map<String, List<TokenBucketPolicy>> hosts,
    @Default(true) bool queueRequests,
    @Default(50) int maxQueueSize,
    @Default(500) int maxGlobalQueueSize,
    @Default(PauseConfig()) PauseConfig pause,
  }) = TokenBucketRateLimitConfig;
}
```

`pauseOnly` builds `RetryAfterPauseInterceptor`; `tokenBucket` builds `TokenBucketRateLimitInterceptor`; `none` builds nothing.

**Equality of non-value fields.** `logPrint`, `onRetry`, `validateStatus`, `interceptors`, and `exceptionHandler` compare by identity. A lambda written inline on every `configure` call makes its box unequal each time, so that box is rebuilt. This costs nothing for log and retry, which keep no state between requests. The docs advise top-level functions and long-lived interceptor instances.

## 5. Interceptor constructors

Each interceptor takes its own box instead of `HttpClientConfig`, plus an optional diagnostics printer. Behaviour is otherwise unchanged.

| Interceptor | Before | After |
|---|---|---|
| `RetryInterceptor` | `(config:, dio:, onRetry:, random:)` | `(config: RetryConfig, dio:, random:, logPrint:)`; `onRetry` moves into `RetryConfig` |
| `CacheInterceptor` | `(config:)` | `(config: CacheConfig, logPrint:)` |
| `PerformanceInterceptor` | `(config:, maxMetricsHistory:, collectDetailedTimings:)` | `(config: PerformanceConfig, logPrint:)` |
| `ConcurrencyLimitInterceptor` | `(config:, global:, perHost:, hosts:, queueRequests:, maxQueueSize:, maxGlobalQueueSize:)` | `(config: ConcurrencyConfig, logPrint:)` |
| `RetryAfterPauseInterceptor` | `(config:, maxPauseWait:, maxPause:, defaultPause:, maxQueueSize:)` | `(config: PauseOnlyRateLimitConfig, logPrint:)` |
| `TokenBucketRateLimitInterceptor` | `(config:, global:, perHost:, hosts:, queueRequests:, maxQueueSize:, maxGlobalQueueSize:, maxPauseWait:, maxPause:, defaultPause:)` | `(config: TokenBucketRateLimitConfig, logPrint:)` |

- `logPrint` has type `void Function(String message)?` and defaults to null, which prints nothing. Today's default `enableLogging` is false, so the default output does not change. Messages keep their `[ClassName]` prefix.
- `CacheInterceptor` and `PerformanceInterceptor` lose their `enableCache` and `enablePerformanceMonitoring` checks: the interceptor exists only when its box is not null.
- `HttpLogInterceptor` keeps its constructor. The client maps `LogConfig` onto its named parameters.
- Validation stays where it is: lowercase `hosts` keys, `TokenBucketPolicy.validate()`, and the concurrency checks still throw from the constructors.

## 6. `TokenBucketPolicy`

`TokenBucketPolicy` in `dart_faltool` becomes freezed, so rate-limit boxes compare by value.

```dart
@freezed
abstract class TokenBucketPolicy with _$TokenBucketPolicy {
  const TokenBucketPolicy._();

  const factory({
    required int permits,
    required Duration per,
    int? burst,
  }) = _TokenBucketPolicy;

  int get effectiveBurst => burst ?? math.max(1, permits ~/ 10);

  void validate() { ... }                                  // uses effectiveBurst
  RateLimiter toRateLimiter({int? maxQueueLength}) { ... } // uses effectiveBurst
}
```

- The constructor stays `const`, so `const [TokenBucketPolicy(...)]` in apps and docs keeps compiling.
- `burst` now returns what the caller passed, possibly null. The computed value moves to `effectiveBurst`. Only the `dart_faltool` tests read `burst` today.
- A policy with no `burst` and one with the computed value behave alike but are unequal. Switching between the two rebuilds the limiter. Rare; documented.

## 7. `BaseHttpClient` and `DefaultHttpClient`

Configuration moves from the two hooks into `BaseHttpClient` itself, so every client gets `configure`, the fixed chain order, and instance reuse.

```dart
abstract class BaseHttpClient implements RequestApiService {
  new({required Dio dio, HttpClientConfig config = const HttpClientConfig()});

  Dio get dio;
  String get baseUrl;
  BaseOptions get options;
  @Deprecated('Use options') BaseOptions get config;
  Interceptors get interceptors;

  /// The configuration new requests use.
  HttpClientConfig get currentConfig;

  /// Applies [config] to requests that start after this call returns.
  /// Throws, and keeps the current configuration, when an interceptor
  /// cannot be built from [config].
  void configure(HttpClientConfig config);

  /// Sets the base URL of the current configuration.
  void setupBaseUrl(String baseUrl);

  /// Adds [interceptors] to the custom slot of the current configuration.
  void addInterceptors(Iterable<Interceptor> interceptors);

  /// Disposes the stateful interceptors of the current configuration.
  /// Needed at the end of a test or a CLI; a Flutter app never calls it.
  void dispose();

  // get, post, postFormData, patch, put, putFormData, delete: section 11
}

class DefaultHttpClient extends BaseHttpClient {
  new _singleton({required super.dio});

  static final DefaultHttpClient instance = DefaultHttpClient._singleton(
    dio: Dio(),
  );
}
```

- `setupOptions` and `setupInterceptors` are removed. The constructor calls `configure(config)` in its body.
- A subclass passes its configuration to the super constructor. An interceptor that needs the client's `dio`, such as a token refresh that re-sends, is built in the subclass constructor body, where `dio` is ready:

```dart
class PaymentHttpClient extends BaseHttpClient {
  PaymentHttpClient(TokenStore store) : super(dio: Dio()) {
    configure(HttpClientConfig(
      baseUrl: 'https://pay.example.com',
      retry: const RetryConfig(),
      interceptors: [TokenRefreshInterceptor(dio, store)],
    ));
  }
}
```

  The default configuration is applied first and replaced at once; it builds only the exception handler.
- `DefaultHttpClient` keeps only its singleton. Its default configuration reproduces today's options and chain.
- `setupBaseUrl(url)` calls `configure(currentConfig.copyWith(baseUrl: url))`, so `currentConfig` always matches `dio.options`.
- `addInterceptors` calls `configure(currentConfig.copyWith(interceptors: [...currentConfig.interceptors, ...interceptors]))`. The added interceptors survive later `configure` calls and move from the end of the chain to the custom slot, so they now see errors (gap 2). Its parameter widens from `Interceptors` to `Iterable<Interceptor>`.
- `options` returns the dio `BaseOptions`. `config` returns the same object and is deprecated, because its name now suggests `HttpClientConfig`.
- `BaseHttpClient` stays abstract: one client class per external system, as the consumer skill teaches.
- `DefaultJsonRpcService` takes any `BaseHttpClient` and uses only its `dio`; it is unaffected.

## 8. `configure` semantics

`configure(next)` runs synchronously in four steps:

1. Compare each box of `next` with the same box of `currentConfig`.
2. Build a new interceptor for every box that changed. Keep the current instance for every box that is equal. If a constructor throws, the call rethrows and nothing changes.
3. Assemble the chain in the order of section 9.
4. Apply in one synchronous block: write the options `next` owns onto `dio.options`, then `dio.interceptors.clear()` (which keeps dio's `ImplyContentTypeInterceptor`) and `addAll(chain)`. Then store `next`.

**Options the config owns.** `configure` writes these fields onto the existing `dio.options` object and leaves every other field alone:

- `baseUrl`, `connectTimeout`, `receiveTimeout`, `sendTimeout`, `contentType`, `followRedirects`, `maxRedirects`.
- `validateStatus`. A null value restores dio's default check, captured from a fresh `BaseOptions` when the client is built.
- The header keys from `headers`, plus `User-Agent` when `userAgent` is set. Keys that the previous config set and `next` does not are removed.

A field or header key set directly on `dio.options`, such as `responseType`, `extra`, or a header added by hand, survives `configure`. `currentConfig` therefore does not describe those values, and switching environments does not reset them. Running requests are safe: dio copies the base options into each request's own `RequestOptions` when the request starts (`Options.compose`), headers included.

| Box | Interceptor | State kept when the box is equal |
|---|---|---|
| `log` | `HttpLogInterceptor` | none |
| `performance` | `PerformanceInterceptor` | metrics and statistics |
| `cache` | `CacheInterceptor` | cache entries |
| `concurrency` | `ConcurrencyLimitInterceptor` | active slots and queues |
| `rateLimit` | `TokenBucketRateLimitInterceptor` or `RetryAfterPauseInterceptor` | tokens, queues, and 429 pauses |
| `retry` | `RetryInterceptor` | none |
| `interceptors` | the app's instances | the app's |
| `exceptionHandler` | the given handler, or one shared `DefaultNetworkExceptionHandlerInterceptor` | its queue |

**Running requests.** dio builds the request, response, and error phases of a request from the interceptor list when `fetch` starts (`dio_mixin.dart`, lines 534 to 582). A request that started before the swap runs to the end on the old interceptors. The client does not track it.

**Replaced interceptors are not disposed.** A replaced limiter still serves its running requests. Its timers end on their own: token bucket refills stop when every bucket is full, and a pause keeps a timer only while it holds requests, each for at most about `maxPauseWait`. A test that swaps a limiter while a request waits must let that request finish before the test ends, or `testWidgets` reports a pending timer.

**Retries cross the swap.** `RetryInterceptor` sends each attempt with `dio.fetch`, which reads the current list. The next attempt of an old request therefore passes the new chain, while the retry count and deadline stay those of the old `RetryConfig`. Documented as the contract: every attempt uses the chain current when the attempt starts.

**Overlap after a limit change.** When `rateLimit` or `concurrency` changes, the old limiter drains its queue under the old limits while the new one starts empty. For a short time the two together can exceed either limit, by at most the old queue size. A 429 pause active in the old limiter is not carried over. Documented.

## 9. Interceptor order

The client assembles the chain in this order. Positions 4 to 8 are the SP3 order.

| # | Interceptor | Reason |
|---|---|---|
| 0 | `ImplyContentTypeInterceptor` | dio's default; kept by `clear()` |
| 1 | `interceptors` (custom slot) | Runs first, so an auth header is stamped before `CacheInterceptor` builds its key, which includes `authorization` |
| 2 | `HttpLogInterceptor` | Sees stamped headers, and sees each retry attempt's error exactly once (before `RetryInterceptor`) |
| 3 | `PerformanceInterceptor` | Measures the wait in the limiter queues, which the user also waits |
| 4 | `CacheInterceptor` | A hit answers without taking a slot or a token |
| 5 | `ConcurrencyLimitInterceptor` | Slot before tokens (SP3) |
| 6 | `TokenBucketRateLimitInterceptor` or `RetryAfterPauseInterceptor` | Sees a server 429 before `RetryInterceptor` (SP2) |
| 7 | `RetryInterceptor` | |
| 8 | exception handler | Last, because it rejects without calling later error interceptors |

Custom interceptors run before `ConcurrencyLimitInterceptor`, so they must follow the SP3 slot-safety rule: end `onResponse` and `onError` with `handler.next(...)` or `handler.reject(err, true)`. The docs state the rule next to the custom slot.

## 10. Diagnostics

The client passes one printer to every interceptor it builds:

```dart
void _diagnostic(String message) {
  final log = _config.log;
  if (log != null && log.diagnostics) (log.logPrint ?? print)(message);
}
```

The printer reads the current configuration on every call. Turning logging on or off changes only the `log` box, so stateful interceptors are kept and still print, or stop printing, at once. A `BaseHttpClient` subclass passes `logPrint: print`, or nothing for silence.

## 11. Request methods

The seven public methods keep their names and parameters. They become thin wrappers over one private request path:

```dart
Future<Response<T>> _request<T>(
  String method,
  String path, {
  Object? data,
  Map<String, Object?>? queryParameters,
  Options? options,
  CancelToken? cancelToken,
  ProgressCallback? onSendProgress,
  ProgressCallback? onReceiveProgress,
  required bool isUseToken,
  required FutureOr<T> Function(Map<String, dynamic> json) converter,
  T? Function(DioException exception, StackTrace? stackTrace)? catchError,
});
```

- It calls `dio.request` with the method set on a copy of `options`, then `mapJson(converter)` and `catchWhenError(catchError)` (section 12).
- Every method accepts an async converter, `FutureOr<T> Function(Map<String, dynamic> json)`. Today only `get` does.
- `queryParameters` widens to `Map<String, Object?>?`, so optional values can be null.
- `isUseToken` is written to `options.extra` under `dart_falconnect.auth.useToken`. `FalconAuthRequestOptionsExtensions` and `FalconAuthOptionsExtensions` add a `useToken` getter and setter, following the retry extensions of SP2. The getter returns true when the key is absent, so Retrofit requests read as using a token. An auth interceptor in the custom slot can read it today; the auth spec builds on it.
- Request bodies are unchanged: `BaseRequestBody` for JSON and `FormData` for multipart.
- `RequestApiService` names its first parameter `path`, as the implementation does, and declares the same parameters as `BaseHttpClient`: `cancelToken`, the progress callbacks, and the widened types.

Callers need no change: every type change widens what a caller may pass. Only a class that implements `RequestApiService` or overrides a request method must update its signature.

## 12. Response mapping and error recovery

**`mapJson`**

| Body | Today | New |
|---|---|---|
| JSON object | converter | converter, unchanged |
| `String` | converter gets `{'result': body}` | unchanged |
| null, array, number, or boolean | `TypeError` | `DioException` |
| converter throws | the raw exception | `DioException` |

The new `DioException` has type `DioExceptionType.unknown`, the request's `requestOptions` and `response`, and an `error` of `CommonException(type: InputErrorType.invalidFormat)`. Its `developerMessage` names the body type or the converter failure, and `originalException` and `stackTrace` carry the converter's exception. It is raised after the interceptor chain, so the exception handler does not see it; the caller and `catchError` do.

**`catchWhenError`**, in its three variants on `Future<Response<T>>`, `Future<JsonRpcResponse<RESULT>>`, and `Future<HttpResponse<T>>`:

| Case | Today | New |
|---|---|---|
| No fallback given | rethrows | rethrows |
| Fallback returns null | resolves with null data | rethrows the original error |
| Fallback returns a value, error has a response | resolves | resolves, unchanged |
| Fallback returns a value, error has no response | null-check crash | resolves with `Response(requestOptions: error.requestOptions, data: value)` |
| JSON-RPC variant, fallback returns a value | a plain `Response` in a `JsonRpcResponse` future | resolves with `JsonRpcResponse(jsonrpc: '2.0', id: <request id>, result: value)`; the id comes from the request body, or 0 when it cannot be read |
| Retrofit variant, fallback returns a value | a plain `Response` in an `HttpResponse` future | resolves with `HttpResponse(value, <response>)` |

`transformData` and `copyWith` on a null `Response` throw a `StateError` that names the missing `requestOptions`, instead of a null-check error.

## 13. Migration

An app that only uses `DefaultHttpClient.instance` needs no change, except where it relied on the `catchError` and parse-error behaviour of rows 12 and 13. A `BaseHttpClient` subclass changes as follows.

```dart
// Before: two hooks, and a chain ordered by hand
class PaymentHttpClient extends BaseHttpClient {
  PaymentHttpClient() : super(dio: Dio());
  static final _config = HttpClientConfig.production();

  @override
  void setupOptions(Dio dio, BaseOptions options) {
    _config.applyTo(dio);
    options.baseUrl = 'https://pay.example.com';
  }

  @override
  void setupInterceptors(Dio dio, Interceptors interceptors) {
    interceptors.addAll([
      PaymentAuthInterceptor(),
      RetryInterceptor(config: _config, dio: dio),
      DefaultNetworkExceptionHandlerInterceptor(),
    ]);
  }
}

// After: one configuration; the client orders the chain
class PaymentHttpClient extends BaseHttpClient {
  PaymentHttpClient()
    : super(
        dio: Dio(),
        config: HttpClientConfig(
          baseUrl: 'https://pay.example.com',
          retry: const RetryConfig(),
          interceptors: [PaymentAuthInterceptor()],
        ),
      );
}
```

Code that builds interceptors by hand changes as follows.

```dart
// Before
final config = HttpClientConfig.production();
RetryInterceptor(config: config, dio: dio);
CacheInterceptor(config: config);

// After
RetryInterceptor(config: const RetryConfig(), dio: dio);
CacheInterceptor(config: const CacheConfig());
```

| # | Breaking change | Action |
|---|---|---|
| 1 | Six interceptor constructors take their own box | Pass the box; see section 5 |
| 2 | `HttpClientConfig` fields moved into boxes | `config.maxRetryAttempts` becomes `config.retry?.maxAttempts`, and so on (section 3) |
| 3 | Presets removed | Build your own configuration values |
| 4 | Default timeouts are 20 s, were 30 s | Set them explicitly to keep 30 s |
| 5 | `applyTo` no longer sets `validateStatus` to `status < 500` | 4xx now fails in `onError`; set `validateStatus` to keep the old behaviour |
| 6 | Four unread fields removed | Delete them |
| 7 | `enableLogging` removed | Pass `logPrint:` to each interceptor |
| 8 | `TokenBucketPolicy.burst` is nullable | Read `effectiveBurst` for the computed value |
| 9 | `addInterceptors` adds to the custom slot at the front of the chain, was an append at the end | Nothing, unless an interceptor relied on running after the exception handler, where it never saw errors |
| 10 | `setupOptions` and `setupInterceptors` removed | Pass `config:` to the super constructor, or call `configure` in the constructor body (section 7) |
| 11 | A `configure` swap overwrites the options the config owns | Put `baseUrl`, timeouts, and headers in the config instead of setting them on `dio.options` |
| 12 | A `catchError` fallback that returns null now rethrows | Return a value to recover |
| 13 | A body that is not a JSON object, or a converter failure, arrives as a `DioException` holding `CommonException(type: InputErrorType.invalidFormat)` | Catch `DioException`; `catchError` now sees these failures |
| 14 | `BaseHttpClient.config` deprecated | Read `options` |
| 15 | `RequestApiService` signatures widened | Only implementers and overriders update their signatures |

## 14. Changes to the SP1, SP2, and SP3 contracts

- Constructors of `TokenBucketRateLimitInterceptor` (SP1, SP2), `RetryInterceptor` and `RetryAfterPauseInterceptor` (SP2), and `ConcurrencyLimitInterceptor` (SP3) change as in section 5.
- `TokenBucketPolicy` becomes freezed; `burst` becomes nullable (section 6).
- `enableLogging` diagnostics become the `logPrint` parameter.
- The chain order of SP3 section 12 gains positions 1 to 3 (section 9).
- `applyTo` stops forcing `validateStatus`. The known gap in SP2 section 16, a server 429 never reaching `RetryInterceptor` under `applyTo`, closes.

## 15. Documentation

Per the skill maintenance rule, in the same change:

| File | Change |
|---|---|
| `skills/dart-falconx-package/SKILL.md` | The `DefaultHttpClient` and interceptor rows: `configure`, `currentConfig`, the boxes, and the new constructors. |
| `skills/dart-falconx-package/references/http.md` | Rewrite the `DefaultHttpClient` section around `configure`, with the dev and prod example and the runtime switch. Rewrite the custom client example and the interceptor catalog with box constructors. Replace the `HttpClientConfig` paragraph. Add the fixed order of section 9, the custom-slot slot-safety rule, the Retrofit rule (never give the API an absolute `baseUrl` when the client switches base URLs), the warning against `dio.interceptors.add(...)`, the section 8 contract, and a 2.0.0 migration note built from section 13. |
| `skills/dart-falconx-package/references/http.md`, converter section | `catchError` rules of section 12, parse failures as `DioException`, the `useToken` extra, async converters for every method, and the removed hooks. |
| `skills/dart-falconx-package/references/json-rpc.md` | The JSON-RPC `catchWhenError` fallback of section 12. |
| `skills/dart-falconx-package/references/models.md` | `TokenBucketPolicy.effectiveBurst`. |
| `dart_falconnect/CLAUDE.md` | Line 40: `HttpClientConfig` holds freezed boxes and has no presets. The order line. |
| `CLAUDE.md` (root) | The order line, if it still lists the old order; the `BaseHttpClient` description without hooks. |
| `dart-engineer-pack` skill `expert-dart-api-integration`, outside this repository | At the plugin source, `projects/indevelopment-plugins/nonthawit-pack/dart-engineer-pack/skills/expert-dart-api-integration/references/`: `client.md` replaces the seam pattern with the config pattern of section 7; `interceptor.md` corrects its claim that `onResponse` and `onError` run in reverse order, since dio 5.11.1 runs them in list order. A separate commit in the NTD OS repository. |

## 16. Testing plan

TDD. Tests use a real `Dio` with a capturing adapter; timing tests run under `fakeAsync`.

**`dart_falconnect/test/engine/https/default_http_client_test.dart` (new)**

- No `configure` call: JSON content type, 20 s connect and receive timeouts, and a chain of `ImplyContentTypeInterceptor` plus one `DefaultNetworkExceptionHandlerInterceptor`.
- Swap while a request runs: the adapter holds request A, `configure` runs, request B starts. A carries the old headers and passes the old interceptors; B carries the new ones.
- Reuse: an equal box yields the identical instance; a changed box yields a new one. Turning `log` on keeps the token bucket instance, its spent tokens, and an active 429 pause.
- Failed build: an invalid policy makes `configure` throw, and `currentConfig`, `dio.options`, and the interceptor list stay unchanged.
- Order: the list matches section 9 for a configuration with every box set. A cache hit spends no token and takes no slot. The exception handler is last.
- `validateStatus`: with the default, a 404 reaches the exception handler, and a 429 reaches `RetryInterceptor`.
- Diagnostics: after turning `log` on, a kept limiter prints through the new printer; after turning it off, it prints nothing.
- `addInterceptors` puts the interceptor in the custom slot, it sees errors, and it survives a later `configure`.
- `setupBaseUrl` updates `currentConfig` and `dio.options.baseUrl`.
- `dispose()` disposes the current limiters.
- A subclass that calls `configure` in its constructor body can pass its own `dio` to an interceptor.
- A header set directly on `dio.options` survives `configure`; a header the previous config set and the next one drops is removed.

**`dart_falconnect/test/engine/https/http_client_test.dart` (new)**

- Each of the seven methods sends the right method, path, query, and body through the one request path.
- An async converter works on every method; a null query value is accepted.
- `isUseToken: false` reaches an interceptor as `requestOptions.useToken == false`; a Retrofit request without the key reads true.
- `mapJson`: a JSON array body, an empty JSON body, and a throwing converter each fail with a `DioException` holding `InputErrorType.invalidFormat`; a `String` body still arrives as `{'result': body}`.

**`dart_falconnect/test/engine/https/extensions/response_extensions_test.dart` (new)**

- `catchWhenError` for each row of the section 12 table, on all three variants, including a connection error with no response.
- `transformData` and `copyWith` on a null response throw a `StateError`.

**Model tests**

- `HttpClientConfig` and every box: `==`, `hashCode`, defaults, and `copyWith(log: null)` turning logging off.
- `RateLimitConfig`: an exhaustive `switch` over the three variants.
- `dart_faltool/test/utils/token_bucket_policy_test.dart`: `effectiveBurst` replaces the `burst` expectations; value equality.

**Existing tests**

- Every SP1, SP2, and SP3 interceptor test, `rate_limit_retry_chain_test.dart`, `test/web/engine_web_test.dart`, and `test/web/compile_smoke.dart` move to box constructors and keep passing.

## 17. Implementation logistics

- Work in a git worktree on branch `feature/client-config` from the `develop` commit that holds this spec. Implement with the `dart-engineer-pack:dart-engineer` agent.
- Run `melos run build_runner` after adding freezed classes; generated files go to `generated/`.
- Export the new files from the barrels in alphabetical order (`directives_ordering`). `https.dart` gains `config/config.dart`.
- Commit with `git commit -- <paths>`. No `Co-Authored-By` or AI attribution.
- Do not push or tag. The owner tags 2.0.0 after this spec merges. Before the tag, confirm the skill matches the source.

## 18. Risks

| Risk | Mitigation |
|---|---|
| A limit change lets old and new limiters overlap, and drops an active 429 pause. | Rebuild only on a limit change; documented in section 8. |
| An inline lambda makes its box unequal on every `configure`. | Harmless for log and retry; the docs advise top-level functions. |
| Direct `dio.interceptors.add(...)` is lost at the next `configure`. | Documented; `addInterceptors` is the supported path. |
| An absolute Retrofit `baseUrl` silently ignores switches. | Documented rule and example. |
| A custom interceptor breaks the slot-safety rule and leaks concurrency slots. | The rule is stated next to the custom slot; SP3 placement tests cover the built-in chain. |
| Many breaking changes in one release. | One migration note; 2.0.0 is not yet tagged. |
| Removing the hooks breaks every `BaseHttpClient` subclass. | The before and after example of section 13; the change is mechanical. |
| An app relied on a null `catchError` fallback resolving with null data. | Migration row 12. |
| A value set directly on `dio.options` is invisible in `currentConfig`. | Documented in section 8; the fix is to add the field to the config when someone needs it. |

## 19. Success criteria

- `DefaultHttpClient.instance` with no `configure` call behaves as today.
- A `configure` call never disturbs a running request, and applies to every request that starts after it.
- A change to one box rebuilds only that box's interceptor, proven for the token bucket, the pause, and the concurrency limiter.
- A failed `configure` leaves everything unchanged.
- The chain order of section 9 holds for every combination of boxes.
- `HttpClientConfig` and the boxes are importable from `package:dart_falconx/dart_falconx.dart`.
- A `BaseHttpClient` subclass needs no hook to configure itself.
- No request method lets a `TypeError` or a raw converter exception escape; `catchError` never crashes on a missing response.
- `melos run analyze`, `melos run test`, `dart compile js`, and the Chrome web test pass.
- Every file in section 15 matches the code.

## 20. Details decided in this spec, for owner review

The brainstorm settled the design; these finer points were chosen here and are open to change at review.

1. `TokenBucketPolicy` keeps a `const` constructor and moves the computed value to `effectiveBurst` (section 6). The alternative, computing `burst` at construction, loses `const`.
2. `PauseConfig` is a nested box shared by both rate-limit variants, and `pauseOnly` keeps its own `maxQueueSize`.
3. `LogConfig.diagnostics` lets an app see HTTP logs without interceptor diagnostics.
4. `HttpLogInterceptor` keeps its constructor; only the six config-reading interceptors change.
5. `applyTo` merges headers, while `configure` also removes the header keys the previous config set and the next one drops.
6. `RetryConfig` carries `onRetry`, so the client can build `RetryInterceptor` from the box alone.
7. The default exception handler is one shared instance, kept across `configure` calls.
8. Parse failures use `DioExceptionType.unknown` with `CommonException(type: InputErrorType.invalidFormat)` (section 12).
9. The JSON-RPC fallback response takes its id from the request body, or 0 when it cannot be read.
10. The `useToken` extra key is `dart_falconnect.auth.useToken`, and its getter defaults to true.
11. `addInterceptors` widens its parameter to `Iterable<Interceptor>`, and `RequestApiService` declares the same parameters as `BaseHttpClient`.
12. `BaseHttpClient` stays abstract.
