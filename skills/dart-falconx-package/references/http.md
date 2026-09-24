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
| `LogConfig(...)` | `HttpLogInterceptor`; `diagnostics` also prints interceptor diagnostics | request, headers, and bodies on; response headers off; sensitive headers and query values redacted |
| `LogConfig.json(...)` | `HttpJsonLogInterceptor`, one JSON line per attempt (see "Server logging") | headers and bodies off; sensitive headers and query values redacted |
| `PerformanceConfig` | `PerformanceInterceptor` | `maxMetricsHistory` 1000 |
| `CacheConfig` | `CacheInterceptor` | 15 min, 50 MB |
| `ConcurrencyConfig` | `ConcurrencyLimitInterceptor` | every scope unlimited |
| `RateLimitConfig.none()`, `.pauseOnly(...)`, `.tokenBucket(...)` | nothing, `RetryAfterPauseInterceptor`, or `TokenBucketRateLimitInterceptor`; never both limiters | `none()` |
| `RetryConfig` | `RetryInterceptor` | 3 attempts, 1 s base delay, 30 s cap, 60 s deadline |

- `LogConfig` is a sealed union of `PrettyLogConfig` (`LogConfig(...)`) and `JsonLogConfig` (`LogConfig.json(...)`). `request`, `requestHeader`, `responseHeader`, and `error` exist only on the pretty variant, so match it before reading or copying them: `if (config.log case final PrettyLogConfig log) client.configure(config.copyWith(log: log.copyWith(responseHeader: true)));`.
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

