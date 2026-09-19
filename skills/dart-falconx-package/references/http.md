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

| Class                                       | Constructor                                                                                                       | Behaviour                                                                                                                                                                      |
|---------------------------------------------|-------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RetryInterceptor`                          | `(config:, dio:)`                                                                                                 | retries timeouts, connection errors, 5xx, 408/409/429; exponential backoff plus jitter; honours `Retry-After` on 429; bounded by `config.maxRetryAttempts` and `maxRetryDelay` |
| `CacheInterceptor`                          | `(config:)`                                                                                                       | in-memory cache of 2xx GET responses; respects `Cache-Control` and `Expires`; `clearCache()`, `evictExpired()`                                                                 |
| `RateLimitInterceptor`                      | `(config:, globalRateLimit: 100, perHostRateLimit: 10, windowSize: 1 min, queueRequests: true, maxQueueSize: 50)` | token bucket per host and global; `getStatistics()`, `clearQueues()`                                                                                                           |
| `PerformanceInterceptor`                    | `(config:, maxMetricsHistory: 1000, collectDetailedTimings: true)`                                                | `getRecentMetrics()`, `getStatistics()` returning `PerformanceStatistics`                                                                                                      |
| `HttpLogInterceptor`                        | `(enabled, request, requestHeader, requestBody, responseHeader, responseBody, error, logPrint)`                   | ANSI-coloured chunked printing; add last                                                                                                                                       |
| `NetworkExceptionHandlerInterceptor`        | abstract `QueuedInterceptor`                                                                                      | implement `onClientError` (4xx) and `onServerError` (5xx), optionally `onNonStandardError`; connect/receive timeouts become `NetworkTimeoutException` first                    |
| `DefaultNetworkExceptionHandlerInterceptor` | `()`                                                                                                              | rejects every error as-is                                                                                                                                                      |

`HttpClientConfig`: `const HttpClientConfig({...})`, presets `production()`, `development()`, `test()`, `copyWith(...)`, and `applyTo(dio)` which sets timeouts, redirects, default headers, user agent, and `validateStatus: status < 500`.

## Helpers

- `RequestOptions.setHeaderTokenBearer(token)` / `removeHeaderToken()`.
- `HttpHeader.AUTHORIZE`, `ACCEPT_LANGUAGE`, `CACHE_CONTROL`, `CONTENT_TYPE`, `CONTENT_LENGTH`, `COOKIE`, `KEEP_ALIVE`, `ORIGIN`, `USER_AGENT`, `X_API_KEY`; `HttpCode.SUCCESS`, `ERROR_UNAUTHORIZED`, `ERROR_NOT_FOUND`, `ERROR_INTERNAL`.
- `Response<dynamic>?.copyWith<T>(...)`, `.transformData<T>(data:)`.
- `Future<Response<T>>.unwrapResponse()`, `.catchWhenError(f)`; `Future<Response<dynamic>>.mapJson(f)`.
- `DioException.toException()` maps to the `NetworkException` subtype for its status code; see `errors.md`.
