# dart_faltool

## Entry points

- `lib/src/src.dart`: internal entry point; re-exports `dart:async`, `dart:convert`, `ansicolor`, `dart_falmodel`, `yaml`, and `dart_faltool.dart`.
- `lib/dart_faltool.dart`: public entry point; re-exports the third-party packages plus `extensions/extensions.dart`, `type_def.dart`, and `utils/utils.dart`.
- Import `package:dart_faltool/src/src.dart` from source files inside this package; consumers import `dart_faltool.dart`.

## Extensions (`lib/extensions/`)

- Give a type that needs null-safe helpers a nullable-receiver extension beside the non-null one, as `FalconToolStringExtension on String` and `FalconStringNullExtension on String?` do.
- Export each new extension file from the barrel `lib/extensions/extensions.dart` and add a matching test file in `test/extensions/`.

## Utils and typedefs

- `lib/utils/app_info.dart`: `AppInfo` reads `version` from `pubspec.yaml`; call `AppInfo.init()` at startup, then read `AppInfo.version`. A conditional import picks `lib/src/utils/app_info_io.dart` or `app_info_web.dart`; on web, `init()` does nothing and `version` stays `'1.0.0'`.
- `lib/utils/functions.dart`: top-level helpers.
  - `runCatching`: runs an async `Result<T>` operation and turns a throw into `Result.failure`, wrapping a `CommonException` as is and anything else through `toException()`.
  - `nowUtc`: current time as a UTC `DateTime`.
  - `constantTimeEquals`: compares two equal-length strings in constant time.
  - `randomDelay`: awaits a secure-random delay in `[minMs, maxMs)` milliseconds; asserts `maxMs > minMs >= 0`.
- `lib/utils/json_serialize.dart`: `JsonSerializeUtil`, static converters for Unix seconds, ISO 8601 UTC strings, and `BigInt` strings.
- `lib/utils/token_bucket_policy.dart`: `TokenBucketPolicy`, a `@freezed` rate-limit policy (`permits` per `per`, optional `burst`) that `dart_falconnect`'s `RateLimitConfig` and `TokenBucketRateLimitInterceptor` consume.
- `lib/utils/uuid_generator.dart`: `UuidGenerator.getV4()` returns a UUID v4.
- `lib/utils/typeid/`: [TypeID](https://github.com/jetify-com/typeid) implementation.
  - `TypeId`: static `generate`, `decode`, `decodeOrNull`, and `isValid` (a UUIDv7 plus a type prefix, base32-encoded).
  - `DecodedTypeId`: `@freezed` model holding `prefix`, `suffix`, and `uuid`; `toString()` rebuilds the TypeID string.
  - `Base32`: the TypeID base32 alphabet only, not a generic base32 codec.
  - Prefixes follow the spec strictly: `[a-z]` only, at most 63 characters, no underscores.
- `lib/type_def.dart`: shared typedefs such as `VoidErrorCallback`.

## Gotchas

- `lib/dart_faltool.dart` re-exports `dartx` with a `hide` clause (`IterableAll`, `IterableAppend`, `MapOrEmpty`, and others); when a new extension clashes with a `dartx` member, add that member to the clause.
