# Third-party re-exports

The umbrella import `package:dart_falconx/dart_falconx.dart` brings every row below into scope. Do not import them separately while the umbrella import is present.

## Via `dart_falconnect`

| Package | Purpose | Hidden |
|---|---|---|
| `dio` | `Dio`, `Response`, `Options`, `Interceptor`, `FormData`, `DioException` | none |
| `dio_cache_interceptor` | HTTP cache store and policy for Dio | `BaseRequest`, `BaseResponse`, `HttpDate` |
| `retrofit` | `@RestApi`, `@GET`, `@Body`, `HttpResponse`, `ParseErrorLogger` | `CacheControl`, `Headers`, `Parser` (import `package:retrofit/retrofit.dart` for `@Headers`) |
| `web_socket_channel` | `WebSocketChannel` | none |

## Via `dart_faltool`

| Package | Purpose | Hidden |
|---|---|---|
| `big_decimal` | arbitrary-precision `BigDecimal` | none |
| `dartx` | Kotlin-style extensions (`firstOrNullWhere`, `sortedBy`, `Pair`) | `IterableAll`, `IterableAppend`, `IterableNumAverageExtension`, `IterableNumSumExtension`, `IterablePartition`, `IterableZip`, `MapOrEmpty`, `NumCoerceInRangeExtension`, `StringCapitalizeExtension` (falcon equivalents exist) |
| `data` | data-structure helpers | `Field` |
| `enum_to_string` | `EnumToString.convertToString` / `fromString` | none |
| `equatable` | `Equatable`, `EquatableMixin` | none |
| `fpdart` | `Either`, `Option`, `TaskEither` | `State`, `Task` |
| `freezed_annotation` | `@freezed`, `@Default` | none |
| `hashlib`, `hashlib/random` | hash digests, `uuid` generator | none |
| `intl` | `DateFormat`, `NumberFormat` | none |
| `json_annotation` | `@JsonSerializable`, `@JsonKey` | none |
| `logger` | `Logger` (`logger/web.dart` on web, `logger/logger.dart` on IO) | none |
| `meta` | `@immutable`, `@protected` | none |
| `numeral`, `numeral/extension` | compact numbers such as `1.2k` | none |
| `retry` | `retry()`, `RetryOptions` | none |
| `rrule` | recurrence rules | `DateTimeRrule` |
| `rxdart` | `PublishSubject`, `BehaviorSubject`, stream operators | none |
| `stack_trace` | `Trace`, `Chain` | none |
| `time` | `5.seconds`, `2.days` on `int` | none |
| `timeago` | relative time strings | none |
| `version` | SemVer `Version` | none |

`dart:` libraries re-exported by `dart_faltool`: `dart:async`, `dart:convert`, `dart:math`, `dart:typed_data`.

## Not re-exported

Add these to your own pubspec when needed: `universal_io` (use instead of `dart:io`), `web`, `yaml`, `ansicolor`, and the dev tools `build_runner`, `freezed`, `json_serializable`, `retrofit_generator`. `dart_falmodel` alone does not re-export `dio` or `dart_faltool`; depend on those directly when you skip the umbrella package.
