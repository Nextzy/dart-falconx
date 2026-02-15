# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dart/Flutter monorepo managed with Melos, containing packages for network operations and utilities:

- **dart_falconnect**: Network connectivity (HTTP client, WebSocket, RPC implementations)
- **dart_falmodel**: Data models, exceptions, and network abstractions  
- **dart_faltool**: Utility extensions and helper functions

### Package Architecture
```
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
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Testing
```bash
# Run all tests in a package
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
  - Freezed-based request/response models
  - Proper JSON serialization with generated code

### Code Generation Structure

Generated files follow strict organization:
- **Output Path**: `lib/{{path}}/generated/{{file}}.g.dart` or `.freezed.dart`
- **Annotations Used**:
  - `@freezed`: Immutable models with unions
  - `@JsonSerializable`: JSON conversion
  - `@retrofit`: REST API clients
- **Important**: Run `melos build_runner` after modifying annotated files

### Exception Architecture

Comprehensive exception hierarchy in `dart_falmodel/lib/exceptions/`:
- **Base exceptions**: Common error patterns
- **HTTP exceptions**: Status code-specific errors (4xx, 5xx)
- **Network exceptions**: Connectivity, timeout, retry failures
- **Domain exceptions**: Business logic errors
- All exceptions support error codes, messages, and stack traces

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
   - String, DateTime, Number, Future, Stream extensions

4. **Stream-Based Communication**
   - WebSocket responses as filtered streams
   - Reactive programming with RxDart
   - Proper subscription management required

## Configuration Details

### Linting Rules
- Base: `very_good_analysis` package
- Customizations in each `analysis_options.yaml`
- Key relaxed rules: `public_member_api_docs`, `file_names`

### Build Configuration
- See `build.yaml` in each package
- Generated files in subdirectories to maintain clean structure
- Retrofit generator enabled for API clients

### Environment Requirements
- Dart SDK: `>=3.9.0 <4.0.0`
- Workspace resolution enabled for monorepo
- Melos: `^7.4.0` for workspace management