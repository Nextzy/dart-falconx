# DefaultErrorType Sealed Class Redesign

**Date:** 2026-04-17
**Package:** dart_falmodel
**Breaking:** Yes (major version bump)

## Problem

`DefaultErrorType` is a flat enum with 14 values that mix different concerns:
- Error nature (system, unexpected, unknown)
- Error source (storage, cache, database, thirdParty)
- Data characteristics (validation, invalidInput, invalidFormat)

This makes it hard for frontend consumers to `switch` by group and lacks coverage for many native Dart exceptions, forcing fallback to `unknown`.

## Goals

1. Group error types into semantic categories that frontend can pattern-match on
2. Cover all native Dart exceptions from `dart:core`, `dart:io`, `dart:async`
3. Use specific-first, parent-class-fallback detection strategy
4. Keep `CommonException.type` as `Object` for compatibility with `NetworkErrorType`, `JsonRpcApiErrorType`, etc.
5. Keep `DefaultErrorCategory` (remote/local/unknown) unchanged — it serves a different axis

## Design

### Sealed class + sub-enums

Replace `enum DefaultErrorType` with `sealed class DefaultErrorType` implemented by 9 sub-enums.

```dart
sealed class DefaultErrorType {
  String get defaultMessage;
}
```

### Sub-enums

#### SystemErrorType
General system-level errors and catch-all.

| Value | defaultMessage | Mapped from |
|---|---|---|
| `unknown` | Something went wrong. Please try again. | Fallback default |
| `system` | System error occurred. | `StateError`, `OutOfMemoryError`, `StackOverflowError` |
| `unexpected` | An unexpected error occurred. | `UnsupportedError`, fallback `Error` |
| `concurrency` | Concurrent modification error. | `ConcurrentModificationError` |

#### InputErrorType
User input and data format errors.

| Value | defaultMessage | Mapped from |
|---|---|---|
| `validation` | Invalid input. Please check your data. | (business logic) |
| `invalidFormat` | Invalid format. | `FormatException` |
| `invalidValue` | Invalid value provided. | (business logic) |
| `outOfRange` | Value out of range. | `RangeError` |
| `argument` | Invalid argument provided. | `ArgumentError` |
| `type` | Type error occurred. | `TypeError`, `NoSuchMethodError` |

#### TimeoutErrorType
Timeout and deadline errors.

| Value | defaultMessage | Mapped from |
|---|---|---|
| `timeout` | Request timed out. Please try again. | `TimeoutException` |
| `deadline` | Operation deadline exceeded. | (business logic) |

#### StorageErrorType
Local storage, file system, and database errors.

| Value | defaultMessage | Mapped from |
|---|---|---|
| `storage` | Storage error occurred. | Fallback `IOException` |
| `cache` | Cache error occurred. | (business logic) |
| `database` | Database error occurred. | (business logic) |
| `fileSystem` | File system error. | `PathNotFoundException`, `FileSystemException` |

#### ConnectivityErrorType
Network and connection errors.

| Value | defaultMessage | Mapped from |
|---|---|---|
| `connection` | Connection error. | (general connectivity) |
| `socket` | Socket error. | `SocketException` |
| `tls` | TLS/SSL error. | `TlsException`, `HandshakeException`, `CertificateException` |
| `dns` | DNS resolution failed. | (business logic) |
| `http` | HTTP error. | `HttpException` |

#### AsyncErrorType
Asynchronous operation errors.

| Value | defaultMessage | Mapped from |
|---|---|---|
| `stream` | Stream error occurred. | `AsyncError` |
| `future` | Future error occurred. | (business logic) |
| `isolate` | Isolate error occurred. | (business logic) |

#### AccessErrorType
Permission and authorization errors.

| Value | defaultMessage | Mapped from |
|---|---|---|
| `permission` | Permission denied. | (business logic) |
| `unauthorized` | Unauthorized access. | (business logic) |
| `deviceNotSupported` | This device is not supported. | (business logic) |

#### ExternalErrorType
Third-party and external service errors.

| Value | defaultMessage | Mapped from |
|---|---|---|
| `thirdParty` | External service error. | (business logic) |
| `serviceUnavailable` | Service is currently unavailable. | (business logic) |

#### BusinessErrorType
Business logic and domain errors.

| Value | defaultMessage | Mapped from |
|---|---|---|
| `businessRule` | Operation not allowed. | (business logic) |
| `notFound` | The requested resource was not found. | (business logic) |
| `conflict` | A conflict occurred. | (business logic) |
| `deprecated` | This feature is deprecated. | (business logic) |

