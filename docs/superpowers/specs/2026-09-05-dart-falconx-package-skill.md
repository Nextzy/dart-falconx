# Spec: dart-falconx-package skill (full rewrite)

- **name:** `dart-falconx-package`
- **mode:** edit (full rewrite of existing skill; do not preserve old structure)
- **target:** `skills/dart-falconx-package/` (repo-tracked; consumers copy the folder into their own `.claude/skills/`)
- **scope:** project
- **budget:** 800 words for `SKILL.md` (`wc -w`); `references/*.md` do not count, but each reference file should stay at or under ~600 words
- **language:** English throughout (the reader is a coding agent)

## Purpose

A consumer project that depends on `dart_falconx` (or one of `dart_falconnect`, `dart_falmodel`, `dart_faltool`) must be able to answer two questions with few tokens:

1. **Discovery** — "I am about to write an HTTP client / utility / error class / add a dependency. Does falconx already provide this?" (prevent reinventing)
2. **Reference** — "I decided to use falconx feature X. How do I call it correctly?"

`SKILL.md` answers (1) directly and routes (2) to one reference file.

## Trigger description (frontmatter `description`)

Must fire in both moments:

- (a) the project lists `dart_falconx`, `dart_falconnect`, `dart_falmodel`, or `dart_faltool` in `pubspec.yaml` AND the agent is about to write HTTP / WebSocket / JSON-RPC / error-handling / model / utility / extension code, or about to add a new pub dependency
- (b) the agent is calling any public API of those packages

Name the packages explicitly so the skill does not fire in unrelated Dart projects.

## `SKILL.md` structure (in this order)

1. **Frontmatter** — `name`, `description` as above.
2. **Setup** (~60 words) — `pubspec.yaml` dependency line, the single umbrella import `package:dart_falconx/dart_falconx.dart`, per-package imports for consumers that depend on only one package, Dart SDK constraint (verify the current value in `dart_falconx/pubspec.yaml`), and that Retrofit/Freezed/JsonSerializable codegen runs in the **consumer** project with `dart run build_runner build --delete-conflicting-outputs`.
3. **Capability map** (~300 words) — a table `Need | Use | package | Ref`. This is the "do-not-reinvent" layer. Rows must cover at least:
   - typed REST client (Retrofit `@RestApi` + Dio from `DefaultHttpClient.instance.dio` or a `BaseHttpClient` subclass)
   - low-level converter-based HTTP (`BaseHttpClient` methods)
   - interceptors (cache, retry, rate limit, log, error handling, and recommended order)
   - WebSocket streams (`SocketClient`, `SocketBoundResource`)
   - JSON-RPC 2.0 (`JsonRpcService` / `DefaultJsonRpcService`, batch, `BatchJsonRpcItem`)
   - local-first repository (`DatasourceBoundState`)
   - success/failure without throwing (`Result<T>`)
   - three exception systems (`CommonException` + `DefaultErrorType`, `NetworkException` + `NetworkErrorType`, JSON-RPC exceptions)
   - request/response models (`BaseModel`, `BaseRequestBody`, `UserFeedback`)
   - String / nullable String / DateTime / num / Object / collection extensions
   - utilities: `TypeId`, `UuidGenerator`, `AppInfo`, `runCatching`, `nowUtc`, `constantTimeEquals`, `randomDelay`
   - third-party libraries available for free through the umbrella import (`rxdart`, `fpdart`, `equatable`, `dartx`, `intl`, `timeago`, `numeral`, `big_decimal`, `hashlib`, `retry`, `logger`, `stack_trace`, `version`, `time`, `rrule`, `data`, `enum_to_string`, `meta`, `freezed_annotation`, `json_annotation`) — verify the exact list against `dart_faltool/lib/dart_faltool.dart`. Note: `universal_io`, `web`, and `yaml` are **not** re-exported; the skill must tell consumers to add `universal_io` to their own pubspec when they need it
