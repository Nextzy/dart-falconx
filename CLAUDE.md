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
dart_faltool (base layer: utilities, extensions)
    ↑
dart_falmodel (middle layer: models, exceptions, abstractions)
    ↑
dart_falconnect (top layer: network implementations)
```

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
  - `RpcService`: Abstract class for JSON-RPC 2.0 over HTTP; `DefaultRpcService`: concrete implementation
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

Two exception systems in dart_falmodel:
- **`ErrorType` enum** (`lib/exceptions/common_exception.dart`): General-purpose (unknown, system, validation, storage, etc.)
- **`NetworkErrorType` enum** (`lib/networks/exceptions/network_exception.dart`): HTTP-specific, maps to status codes
- `NetworkException extends CommonException<NetworkErrorType>` — do NOT mix with `ErrorType`
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
- Customizations in each `analysis_options.yaml`
- Enforced: `prefer_single_quotes`, `avoid_print`, `avoid_relative_lib_imports`
- Key relaxed rules: `public_member_api_docs`, `file_names`, `constant_identifier_names`, `avoid_catches_without_on_clauses`, `avoid_positional_boolean_parameters`, and others
- Generated files excluded from analysis in `dart_falmodel` and `dart_faltool` (`**/generated/**`, `*.g.dart`, `*.freezed.dart`)

### Build Configuration
- See `build.yaml` in `dart_falconnect` and `dart_falmodel` (no build.yaml in other packages)
- Generated files in subdirectories to maintain clean structure
- Retrofit generator enabled for API clients
- Melos scripts defined in root `pubspec.yaml` under `melos:` key (not in `melos.yaml`)

### Environment Requirements
- Dart SDK: `>=3.9.0 <4.0.0`
- Workspace resolution enabled for monorepo
- Melos: `^7.4.0` for workspace management