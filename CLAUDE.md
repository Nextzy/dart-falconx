# dart-falconx

## Project overview

Dart monorepo managed with Melos, holding four packages:

- **dart_falconx**: umbrella package; re-exports the three packages below so consumers need one import.
- **dart_falconnect**: network clients (HTTP, WebSocket, JSON-RPC).
- **dart_falmodel**: data models, exceptions, and network abstractions.
- **dart_faltool**: extensions, helpers, and re-exported third-party packages.

```
dart_falconx (umbrella: re-exports all packages)
    ↑
dart_faltool ←→ dart_falmodel (circular dependency via workspace resolution)
    ↑
dart_falconnect (top layer: network implementations)
```

- Leave the `dart_faltool` ↔ `dart_falmodel` cycle in place: Dart workspace resolution resolves it, and it breaks no layering rule.

## Platform support

- Every package serves any Dart project: Flutter apps (Android, iOS, macOS, Windows, Linux, web) and pure-Dart servers and CLIs.
- Keep every package pure Dart: never depend on the Flutter SDK or import `package:flutter`.
- Reach `dart:io` only from the `if (dart.library.io)` branch of a conditional import, as `dart_falmodel/lib/extensions/exception_extensions.dart` does; never import `dart:html`, `dart:ffi`, or `dart:isolate` under `lib/`.
- Run the platform gates from `dart_falconnect/`: `dart compile js test/web/compile_smoke.dart -o /tmp/smoke.js` (repeat with `wasm` and `exe`), then `dart test -p chrome test/web/engine_web_test.dart`.

## Commands

Scripts live under the `melos:` key of the root `pubspec.yaml` (there is no `melos.yaml`); run each one as `melos run <name>`.

| Script                                   | Runs                                                                |
|------------------------------------------|---------------------------------------------------------------------|
| `melos run get` / `upgrade` / `outdated` | `dart pub get` / `upgrade` / `outdated` in every package            |
| `melos run analyze`                      | `dart analyze` (concurrency 4)                                      |
| `melos run format`                       | `dart format --set-exit-if-changed .`                               |
| `melos run fix`                          | `dart fix --apply` with a curated `--code=` allowlist               |
| `melos run fix:format`                   | `fix`, then `format`                                                |
| `melos run test`                         | `dart test` in every package with a `test/` dir, fail-fast          |
| `melos run build_runner`                 | `build --delete-conflicting-outputs` (use after merges)             |
| `melos run build_runner:fast`            | `build` only, reuses the incremental cache (use when adding fields) |
| `melos run build_runner:watch`           | Watch mode                                                          |

- Reset corrupted dependencies with `melos clean`, then `melos bootstrap`.
- Run one test file from its package: `cd dart_faltool && dart test test/extensions/string_extensions_test.dart`.
- `dart_falconx` holds only the stub `test/unit_test.dart`; the other three packages hold real tests.

## Architecture

### Network engines (`dart_falconnect/lib/engine/`)

- `https/`: `BaseHttpClient` wraps Dio and applies an `HttpClientConfig` through `configure()`; every request method takes a converter function.
- `sockets/`: `SocketClient`, a WebSocket client with retry and its own interceptors.
- `rpc/`: `JsonRpcService` (JSON-RPC 2.0 over HTTP) and its concrete `DefaultJsonRpcService`; `batch()` returns `List<BatchJsonRpcItem>`, a sealed class from `dart_falmodel`.
- `BaseHttpClient.configure()` assembles the interceptor chain in a fixed order; read `skills/dart-falconx-package/references/http.md` before adding or reordering an interceptor.

### Models and exceptions (`dart_falmodel/lib/`)

| System   | Type discriminant                                                             | Location                                     |
|----------|-------------------------------------------------------------------------------|----------------------------------------------|
| General  | `DefaultErrorType`, a sealed class implemented by nine enums                  | `exceptions/common_exception.dart`           |
| HTTP     | `NetworkErrorType` enum, mapped to status codes                               | `networks/exceptions/network_exception.dart` |
| JSON-RPC | `JsonRpcErrorCategory` plus `JsonRpcApiErrorType` / `JsonRpcRequestErrorType` | `networks/rpc/exceptions/`                   |

- `CommonException` carries `type` (an `Object`, normally a `DefaultErrorType` value), `userMessage`, `developerMessage`, `data`, and `toJsonRpcError()`; it has no `category` field.
- A `NetworkException` carries a `NetworkErrorType`, never a `DefaultErrorType` enum; each HTTP exception class sets its default through `super.type = NetworkErrorType.<value>`.
- Keep the misspelled `NetworkNotImplementException` (501) and both 401 classes, `NetworkAuthenticationException` and `UnauthorizedException`, for backward compatibility.
- `Result<T>` (`models/result.dart`) is one `Equatable` class built through its `success`, `failure`, `dataFailure`, and `domainFailure` factories.

### Code generation

- Generated files land in `lib/{{path}}/generated/{{file}}.g.dart` or `.freezed.dart`, per each package's `build.yaml`.
- Run `melos run build_runner` after editing a `@freezed` or `@JsonSerializable` class.

## Gotchas

- Add every new exception class's export to `dart_falmodel/lib/networks/exceptions/exceptions.dart`; a missing export surfaces as a misleading analyzer error, such as "method can't be unconditionally invoked because receiver can be 'null'".
- After large changes, run `dart pub get` before `dart analyze` to clear stale analyzer state.
- On web, `int` bitwise and shift operators truncate to 32 bits: never shift or mask a value that may exceed 32 bits, and cover such a path with a `dart test -p chrome` test.
- Update the consumer skill with every public API change; see [Skill maintenance](#skill-maintenance).

## Skill maintenance

`skills/dart-falconx-package/` is the consumer-facing skill. Downstream projects copy this folder into their own `.claude/skills/` so their agents know what the package provides and how to call it. It is documentation, and it drifts silently when code changes.

**Rule:** whenever a change touches the public API of `dart_falconnect`, `dart_falmodel`, or `dart_faltool` (a new, renamed, or removed public class, method, or parameter; a changed signature; an edit to an export or `hide` list in `dart_*/lib/dart_*.dart`; a newly re-exported third-party package), update `skills/dart-falconx-package/SKILL.md` and the matching file under `skills/dart-falconx-package/references/` in the same change. Internal refactors that leave the public surface unchanged do not require a skill update.

Before bumping a version, confirm the skill still matches the source.

## Configuration

- One root `analysis_options.yaml`, based on `very_good_analysis`, covers every package.
- `strict-casts` and `strict-inference` are on: declare every type the analyzer cannot infer, including function-typed locals.
- The `build.yaml` in `dart_falconnect`, `dart_falmodel`, and `dart_faltool` runs `json_serializable` in checked mode with `explicit_to_json: true`: generated `fromJson` validates types, and nested models serialize through their own `toJson()`.

## Third-party packages

- `skills/dart-falconx-package/references/third-party.md` — open when choosing or calling a re-exported third-party package.
