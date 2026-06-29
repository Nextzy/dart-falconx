# dart_falmodel reference

Data models, exception hierarchy, and the `Result<T>` pattern.

---

## Result<T>

Type-safe success/failure without throwing. Failures carry a `CommonException`.

### Construction

```dart
Result<User> ok      = Result.success(user);
Result<User> fail    = Result.failure(CommonException(type: SystemErrorType.unknown));
Result<User> dFail   = Result.dataFailure(code: StorageErrorType.database, userMessage: 'DB error');
Result<User> domFail = Result.domainFailure(code: BusinessErrorType.notFound);
```

### Accessors

```dart
result.isSuccess       // bool
result.isFailure       // bool
result.value           // T — throws StateError if failure
result.valueOrNull     // T?
result.valueOr(def)    // T
result.exception       // CommonException — throws if success
result.exceptionOrNull // CommonException?
result.stackTraceOrNull // StackTrace?
```

### Transforms

```dart
// Map value (stays success/failure)
Result<String> name = result.map((user) => user.name);

// Flat-map (chain Result-returning operation)
Result<Profile> profile = result.flatMap((user) => loadProfile(user.id));

// Fold into any type
String msg = result.resolve(
  (user) => 'Hello ${user.name}',
  (err, st) => 'Error: ${err.message}',
);

// Side-effect callbacks
result.when(
  (user) => print(user),
  (err, st) => logger.e(err),
);

result.doOnSuccess((user) => cache.put(user));
result.doOnFailure((err) => analytics.track(err));

// Recover from failure
Result<User> safe = result.recover((_) => User.guest());
Result<User> safe2 = result.recoverWith((_) => Result.success(User.guest()));

// Transform exception
Result<User> mapped = result.mapException((e) => e.copyWith(userMessage: 'Retry'));

// Update failure messages without changing type
Result<User> r2 = result.updateFailMessage(userMessage: 'Try again');
```

---

## Exception system 1 — CommonException (general)

Base class for all exceptions.

```dart
const CommonException({
  required Object type,        // a DefaultErrorType implementor
  String? userMessage,
  String? developerMessage,
  Map<String, dynamic>? data,
  Object? originalException,
  StackTrace? stackTrace,
})
```

**`DefaultErrorType` is a sealed class.** The concrete error-type enums are:

| Enum                    | Values (examples)                                                               |
|-------------------------|---------------------------------------------------------------------------------|
| `SystemErrorType`       | `unknown`, `system`, `unexpected`, `concurrency`                                |
| `InputErrorType`        | `validation`, `invalidFormat`, `invalidValue`, `outOfRange`, `argument`, `type` |
| `TimeoutErrorType`      | `timeout`, `deadline`                                                           |
| `StorageErrorType`      | `storage`, `cache`, `database`, `fileSystem`                                    |
| `ConnectivityErrorType` | `connection`, `socket`, `tls`, `dns`, `http`                                    |
| `AsyncErrorType`        | `stream`, `future`, `isolate`                                                   |
| `AccessErrorType`       | `permission`, `unauthorized`, `deviceNotSupported`                              |
| `ExternalErrorType`     | `thirdParty`, `serviceUnavailable`                                              |
| `BusinessErrorType`     | `businessRule`, `notFound`, `conflict`, `deprecated`                            |

### Layer-specific subclasses

```dart
DataLayerException(type: StorageErrorType.database, userMessage: '...')
DomainLayerException(type: BusinessErrorType.notFound)
TodoException(...)       // marks incomplete work
```

### CommonException methods

```dart
exception.message        // userMessage ?? developerMessage ?? generic fallback
exception.copyWith(...)  // shallow copy with overrides
exception.mapMessage(userMessage: (t) => ..., developerMessage: (t) => ...)
exception.mapUserMessage((t) => ...)
exception.mapDeveloperMessage((t) => ...)

// Convert to UserFeedback variants
exception.toFailure(level: FeedbackLevel.high)
exception.toWarning()
exception.toInformation()

// Convert to JSON-RPC error (see exception system 3)
exception.toJsonRpcError(userMessage: 'Override message')
```

---

## Exception system 2 — NetworkException (HTTP)

```dart
class NetworkException extends CommonException {
  final int statusCode;
  final Response<dynamic>? response;
  final RequestOptions? requestOptions;
  final List<NetworkException>? errors;
}
```

**`NetworkErrorType` enum** maps 1:1 to HTTP status codes plus general categories:
`unknown`, `network`, `timeout`, `noInternet`, `clientError`, `serverError`,
`badRequest` (400), `unauthorized` (401), `forbidden` (403), `notFound` (404),
`conflict` (409), `tooManyRequests` (429), `internalServerError` (500),
`serviceUnavailable` (503), `gatewayTimeout` (504), and many more.

```dart
NetworkErrorType.fromStatusCode(404)  // → NetworkErrorType.notFound
NetworkErrorType.notFound.statusCode  // → 404
NetworkErrorType.notFound.defaultMessage // human-readable string
NetworkErrorType.badRequest.isClientError // true
NetworkErrorType.internalServerError.isServerError // true
```

**Concrete exception classes** (one per HTTP status, exported publicly):
`BadRequestException`, `UnauthorizedException`, `ForbiddenException`,
`NotFoundException`, `ConflictException`, `TooManyRequestsException`,
`InternalServerErrorException`, `ServiceUnavailableException`,
`GatewayTimeoutException`, etc.

Known quirk: `NetworkNotImplementException` (501) — the class name is missing
"ed"; preserved for backward compatibility.

