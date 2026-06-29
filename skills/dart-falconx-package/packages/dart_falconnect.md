# dart_falconnect reference

Provides HTTP, WebSocket, and JSON-RPC clients built on Dio and web_socket_channel.
Compiles to web; do not use `dart:io` directly — use `universal_io` if needed.

---

## HTTP — use Retrofit + Dio (recommended)

For typed REST clients, define a Retrofit `@RestApi` and back it with a Dio that
carries the interceptor chain. `dio` and `retrofit` annotations come through the
umbrella import — no extra package import needed for `@RestApi`/`@GET`/`@POST`/
`@Path`/`@Query`/`@Body`/`@Header`.

```dart
import 'package:dart_falconx/dart_falconx.dart';

part 'user_api.g.dart';

@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String baseUrl}) = _UserApi;

  @GET('/users/{id}')
  Future<User> getUser(@Path('id') String id);

  @POST('/users')
  Future<User> createUser(@Body() CreateUserBody body);
}
```

Generate the `.g.dart` in the **consumer** project:
`dart run build_runner build --delete-conflicting-outputs`.

Wire it with a configured Dio — reuse the interceptor chain instead of a bare `Dio()`:

```dart
// Quick: shared default client (JSON, 20s timeouts, error-handling interceptor)
final api = UserApi(DefaultHttpClient.instance.dio, baseUrl: 'https://api.example.com');
final user = await api.getUser('1');

// Production: custom interceptors via a BaseHttpClient subclass (see below)
final api2 = UserApi(MyApiClient().dio);
```