4. **Do-not-reinvent rules** (~100 words) — before adding a pub dependency or writing a helper, check the capability map; do not `import 'package:rxdart/...'` (or any other re-exported lib) directly when the umbrella import is already present; never `import 'dart:io'`, use `universal_io`; prefer Retrofit + Dio over hand-rolled `BaseHttpClient` calls.
5. **Cross-cutting gotchas** (~150 words) — keep only rules that are still true in the current source:
   - `NetworkException` uses `NetworkErrorType`; do not mix with `DefaultErrorType`
   - hide lists: `dartx` and `fpdart` members hidden by `dart_faltool`; Retrofit `Headers`, `Parser`, `CacheControl` hidden by the umbrella export (import `package:retrofit/retrofit.dart` directly for `@Headers`)
   - `BaseRequestBody` subclasses must implement `toJson()`
   - interceptor order: auth → `RetryInterceptor` → `CacheInterceptor` → `HttpLogInterceptor` (the falconnect class; Dio's own `LogInterceptor` is a different class)
   - JSON-RPC batch responses drop items without an `id`
   - known naming quirks preserved for compatibility (`NetworkNotImplementException`, duplicate 401 classes)
6. **Out of scope** (one line) — does not teach general Dio / Retrofit / Freezed usage; does not cover package internals.

## `references/` files

Organised by capability, not by package. Every section carries a `package:` tag so a consumer that depends on only one package knows whether the symbol is available. Every code snippet must be short and must compile against the current source (correct class names, parameter names, return types).

| File | Content |
|---|---|
| `references/http.md` | Retrofit + Dio (recommended), `DefaultHttpClient`, `BaseHttpClient` subclass + typed methods + converters, interceptor catalog and order, runtime-adding interceptors, accessing Dio |
| `references/websocket.md` | `SocketClient` lifecycle, filtered streams, reconnection, socket exceptions, `SocketBoundResource` |
| `references/json-rpc.md` | `JsonRpcService` / `DefaultJsonRpcService`, single call, batch call, `BatchJsonRpcItem` (`resolve`, `map`, `responseOrNull`, `errorOrNull`), request id semantics (`int?`), error handling |
| `references/errors.md` | `Result<T>` construction/accessors/transforms; `CommonException` + `DefaultErrorType`; `NetworkException` + `NetworkErrorType` status-code map; JSON-RPC exceptions + `JsonRpcErrorCategory`, `JsonRpcApiErrorType`, `JsonRpcRequestErrorType`; `toJsonRpcError()` |
| `references/models.md` | `BaseModel`, `BaseRequestBody`, `UserFeedback`, `DatasourceBoundState` |
| `references/extensions.md` | extension catalog grouped by receiver type: String, String?, DateTime, num/int/double, Object, Iterable/List/Map, Enum, Future, Stream |
| `references/utils.md` | `TypeId`, `UuidGenerator`, `AppInfo`, `runCatching`, `nowUtc`, `constantTimeEquals`, `randomDelay` |
| `references/third-party.md` | full re-export list with one-line purpose each, hide lists, and which `dart:` libraries are re-exported |

## Hard requirements for the author

- **Verify every symbol against source** before writing it: `grep -rn` in `dart_falconnect/lib`, `dart_falmodel/lib`, `dart_faltool/lib`. The old skill was written at 1.0.6; the packages are now at 1.0.10. Do not carry over any class, method, or parameter that no longer exists or whose signature changed.
- Source of truth for re-exports and hide lists: `dart_faltool/lib/dart_faltool.dart`, `dart_falconnect/lib/dart_falconnect.dart`, `dart_falmodel/lib/dart_falmodel.dart`, `dart_falconx/lib/dart_falconx.dart`.
- Delete the old `packages/` directory and `.DS_Store` after all content has been migrated into `references/`.
- Do not modify any package source, `CLAUDE.md`, or `pubspec.yaml`. Do not commit.

## Out of scope

- Changes to package code or public API
- Any file outside `skills/dart-falconx-package/`
- Git commits
