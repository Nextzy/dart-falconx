# dart-falconx

## Project overview

Dart monorepo managed with Melos, holding four packages:

- **dart_falconx**: umbrella package; re-exports the three packages below so consumers need one import.
- **dart_falconnect**: network clients (HTTP, WebSocket, JSON-RPC).
- **dart_falmodel**: data models, exceptions, and network abstractions.
- **dart_faltool**: extensions, helpers, and re-exported third-party packages.

```
dart_falconx      (umbrella: re-exports the three packages below)
    ↓
dart_falconnect   (network implementations)
    ↓
dart_falmodel     (models, exceptions, Result)
    ↓
dart_faltool      (extensions and helpers)
```

- Keep every dependency pointing down the diagram: a package depends only on packages below it. Never add `dart_falmodel` or `dart_falconnect` to `dart_faltool`: a cycle makes pub reject `dart_falmodel` or `dart_faltool` when an app lists either one alone as a git dependency.
- Put a helper that needs `Result` or `CommonException` in `dart_falmodel`, never in `dart_faltool`.
- Declare a dependency on another package in this repo as a git dependency on `https://github.com/Nextzy/dart-falconx`, with `ref:` set to the repo version and `path:` set to the package; never use a `path:` dependency. The workspace still resolves it to the local folder. An app receives the tag, which matches the tag it writes for the same package; a path dependency reaches the app as a commit hash and conflicts with that tag.
- Put a file that no app imports under `lib/src/`, in the folder it would have outside `lib/src/`, and export from a barrel only what apps use. Each package's internal prelude is `lib/src/src.dart`; files inside the package import it, and consumers import the barrel.

## Platform support

- Every package serves any Dart project: Flutter apps (Android, iOS, macOS, Windows, Linux, web) and pure-Dart servers and CLIs.
- Keep every package pure Dart: never depend on the Flutter SDK or import `package:flutter`.
- Reach `dart:io` only from the `if (dart.library.io)` branch of a conditional import, as `dart_falmodel/lib/extensions/exception_extensions.dart` does; never import `dart:html`, `dart:ffi`, or `dart:isolate` under `lib/`.
- Run `melos run test:platforms` after touching any `lib/` code that could behave differently on web, wasm, or native; it needs Chrome.
- Mark a test that needs `dart:io` `@TestOn('vm')`; `melos run test:web` runs every other test in Chrome.

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
| `melos run test:platforms`               | `test:compile`, then `test:web`                                     |
| `melos run test:compile`                 | compiles `dart_falconnect/test/web/compile_smoke.dart` to js, wasm, and exe |
| `melos run test:web`                     | every package's tests in Chrome, under dart2js and then dart2wasm   |
| `melos run build_runner`                 | `build`, one package at a time                                      |
| `melos run build_runner:check`           | `build --only-check`: fails on a stale or missing generated file    |
| `melos run build_runner:watch`           | Watch mode                                                          |

- Reset corrupted dependencies with `melos clean`, then `melos bootstrap`.
- Run one test file from its package: `cd dart_faltool && dart test test/extensions/string_extensions_test.dart`.
- `dart_falconx` holds the stub `test/unit_test.dart` and `test/internal_dependencies_test.dart`, which fails when a pubspec breaks the two dependency rules under [Project overview](#project-overview) or a version drifts; the other three packages hold real tests.

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

- Generated files land in `lib/{{path}}/generated/{{file}}.g.dart` or `.freezed.dart`, per each package's `build.yaml`. `dart_falconnect` also generates Retrofit test fixtures into `test/{{path}}/generated/{{file}}.g.dart`.
- Run `melos run build_runner` after editing a `@freezed` or `@JsonSerializable` class, and `melos run build_runner:check` before committing.

## Gotchas

- Add every new exception class's export to `dart_falmodel/lib/networks/exceptions/exceptions.dart`; a missing export surfaces as a misleading analyzer error, such as "method can't be unconditionally invoked because receiver can be 'null'".
- After large changes, run `dart pub get` before `dart analyze` to clear stale analyzer state.
- On web, `int` bitwise and shift operators truncate to 32 bits: never shift or mask a value that may exceed 32 bits, and cover such a path with a `dart test -p chrome` test.
- Update the consumer skill with every public API change; see [Skill maintenance](#skill-maintenance).

## Skill maintenance

`skills/dart-falconx-package/` is the consumer-facing skill. Downstream projects copy this folder into their own `.claude/skills/` so their agents know what the package provides and how to call it. It is documentation, and it drifts silently when code changes.

**Rule:** whenever a change touches the public API of `dart_falconnect`, `dart_falmodel`, or `dart_faltool` (a new, renamed, or removed public class, method, or parameter; a changed signature; an edit to an export or `hide` list in `dart_*/lib/dart_*.dart`; a newly re-exported third-party package), update `skills/dart-falconx-package/SKILL.md` and the matching file under `skills/dart-falconx-package/references/` in the same change. Internal refactors that leave the public surface unchanged do not require a skill update.

Before bumping a version, confirm the skill still matches the source. A bump sets the same version in all five pubspecs and in every sibling `ref:`.

## Configuration

- One root `analysis_options.yaml`, based on `very_good_analysis`, covers every package.
- `strict-casts` and `strict-inference` are on: declare every type the analyzer cannot infer, including function-typed locals.
- The `build.yaml` in `dart_falconnect`, `dart_falmodel`, and `dart_faltool` runs `json_serializable` in checked mode with `explicit_to_json: true`: generated `fromJson` validates types, and nested models serialize through their own `toJson()`.

## Third-party packages

- `skills/dart-falconx-package/references/third-party.md` — open when choosing or calling a re-exported third-party package.
