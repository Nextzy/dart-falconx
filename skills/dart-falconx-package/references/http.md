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

final api = UserApi(DefaultHttpClient.instance.dio, baseUrl: 'https://api.example.com');
```

Generate `_UserApi` with `dart run build_runner build --delete-conflicting-outputs`.
Retrofit's `Future<HttpResponse<T>>` gains `.unwrapResponse()` and `.catchWhenError(f)`.

## `DefaultHttpClient`

Singleton `DefaultHttpClient.instance`: JSON content type, 20 s connect and receive timeouts, one `DefaultNetworkExceptionHandlerInterceptor` (rejects every error unchanged). Reach Dio with `.dio`; base URL with `.baseUrl` / `setupBaseUrl(url)`.

## Custom client: subclass `BaseHttpClient`

```dart
class ApiClient extends BaseHttpClient {
  ApiClient() : super(dio: Dio());

  static final _config = HttpClientConfig.production();

  @override
  void setupOptions(Dio dio, BaseOptions options) {
    _config.applyTo(dio);
    options.baseUrl = 'https://api.example.com';
  }

  @override
  void setupInterceptors(Dio dio, Interceptors interceptors) {
    interceptors.addAll([
      AuthInterceptor(),                              // yours
      RetryInterceptor(config: _config, dio: dio),
      CacheInterceptor(config: _config),
      HttpLogInterceptor(),
    ]);
  }
}
```

Both hooks run inside the `BaseHttpClient` constructor, so fields assigned in your constructor body are not yet set; use `static` or initializer fields.

Members: `dio`, `baseUrl`, `setupBaseUrl(String)`, `config` (`BaseOptions`), `interceptors`, `addInterceptors(Interceptors)` to append at runtime.

## Converter-based calls

Every method takes `converter: (Map<String, dynamic> json) => T` and returns `Future<Response<T>>`. A plain `String` body arrives as `{'result': body}`.

| Method                                | Body                                                    | Extras                                                                                       |
|---------------------------------------|---------------------------------------------------------|----------------------------------------------------------------------------------------------|
| `get<T>`                              | none                                                    | `queryParameters`, `options`, `cancelToken`, `onReceiveProgress`; `converter` may be async   |
| `post<T>`, `patch<T>`, `put<T>`       | `data: BaseRequestBody?` (serialised with `toJson()`)   | plus `onSendProgress`                                                                        |
| `postFormData<T>`, `putFormData<T>`   | `data: FormData?`                                       | same                                                                                         |
| `delete<T>`                           | `data: BaseRequestBody?`                                | `queryParameters`, `cancelToken`                                                             |

`catchError: (DioException e, StackTrace? st) => T?` returns a fallback to resolve the future, or `null` to rethrow. `isUseToken` is accepted but only your own interceptors read it.

```dart
final res = await client.get<UserDto>('/users/$id', converter: UserDto.fromJson);
final user = res.data;
```

## Interceptor catalog

| Class                                         | Constructor                                                                                                                                                              | Behaviour                                                                                                                                                                                                                                                                                                                                                                                        |
|-----------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RetryInterceptor`                            | `(config:, dio:, onRetry:, random:)`                                                                                                                                     | loops up to `retryAttempts ?? config.maxRetryAttempts`; 429 and `connectionTimeout` for every method; timeouts, connection errors, 408/409/5xx only for idempotent methods unless `retryNonIdempotent`; `Retry-After` on 429/503 (not retried above `maxRetryDelay`), else full jitter; stops at `config.maxRetryDuration`; never retries cancels, local 429s, `Stream` bodies, bad certificates |
| `CacheInterceptor`                            | `(config:)`                                                                                                                                                              | in-memory cache of 2xx GET responses; respects `Cache-Control` and `Expires`; `clearCache()`, `evictExpired()`                                                                                                                                                                                                                                                                                   |
| `ConcurrencyLimitInterceptor`                 | `(config:, global:, perHost:, hosts: {}, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500)`                                                                | most requests in flight per host and in total, on `resilience` `Bulkhead`; a null limit means none; full queue → local 429 with `BulkheadRejectedException` and no `Retry-After`; a retry or re-send reuses its request's slot; `getStatistics()`, `dispose()` |
| `TokenBucketRateLimitInterceptor`             | `(config:, global: [], perHost: [], hosts: {}, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500, maxPauseWait: 10 s, maxPause: 10 min, defaultPause: 5 s)` | token buckets from `TokenBucketPolicy` lists; no policy means no token limit; pauses a host on 429, or 503 with `Retry-After`; full queue or long pause → local 429 through the error chain; `getStatistics()`, `dispose()`; do not add `RetryAfterPauseInterceptor` next to it                                                                                                                  |
| `RetryAfterPauseInterceptor`                  | `(config:, maxPauseWait: 10 s, maxPause: 10 min, defaultPause: 5 s, maxQueueSize: 50)`                                                                                   | the pause of `TokenBucketRateLimitInterceptor` without token limits; `dispose()`                                                                                                                                                                                                                                                                                                                 |
| `PerformanceInterceptor`                      | `(config:, maxMetricsHistory: 1000, collectDetailedTimings: true)`                                                                                                       | `getRecentMetrics()`, `getStatistics()` returning `PerformanceStatistics`                                                                                                                                                                                                                                                                                                                        |
| `HttpLogInterceptor`                          | `(enabled, request, requestHeader, requestBody, responseHeader, responseBody, error, logPrint)`                                                                          | ANSI-coloured chunked printing; logs requests and responses from anywhere in the chain, errors only when placed before `RetryInterceptor` and the exception handler |
| `NetworkExceptionHandlerInterceptor`          | abstract `QueuedInterceptor`                                                                                                                                             | implement `onClientError` (4xx) and `onServerError` (5xx), optionally `onNonStandardError`; connect/receive timeouts become `NetworkTimeoutException` first                                                                                                                                                                                                                                      |
| `DefaultNetworkExceptionHandlerInterceptor`   | `()`                                                                                                                                                                     | rejects every error as-is                                                                                                                                                                                                                                                                                                                                                                        |

