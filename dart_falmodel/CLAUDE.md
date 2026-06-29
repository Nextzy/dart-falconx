# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

`dart_falmodel` is the middle layer of the dart_falconx monorepo. It defines data models, exception hierarchies, and network abstractions consumed by `dart_falconnect` (network implementations) and downstream apps. It depends on `dart_faltool` (utilities) and re-exports it via `lib.dart`.

## Common Commands

```bash
# Install dependencies
dart pub get

# Code generation (required after modifying @freezed or @JsonSerializable classes)
dart run build_runner build -d

# Analyze
dart analyze

# Run tests (currently only test/unit_test.dart)
dart test
```

## Architecture

### Entry Points

- `lib/lib.dart` — Internal "prelude" that re-exports dart:async, dart:convert, Dio, Freezed/JSON annotations, json_annotation, and dart_faltool. Most files in this package import from here instead of individual packages.
- `lib/dart_falmodel.dart` — Public API barrel that exports the five modules: exceptions, extensions, feedbacks, models, networks.

### Three Exception Systems

1. **`CommonException`** (`lib/exceptions/common_exception.dart`) — Generic exception with `type` and `category` fields. Base for all exceptions.
   - `DefaultErrorType` enum: general-purpose categories (unknown, system, validation, storage, etc.)
   - `category` field: optional grouping (e.g., `JsonRpcErrorCategory`)
   - `toJsonRpcError()`: converts to `JsonRpcError` for RPC responses, auto-resolving category from `type`
   - Layer-specific subclasses: `DataLayerException`, `DomainLayerException`, `TodoException`

2. **`NetworkException`** (`lib/networks/exceptions/network_exception.dart`) — Extends `CommonException` with HTTP-specific fields (`statusCode`, `response`, `requestOptions`).
   - `NetworkErrorType` enum: maps 1:1 to HTTP status codes (400–511) plus general categories (network, timeout, noInternet)
   - `BaseHttpException`: abstract subclass adding retry logic, error detail extraction, and logging helpers
   - Concrete exceptions organized in `code4XX/` and `code5XX/` directories, one class per HTTP status code

3. **JSON-RPC exceptions** (`lib/networks/rpc/exceptions/`) — RPC-specific exception types:
   - `JsonRpcCommonException`, `JsonRpcDataLayerException`, `JsonRpcDomainLayerException` — extend their base counterparts
   - `JsonRpcErrorCategory` enum: `API_ERROR`, `EXTERNAL_API_ERROR`, `INVALID_REQUEST_ERROR`, `UNKNOWN`
   - `JsonRpcApiErrorType` enum: server-side errors (INTERNAL_SERVER_ERROR, UNAUTHORIZED, FORBIDDEN, RATE_LIMITED, etc.)
   - `JsonRpcRequestErrorType` enum: client request errors (INVALID_JSON_RPC, BAD_REQUEST, INCORRECT_TYPE, etc.)
   - `RemoteExternalApiErrorType` enum: external API errors
   - Barrel: `lib/networks/rpc/exceptions/exceptions.dart` — new RPC exception files MUST be added here

**Critical**: These three systems must not be mixed. `NetworkException` uses `NetworkErrorType`, not `ErrorType`. JSON-RPC exceptions use `JsonRpcErrorCategory` + `JsonRpcApiErrorType`/`JsonRpcRequestErrorType`.

### Adding New Network Exceptions

1. Create the exception class extending `BaseHttpException` in the appropriate `code4XX/` or `code5XX/` directory
2. Set the default `NetworkErrorType` via `super.type`
3. Add the export to `lib/networks/exceptions/exceptions.dart` — **alphabetically sorted** (enforced by `directives_ordering` lint)
4. If the status code is new, add it to `NetworkErrorType` enum's `statusCode` getter, `fromStatusCode` factory, and `defaultMessage` getter

### Result Pattern

`Result<T>` (`lib/models/result.dart`) — Success/Failure type without Freezed. Failures carry `CommonException`. Provides `map`, `flatMap`, `recover`, `when`, `resolve`, and convenience factories (`dataFailure`, `domainFailure`).

### JSON-RPC Models

Split into success (`JsonRpcResponse<RESULT>`) and error (`JsonRpcErrorResponse`) types — both Freezed. `JsonRpcResult` is the abstract interface all RPC result types must implement (requires `toJson()`). `RawJsonRpcResult` wraps a raw `Map` for manual construction. `BatchJsonRpcItem` is a hand-written sealed class (not Freezed) with `resolve`, `map`, `responseOrNull`, `errorOrNull` for batch response handling.

`JsonRpcError` is a Freezed sealed class with `category` (`JsonRpcErrorCategory`), `code` (String), `userMessage`, and optional `developerMessage`. Convenience factories: `invalidRequest`, `external`, `internal`, `methodNotImplement`, `invalidParams`.

### UserFeedback

Freezed sealed class (`lib/feedbacks/feedback.dart`) with four variants: `Success`, `Warning`, `Failure`, `Information`. Each has a `FeedbackLevel`. Provides both Freezed `when`/`maybeWhen` and a custom `match` method.

### Code Generation

Generated files go to `lib/{{path}}/generated/` (configured in `build.yaml`). Currently used for:
- `networks/https/responses/remote_error.dart` (Freezed + JSON)
- `networks/rpc/json_rpc_response.dart` (Freezed + JSON)
- `networks/rpc/json_rpc_request.dart`, `json_rpc_error.dart`
- `feedbacks/feedback.dart` (Freezed + JSON)

## Gotchas

- `lib/lib.dart` is not the public API — it's an internal convenience import. The public API is `dart_falmodel.dart`.
- Known typo: `NetworkNotImplementException` (501) — preserved for backward compatibility, do not rename.
- Duplicate 401 classes: both `NetworkAuthenticationException` and `UnauthorizedException` exist — both are intentional.
- Missing barrel exports cause misleading analyzer errors (e.g., "method can't be unconditionally invoked because receiver can be 'null'") rather than clear import errors.
- `strict-casts` and `strict-inference` are enabled — no implicit `dynamic`.
