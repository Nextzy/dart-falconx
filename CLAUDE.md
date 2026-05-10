# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dart/Flutter monorepo managed with Melos, containing packages for network operations and utilities:

- **dart_falconx**: Umbrella package that re-exports all packages below (single import for consumers)
- **dart_falconnect**: Network connectivity (HTTP client, WebSocket, RPC implementations)
- **dart_falmodel**: Data models, exceptions, and network abstractions
- **dart_faltool**: Utility extensions and helper functions

### Package Architecture
```
dart_falconx (umbrella: re-exports all packages)
    ↑
dart_faltool ←→ dart_falmodel (circular dependency via workspace resolution)
    ↑
dart_falconnect (top layer: network implementations)
```
- `dart_faltool`: utilities, extensions — depends on `dart_falmodel`
- `dart_falmodel`: models, exceptions, abstractions — depends on `dart_faltool`
- Both resolve via Dart workspace resolution (not a layering violation)

## Common Development Commands

### Package Management
```bash
# Install dependencies for all packages
melos get

# Upgrade dependencies
melos upgrade

# Check outdated packages
melos outdated

# Clean everything and reinstall (when dependencies are corrupted)
melos clean
flutter clean
melos bootstrap
```

### Code Generation
```bash
# Generate code for all packages (Freezed, JsonSerializable, Retrofit)
melos build_runner

# Generate in specific package with conflict resolution
cd dart_falconnect
dart run build_runner build -d

# Watch mode for continuous generation
dart run build_runner watch --delete-conflicting-outputs
```

### Testing
```bash
# Run all tests in a package (dart_faltool has real tests; other packages have stubs)
cd dart_faltool
dart test

# Run specific test file
dart test test/extensions/string_extensions_test.dart

# Run tests matching pattern
dart test -n "StringExtension"

# Run with coverage
dart test --coverage
```

### Code Quality
```bash
# Analyze code
dart analyze

# Auto-fix issues
dart fix --apply

# Format code
dart format .
```

### Custom Melos Scripts (root `pubspec.yaml`)

| Script                         | Purpose                                                                      |
|--------------------------------|------------------------------------------------------------------------------|
| `melos run analyze`            | `dart analyze` with `analysis_options.ci.yaml --fatal-infos` (concurrency 4) |
| `melos run format`             | `dart format --set-exit-if-changed .`                                        |
| `melos run fix`                | `dart fix --apply` with curated `--code=` allowlist                          |
| `melos run fix:format`         | Run `fix` then `format`                                                      |
| `melos run test`               | `dart test` in packages with a `test/` dir, fail-fast                        |
| `melos run build_runner`       | `build --delete-conflicting-outputs` (use after merges)                      |
| `melos run build_runner:fast`  | `build` only, reuses incremental cache (use when adding fields)              |
| `melos run build_runner:watch` | Watch mode                                                                   |
| `melos run get` / `upgrade`    | `dart pub get` / `pub upgrade` across packages                               |
| `melos run check`              | Run `analyze` then `test`                                                    |

## High-Level Architecture

### Core Components