`HttpClientConfig`: `const HttpClientConfig({...})`, presets `production()`, `development()`, `test()`, `copyWith(...)`, and `applyTo(dio)` which sets timeouts, redirects, default headers, user agent, and `validateStatus: status < 500`. Retry fields: `maxRetryAttempts`, `retryDelay`, `maxRetryDelay`, `maxRetryDuration`. Because `applyTo` accepts every status below 500, a 429 reaches the caller as a normal response and `RetryInterceptor` never sees it; the rate limiter still pauses the host.

## Interceptor order

```dart
interceptors.addAll([
  CacheInterceptor(config: config),
  ConcurrencyLimitInterceptor(config: config, global: 16, perHost: 4),
  TokenBucketRateLimitInterceptor(config: config), // or RetryAfterPauseInterceptor, never both
  RetryInterceptor(config: config, dio: dio),
  DefaultNetworkExceptionHandlerInterceptor(),
]);
```

- `CacheInterceptor` comes first: a cache hit answers in `onRequest` without calling the response interceptors, so it takes no concurrency slot and spends no token. Any interceptor that answers in `onRequest`, such as a cache or a mock, goes before `ConcurrencyLimitInterceptor`; placed after it, every answer it gives keeps a slot forever.
- `ConcurrencyLimitInterceptor` comes before the rate limiter: the slot is taken before the tokens, so the token ceiling holds on the wire and the pause gate sees every request. A request holds its slot while the rate limiter holds it, so set `perHost` below `global`, for example 4 and 16, so one slow or paused host cannot take every global slot.
- The rate limiter comes before `RetryInterceptor`: dio runs `onError` in list order, so the limiter sees a server 429 and starts the pause before the retry is sent. The retry then passes the pause gate, and the total wait is the longer of the retry delay and the pause, never their sum.
- An interceptor that re-sends from `onError`, such as an auth refresh, goes after `ConcurrencyLimitInterceptor`. Placed before it, the re-send reuses its request's slot, which also works.
- `DefaultNetworkExceptionHandlerInterceptor` comes last: it rejects without calling later error interceptors, so a `ConcurrencyLimitInterceptor` placed after it would never get its slots back.
- Every retry passes the whole chain again, so error interceptors see each attempt. Placed before `RetryInterceptor`, one sees every attempt exactly once with a distinct `requestOptions.retryAttempt`; placed after it, one sees attempts 1..n from inside the retries plus the final error again, so it reports the last failure twice. Place error loggers and crash reporters before `RetryInterceptor`.
- A retry is a fresh `dio.fetch` of a copy of the original options. To replay a failed request by hand, call `dio.get(...)` (or `fetch` with fresh options) again, not `dio.fetch(error.requestOptions)`: the failed options carry `retryAttempt > 0`, which reads as a nested attempt and is never retried.