| Class                                       | Constructor                                                                                                                                                                              | Behaviour                                                                                                                                                                                                                                                                                                                                                                         |
|---------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RetryInterceptor`                          | `(config: RetryConfig(maxAttempts: 3, delay: 1 s, maxDelay: 30 s, maxDuration: 60 s, onRetry:), dio:, logPrint:, random:)`                                                               | loops up to `retryAttempts ?? config.maxAttempts`; 429 and `connectionTimeout` for every method; timeouts, connection errors, 408/409/5xx only for idempotent methods unless `retryNonIdempotent`; `Retry-After` on 429/503 (not retried above `maxDelay`), else full jitter; stops at `config.maxDuration`; never retries cancels, local 429s, `Stream` bodies, bad certificates |
| `CacheInterceptor`                          | `(config: CacheConfig(duration: 15 min, maxSize: 50 MB), logPrint:)`                                                                                                                     | in-memory cache of 2xx GET responses; respects `Cache-Control` and `Expires`; `clearCache()`, `evictExpired()`; a hit passes every response interceptor, bound to the current request, and reads `response.isCacheHit`                                                                                                                                                            |
| `ConcurrencyLimitInterceptor`               | `(config: ConcurrencyConfig(global:, perHost:, hosts:, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500), logPrint:)`                                                      | most requests in flight per host and in total, on `resilience` `Bulkhead`; a null limit means none; full queue → local 429 with `BulkheadRejectedException` and no `Retry-After`; a retry or re-send reuses its request's slot; `getStatistics()`, `dispose()`                                                                                                                    |
| `TokenBucketRateLimitInterceptor`           | `(config: TokenBucketRateLimitConfig(global: [], perHost: [], hosts: {}, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500, pause: PauseConfig()), logPrint:)`              | token buckets from `TokenBucketPolicy` lists; no policy means no token limit; pauses a host on 429, or 503 with `Retry-After`; full queue or long pause → local 429 through the error chain; `getStatistics()`, `dispose()`; do not add `RetryAfterPauseInterceptor` next to it                                                                                                   |
| `RetryAfterPauseInterceptor`                | `(config: PauseOnlyRateLimitConfig(pause: PauseConfig(maxPauseWait: 10 s, maxPause: 10 min, defaultPause: 5 s), maxQueueSize: 50), logPrint:)`                                           | the pause of `TokenBucketRateLimitInterceptor` without token limits; `dispose()`                                                                                                                                                                                                                                                                                                  |
| `PerformanceInterceptor`                    | `(config: PerformanceConfig(maxMetricsHistory: 1000), logPrint:)`                                                                                                                        | `getRecentMetrics()`, `getStatistics()` and `getUrlStatistics()` returning immutable `PerformanceStatistics` snapshots                                                                                                                                                                                                                                                            |
| `HttpLogInterceptor`                        | `(enabled, request, requestHeader, requestBody, responseHeader, responseBody, error, redactHeaders, redactQueryParameters, logPrint)`                                                    | ANSI-coloured chunked printing, following the global `ansiColorDisabled`, which it never writes; prints the status and duration of every response and error; redacts listed headers and query values; logs requests and responses from anywhere in the chain, errors only when placed before `RetryInterceptor` and the exception handler                                         |
| `HttpJsonLogInterceptor`                    | `(config: JsonLogConfig(requestHeaders: false, responseHeaders: false, requestBody: false, responseBody: false, maxBodyBytes: 4096, redactHeaders:, redactQueryParameters:, logPrint:))` | one JSON line per attempt with OpenTelemetry field names (see "Server logging"); never resolves or rejects; a throwing `logPrint` is ignored                                                                                                                                                                                                                                      |
| `NetworkExceptionHandlerInterceptor`        | abstract `QueuedInterceptor`                                                                                                                                                             | implement `onClientError` (4xx) and `onServerError` (5xx), optionally `onNonStandardError`; connect/receive timeouts become `NetworkTimeoutException` first                                                                                                                                                                                                                       |
| `DefaultNetworkExceptionHandlerInterceptor` | `()`                                                                                                                                                                                     | rejects every error as-is                                                                                                                                                                                                                                                                                                                                                         |

Every `config` defaults to its box built with no arguments. `logPrint` receives diagnostics; null prints nothing. The two logs are the exception: their `logPrint` receives the log itself and defaults to the console. Inside a `BaseHttpClient`, the client passes a printer that follows `LogConfig.diagnostics`.

`HttpClientConfig` is freezed: `==`, `copyWith` (which can set a box to `null`), `effectiveHeaders`, and `applyTo(dio)`, which writes the owned options onto a bare `Dio`, merges `headers`, and sets `validateStatus` only when given. It has no presets.

The public model classes behind the interceptors (`CacheEntry`, `ConcurrencyLimitStatistics`, `TokenBucketRateLimitStatistics`, `RequestMetrics`, `PerformanceStatistics`) are freezed classes exported from `interceptors/models/`. Every `getStatistics()` and `getUrlStatistics()` returns an immutable snapshot: its maps and lists throw on mutation, and a snapshot taken earlier keeps its values while the interceptor records more requests. `RequestMetrics` is immutable too; the interceptor completes it with `copyWith` when the response or error arrives, and its `toJson()` reports `method`, `url`, `startTime`, `endTime`, `statusCode`, `error`, `totalDuration`, `requestSize`, and `responseSize`. Both `RequestMetrics.fromJson` and `PerformanceStatistics.fromJson` exist (generated; `totalDuration` and the computed statistics are recomputed, not read); `toJson` is generated too, with `Duration` fields in whole milliseconds through `DurationMillisecondsConverter`.

## Interceptor order

`BaseHttpClient` assembles this order itself, with your `interceptors`, `HttpLogInterceptor` or `HttpJsonLogInterceptor`, and `PerformanceInterceptor` in front. A chain you build by hand on a bare `Dio` must follow it:

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

- `CacheInterceptor` comes first: a cache hit answers in `onRequest` before the limiters see the request, so it takes no concurrency slot and spends no token. The hit still passes every response interceptor, where the limiters find no slot to give back. Any interceptor that answers in `onRequest`, such as a cache or a mock, goes before `ConcurrencyLimitInterceptor`; placed after it, every answer it gives with a plain `resolve` keeps a slot forever.
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

### Refill timers and `dispose()`

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
- `redactHeaders` (default `defaultRedactedHeaders`) and `redactQueryParameters` (default `defaultRedactedQueryParameters`) apply to both log formats and compare names ignoring case. Extend them: `redactHeaders: {...defaultRedactedHeaders, 'x-tenant-secret'}`. Pass `const {}` to turn one off, for example in development.
- A retried request prints one line per attempt. Limiter diagnostics print as JSON lines with `severity_text` `DEBUG` while `diagnostics` is on.
- A `logPrint` that throws is ignored, and a header or body value whose `toString()` throws leaves a minimal `WARN` line whose `body` ends in `(log failed)`; logging never fails a request.
- An OpenTelemetry Collector's `filelog` receiver with a `json_parser` operator turns each line into a log record; the Datadog agent and Cloud Logging read JSON on stdout too. Cloud Logging without a Collector does not map `severity_text` to its own `severity`.
- Switch formats at run time with `client.configure(client.currentConfig.copyWith(log: const LogConfig.json()))`; the limiters keep their state.

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
- Build the client once per process (see "Refill timers and `dispose()`").
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

## Helpers

- `RequestOptions.setHeaderTokenBearer(token)` / `removeHeaderToken()`.
- `HttpHeader.AUTHORIZE`, `ACCEPT_LANGUAGE`, `CACHE_CONTROL`, `CONTENT_TYPE`, `CONTENT_LENGTH`, `COOKIE`, `KEEP_ALIVE`, `ORIGIN`, `USER_AGENT`, `X_API_KEY`; `HttpCode.SUCCESS`, `ERROR_UNAUTHORIZED`, `ERROR_NOT_FOUND`, `ERROR_INTERNAL`.
- `Response<dynamic>?.copyWith<T>(...)`, `.transformData<T>(data:)`.
- `Future<Response<T>>.unwrapResponse()`, `.catchWhenError(f)`; `Future<Response<dynamic>>.mapJson(f)`.
- `DioException.toException()` maps to the `NetworkException` subtype for its status code; see `errors.md`.
- `headers.retryAfter` and `parseRetryAfter(value, serverDate:)` (from `dart_falmodel`) read `Retry-After` as seconds or HTTP-date; `response.isLocalRateLimit` marks a client-side 429.
- `response.isCacheHit` marks a response answered by `CacheInterceptor`; a response interceptor that counts responses sees hits too, so check it there.
