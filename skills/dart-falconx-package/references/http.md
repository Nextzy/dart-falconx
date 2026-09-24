# HTTP

`package: dart_falconnect` (re-exports `dio`, `retrofit`, `dio_cache_interceptor`, `web_socket_channel`).

## Recommended: Retrofit + Dio

```dart
import 'package:dart_falconx/dart_falconx.dart';
import 'package:retrofit/retrofit.dart' show Headers; // only when @Headers is needed
part 'user_api.g.dart';

@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String? baseUrl}) = _UserApi;

  @GET('/users/{id}')
  Future<UserDto> getUser(@Path('id') String id);

  @POST('/users')
  Future<UserDto> create(@Body() CreateUserBody body);
}

final api = UserApi(DefaultHttpClient.instance.dio); // base URL from the client config
```

Generate `_UserApi` with `dart run build_runner build --delete-conflicting-outputs`.
Retrofit's `Future<HttpResponse<T>>` gains `.unwrapResponse()` and `.catchWhenError(f)`.

## Configure a client

Every `BaseHttpClient`, `DefaultHttpClient.instance` included, runs on one `HttpClientConfig`: the dio options it owns, plus one box per feature. A null box turns its feature off. With no `configure` call, a client has JSON content type, 20 s connect and receive timeouts, no send timeout, and `DefaultNetworkExceptionHandlerInterceptor`.

```dart
final dev = HttpClientConfig(
  baseUrl: 'https://dev.api.example.com',
  log: const LogConfig(),
  retry: const RetryConfig(maxAttempts: 1),
  rateLimit: const RateLimitConfig.pauseOnly(),
);

final prod = HttpClientConfig(
  baseUrl: 'https://api.example.com',
  cache: const CacheConfig(),
  concurrency: const ConcurrencyConfig(global: 16, perHost: 4),
  rateLimit: RateLimitConfig.tokenBucket(
    perHost: [TokenBucketPolicy(permits: 100, per: const Duration(minutes: 1))],
  ),
  retry: const RetryConfig(),
  interceptors: [AuthInterceptor(tokenStore)],
);

void main() {
  DefaultHttpClient.instance.configure(kReleaseMode ? prod : dev);
  runApp(const App());
}
```

`configure` applies to requests that start after it returns. Requests already running finish on the configuration they started with. Only the interceptors whose box changed are rebuilt, so token buckets, 429 pauses, concurrency slots, the cache, and performance statistics survive an unrelated change:

```dart
final client = DefaultHttpClient.instance;
client.configure(client.currentConfig.copyWith(log: const LogConfig())); // limiter kept
client.configure(client.currentConfig.copyWith(log: null));              // log off
client.setupBaseUrl('https://staging.api.example.com');
```

| Box | Adds | Defaults |
|---|---|---|
| `LogConfig` | `HttpLogInterceptor`; `diagnostics` also prints interceptor diagnostics | request, headers, and bodies on; response headers off |
| `PerformanceConfig` | `PerformanceInterceptor` | `maxMetricsHistory` 1000 |
| `CacheConfig` | `CacheInterceptor` | 15 min, 50 MB |
| `ConcurrencyConfig` | `ConcurrencyLimitInterceptor` | every scope unlimited |
| `RateLimitConfig.none()`, `.pauseOnly(...)`, `.tokenBucket(...)` | nothing, `RetryAfterPauseInterceptor`, or `TokenBucketRateLimitInterceptor`; never both limiters | `none()` |
| `RetryConfig` | `RetryInterceptor` | 3 attempts, 1 s base delay, 30 s cap, 60 s deadline |