### Each sub-enum structure

```dart
enum XxxErrorType implements DefaultErrorType {
  value1('message'),
  value2('message');

  const XxxErrorType(this._message);
  final String _message;

  @override
  String get defaultMessage => _message;
}
```

### Detection strategy: `_detectErrorType()`

Order: specific exception → parent class fallback → `SystemErrorType.unknown`

```dart
Object _detectErrorType(Object? exception) {
  // ─── Connectivity (specific) ───
  if (exception is SocketException)       return ConnectivityErrorType.socket;
  if (exception is TlsException)          return ConnectivityErrorType.tls;
  if (exception is HandshakeException)    return ConnectivityErrorType.tls;
  if (exception is CertificateException)  return ConnectivityErrorType.tls;
  if (exception is HttpException)         return ConnectivityErrorType.http;

  // ─── Storage (specific) ───
  if (exception is PathNotFoundException) return StorageErrorType.fileSystem;
  if (exception is FileSystemException)   return StorageErrorType.fileSystem;

  // ─── Input ───
  if (exception is FormatException)       return InputErrorType.invalidFormat;
  if (exception is TypeError)             return InputErrorType.type;
  if (exception is RangeError)            return InputErrorType.outOfRange;
  if (exception is ArgumentError)         return InputErrorType.argument;
  if (exception is NoSuchMethodError)     return InputErrorType.type;

  // ─── Timeout ───
  if (exception is TimeoutException)      return TimeoutErrorType.timeout;

  // ─── System (specific) ───
  if (exception is ConcurrentModificationError) return SystemErrorType.concurrency;
  if (exception is OutOfMemoryError)      return SystemErrorType.system;
  if (exception is StackOverflowError)    return SystemErrorType.system;
  if (exception is StateError)            return SystemErrorType.system;
  if (exception is UnsupportedError)      return SystemErrorType.unexpected;

  // ─── Async ───
  if (exception is AsyncError)            return AsyncErrorType.stream;

  // ─── Parent class fallback ───
  if (exception is IOException)           return StorageErrorType.storage;
  if (exception is Error)                 return SystemErrorType.unexpected;

  return SystemErrorType.unknown;
}
```

### `_io_stubs.dart` updates

Add web stubs for new `dart:io` types used in `_detectErrorType()`:

```dart
// Existing
class HttpException implements Exception {}
class HandshakeException implements Exception {}
class CertificateException implements Exception {}
class FileSystemException implements Exception {}
class IOException implements Exception {}

// New
class SocketException implements Exception {}
class TlsException implements Exception {}
class PathNotFoundException implements Exception {}
```

Note: `OutOfMemoryError`, `StackOverflowError`, `ConcurrentModificationError`, `NoSuchMethodError` are in `dart:core` and do not need stubs.

### `_io_real.dart`

No change — `export 'dart:io'` already covers all added types.

## Files changed

| File | Change |
|---|---|
| `lib/exceptions/common_exception.dart` | Remove `enum DefaultErrorType`, add `sealed class DefaultErrorType` + 9 sub-enums. Keep `DefaultErrorCategory` unchanged. |
| `lib/extensions/exception_extensions.dart` | Update `_detectErrorType()` with new mapping. Update default fallbacks from `DefaultErrorType.unknown` to `SystemErrorType.unknown`. |
| `lib/extensions/_io_stubs.dart` | Add `SocketException`, `TlsException`, `PathNotFoundException` stubs. |
| `lib/models/result.dart` | Update `DefaultErrorType.unexpected` to `SystemErrorType.unexpected`. |

## Frontend usage

```dart
// Specific value matching
switch (error.type) {
  case StorageErrorType.cache:       handleCache();
  case InputErrorType.validation:    showValidationError();
  case SystemErrorType.unknown:      showGenericError();
}

// Group matching
switch (error.type) {
  case StorageErrorType():      showStorageError();
  case ConnectivityErrorType(): showNetworkError();
  case TimeoutErrorType():      showRetryDialog();
  case AccessErrorType():       showLoginScreen();
  case _:                       showGenericError();
}
```

Note: `CommonException.type` is `Object`, so frontend must cast or check `is DefaultErrorType` before switching:

```dart
final type = error.type;
if (type is DefaultErrorType) {
  switch (type) {
    case StorageErrorType(): ...
    case ConnectivityErrorType(): ...
  }
}
```
