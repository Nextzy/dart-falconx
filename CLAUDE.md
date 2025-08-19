# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dart/Flutter monorepo managed with Melos, containing three interconnected packages for network operations and utilities:

- **dart_falconnect**: Network connectivity package (HTTP client, WebSocket, RPC)
- **dart_falmodel**: Data models and network abstractions
- **dart_faltool**: Utility extensions and helper functions

## Common Development Commands

### Package Management
```bash
# Get dependencies for all packages
melos get
# or
flutter pub get  # in each package directory

# Upgrade dependencies
melos upgrade

# Check outdated dependencies
melos outdated

# Clean and restart (when dependencies are corrupted)
melos restart
```

### Code Generation
```bash
# Run build_runner for all packages that need code generation
melos build_runner

# Run build_runner in a specific package
cd dart_falconnect
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testing
```bash
# Run all tests in a specific package
cd dart_faltool
dart test

# Run a single test file
dart test test/extensions/string_extensions_test.dart

# Run tests matching a pattern
dart test -n "StringExtension"

# Run tests with specific tags
dart test -t "unit"
```

### Linting and Analysis
```bash
# Analyze code in each package
dart analyze

# Fix linting issues
dart fix --apply
```

## Architecture Overview

### Package Dependencies
The packages follow a layered architecture:
```
dart_faltool (base utilities)
    ↑
dart_falmodel (models & abstractions)
    ↑
dart_falconnect (network implementation)
```

### Key Components

**dart_falconnect/lib/engine/**
- **https/**: HTTP client implementation with interceptors (cache, error handling, retry, rate limiting)
  - `BaseHttpClient`: Abstract class providing typed HTTP methods with automatic JSON conversion
  - Interceptor pattern for cross-cutting concerns
  
- **sockets/**: WebSocket client implementation
  - `SocketClient`: Abstract WebSocket client with retry logic and interceptor support
  - Stream-based response handling
  
- **rpc/**: JSON-RPC implementation using Freezed for code generation
  - Request/Response models with proper serialization

### Code Generation Patterns

The project uses several code generation tools:

1. **Freezed**: For immutable data classes (see `rpc_request.dart`)
   - Generated files go to `lib/{{path}}/generated/` subdirectory
   
2. **JsonSerializable**: For JSON serialization
   - Works in conjunction with Freezed
   
3. **Retrofit**: For REST API client generation

When modifying files with code generation annotations (@freezed, @JsonSerializable), always run build_runner afterward.

### Network Exception Hierarchy

The project has a comprehensive exception system in `dart_falconnect/lib/engine/https/exceptions/`:
- HTTP 4xx errors (authentication, forbidden, not found, etc.)
- HTTP 5xx errors (internal server error, gateway timeout, etc.)
- Network-specific exceptions (timeout, no internet connection)

### Important Patterns

1. **Extension Methods**: Heavy use of Dart extensions for type conversions and utilities (see dart_faltool)

2. **Interceptor Pattern**: Both HTTP and WebSocket clients use interceptor chains for:
   - Logging
   - Error handling
   - Retry logic
   - Performance monitoring
   - Rate limiting

3. **Stream-Based WebSockets**: WebSocket responses are exposed as filtered streams for reactive programming

4. **Type-Safe HTTP Methods**: All HTTP methods require converter functions for automatic JSON to model conversion

## Configuration

### Analysis Options
The project uses `very_good_analysis` package for strict linting with some rules disabled for practical reasons (see `analysis_options.yaml` in each package).

### Build Configuration
Code generation outputs are configured to generate into `generated/` subdirectories to keep the main source directories clean (see `build.yaml`).

## Development Tips

1. Always run `melos get` after pulling changes that modify pubspec files
2. Generated files (`*.g.dart`, `*.freezed.dart`) should not be edited manually
3. When adding new packages to the workspace, update the root `pubspec.yaml` workspace section
4. The project requires Dart SDK >=3.9.0