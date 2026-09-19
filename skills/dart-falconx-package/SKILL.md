---
name: dart-falconx-package
description: Use when a Dart or Flutter project lists dart_falconx, dart_falconnect, dart_falmodel, or dart_faltool in pubspec.yaml and you are about to write HTTP, WebSocket, JSON-RPC, error-handling, model, utility, or extension code, add a pub dependency, or call any public API of those packages.
---

# dart-falconx package

Answers "does falconx already provide this?" here and routes "how do I call it?" to one file under `references/`.

## Setup

```yaml
dependencies:
  dart_falconx:                      # or only dart_falconnect / dart_falmodel / dart_faltool
    git:
      url: https://github.com/Nextzy/dart-falconx
      ref: <latest_tag>              # e.g. 1.0.11 — see `git ls-remote --tags`
      path: dart_falconx             # dart_falconnect / dart_falmodel / dart_faltool
environment:
  sdk: ">=3.13.0 <4.0.0"
```

```dart
import 'package:dart_falconx/dart_falconx.dart';        // umbrella: all three packages
import 'package:dart_falconnect/dart_falconnect.dart';  // single-package consumers
import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:dart_faltool/dart_faltool.dart';
```

Retrofit, Freezed, and JsonSerializable codegen runs in the consumer project: `dart run build_runner build --delete-conflicting-outputs`.

## Capability map

| Need                                            | Use                                                                                                                                                                                                                                                                                                                                               | Package                     | Ref                         |
|-------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|-----------------------------|
| Typed REST client                               | Retrofit `@RestApi` on `DefaultHttpClient.instance.dio` or a `BaseHttpClient` subclass                                                                                                                                                                                                                                                            | dart_falconnect             | `references/http.md`        |
| Converter-based HTTP                            | `BaseHttpClient.get/post/postFormData/patch/put/putFormData/delete` with `converter:`                                                                                                                                                                                                                                                             | dart_falconnect             | `references/http.md`        |
| Interceptors                                    | `RetryInterceptor`, `CacheInterceptor`, `RateLimitInterceptor`, `PerformanceInterceptor`, `HttpLogInterceptor`, `NetworkExceptionHandlerInterceptor`, `HttpClientConfig`                                                                                                                                                                          | dart_falconnect             | `references/http.md`        |
| WebSocket streams                               | `SocketClient`, `SocketBoundResource.asStream`, `SocketLogInterceptor`                                                                                                                                                                                                                                                                            | dart_falconnect             | `references/websocket.md`   |
| JSON-RPC 2.0                                    | `JsonRpcService` / `DefaultJsonRpcService`: `request`, `notify`, `batch` returning `BatchJsonRpcItem`                                                                                                                                                                                                                                             | dart_falconnect             | `references/json-rpc.md`    |
| Local-first repository                          | `DatasourceBoundState.asResultStream` and siblings                                                                                                                                                                                                                                                                                                | dart_falconnect             | `references/models.md`      |
| Success/failure without throwing                | `Result<T>`, `runCatching`, `Future.toResult()`                                                                                                                                                                                                                                                                                                   | dart_falmodel, dart_faltool | `references/errors.md`      |
| General exceptions                              | `CommonException` with `DefaultErrorType` enums (`SystemErrorType`, `InputErrorType`, ...)                                                                                                                                                                                                                                                        | dart_falmodel               | `references/errors.md`      |
| HTTP status exceptions                          | `NetworkException` with `NetworkErrorType`; `dioException.toException()`                                                                                                                                                                                                                                                                          | dart_falmodel               | `references/errors.md`      |
| JSON-RPC exceptions                             | `JsonRpcCommonException` family, `JsonRpcError`, `toJsonRpcError()`                                                                                                                                                                                                                                                                               | dart_falmodel               | `references/errors.md`      |
| Request/response models                         | `BaseModel`, `BaseRequestBody`, `BaseFormDataBody`, `PaginatedRequest/Response`, `BaseResponse`, `UserFeedback`                                                                                                                                                                                                                                   | dart_falmodel               | `references/models.md`      |
| String / String?                                | `toIntOrZero`, `isEmail`, `toCamelCase`, `maskEmail`, `toEnum<T>()`, `toBase64`                                                                                                                                                                                                                                                                   | dart_faltool                | `references/extensions.md`  |
| DateTime / Duration                             | `isSameDay`, `addMonth`, `toRelative`, `weekOfYear`, `toHumanReadable`                                                                                                                                                                                                                                                                            | dart_faltool                | `references/extensions.md`  |
| num / int / double                              | `clampValue`, `inRange`, `roundToPlace`, `toPercentage`, `orZero`                                                                                                                                                                                                                                                                                 | dart_faltool                | `references/extensions.md`  |
| Object / dynamic                                | `let`, `also`, `takeIf`, `asIntOrNull`, `asMapOr`                                                                                                                                                                                                                                                                                                 | dart_faltool                | `references/extensions.md`  |
| Iterable / List / Map / Enum / Future / Stream  | `removeDuplicatesBy`, `deepMerge`, `getPath`, `byValue`, `retryWithBackoff`, `combineLatest`                                                                                                                                                                                                                                                      | dart_faltool                | `references/extensions.md`  |
| IDs, app version, security helpers              | `TypeId`, `UuidGenerator`, `AppInfo`, `nowUtc`, `constantTimeEquals`, `randomDelay`, `JsonSerializeUtil`                                                                                                                                                                                                                                          | dart_faltool                | `references/utils.md`       |
| Third-party libs, free with the umbrella import | `dio`, `retrofit`, `dio_cache_interceptor`, `web_socket_channel`, `rxdart`, `fpdart`, `equatable`, `dartx`, `intl`, `timeago`, `numeral`, `big_decimal`, `hashlib`, `retry`, `logger`, `stack_trace`, `version`, `time`, `rrule`, `data`, `enum_to_string`, `meta`, `freezed_annotation`, `json_annotation`, `dart:async/convert/math/typed_data` | see ref                     | `references/third-party.md` |