**dart_falconnect/lib/engine/**
- **https/**: HTTP client with comprehensive interceptor system
  - `BaseHttpClient`: Abstract class with typed HTTP methods and automatic JSON conversion
  - Interceptors: cache, retry, rate limiting, logging, error handling
  - All methods require converter functions for type-safe responses
  
- **sockets/**: WebSocket implementation with reactive streams
  - `SocketClient`: Abstract WebSocket with retry logic and interceptor support
  - Stream-based filtering for specific response types
  - Automatic reconnection handling
  
- **rpc/**: JSON-RPC protocol implementation
  - `JsonRpcService`: Abstract class for JSON-RPC 2.0 over HTTP; `DefaultJsonRpcService`: concrete implementation
  - `BatchJsonRpcItem`: Sealed class with `resolve`, `map`, `responseOrNull`, `errorOrNull` for batch responses
  - Freezed-based request/response models with generated JSON serialization

### Code Generation Structure

Generated files follow strict organization:
- **Output Path**: `lib/{{path}}/generated/{{file}}.g.dart` or `.freezed.dart`
- **Annotations Used**:
  - `@freezed`: Immutable models with unions
  - `@JsonSerializable`: JSON conversion
  - `@retrofit`: REST API clients
- **Important**: Run `melos build_runner` after modifying annotated files

### Exception Architecture

Three exception systems in dart_falmodel:
- **`DefaultErrorType` enum** (`lib/exceptions/common_exception.dart`): General-purpose (unknown, system, validation, storage, etc.)
- **`NetworkErrorType` enum** (`lib/networks/exceptions/network_exception.dart`): HTTP-specific, maps to status codes
- **JSON-RPC exceptions** (`lib/networks/rpc/exceptions/`): `JsonRpcCommonException`, `JsonRpcDataLayerException`, `JsonRpcDomainLayerException` — use `JsonRpcErrorCategory` and `JsonRpcApiErrorType`/`JsonRpcRequestErrorType` enums
- `CommonException` has a `category` field and `toJsonRpcError()` method for converting to `JsonRpcError`
- `NetworkException extends CommonException` — do NOT mix with `ErrorType`
- Each HTTP exception class has a default `NetworkErrorType` via `super.type = NetworkErrorType.xxx`
- Barrel exports in `networks/exceptions/exceptions.dart` — new exception files MUST be added here
- Known typo: `NetworkNotImplementException` (501) — missing "ed" in "Implemented", preserved for backward compatibility
- Duplicate: both `NetworkAuthenticationException` and `UnauthorizedException` exist for 401

### Key Design Patterns

1. **Interceptor Chain Pattern**
   - Both HTTP and WebSocket use middleware-style interceptors
   - Enables cross-cutting concerns without modifying core logic
   - Order matters: auth → retry → cache → logging

2. **Result Pattern** (dart_falmodel)
   - Type-safe error handling without exceptions
   - Success/Failure union types with pattern matching
   - Comprehensive extension methods for transformation

3. **Extension Methods**
   - Heavy use throughout dart_faltool
   - Type conversions, null safety, collection utilities
   - String, StringValidator, DateTime, Number, Future, Stream, Iterable, List, Map, Enum, Object extensions

4. **Stream-Based Communication**
   - WebSocket responses as filtered streams
   - Reactive programming with RxDart
   - Proper subscription management required

## Gotchas

- When adding new exception classes, always add the export to `dart_falmodel/lib/networks/exceptions/exceptions.dart` — missing exports cause misleading analyzer errors (e.g., "method can't be unconditionally invoked because receiver can be 'null'")
- Exports in barrel files must be sorted alphabetically (enforced by `directives_ordering` lint rule)
- After large changes, run `dart pub get` before `dart analyze` to clear stale analyzer state

## Configuration Details

### Linting Rules
- Base: `very_good_analysis` package
- Single `analysis_options.yaml` at the workspace root applies to every package (consolidated; per-package configs were removed)
- `strict-casts` and `strict-inference` enabled — no implicit `dynamic`
- Enforced: `prefer_single_quotes`, `avoid_print`, `avoid_relative_lib_imports`
- Key relaxed rules: `public_member_api_docs`, `file_names`, `constant_identifier_names`, `avoid_redundant_argument_values`, and others
- Generated files excluded globally (`**/*.g.dart`, `**/*.freezed.dart`, `**/*.gen.dart`, `**/generated/**`, `**/build/**`)

### Build Configuration
- See `build.yaml` in `dart_falconnect`, `dart_falmodel`, and `dart_faltool`
- Generated files in subdirectories to maintain clean structure
- Retrofit generator enabled for API clients
- Melos scripts defined in root `pubspec.yaml` under `melos:` key (not in `melos.yaml`)

### Environment Requirements
- Dart SDK: `>=3.9.0 <4.0.0`
- Workspace resolution enabled for monorepo
- Melos: `^7.5.1` for workspace management

## Third-Party Packages

Packages flow upward: `dart_faltool` re-exports many of these via `dart_faltool.dart`, so consumers of `dart_falconx` get them transitively.

### Networking (`dart_falconnect`, `dart_falmodel`)

| Package                                 | Purpose                                                             |
|-----------------------------------------|---------------------------------------------------------------------|
| `dio`                                   | HTTP client — base of `BaseHttpClient`, JSON-RPC, interceptor chain |
| `dio_cache_interceptor`                 | Response caching strategy for `CacheInterceptor`                    |
| `retrofit` + `retrofit_generator`       | Annotation-driven REST client codegen                               |
| `web_socket_channel`                    | Cross-platform WebSocket — auto-resolves to `IO`/`Html` channel     |
| `freezed_annotation` + `freezed`        | Sealed unions / immutable models (request/response, errors)         |
| `json_annotation` + `json_serializable` | JSON serialization codegen                                          |
| `ansicolor`                             | ANSI-colored log output for `LogInterceptor`                        |

### Utilities (`dart_faltool`, re-exported)

| Package          | Purpose                                                                           |
|------------------|-----------------------------------------------------------------------------------|
| `rxdart`         | Reactive streams (`PublishSubject`, operators) — used by `SocketClient`           |
| `fpdart`         | Functional types (`Either`, `Option`, `Task`) for `Result` patterns               |
| `equatable`      | Value equality without boilerplate                                                |
| `dartx`          | Kotlin-style extensions; some members hidden to avoid clash with local extensions |
| `meta`           | Dart annotations (`@immutable`, `@protected`, etc.)                               |
| `logger`         | Structured/pretty log printer                                                     |
| `intl`           | i18n plus locale-aware date/number formatting                                     |
| `timeago`        | Human-readable relative time (`5 minutes ago`)                                    |
| `numeral`        | Compact number formatting (`1.2k`, `3.4m`)                                        |
| `big_decimal`    | Arbitrary-precision decimal arithmetic                                            |
| `hashlib`        | Crypto / non-crypto hash digests (used by TypeID)                                 |
| `retry`          | Generic retry-with-backoff helper                                                 |
| `stack_trace`    | Stack-trace parsing / formatting                                                  |
| `version`        | SemVer parsing (used by `AppInfo`)                                                |
| `yaml`           | YAML parser (used by `AppInfo` to read `pubspec.yaml`)                            |
| `universal_io`   | Cross-platform `dart:io` substitute (web-safe `File`, `Platform`, `HttpClient`)   |
| `web`            | Modern `package:web` JS interop bindings                                          |
| `enum_to_string` | Enum to/from string helpers                                                       |
| `data`           | Data-structure / buffer helpers                                                   |

### Dev / Tooling

| Package              | Purpose                                                   |
|----------------------|-----------------------------------------------------------|
| `melos`              | Monorepo orchestrator (workspace, scripts)                |
| `build_runner`       | Codegen runner                                            |
| `very_good_analysis` | Opinionated lint preset (base of `analysis_options.yaml`) |
| `lints`              | Stock Dart lints                                          |
| `test`               | Dart test framework                                       |