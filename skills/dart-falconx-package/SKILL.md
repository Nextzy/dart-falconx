---
name: dart-falconx-package
description: Use when writing Dart/Flutter code in a project that imports dart_falconx, dart_falconnect, dart_falmodel, or dart_faltool — covers the umbrella import, HTTP/WebSocket/JSON-RPC clients, the Result error-handling pattern, three exception systems, data models, and utility extensions. Helps an agent call the public API correctly while reading few tokens.
---

# dart-falconx package reference

## Single import

```dart
import 'package:dart_falconx/dart_falconx.dart';
```

This one line re-exports everything from all three packages plus their transitive
third-party libraries. Individual package imports (`package:dart_falconnect/...`,
`package:dart_falmodel/...`, `package:dart_faltool/...`) also work for consumers
who depend on only one package.

## Package map

| Package           | Purpose                                                                             | Detail file                   |
|-------------------|-------------------------------------------------------------------------------------|-------------------------------|
| `dart_falconnect` | HTTP client, WebSocket, JSON-RPC, interceptors, datasource binding                  | `packages/dart_falconnect.md` |
| `dart_falmodel`   | `Result<T>`, exception hierarchy, request/response models, `UserFeedback`           | `packages/dart_falmodel.md`   |
| `dart_faltool`    | Extension methods, `TypeId`, `AppInfo`, `runCatching`, `nowUtc`, `constantTimeEquals`, `randomDelay`, re-exported third-party libs | `packages/dart_faltool.md`    |

## Routing guide — which file to open

| Task                                           | Read                                        |
|------------------------------------------------|---------------------------------------------|
| Making HTTP REST calls (typed)                 | `dart_falconnect.md` → Retrofit + Dio       |
| Low-level / converter-based HTTP calls         | `dart_falconnect.md` → BaseHttpClient       |
| Setting up or customising interceptors         | `dart_falconnect.md` → Interceptors         |
| WebSocket / real-time streams                  | `dart_falconnect.md` → SocketClient         |
| JSON-RPC 2.0 over HTTP                         | `dart_falconnect.md` → JSON-RPC             |
| Local-first repository pattern                 | `dart_falconnect.md` → DatasourceBoundState |
| Handling success/failure without throwing      | `dart_falmodel.md` → Result                 |
| Mapping or catching HTTP status-code errors    | `dart_falmodel.md` → NetworkException       |
| JSON-RPC server-side error types               | `dart_falmodel.md` → JSON-RPC exceptions    |
| General domain / data-layer exceptions         | `dart_falmodel.md` → CommonException        |
| Defining request or response body classes      | `dart_falmodel.md` → Models                 |
| String, DateTime, num, collection utilities    | `dart_faltool.md` → Extensions              |
| TypeID generation / decoding                   | `dart_faltool.md` → TypeId                  |
| Available third-party libs via umbrella import | `dart_faltool.md` → Re-exports              |

## Cross-cutting gotchas

**Prefer Retrofit + Dio for HTTP.**
Define typed clients with Retrofit `@RestApi` (annotations come via the umbrella
import) backed by a configured Dio from `DefaultHttpClient.instance.dio` or a
`BaseHttpClient` subclass. Use `BaseHttpClient`'s own methods only for low-level /
converter-based calls — each (`get`, `post`, `patch`, `put`, `delete`) then requires
`converter: (Map<String, dynamic>) → T`; there is no raw JSON response API.

**Do not mix `NetworkException` with `DefaultErrorType`.**
`NetworkException` extends `CommonException` and uses `NetworkErrorType` (an enum
mapping to HTTP status codes). `DefaultErrorType` is the sealed-class hierarchy for
general domain errors (`SystemErrorType`, `InputErrorType`, etc.). They are separate
systems. Use `NetworkErrorType` only when handling HTTP failures.

**`dartx` and `fpdart` hide some members.**
`dart_faltool` re-exports `dartx` but hides:
`IterableAll`, `IterableAppend`, `IterableNumAverageExtension`,
`IterableNumSumExtension`, `IterablePartition`, `IterableZip`,
`MapOrEmpty`, `NumCoerceInRangeExtension`, `StringCapitalizeExtension`.
`fpdart` is re-exported hiding `State` and `Task`.
Use the local extension equivalents where those symbols collide.

**`BaseRequestBody` requires `toJson()`.**
POST/PUT/PATCH/DELETE body classes must extend `BaseRequestBody` and implement
`Map<String, Object?> toJson()`. This is what the HTTP methods call internally.

**Web-safe package — no `dart:io` imports.**
The package compiles to web. For platform file/IO access use
`package:universal_io/io.dart` (re-exported through `dart_faltool`).

**Interceptor order matters.**
Recommended insertion order: auth → `RetryInterceptor` → `CacheInterceptor` →
`LogInterceptor`. Add interceptors in `setupInterceptors()` in that order.

**JSON-RPC batch responses include only items with an `id`.**
Items without an `id` field are silently dropped from the returned
`List<BatchJsonRpcItem<dynamic>>`.
