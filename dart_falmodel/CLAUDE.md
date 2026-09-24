# dart_falmodel

## Entry points

- `lib/lib.dart` is the internal prelude: it re-exports `dart:async`, `dart:convert`, `dart_faltool`, `dio`, `freezed_annotation`, `json_annotation`, and `dart_falmodel.dart`. Import it from files inside this package.
- `lib/dart_falmodel.dart` is the public barrel: it exports `exceptions/`, `extensions/`, `feedbacks/`, `models/`, and `networks/`.
- Point consumers at `dart_falmodel.dart`, never at `lib.dart`.

## Exceptions

### General (`lib/exceptions/`)

- `CommonException` has three subclasses: `DataLayerException`, `DomainLayerException`, and `TodoException`.
- `toJsonRpcError()` resolves the `JsonRpcErrorCategory` from the concrete JSON-RPC subclass first, then from `type`, and falls back to `API_ERROR`.

### HTTP (`lib/networks/exceptions/`)

- `NetworkException` adds `statusCode`, `response`, `requestOptions`, and `errors`; `NetworkErrorType` also holds general values such as `network`, `timeout`, and `noInternet`.
- `BaseHttpException`, abstract, adds `isRetryable`, `recommendedRetryDelay`, `extractErrorDetails`, and `toLogString`. Concrete classes sit one per status code in `code4XX/` and `code5XX/`.

To add a network exception:

1. Create the class under `code4XX/` or `code5XX/`, extending `BaseHttpException`.
2. Set its default `NetworkErrorType` through `super.type`.
3. Export it from `lib/networks/exceptions/exceptions.dart`.
4. For a new status code, extend the `statusCode` and `defaultMessage` getters and the static `fromStatusCode` on `NetworkErrorType`.

### JSON-RPC (`lib/networks/rpc/exceptions/`)

- `JsonRpcCommonException` extends `CommonException`; `JsonRpcDataLayerException` and `JsonRpcDomainLayerException` extend `JsonRpcCommonException` and have concrete subclasses such as `JsonRpcDatabaseException`.
- `JsonRpcErrorCategory` values: `API_ERROR`, `EXTERNAL_API_ERROR`, `INVALID_REQUEST_ERROR`, `UNKNOWN`.
- `JsonRpcApiErrorType` and `JsonRpcRequestErrorType` are marker interfaces. Server codes live in `JsonRpcApiErrorTypeEnum` (`UNAUTHORIZED`, `RATE_LIMITED`); client codes live in `JsonRpcRequestErrorTypeEnum` (`BAD_REQUEST`, `INCORRECT_TYPE`).
- Export every new RPC exception file from `lib/networks/rpc/exceptions/exceptions.dart`.

## Result

- A failed `Result<T>` carries a `CommonException`. Transform with `map`, `mapException`, `flatMap`, `recover`, or `recoverWith`; consume with `resolve` or `when`.

## JSON-RPC models (`lib/networks/rpc/`)

- `JsonRpcResponse<RESULT>` (success) and `JsonRpcErrorResponse` (error) are Freezed types in `json_rpc_response.dart`.
- `JsonRpcResult` is the empty base of every result type. `JsonRpcModelResult` requires `toJson()`; `JsonRpcListResult`, `JsonRpcIntResult`, `JsonRpcStringResult`, `JsonRpcBoolResult`, and `JsonRpcRawResult` (a raw `Map`) cover the rest.
- `JsonRpcError` is a Freezed sealed class implementing `Exception`, with `category`, `code`, `userMessage`, `developerMessage`, and `data`. Its factories are `invalidRequest`, `external`, `internal`, `methodNotImplement`, and `invalidParams`.
- `BatchJsonRpcItem` is hand-written, without Freezed, and exposes `resolve`, `map`, `responseOrNull`, and `errorOrNull`.

## User feedback (`lib/feedbacks/feedback.dart`)

- `UserFeedback` is a Freezed sealed class with factories `success`, `warning`, `failure`, and `information`; each takes a `FeedbackLevel` that defaults to `medium`.
- Match a feedback with Freezed `when` / `maybeWhen` or the custom `match`.

## Code generation

- Five sources produce `.freezed.dart` and `.g.dart` output: `feedbacks/feedback.dart`, `networks/https/responses/remote_error.dart`, `networks/rpc/json_rpc_error.dart`, `networks/rpc/json_rpc_request.dart`, and `networks/rpc/json_rpc_response.dart`.