- The client orders the chain: your `interceptors`, log, performance, cache, concurrency limit, rate limit, retry, then `exceptionHandler` (null means `DefaultNetworkExceptionHandlerInterceptor`).
- `configure` owns `baseUrl`, the three timeouts, `contentType`, redirects, `validateStatus` (null means dio's default, 2xx only), and the header keys of `headers` and `userAgent`. Other `dio.options` fields, and headers you set by hand, survive it.
- Add interceptors with `addInterceptors` or the config, never with `dio.interceptors.add(...)`: `configure` rebuilds the list.
- When the client switches base URLs, give Retrofit APIs no absolute `baseUrl`, neither as the factory argument nor in `@RestApi(baseUrl:)`. An absolute one wins over `dio.options.baseUrl`.
- A box holding an inline lambda (`logPrint`, `onRetry`, `validateStatus`) is unequal on every `configure`, so its interceptor is rebuilt. Pass top-level functions.
- The next attempt of a request that was retrying across a `configure` passes the new chain, with its old retry settings.
- Call `dispose()` at the end of a test or a CLI. A Flutter app never needs it.

## Custom client: subclass `BaseHttpClient`

Write one client class per external system, and pass its configuration to the super constructor:

```dart
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

An interceptor that needs the client's `dio`, such as a token refresh that re-sends, is built in the constructor body, where `dio` is ready:

```dart
class PaymentHttpClient extends BaseHttpClient {
  PaymentHttpClient(TokenStore store) : super(dio: Dio()) {
    configure(HttpClientConfig(
      baseUrl: 'https://pay.example.com',
      interceptors: [TokenRefreshInterceptor(dio, store)],
    ));
  }
}
```

The constructor applies the configuration at once. It replaces what an injected `Dio` had for the options the configuration owns (base URL, timeouts, content type, redirects, `validateStatus`, and its header keys); the adapter and every other option stay. Set those values through the configuration.

Your interceptors run before `ConcurrencyLimitInterceptor`, so they follow its slot-safety rule (see "Interceptor order"): end `onResponse` and `onError` with `handler.next(...)` or `handler.reject(err, true)`.

Members: `dio`, `baseUrl`, `options` (the dio `BaseOptions`), `interceptors`, `currentConfig`, `configure(config)`, `setupBaseUrl(url)`, `addInterceptors(interceptors)`, `dispose()`.

## Converter-based calls

Every method takes `converter: (Map<String, dynamic> json) => T` and returns `Future<Response<T>>`. A plain `String` body arrives as `{'result': body}`.

| Method                                | Body                                                    | Extras                                                                                       |
|---------------------------------------|---------------------------------------------------------|----------------------------------------------------------------------------------------------|
| `get<T>`                              | none                                                    | `queryParameters`, `options`, `cancelToken`, `onReceiveProgress`                             |
| `post<T>`, `patch<T>`, `put<T>`       | `data: BaseRequestBody?` (serialised with `toJson()`)   | plus `onSendProgress`                                                                        |
| `postFormData<T>`, `putFormData<T>`   | `data: FormData?`                                       | same                                                                                         |
| `delete<T>`                           | `data: BaseRequestBody?`                                | `queryParameters`, `cancelToken`                                                             |

Every method accepts a converter that may be async. `catchError: (DioException e, StackTrace? st) => T?` returns a fallback value, and returning `null` rethrows the original error; a failure with no response, such as a timeout or a lost connection, recovers too. A body that is not a JSON object, or a converter that throws, fails with a `DioException` whose `error` is `CommonException(type: InputErrorType.invalidFormat)`, and `catchError` sees it. `isUseToken: false` sets `requestOptions.useToken` to false for your auth interceptor; `useToken` reads true when unset, Retrofit requests included.

```dart
final res = await client.get<UserDto>('/users/$id', converter: UserDto.fromJson);
final user = res.data;
```

## Interceptor catalog

| Class                                       | Constructor                                                                                                                                                                 | Behaviour                                                                                                                                                                                                                                                                                                                                                                         |
|---------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RetryInterceptor`                          | `(config: RetryConfig(maxAttempts: 3, delay: 1 s, maxDelay: 30 s, maxDuration: 60 s, onRetry:), dio:, logPrint:, random:)`                                                  | loops up to `retryAttempts ?? config.maxAttempts`; 429 and `connectionTimeout` for every method; timeouts, connection errors, 408/409/5xx only for idempotent methods unless `retryNonIdempotent`; `Retry-After` on 429/503 (not retried above `maxDelay`), else full jitter; stops at `config.maxDuration`; never retries cancels, local 429s, `Stream` bodies, bad certificates |
| `CacheInterceptor`                          | `(config: CacheConfig(duration: 15 min, maxSize: 50 MB), logPrint:)`                                                                                                        | in-memory cache of 2xx GET responses; respects `Cache-Control` and `Expires`; `clearCache()`, `evictExpired()`                                                                                                                                                                                                                                                                    |
| `ConcurrencyLimitInterceptor`               | `(config: ConcurrencyConfig(global:, perHost:, hosts:, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500), logPrint:)`                                         | most requests in flight per host and in total, on `resilience` `Bulkhead`; a null limit means none; full queue → local 429 with `BulkheadRejectedException` and no `Retry-After`; a retry or re-send reuses its request's slot; `getStatistics()`, `dispose()`                                                                                                                    |
| `TokenBucketRateLimitInterceptor`           | `(config: TokenBucketRateLimitConfig(global: [], perHost: [], hosts: {}, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500, pause: PauseConfig()), logPrint:)` | token buckets from `TokenBucketPolicy` lists; no policy means no token limit; pauses a host on 429, or 503 with `Retry-After`; full queue or long pause → local 429 through the error chain; `getStatistics()`, `dispose()`; do not add `RetryAfterPauseInterceptor` next to it                                                                                                   |
| `RetryAfterPauseInterceptor`                | `(config: PauseOnlyRateLimitConfig(pause: PauseConfig(maxPauseWait: 10 s, maxPause: 10 min, defaultPause: 5 s), maxQueueSize: 50), logPrint:)`                              | the pause of `TokenBucketRateLimitInterceptor` without token limits; `dispose()`                                                                                                                                                                                                                                                                                                  |
| `PerformanceInterceptor`                    | `(config: PerformanceConfig(maxMetricsHistory: 1000, collectDetailedTimings: true), logPrint:)`                                                                             | `getRecentMetrics()`, `getStatistics()` returning `PerformanceStatistics`                                                                                                                                                                                                                                                                                                         |
| `HttpLogInterceptor`                        | `(enabled, request, requestHeader, requestBody, responseHeader, responseBody, error, logPrint)`                                                                             | ANSI-coloured chunked printing; logs requests and responses from anywhere in the chain, errors only when placed before `RetryInterceptor` and the exception handler                                                                                                                                                                                                               |
| `NetworkExceptionHandlerInterceptor`        | abstract `QueuedInterceptor`                                                                                                                                                | implement `onClientError` (4xx) and `onServerError` (5xx), optionally `onNonStandardError`; connect/receive timeouts become `NetworkTimeoutException` first                                                                                                                                                                                                                       |
| `DefaultNetworkExceptionHandlerInterceptor` | `()`                                                                                                                                                                        | rejects every error as-is                                                                                                                                                                                                                                                                                                                                                         |

Every `config` defaults to its box built with no arguments. `logPrint` receives diagnostics; null prints nothing. Inside a `BaseHttpClient`, the client passes a printer that follows `LogConfig.diagnostics`.

`HttpClientConfig` is freezed: `==`, `copyWith` (which can set a box to `null`), `effectiveHeaders`, and `applyTo(dio)`, which writes the owned options onto a bare `Dio`, merges `headers`, and sets `validateStatus` only when given. It has no presets.

## Interceptor order

`BaseHttpClient` assembles this order itself, with your `interceptors`, `HttpLogInterceptor`, and `PerformanceInterceptor` in front. A chain you build by hand on a bare `Dio` must follow it:

```dart
dio.interceptors.addAll([
  CacheInterceptor(),
  ConcurrencyLimitInterceptor(
    config: const ConcurrencyConfig(global: 16, perHost: 4),
  ),
  TokenBucketRateLimitInterceptor(), // or RetryAfterPauseInterceptor, never both
  RetryInterceptor(dio: dio),
  DefaultNetworkExceptionHandlerInterceptor(),
]);
```

- `CacheInterceptor` comes first: a cache hit answers in `onRequest` without calling the response interceptors, so it takes no concurrency slot and spends no token. Any interceptor that answers in `onRequest`, such as a cache or a mock, goes before `ConcurrencyLimitInterceptor`; placed after it, every answer it gives keeps a slot forever.
- `ConcurrencyLimitInterceptor` comes before the rate limiter: the slot is taken before the tokens, so the token ceiling holds on the wire and the pause gate sees every request. A request holds its slot while the rate limiter holds it, so set `perHost` below `global`, for example 4 and 16, so one slow or paused host cannot take every global slot.
- The rate limiter comes before `RetryInterceptor`: dio runs `onError` in list order, so the limiter sees a server 429 and starts the pause before the retry is sent. The retry then passes the pause gate, and the total wait is the longer of the retry delay and the pause, never their sum.
- An interceptor that re-sends from `onError`, such as an auth refresh, goes in your `interceptors` inside a `BaseHttpClient`, which places it before `ConcurrencyLimitInterceptor`. There the re-send reuses its request's slot, as long as the interceptor ends the error phase by the slot-safety rule below. In a chain you build by hand, it may also go after `ConcurrencyLimitInterceptor`.
- **Slot safety.** dio has no "request finished" hook, so `ConcurrencyLimitInterceptor` gives a slot back only when its own `onResponse` or `onError` runs, or when the request's `CancelToken` cancels. Keep both reachable:
  - Interceptors after it end `onRequest` with `handler.next(...)`, `handler.resolve(response, true)`, or `handler.reject(err, true)`. A plain `resolve` or `reject` skips the limiter's `onResponse` and `onError` (a cancel-type reject is safe). An auth interceptor that rejects when it has no token must pass `true`.
  - Interceptors before it end `onResponse` and `onError` with `handler.next(...)` or `handler.reject(err, true)`. A business-error interceptor that turns a 200 into a `DioException` must pass `true`, or go after the limiter. `handler.resolve(...)` in their `onError` is safe only with the response of a re-send of the same `RequestOptions`, which gives the slot back itself.
- `DefaultNetworkExceptionHandlerInterceptor` comes last: it rejects without calling later error interceptors, so a `ConcurrencyLimitInterceptor` placed after it would never get its slots back.
- Every retry passes the whole chain again, so error interceptors see each attempt. Placed before `RetryInterceptor`, one sees every attempt exactly once with a distinct `requestOptions.retryAttempt`; placed after it, one sees attempts 1..n from inside the retries plus the final error again, so it reports the last failure twice. Place error loggers and crash reporters before `RetryInterceptor`.
- A retry is a fresh `dio.fetch` of a copy of the original options. To replay a failed request by hand, call `dio.get(...)` (or `fetch` with fresh options) again, not `dio.fetch(error.requestOptions)`: the failed options carry `retryAttempt > 0`, which reads as a nested attempt and is never retried.

## Rate limiting

Every scope is unlimited until you give it a policy. A `TokenBucketPolicy` means "at most `permits` requests in any window of `per`"; `burst` (null means 10% of `permits`, at least 1; `effectiveBurst` returns the computed value) is how many may leave back to back after idle time, and the steady rate is `permits - effectiveBurst + 1` per `per`.

```dart
const rateLimit = RateLimitConfig.tokenBucket(
  hosts: {
    'api.partner.com': [
      TokenBucketPolicy(permits: 100, per: Duration(minutes: 1)),
      TokenBucketPolicy(permits: 5000, per: Duration(hours: 1), burst: 50),
    ],
  },
);
// In a client: HttpClientConfig(rateLimit: rateLimit).
// On a bare Dio: TokenBucketRateLimitInterceptor(config: rateLimit).
```

`hosts` keys must be bare hosts exactly as `Uri.host` returns them: lowercase, with no port, brackets, or spaces (`::1` is valid). An empty list (`'api.my-backend.com': []`) opts a host out of `perHost`.

Tokens are never returned. When a later tier's full queue rejects a request, tokens already taken by earlier tiers stay spent. A request cancelled with a `CancelToken` while it waits for tokens keeps its queue place and still spends a token when it reaches the front; it is neither forwarded nor counted in `getStatistics().forwarded`. For screens that cancel queued requests often, keep `maxQueueSize` small or set `queueRequests: false`.

### Pause on 429 and 503

A 429 pauses its host for its `Retry-After` (seconds or HTTP-date), else for `defaultPause`; a 503 pauses only when it carries `Retry-After`. Every pause is clamped to `maxPause`, never shortens an earlier one, and applies to hosts without a policy too. While a host is paused, a request waits when the remaining pause is at most `maxPauseWait` and fewer than `maxQueueSize` requests already wait; otherwise it fails at once with a local 429 carrying `Retry-After`. An extension that pushes the remaining pause past `maxPauseWait` also releases every held request, which then re-checks the pause and fails the same way, so a held request waits at most about `maxPauseWait` from admission. A request that gets its tokens during a pause spends them and waits again, so the ceiling also holds after the pause.

A local 429 (full queue or long pause) has type `DioExceptionType.badResponse` and goes through every error interceptor, so callers get `NetworkLimitExceededException` for local and server 429s alike. `response.isLocalRateLimit` tells them apart, for example to keep them out of crash reports. `getStatistics()` exposes the pause through `heldByHost` (requests held per host) and `pausedUntilByHost` (end time of each active pause), and its `rejected` counter includes pause rejections.

Use `RetryAfterPauseInterceptor` for the pause alone. `TokenBucketRateLimitInterceptor` already contains it; a chain with the token bucket must not add `RetryAfterPauseInterceptor`.

### Migrating from 1.x `RateLimitInterceptor`

Renaming the class is not enough. The 1.x `RateLimitInterceptor` limited every request by default (100 req/s global, 10 req/s per host); `TokenBucketRateLimitInterceptor()` limits nothing. The closest equivalent of the 1.x defaults:

```dart
const rateLimit = RateLimitConfig.tokenBucket(
  global: [TokenBucketPolicy(permits: 100, per: Duration(seconds: 1))],
  perHost: [TokenBucketPolicy(permits: 10, per: Duration(seconds: 1))],
);
```

1.x let a full bucket release ten seconds of quota at once (1,000 global, 100 per host); 2.0.0 never releases more than `permits` in any window of `per`. `globalRateLimit`, `perHostRateLimit`, and `windowSize` become policy lists; `clearQueues()` has no replacement (`dispose()` cancels waiting requests); `getStatistics()` returns `TokenBucketRateLimitStatistics` instead of a `Map`.

Refill timers outlive the last request, so call `dispose()` where timers must stop:

| Context                                        | Call `dispose()`                                                                                         |
|------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| Flutter app, client lives as long as the app   | not needed                                                                                               |
| Scoped client (DI scope, logout, env switch)   | when the scope ends: get_it `dispose:`, injectable `@disposeMethod`, Riverpod `ref.onDispose`            |
| `testWidgets` with a real client               | at the end of the test body or from a widget's `dispose`; `addTearDown` is too late and the test fails   |
| Unit test under `fakeAsync`                    | at the end of the `fakeAsync` body                                                                       |
| CLI                                            | in a `finally` before `main` returns, or exit waits until every bucket refills                           |
| Server (dart_frog)                             | not needed                                                                                               |

On a server, build the client once per process (a top-level variable returned by `provider`). A client built inside a per-request `provider` starts with full buckets on every request and limits nothing.

## Concurrency limit

`ConcurrencyLimitInterceptor` limits how many requests are in flight at once. Every scope is unlimited until you set it.

```dart
const concurrency = ConcurrencyConfig(
  global: 16,
  perHost: 4,
  hosts: {'pay.partner.com': 2, 'cdn.example.com': null},
);
```

`pay.partner.com` runs 2 requests at once; `cdn.example.com` has no host limit but still counts toward the 16 global slots; every other host gets 4. `hosts` keys follow the token bucket rule: bare lowercase hosts as `Uri.host` returns them.

A request takes a slot in `onRequest` and gives it back when its response or error passes the interceptor, or when its `CancelToken` cancels. Without a free slot it waits in a FIFO queue (`maxQueueSize` per host, `maxGlobalQueueSize` for the global limit), or fails at once with `queueRequests: false`. A full queue fails the request with a local 429: `isLocalRateLimit` is true, `err.error` is a `BulkheadRejectedException` until the exception handler maps it to `NetworkLimitExceededException`, and there is no `Retry-After`, so `recommendedRetryDelay` falls back to 1 minute. A retry attempt, or a re-send of `err.requestOptions`, reuses the slot its request still holds, so a limit of 1 never deadlocks.

Limitations:

- Nothing limits the time a request spends in the queue. Pass a `CancelToken` with a deadline to bound it.
- A request cancelled while it waits keeps its queue place until it reaches the head, so it counts toward `maxQueueSize` until then. One cancelled while it waits for the global slot also keeps its host slot until then.
- A request that never ends holds its slot. Keep `connectTimeout` and `receiveTimeout` set.
- A `ResponseType.stream` response gives its slot back when its headers arrive, before its body is read.
- Two concurrent fetches of one `RequestOptions` object share one slot: the second waits for the first one's slot, and may still run after the first gives it back.

`getStatistics()` returns `ConcurrencyLimitStatistics`: `forwarded`, `rejected`, `activeByHost` and `waitingByHost` (only hosts with a request in flight or queued; idle hosts are forgotten), `globalActive`, `globalWaiting`. `dispose()` cancels queued requests and lets requests in flight finish; afterwards, requests to a limited host are cancelled and requests to an unlimited host pass. `Bulkhead` keeps no timer, so a missing `dispose()` never delays a CLI exit or fails `testWidgets`.

## Client and server deployment

**Web**

- A browser hides every cross-origin response header outside the CORS safelist, including `Retry-After` and `Date`. Have the server send `Access-Control-Expose-Headers: Retry-After, Date`. Without it, a 429 pauses for `defaultPause`, a 503 does not pause, `RetryInterceptor` uses backoff instead of `Retry-After`, and the pause runs on the client clock. Tests with a fake adapter cannot catch this.
- Chrome opens at most 6 connections per host over HTTP/1.1, so a `perHost` above 6 changes nothing on the web.

**Apps**

- A request that stalls, for example while the app is in the background, holds its concurrency slot until a dio timeout fires.

**Servers**

- Limits count per process, isolate, or container instance. Divide a partner's limit by the instance count; with autoscaling, rely on the 429 pause as the last line.
- Limits are keyed by host. When a partner limits per API key and you use one key per tenant, build one client per key; otherwise one tenant's 429 pauses every tenant.
- Queued requests outlive the incoming request that started them. Give each incoming request a `CancelToken` that cancels at its deadline; it bounds the concurrency queue, the token wait, the pause hold, retry backoff, and the request in flight together.
- Build the client once per process (see the `dispose()` table above).
- For an open-ended set of hosts, prefer named `hosts` keys over `perHost` in `TokenBucketRateLimitInterceptor`: its per-host buckets are never freed. `ConcurrencyLimitInterceptor` forgets idle hosts itself.

## Retry

```dart
await dio.post<dynamic>(
  '/payments',
  options: Options()
    ..retryNonIdempotent = true // allow retries of this POST after 5xx and timeouts
    ..retryAttempts = 5,        // overrides RetryConfig.maxAttempts
);
await dio.get<dynamic>('/live', options: Options()..disableRetry = true);
```

`RetryConfig(onRetry: (error, attempt, delay) {...})` runs before each wait; `error.stackTrace` holds the failure's stack trace.

### Migrating `RetryInterceptor` from 1.x

- `POST` and `PATCH` are no longer retried after a 5xx, a timeout other than `connectionTimeout`, or a connection error, unless `retryNonIdempotent` is set.
- A `Retry-After` longer than `RetryConfig.maxDelay` ends retrying instead of waiting.
- Retries reach `RetryConfig.maxAttempts`; 1.x ran at most one retry.
- `extra['retryCount']` and `extra['isRetry']` are gone; read `requestOptions.retryAttempt`.
- The delay is full jitter, a random time up to the exponential cap, instead of the cap plus up to one second.

## Helpers

- `RequestOptions.setHeaderTokenBearer(token)` / `removeHeaderToken()`.
- `HttpHeader.AUTHORIZE`, `ACCEPT_LANGUAGE`, `CACHE_CONTROL`, `CONTENT_TYPE`, `CONTENT_LENGTH`, `COOKIE`, `KEEP_ALIVE`, `ORIGIN`, `USER_AGENT`, `X_API_KEY`; `HttpCode.SUCCESS`, `ERROR_UNAUTHORIZED`, `ERROR_NOT_FOUND`, `ERROR_INTERNAL`.
- `Response<dynamic>?.copyWith<T>(...)`, `.transformData<T>(data:)`.
- `Future<Response<T>>.unwrapResponse()`, `.catchWhenError(f)`; `Future<Response<dynamic>>.mapJson(f)`.
- `DioException.toException()` maps to the `NetworkException` subtype for its status code; see `errors.md`.
- `headers.retryAfter` and `parseRetryAfter(value, serverDate:)` (from `dart_falmodel`) read `Retry-After` as seconds or HTTP-date; `response.isLocalRateLimit` marks a client-side 429.

## Migrating to the 2.0.0 client config

An app that only uses `DefaultHttpClient.instance` needs no change, except where it relied on the old `catchError` behaviour below. A `BaseHttpClient` subclass drops its hooks:

```dart
// 1.x
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

// 2.0.0
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

- `setupOptions` and `setupInterceptors` are gone. Pass `config:` to the super constructor, or call `configure` in the constructor body.
- Each interceptor takes its own box: `RetryInterceptor(config: const RetryConfig(), dio: dio)`, `CacheInterceptor()`, and so on (see the catalog).
- `HttpClientConfig` fields moved into boxes: `maxRetryAttempts` is `retry?.maxAttempts`, `retryDelay` is `retry?.delay`, `maxRetryDelay` is `retry?.maxDelay`, `maxRetryDuration` is `retry?.maxDuration`, `cacheDuration` is `cache?.duration`, `maxCacheSize` is `cache?.maxSize`, and `defaultHeaders` is `headers`. `enableCache` and `enablePerformanceMonitoring` become a null or non-null box; `enableLogging` becomes `LogConfig.diagnostics` inside a client, or `logPrint:` on a bare interceptor.
- `production()`, `development()`, and `test()` are removed; build your own values.
- Default timeouts are 20 s; they were 30 s in `HttpClientConfig`.
- `applyTo` no longer sets `validateStatus` to `status < 500`, so a 4xx fails in `onError` and reaches `RetryInterceptor`. Set `validateStatus` to keep the old behaviour.
- `maxConnectionsPerHost`, `idleConnectionTimeout`, `validateCertificates`, and `logBodies` are removed.
- `TokenBucketPolicy.burst` is the value you passed, possibly null; `effectiveBurst` returns the computed one.
- `addInterceptors` adds to the front of the chain, where interceptors see errors; it used to append after the exception handler.
- `configure` overwrites the options it owns; put `baseUrl`, timeouts, and headers in the config.
- A `catchError` fallback that returns `null` now rethrows; it used to resolve with null data.
- A non-object body or a throwing converter now fails with a `DioException` holding `InputErrorType.invalidFormat`, which `catchError` sees.
- `BaseHttpClient.config` is removed; read `options`.
- `RequestApiService` names its first parameter `path` and declares the same parameters as `BaseHttpClient`; only implementers update.
