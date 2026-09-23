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

| Method                              | Body                                                  | Extras                                                                                     |
|-------------------------------------|-------------------------------------------------------|--------------------------------------------------------------------------------------------|
| `get<T>`                            | none                                                  | `queryParameters`, `options`, `cancelToken`, `onReceiveProgress`; `converter` may be async |
| `post<T>`, `patch<T>`, `put<T>`     | `data: BaseRequestBody?` (serialised with `toJson()`) | plus `onSendProgress`                                                                      |
| `postFormData<T>`, `putFormData<T>` | `data: FormData?`                                     | same                                                                                       |
| `delete<T>`                         | `data: BaseRequestBody?`                              | `queryParameters`, `cancelToken`                                                           |

`catchError: (DioException e, StackTrace? st) => T?` returns a fallback to resolve the future, or `null` to rethrow. `isUseToken` is accepted but only your own interceptors read it.

```dart
final res = await client.get<UserDto>('/users/$id', converter: UserDto.fromJson);
final user = res.data;
```

## Interceptor catalog

| Class                                       | Constructor                                                                                                     | Behaviour                                                                                                                                                                                                                  |
|---------------------------------------------|-----------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RetryInterceptor`                          | `(config:, dio:)`                                                                                               | retries timeouts, connection errors, 5xx, 408/409/429; exponential backoff plus jitter; honours `Retry-After` on 429; bounded by `config.maxRetryAttempts` and `maxRetryDelay`                                             |
| `CacheInterceptor`                          | `(config:)`                                                                                                     | in-memory cache of 2xx GET responses; respects `Cache-Control` and `Expires`; `clearCache()`, `evictExpired()`                                                                                                             |
| `TokenBucketRateLimitInterceptor`           | `(config:, global: [], perHost: [], hosts: {}, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500)` | token buckets from `TokenBucketPolicy` lists; no policy means unlimited; each request passes its host tiers (`hosts[host]`, else `perHost`) then `global`; full queue → 429 `DioException`; `getStatistics()`, `dispose()` |
| `PerformanceInterceptor`                    | `(config:, maxMetricsHistory: 1000, collectDetailedTimings: true)`                                              | `getRecentMetrics()`, `getStatistics()` returning `PerformanceStatistics`                                                                                                                                                  |
| `HttpLogInterceptor`                        | `(enabled, request, requestHeader, requestBody, responseHeader, responseBody, error, logPrint)`                 | ANSI-coloured chunked printing; add last                                                                                                                                                                                   |
| `NetworkExceptionHandlerInterceptor`        | abstract `QueuedInterceptor`                                                                                    | implement `onClientError` (4xx) and `onServerError` (5xx), optionally `onNonStandardError`; connect/receive timeouts become `NetworkTimeoutException` first                                                                |
| `DefaultNetworkExceptionHandlerInterceptor` | `()`                                                                                                            | rejects every error as-is                                                                                                                                                                                                  |

`HttpClientConfig`: `const HttpClientConfig({...})`, presets `production()`, `development()`, `test()`, `copyWith(...)`, and `applyTo(dio)` which sets timeouts, redirects, default headers, user agent, and `validateStatus: status < 500`.

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

`hosts` keys must be lowercase. An empty list (`'api.my-backend.com': []`) opts a host out of `perHost`.

Tokens are never returned. When a later tier's full queue rejects a request, tokens already taken by earlier tiers stay spent. A request cancelled with a `CancelToken` while it waits keeps its queue place and still spends a token when it reaches the front: the caller gets the cancel error at once, the quota is used anyway, and `getStatistics().forwarded` counts it. For screens that cancel queued requests often, keep `maxQueueSize` small or set `queueRequests: false`.

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

| Context                                      | Call `dispose()`                                                                                       |
|----------------------------------------------|--------------------------------------------------------------------------------------------------------|
| Flutter app, client lives as long as the app | not needed                                                                                             |
| Scoped client (DI scope, logout, env switch) | when the scope ends: get_it `dispose:`, injectable `@disposeMethod`, Riverpod `ref.onDispose`          |
| `testWidgets` with a real client             | at the end of the test body or from a widget's `dispose`; `addTearDown` is too late and the test fails |
| Unit test under `fakeAsync`                  | at the end of the `fakeAsync` body                                                                     |
| CLI                                          | in a `finally` before `main` returns, or exit waits until every bucket refills                         |
| Server (dart_frog)                           | not needed                                                                                             |

On a server, build the client once per process (a top-level variable returned by `provider`). A client built inside a per-request `provider` starts with full buckets on every request and limits nothing.

## Helpers

- `RequestOptions.setHeaderTokenBearer(token)` / `removeHeaderToken()`.
- `HttpHeader.AUTHORIZE`, `ACCEPT_LANGUAGE`, `CACHE_CONTROL`, `CONTENT_TYPE`, `CONTENT_LENGTH`, `COOKIE`, `KEEP_ALIVE`, `ORIGIN`, `USER_AGENT`, `X_API_KEY`; `HttpCode.SUCCESS`, `ERROR_UNAUTHORIZED`, `ERROR_NOT_FOUND`, `ERROR_INTERNAL`.
- `Response<dynamic>?.copyWith<T>(...)`, `.transformData<T>(data:)`.
- `Future<Response<T>>.unwrapResponse()`, `.catchWhenError(f)`; `Future<Response<dynamic>>.mapJson(f)`.
- `DioException.toException()` maps to the `NetworkException` subtype for its status code; see `errors.md`.