## Do not reinvent

- Before adding a pub dependency or writing a helper, scan the map above and `references/third-party.md`.
- When the umbrella import is present, do not also `import 'package:rxdart/...'` or any other re-exported library; the symbols are already in scope.
- Never `import 'dart:io'`; the packages compile to web. Use `package:universal_io/io.dart`, added to your own pubspec (it is not re-exported).
- Prefer Retrofit + Dio for REST. Use `BaseHttpClient` methods only for one-off converter-based calls.

## Gotchas

- `NetworkException` carries a `NetworkErrorType`; the general hierarchy uses `DefaultErrorType` enums. Do not mix them.
- Hidden symbols: `dart_faltool` hides `dartx` `IterableAll`, `IterableAppend`, `IterableNumAverageExtension`, `IterableNumSumExtension`, `IterablePartition`, `IterableZip`, `MapOrEmpty`, `NumCoerceInRangeExtension`, `StringCapitalizeExtension` and `fpdart` `State`, `Task`. `dart_falconnect` hides Retrofit `Headers`, `Parser`, `CacheControl`; `import 'package:retrofit/retrofit.dart'` directly for `@Headers`.
- `BaseRequestBody` subclasses must implement `Map<String, Object?> toJson()`; the HTTP methods call it.
- Interceptor order: auth, then `RetryInterceptor`, `CacheInterceptor`, `HttpLogInterceptor` last so it sees every change. Dio's own `LogInterceptor` is a different class.
- JSON-RPC batch responses silently drop items without an `id`.
- Kept for compatibility: `NetworkNotImplementException` (501, missing "ed") and both `NetworkAuthenticationException` and `UnauthorizedException` for 401.
- `dart_falmodel` alone does not re-export `dio`; import it yourself for `Response` / `RequestOptions`.

## Out of scope

General Dio, Retrofit, or Freezed usage, and package internals.