**Gotchas**
- Retrofit's `Headers`, `Parser`, `CacheControl` are **hidden** by the umbrella
  export (Dio's versions win). For the `@Headers({...})` annotation, import
  `package:retrofit/retrofit.dart` directly.
- Retrofit error handling: a non-2xx response throws `DioException`. Add a
  `NetworkExceptionHandlerInterceptor` to the Dio so failures surface as the
  package's `NetworkException` types (see `dart_falmodel.md`).

---

## HTTP — Dio + interceptors via BaseHttpClient

Use `BaseHttpClient` / `DefaultHttpClient` to assemble the interceptor-configured
Dio that backs your Retrofit client (`client.dio`). Its typed `get`/`post`/… methods
below are a converter-based alternative for when you are not using Retrofit.

Abstract class. Subclass it and override `setupOptions` and/or `setupInterceptors`.

```dart
class MyApiClient extends BaseHttpClient {
  MyApiClient() : super(dio: Dio());

  @override
  void setupOptions(Dio dio, BaseOptions options) {
    options
      ..baseUrl = 'https://api.example.com'
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 20)
      ..contentType = Headers.jsonContentType;
  }

  @override
  void setupInterceptors(Dio dio, Interceptors interceptors) {
    interceptors.addAll([
      RetryInterceptor(dio: dio),
      CacheInterceptor(),
      LogInterceptor(),
    ]);
  }
}
```

`DefaultHttpClient` is a ready-made singleton (`DefaultHttpClient.instance`) with
JSON content-type, 20-second timeouts, and `DefaultNetworkExceptionHandlerInterceptor`.
Use it for quick one-off calls; subclass `BaseHttpClient` for production clients.

### HTTP methods

All methods share the same signature shape. `converter` is always **required**.

```dart
// GET
Future<Response<T>> get<T>(
  String path, {
  Map<String, Object>? queryParameters,
  Options? options,
  CancelToken? cancelToken,
  ProgressCallback? onReceiveProgress,
  bool isUseToken = true,
  required FutureOr<T> Function(Map<String, dynamic> json) converter,
  T? Function(DioException e, StackTrace? s)? catchError,
})

// POST (JSON body)
Future<Response<T>> post<T>(
  String path, {
  BaseRequestBody? data,           // calls data.toJson() internally
  Map<String, Object>? queryParameters,
  Options? options,
  CancelToken? cancelToken,
  ProgressCallback? onSendProgress,
  ProgressCallback? onReceiveProgress,
  bool isUseToken = true,
  required T Function(Map<String, dynamic> json) converter,
  T? Function(DioException e, StackTrace? s)? catchError,
})

// POST (form/file upload)
Future<Response<T>> postFormData<T>(String path, { FormData? data, ..., required converter, ... })

// PATCH, PUT — same signature as post
// putFormData — same as postFormData but PUT verb
// DELETE — no onSendProgress / onReceiveProgress
Future<Response<T>> delete<T>(
  String path, {
  BaseRequestBody? data,
  Map<String, Object>? queryParameters,
  Options? options,
  CancelToken? cancelToken,
  bool isUseToken = true,
  required T Function(Map<String, dynamic> json) converter,
  T? Function(DioException e, StackTrace? s)? catchError,
})
```

### Minimal usage example

```dart
final client = MyApiClient();

// GET
final response = await client.get<User>(
  '/users/1',
  converter: User.fromJson,
);
final user = response.data!;

// POST with body
await client.post<CreateUserResponse>(
  '/users',
  data: CreateUserBody(name: 'Alice', email: 'alice@example.com'),
  converter: CreateUserResponse.fromJson,
  catchError: (e, s) => null,
);
```

### Runtime-adding interceptors

```dart
client.addInterceptors(Interceptors()..add(MyCustomInterceptor()));
```

### Accessing Dio directly

```dart
client.dio           // Dio instance
client.baseUrl       // current base URL string
client.config        // BaseOptions
client.interceptors  // Interceptors list
client.setupBaseUrl('https://other.example.com');
```

---

## HTTP Interceptors

| Class                                       | Purpose                                                                                              |
|---------------------------------------------|------------------------------------------------------------------------------------------------------|
| `RetryInterceptor`                          | Exponential backoff with jitter; respects `Retry-After`; retries on 5xx / 408 / 429 / 409 / timeouts |
| `CacheInterceptor`                          | Response caching via `dio_cache_interceptor`                                                         |
| `LogInterceptor`                            | Request/response logging with ANSI colours                                                           |
| `PerformanceInterceptor`                    | Request timing (timing fields are `null` on web)                                                     |
| `RateLimitInterceptor`                      | Rate limiting                                                                                        |
| `NetworkExceptionHandlerInterceptor`        | Abstract: override `onClientError` / `onServerError` / `onNonStandardError`                          |
| `DefaultNetworkExceptionHandlerInterceptor` | Concrete: rejects all errors (no custom handling)                                                    |

**Order:** add to `setupInterceptors` in this sequence:
auth (custom) → `RetryInterceptor` → `CacheInterceptor` → `LogInterceptor`

---

## WebSocket — SocketClient

Abstract class. Subclass and implement `setupConfig`.

```dart
class PriceSocketClient extends SocketClient {
  PriceSocketClient() : super('wss://stream.example.com/prices');

  @override
  void setupConfig(SocketOptions configs) {
    configs.retryLimit = 5;
  }

  @override
  void setupInterceptors(SocketInterceptors interceptors) {
    interceptors.add(SocketLogInterceptor());
  }
}
```

### Key methods

```dart
// Send a message (auto-opens channel on first call)
await client.request(jsonEncode({'type': 'subscribe', 'channel': 'BTC-USD'}));

// Typed stream with optional filter
Stream<PriceUpdate> stream = client.getResponseStream<PriceUpdate>(
  filter: (r) => r.data.contains('"type":"price"'),
  converter: (r) => PriceUpdate.fromJson(jsonDecode(r.data)),
);

// Raw SocketResponse stream
Stream<SocketResponse> raw = client.getRawStream(
  filter: (r) => r.data.isNotEmpty,
);

// Manage channel manually
await client.createChannel();
await client.closeChannel();
await client.checkConnection(); // sends 'ping'; reconnects if channel is dead

bool closed = client.isClose;
SocketOptions opts = client.options;
```

`SocketResponse` carries `.data` (raw String) and `.requestOptions`.

The stream is a `PublishSubject<SocketResponse>` — late subscribers do not receive
past events.

### Socket exceptions

| Class                              | When                                         |
|------------------------------------|----------------------------------------------|
| `SocketRetryException`             | During retry attempts (carries `retryCount`) |
| `SocketException`                  | After retry limit exhausted                  |
| `SocketOperationNotFoundException` | Unknown operation                            |

### SocketBoundResource

Transforms a socket stream into `Result<EntityType>`:

```dart
SocketBoundResource<Entity, RawResponse>(
  socketStream: client.getResponseStream(...),
  processResponse: (raw) => Entity.fromRaw(raw),
)
```

---

## JSON-RPC 2.0 — JsonRpcService / DefaultJsonRpcService

`JsonRpcService` is abstract. `DefaultJsonRpcService` is the concrete implementation.

```dart
final rpc = DefaultJsonRpcService(
  Dio(),
  baseUrl: 'https://api.example.com/rpc',
  jsonrpc: '2.0',
);
```

### Methods

```dart
// Single request — expects a 'result' field
Future<JsonRpcResponse<RESULT>> request<RESULT extends JsonRpcResult>({
  String? path,
  required String method,
  Map<String, dynamic>? params,
  String? id,           // auto-generated if omitted
  String? mockId,
  required RESULT Function(Map<String, dynamic> json) fromResultJson,
  Map<String, dynamic>? queryParameters,
  Map<String, dynamic>? headers,
  Map<String, dynamic>? extra,
})

// Fire-and-forget (no expected result)
Future<void> notify({
  String? path,
  required String method,
  Map<String, dynamic>? params,
  String? mockId,
})

FutureOr<void> notifySync({...}) // delegates to notify

// Batch — multiple calls in one HTTP POST
Future<List<BatchJsonRpcItem<dynamic>>> batch(
  String path, {
  required List<BatchJsonRpcBody<dynamic>> bodyList,
})
```

### Error handling

- Server returns an error object → throws `JsonRpcErrorResponse`
- `result` field absent on a non-notify call → throws `StateError`

### Batch response handling

```dart
final items = await rpc.batch('/rpc', bodyList: [...]);

for (final item in items) {
  final value = item.resolve(
    success: (response) => response.result,
    failure: (error) => handleError(error.errors.first),
  );
}

// Null-safe accessors
final ok  = item.responseOrNull;  // JsonRpcResponse?
final err = item.errorOrNull;     // JsonRpcErrorResponse?
item.isSuccess;
item.isFailure;

// Transform success value
final mapped = item.map<MyResult>((r) => JsonRpcResponse(...));
```

Items without an `id` in the server response are silently dropped.

### Result types

```dart
// Model result (has toJson)
class MyResult extends JsonRpcModelResult {
  MyResult({required this.value});
  final String value;

  factory MyResult.fromJson(Map<String, dynamic> json) =>
      MyResult(value: json['value'] as String);

  @override
  Map<String, dynamic> toJson() => {'value': value};
}

// List of results
class MyListResult extends JsonRpcListResult<MyResult> {
  const MyListResult(super.data);
}

// Primitive wrappers
class MyStringResult extends JsonRpcStringResult {
  const MyStringResult(super.data);
}

// Raw map result (no subclassing)
final raw = JsonRpcRawResult({'key': 'value'});
```

---

## DatasourceBoundState — repository pattern

Static helper providing three strategies. All return `Result<T>`.

```dart
// Local DB only — stream
Stream<Result<T>> DatasourceBoundState.asLocalResultStream<T>({
  required Future<T> Function() loadFromDbFuture,
  CommonException Function(CommonException, StackTrace?)? handleError,
  bool log = false,
})

// Local DB only — future
Future<Result<T>> DatasourceBoundState.asLocalResultFuture<T>({...})

// Remote API only — stream / future equivalents
Stream<Result<T>>  DatasourceBoundState.asRemoteResultStream<T>({...})
Future<Result<T>>  DatasourceBoundState.asRemoteResultFuture<T>({...})

// Combined: emit local first, then optionally fetch remote
Stream<Result<DataType>> DatasourceBoundState.asResultStream<DataType, ResponseType>({
  required Future<DataType>        Function()               loadFromDbFuture,
  required Future<ResponseType>    Function()               fetchFromRemoteFuture,
  required Future<void>            Function(ResponseType)   saveToDbFuture,
  required bool                    Function(DataType?)       shouldFetch,
  Future<DataType>                 Function(ResponseType)?  processResponse, // required when DataType != ResponseType
  CommonException Function(CommonException, StackTrace?)?   handleError,
})
```

See `dart_falmodel.md` for `Result<T>` API.