Duplicate 401 classes: both `NetworkAuthenticationException` and
`UnauthorizedException` exist — both are valid.

```dart
// Convert to Dio exception for re-throwing in interceptors
networkException.toDioException(requestOptions: opts)
```

**Interceptor error routing** — `NetworkExceptionHandlerInterceptor` (abstract):
- 4xx → `onClientError(NetworkException, handler)`
- 5xx → `onServerError(NetworkException, handler)`
- other → `onNonStandardError(NetworkException, handler)`

---

## Exception system 3 — JSON-RPC exceptions

Use these on the server side (or when your app acts as a JSON-RPC server).

```dart
JsonRpcCommonException(type: JsonRpcApiErrorTypeEnum.UNAUTHORIZED, ...)
JsonRpcDataLayerException(type: JsonRpcApiErrorTypeEnum.INTERNAL_SERVER_ERROR, ...)
JsonRpcDomainLayerException(type: JsonRpcRequestErrorTypeEnum.BAD_REQUEST, ...)
```

**`JsonRpcErrorCategory` enum:**

```dart
JsonRpcErrorCategory.API_ERROR             // server-side error
JsonRpcErrorCategory.EXTERNAL_API_ERROR    // upstream/third-party error
JsonRpcErrorCategory.INVALID_REQUEST_ERROR // bad client request
JsonRpcErrorCategory.UNKNOWN
```

**Error type enums:**

| Enum                              | Values (examples)                                                                                                                                                                     |
|-----------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `JsonRpcApiErrorTypeEnum`         | `INTERNAL_SERVER_ERROR`, `UNAUTHORIZED`, `TOKEN_INVALID`, `TOKEN_EXPIRED`, `TOKEN_REVOKED`, `FORBIDDEN`, `RATE_LIMITED`, `METHOD_NOT_IMPLEMENTED`, `NOT_FOUND`, `FEATURE_DISABLED`, … |
| `JsonRpcRequestErrorTypeEnum`     | `INVALID_JSON_RPC`, `BAD_REQUEST`, `INCORRECT_TYPE`, `INVALID_VALUE`, `CONFLICTING_PARAMETERS`                                                                                        |
| `JsonRpcExternalApiErrorTypeEnum` | `INVALID_JSON_RPC`, `BAD_REQUEST`, `INCORRECT_TYPE`, `INVALID_VALUE`, `CONFLICTING_PARAMETERS`                                                                                        |

**`JsonRpcError` (Freezed sealed class)** — the wire-format error object:

```dart
// Canonical constructor
JsonRpcError(
  category: JsonRpcErrorCategory.API_ERROR,
  code: 'UNAUTHORIZED',
  userMessage: 'Please log in.',
  developerMessage: 'Token expired.',
  data: {'providers': ['GOOGLE']},
)

// Convenience factories
JsonRpcError.internal(code: 'INTERNAL_SERVER_ERROR', userMessage: '...')
JsonRpcError.invalidRequest(code: 'BAD_REQUEST', userMessage: '...')
JsonRpcError.invalidParams(code: 'INVALID_VALUE', userMessage: '...')
JsonRpcError.external(code: 'BAD_REQUEST')
JsonRpcError.methodNotImplement(userMessage: '...')

JsonRpcError.fromJson(map)
```

**Response envelopes:**

```dart
JsonRpcResponse<RESULT>(jsonrpc: '2.0', id: 1, result: myResult)
JsonRpcErrorResponse(jsonrpc: '2.0', id: 1, errors: [error])
JsonRpcErrorResponse.single(jsonrpc: '2.0', id: 1, error: error)
```

---

## Models

### BaseModel

```dart
abstract class BaseModel<T> with EquatableMixin {
  T copyWith();          // must implement
  bool? get stringify => true;
}
```

### Request bodies

```dart
// BaseRequestBody — extend for POST/PUT/PATCH/DELETE body
abstract class BaseRequestBody extends BaseRequest {
  Map<String, Object?> toJson();    // required
  String toJsonStr();               // jsonEncode(toJson())
}

// BaseRequest — extend for query-parameter requests
abstract class BaseRequest with EquatableMixin {}

// PaginatedRequest — adds page + pageSize
abstract class PaginatedRequest extends BaseRequest {
  final int page;      // default 1
  final int pageSize;  // default 20
  Map<String, dynamic> toQueryParameters(); // {'page': ..., 'page_size': ...}
}
```

### UserFeedback (Freezed sealed)

```dart
// Variants
UserFeedback.success(message: '...', level: FeedbackLevel.medium)
UserFeedback.warning(message: '...')
UserFeedback.failure(message: '...')
UserFeedback.information(message: '...')

// Pattern-match
feedback.when(
  success: (msg, level) => ...,
  warning: (msg, level) => ...,
  failure: (msg, level) => ...,
  information: (msg, level) => ...,
)

feedback.match(
  onSuccess: (s) => ...,
  onWarning: (w) => ...,
  onFailure: (f) => ...,
  onInformation: (i) => ...,
)

// Convenience
feedback.successMessage      // String? — non-null only for Success
feedback.errorMessage        // String? — non-null only for Failure
feedback.warningMessage
feedback.informationMessage

// From exception
UserFeedback.failureFromException(exception, level: FeedbackLevel.high)
UserFeedback.warningFromException(exception)

// Serialisation
UserFeedback.fromJson(map)
```

**`FeedbackLevel`:** `low`, `medium` (default), `high`, `critical`.
`level.isProminent` → true for `high` / `critical`.