## Rate limiting

Every scope is unlimited until you give it a policy. A `TokenBucketPolicy` means "at most `permits` requests in any window of `per`"; `burst` (default 10% of `permits`, at least 1) is how many may leave back to back after idle time, and the steady rate is `permits - burst + 1` per `per`.

```dart
final rateLimit = TokenBucketRateLimitInterceptor(
  config: config,
  hosts: const {
    'api.partner.com': [
      TokenBucketPolicy(permits: 100, per: Duration(minutes: 1)),
      TokenBucketPolicy(permits: 5000, per: Duration(hours: 1), burst: 50),
    ],
  },
);
```

`hosts` keys must be bare hosts exactly as `Uri.host` returns them: lowercase, with no port, brackets, or spaces (`::1` is valid). An empty list (`'api.my-backend.com': []`) opts a host out of `perHost`.

Tokens are never returned. When a later tier's full queue rejects a request, tokens already taken by earlier tiers stay spent. A request cancelled with a `CancelToken` while it waits for tokens keeps its queue place and still spends a token when it reaches the front; it is neither forwarded nor counted in `getStatistics().forwarded`. For screens that cancel queued requests often, keep `maxQueueSize` small or set `queueRequests: false`.

### Pause on 429 and 503

A 429 pauses its host for its `Retry-After` (seconds or HTTP-date), else for `defaultPause`; a 503 pauses only when it carries `Retry-After`. Every pause is clamped to `maxPause`, never shortens an earlier one, and applies to hosts without a policy too. While a host is paused, a request waits when the remaining pause is at most `maxPauseWait` and fewer than `maxQueueSize` requests already wait; otherwise it fails at once with a local 429 carrying `Retry-After`. An extension that pushes the remaining pause past `maxPauseWait` also releases every held request, which then re-checks the pause and fails the same way, so a held request waits at most about `maxPauseWait` from admission. A request that gets its tokens during a pause spends them and waits again, so the ceiling also holds after the pause.

A local 429 (full queue or long pause) has type `DioExceptionType.badResponse` and goes through every error interceptor, so callers get `NetworkLimitExceededException` for local and server 429s alike. `response.isLocalRateLimit` tells them apart, for example to keep them out of crash reports. `getStatistics()` exposes the pause through `heldByHost` (requests held per host) and `pausedUntilByHost` (end time of each active pause), and its `rejected` counter includes pause rejections.

Use `RetryAfterPauseInterceptor` for the pause alone. `TokenBucketRateLimitInterceptor` already contains it; a chain with the token bucket must not add `RetryAfterPauseInterceptor`.

### Migrating from 1.x `RateLimitInterceptor`

Renaming the class is not enough. `RateLimitInterceptor(config: config)` limited every request by default (100 req/s global, 10 req/s per host); `TokenBucketRateLimitInterceptor(config: config)` limits nothing. The closest equivalent of the 1.x defaults:

```dart
final rateLimit = TokenBucketRateLimitInterceptor(
  config: config,
  global: const [TokenBucketPolicy(permits: 100, per: Duration(seconds: 1))],
  perHost: const [TokenBucketPolicy(permits: 10, per: Duration(seconds: 1))],
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
final concurrency = ConcurrencyLimitInterceptor(
  config: config,
  global: 16,
  perHost: 4,
  hosts: const {'pay.partner.com': 2, 'cdn.example.com': null},
);
```

`pay.partner.com` runs 2 requests at once; `cdn.example.com` has no host limit but still counts toward the 16 global slots; every other host gets 4. `hosts` keys follow the token bucket rule: bare lowercase hosts as `Uri.host` returns them.

A request takes a slot in `onRequest` and gives it back when its response or error passes the interceptor, or when its `CancelToken` cancels. Without a free slot it waits in a FIFO queue (`maxQueueSize` per host, `maxGlobalQueueSize` for the global limit), or fails at once with `queueRequests: false`. A full queue fails the request with a local 429: `isLocalRateLimit` is true, `err.error` is a `BulkheadRejectedException` until the exception handler maps it to `NetworkLimitExceededException`, and there is no `Retry-After`, so `recommendedRetryDelay` falls back to 1 minute. A retry attempt, or a re-send of `err.requestOptions`, reuses the slot its request still holds, so a limit of 1 never deadlocks.

Limitations:

- Nothing limits the time a request spends in the queue. Pass a `CancelToken` with a deadline to bound it.
- A request cancelled while it waits keeps its queue place until it reaches the head, so it counts toward `maxQueueSize` until then.
- A request that never ends holds its slot. Keep `connectTimeout` and `receiveTimeout` set.
- A `ResponseType.stream` response gives its slot back when its headers arrive, before its body is read.
- Two concurrent fetches of one `RequestOptions` object share one slot.

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
    ..retryAttempts = 5,        // overrides config.maxRetryAttempts
);
await dio.get<dynamic>('/live', options: Options()..disableRetry = true);
```

`onRetry: (error, attempt, delay) {...}` runs before each wait; `error.stackTrace` holds the failure's stack trace.

### Migrating `RetryInterceptor` from 1.x

- `POST` and `PATCH` are no longer retried after a 5xx, a timeout other than `connectionTimeout`, or a connection error, unless `retryNonIdempotent` is set.
- A `Retry-After` longer than `maxRetryDelay` ends retrying instead of waiting.
- Retries reach `maxRetryAttempts`; 1.x ran at most one retry.
- `extra['retryCount']` and `extra['isRetry']` are gone; read `requestOptions.retryAttempt`.
- The delay is full jitter, a random time up to the exponential cap, instead of the cap plus up to one second.

## Helpers

- `RequestOptions.setHeaderTokenBearer(token)` / `removeHeaderToken()`.
- `HttpHeader.AUTHORIZE`, `ACCEPT_LANGUAGE`, `CACHE_CONTROL`, `CONTENT_TYPE`, `CONTENT_LENGTH`, `COOKIE`, `KEEP_ALIVE`, `ORIGIN`, `USER_AGENT`, `X_API_KEY`; `HttpCode.SUCCESS`, `ERROR_UNAUTHORIZED`, `ERROR_NOT_FOUND`, `ERROR_INTERNAL`.
- `Response<dynamic>?.copyWith<T>(...)`, `.transformData<T>(data:)`.
- `Future<Response<T>>.unwrapResponse()`, `.catchWhenError(f)`; `Future<Response<dynamic>>.mapJson(f)`.
- `DioException.toException()` maps to the `NetworkException` subtype for its status code; see `errors.md`.
- `headers.retryAfter` and `parseRetryAfter(value, serverDate:)` (from `dart_falmodel`) read `Retry-After` as seconds or HTTP-date; `response.isLocalRateLimit` marks a client-side 429.
