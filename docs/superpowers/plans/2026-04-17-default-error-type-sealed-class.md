# DefaultErrorType Sealed Class Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat `DefaultErrorType` enum with a `sealed class` + 9 sub-enums to enable group-level pattern matching and comprehensive native Dart exception coverage.

**Architecture:** The `sealed class DefaultErrorType` becomes the abstract interface. Each error group is a separate `enum` that `implements DefaultErrorType`. Detection logic in `_detectErrorType()` uses specific-first, parent-class-fallback ordering. `CommonException.type` stays `Object`.

**Tech Stack:** Dart 3.9+, sealed classes, enhanced enums, pattern matching

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `dart_falmodel/lib/exceptions/common_exception.dart` | Modify | Remove old `enum DefaultErrorType`, add `sealed class` + 9 sub-enums |
| `dart_falmodel/lib/extensions/_io_stubs.dart` | Modify | Add web stubs for `SocketException`, `TlsException`, `PathNotFoundException` |
| `dart_falmodel/lib/extensions/exception_extensions.dart` | Modify | Update `_detectErrorType()` and all `DefaultErrorType.xxx` references |
| `dart_falmodel/lib/models/result.dart` | Modify | Update `DefaultErrorType.unexpected` to `SystemErrorType.unexpected` |
| `dart_falmodel/test/exceptions/default_error_type_test.dart` | Create | Tests for sealed class hierarchy and `defaultMessage` |
| `dart_falmodel/test/extensions/exception_extensions_test.dart` | Create | Tests for `_detectErrorType()` mapping |

---

### Task 1: Add web stubs for new `dart:io` types

**Files:**
- Modify: `dart_falmodel/lib/extensions/_io_stubs.dart`

- [ ] **Step 1: Add the new stub classes**

In `dart_falmodel/lib/extensions/_io_stubs.dart`, add three new stub classes after the existing ones:

```dart
// Web stub for the small subset of `dart:io` types referenced by
// `exception_extensions.dart`. These `is` checks can never match on web
// (the real classes only exist on the VM), but the file still has to
// compile under dart2js.
//
// Do not add behaviour here — keep these as inert sentinel classes.

class HttpException implements Exception {}

class HandshakeException implements Exception {}

class CertificateException implements Exception {}

class FileSystemException implements Exception {}

class IOException implements Exception {}

class SocketException implements Exception {}

class TlsException implements Exception {}

class PathNotFoundException implements Exception {}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd dart_falmodel && dart analyze lib/extensions/_io_stubs.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add dart_falmodel/lib/extensions/_io_stubs.dart
git commit -m "feat(falmodel): add web stubs for SocketException, TlsException, PathNotFoundException"
```

---

### Task 2: Replace `DefaultErrorType` enum with sealed class + sub-enums

**Files:**
- Modify: `dart_falmodel/lib/exceptions/common_exception.dart`

- [ ] **Step 1: Write failing test for sealed class hierarchy**

Create `dart_falmodel/test/exceptions/default_error_type_test.dart`:

```dart
import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultErrorType sealed class', () {
    test('SystemErrorType implements DefaultErrorType', () {
      expect(SystemErrorType.unknown, isA<DefaultErrorType>());
      expect(SystemErrorType.system, isA<DefaultErrorType>());
      expect(SystemErrorType.unexpected, isA<DefaultErrorType>());
      expect(SystemErrorType.concurrency, isA<DefaultErrorType>());
    });

    test('InputErrorType implements DefaultErrorType', () {
      expect(InputErrorType.validation, isA<DefaultErrorType>());
      expect(InputErrorType.invalidFormat, isA<DefaultErrorType>());
      expect(InputErrorType.invalidValue, isA<DefaultErrorType>());
      expect(InputErrorType.outOfRange, isA<DefaultErrorType>());
      expect(InputErrorType.argument, isA<DefaultErrorType>());
      expect(InputErrorType.type, isA<DefaultErrorType>());
    });

    test('TimeoutErrorType implements DefaultErrorType', () {
      expect(TimeoutErrorType.timeout, isA<DefaultErrorType>());
      expect(TimeoutErrorType.deadline, isA<DefaultErrorType>());
    });

    test('StorageErrorType implements DefaultErrorType', () {
      expect(StorageErrorType.storage, isA<DefaultErrorType>());
      expect(StorageErrorType.cache, isA<DefaultErrorType>());
      expect(StorageErrorType.database, isA<DefaultErrorType>());
      expect(StorageErrorType.fileSystem, isA<DefaultErrorType>());
    });

    test('ConnectivityErrorType implements DefaultErrorType', () {
      expect(ConnectivityErrorType.connection, isA<DefaultErrorType>());
      expect(ConnectivityErrorType.socket, isA<DefaultErrorType>());
      expect(ConnectivityErrorType.tls, isA<DefaultErrorType>());
      expect(ConnectivityErrorType.dns, isA<DefaultErrorType>());
      expect(ConnectivityErrorType.http, isA<DefaultErrorType>());
    });

    test('AsyncErrorType implements DefaultErrorType', () {
      expect(AsyncErrorType.stream, isA<DefaultErrorType>());
      expect(AsyncErrorType.future, isA<DefaultErrorType>());
      expect(AsyncErrorType.isolate, isA<DefaultErrorType>());
    });

    test('AccessErrorType implements DefaultErrorType', () {
      expect(AccessErrorType.permission, isA<DefaultErrorType>());
      expect(AccessErrorType.unauthorized, isA<DefaultErrorType>());
      expect(AccessErrorType.deviceNotSupported, isA<DefaultErrorType>());
    });

    test('ExternalErrorType implements DefaultErrorType', () {
      expect(ExternalErrorType.thirdParty, isA<DefaultErrorType>());
      expect(ExternalErrorType.serviceUnavailable, isA<DefaultErrorType>());
    });

    test('BusinessErrorType implements DefaultErrorType', () {
      expect(BusinessErrorType.businessRule, isA<DefaultErrorType>());
      expect(BusinessErrorType.notFound, isA<DefaultErrorType>());
      expect(BusinessErrorType.conflict, isA<DefaultErrorType>());
      expect(BusinessErrorType.deprecated, isA<DefaultErrorType>());
    });
  });

  group('defaultMessage', () {
    test('SystemErrorType has correct messages', () {
      expect(
        SystemErrorType.unknown.defaultMessage,
        'Something went wrong. Please try again.',
      );
      expect(SystemErrorType.system.defaultMessage, 'System error occurred.');
      expect(
        SystemErrorType.unexpected.defaultMessage,
        'An unexpected error occurred.',
      );
      expect(
        SystemErrorType.concurrency.defaultMessage,
        'Concurrent modification error.',
      );
    });

    test('InputErrorType has correct messages', () {
      expect(
        InputErrorType.validation.defaultMessage,
        'Invalid input. Please check your data.',
      );
      expect(InputErrorType.invalidFormat.defaultMessage, 'Invalid format.');
      expect(
        InputErrorType.invalidValue.defaultMessage,
        'Invalid value provided.',
      );
      expect(InputErrorType.outOfRange.defaultMessage, 'Value out of range.');
      expect(
        InputErrorType.argument.defaultMessage,
        'Invalid argument provided.',
      );
      expect(InputErrorType.type.defaultMessage, 'Type error occurred.');
    });

    test('TimeoutErrorType has correct messages', () {
      expect(
        TimeoutErrorType.timeout.defaultMessage,
        'Request timed out. Please try again.',
      );
      expect(
        TimeoutErrorType.deadline.defaultMessage,
        'Operation deadline exceeded.',
      );
    });

    test('StorageErrorType has correct messages', () {
      expect(
        StorageErrorType.storage.defaultMessage,
        'Storage error occurred.',
      );
      expect(StorageErrorType.cache.defaultMessage, 'Cache error occurred.');
      expect(
        StorageErrorType.database.defaultMessage,
        'Database error occurred.',
      );
      expect(StorageErrorType.fileSystem.defaultMessage, 'File system error.');
    });
  });

  group('pattern matching', () {
    test('can switch on specific value', () {
      final DefaultErrorType type = StorageErrorType.cache;
      final result = switch (type) {
        StorageErrorType.cache => 'cache',
        _ => 'other',
      };
      expect(result, 'cache');
    });

    test('can switch on group', () {
      final DefaultErrorType type = ConnectivityErrorType.socket;
      final result = switch (type) {
        SystemErrorType() => 'system',
        InputErrorType() => 'input',
        TimeoutErrorType() => 'timeout',
        StorageErrorType() => 'storage',
        ConnectivityErrorType() => 'connectivity',
        AsyncErrorType() => 'async',
        AccessErrorType() => 'access',
        ExternalErrorType() => 'external',
        BusinessErrorType() => 'business',
      };
      expect(result, 'connectivity');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd dart_falmodel && dart test test/exceptions/default_error_type_test.dart`
Expected: Compilation error — `DefaultErrorType` is still a flat enum, `SystemErrorType` etc. don't exist

- [ ] **Step 3: Replace the enum with sealed class + sub-enums**

Replace everything from `enum DefaultErrorType {` through the closing `}` of its `defaultMessage` getter (lines 9–43) in `dart_falmodel/lib/exceptions/common_exception.dart` with:

```dart
sealed class DefaultErrorType {
  String get defaultMessage;
}

enum SystemErrorType implements DefaultErrorType {
  unknown('Something went wrong. Please try again.'),
  system('System error occurred.'),
  unexpected('An unexpected error occurred.'),
  concurrency('Concurrent modification error.');

  const SystemErrorType(this._message);
  final String _message;

  @override
  String get defaultMessage => _message;
}

enum InputErrorType implements DefaultErrorType {
  validation('Invalid input. Please check your data.'),
  invalidFormat('Invalid format.'),
  invalidValue('Invalid value provided.'),
  outOfRange('Value out of range.'),
  argument('Invalid argument provided.'),
  type('Type error occurred.');

  const InputErrorType(this._message);
  final String _message;

  @override
  String get defaultMessage => _message;
}

enum TimeoutErrorType implements DefaultErrorType {
  timeout('Request timed out. Please try again.'),
  deadline('Operation deadline exceeded.');

  const TimeoutErrorType(this._message);
  final String _message;

  @override
  String get defaultMessage => _message;
}

enum StorageErrorType implements DefaultErrorType {
  storage('Storage error occurred.'),
  cache('Cache error occurred.'),
  database('Database error occurred.'),
  fileSystem('File system error.');

  const StorageErrorType(this._message);
  final String _message;

  @override
  String get defaultMessage => _message;
}

enum ConnectivityErrorType implements DefaultErrorType {
  connection('Connection error.'),
  socket('Socket error.'),
  tls('TLS/SSL error.'),
  dns('DNS resolution failed.'),
  http('HTTP error.');

  const ConnectivityErrorType(this._message);
  final String _message;

  @override
  String get defaultMessage => _message;
}

enum AsyncErrorType implements DefaultErrorType {
  stream('Stream error occurred.'),
  future('Future error occurred.'),
  isolate('Isolate error occurred.');

  const AsyncErrorType(this._message);
  final String _message;

  @override
  String get defaultMessage => _message;
}

enum AccessErrorType implements DefaultErrorType {
  permission('Permission denied.'),
  unauthorized('Unauthorized access.'),
  deviceNotSupported('This device is not supported.');

  const AccessErrorType(this._message);
  final String _message;

  @override
  String get defaultMessage => _message;
}

enum ExternalErrorType implements DefaultErrorType {
  thirdParty('External service error.'),
  serviceUnavailable('Service is currently unavailable.');

  const ExternalErrorType(this._message);
  final String _message;

  @override
  String get defaultMessage => _message;
}

enum BusinessErrorType implements DefaultErrorType {
  businessRule('Operation not allowed.'),
  notFound('The requested resource was not found.'),
  conflict('A conflict occurred.'),
  deprecated('This feature is deprecated.');

  const BusinessErrorType(this._message);
  final String _message;

  @override
  String get defaultMessage => _message;
}
```

Keep `enum DefaultErrorCategory` and `class CommonException` unchanged.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd dart_falmodel && dart test test/exceptions/default_error_type_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add dart_falmodel/lib/exceptions/common_exception.dart dart_falmodel/test/exceptions/default_error_type_test.dart
git commit -m "feat(falmodel)!: replace DefaultErrorType enum with sealed class + 9 sub-enums

BREAKING CHANGE: DefaultErrorType is now a sealed class. All values like
DefaultErrorType.unknown are now SystemErrorType.unknown, etc."
```

---

### Task 3: Update `exception_extensions.dart` — detection and references

**Files:**
- Modify: `dart_falmodel/lib/extensions/exception_extensions.dart`

- [ ] **Step 1: Write failing test for `_detectErrorType()` mapping**

Create `dart_falmodel/test/extensions/exception_extensions_test.dart`:

```dart
import 'dart:async';

import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:test/test.dart';

void main() {
  /// Helper: calls toException() on an object and returns the resolved type.
  Object detectType(Object exception) => exception.toException().type;

  group('_detectErrorType — Connectivity', () {
    test('FormatException maps to InputErrorType.invalidFormat', () {
      expect(detectType(const FormatException()), InputErrorType.invalidFormat);
    });

    test('TypeError maps to InputErrorType.type', () {
      // Create a real TypeError by catching one
      try {
        (42 as dynamic).noSuchMethod; // ignore: unused_result
      } on TypeError catch (e) {
        expect(detectType(e), InputErrorType.type);
        return;
      }
      fail('Expected TypeError');
    });

    test('RangeError maps to InputErrorType.outOfRange', () {
      expect(detectType(RangeError('test')), InputErrorType.outOfRange);
    });

    test('ArgumentError maps to InputErrorType.argument', () {
      expect(detectType(ArgumentError('test')), InputErrorType.argument);
    });
  });

  group('_detectErrorType — Timeout', () {
    test('TimeoutException maps to TimeoutErrorType.timeout', () {
      expect(
        detectType(TimeoutException('test')),
        TimeoutErrorType.timeout,
      );
    });
  });

  group('_detectErrorType — System', () {
    test('StateError maps to SystemErrorType.system', () {
      expect(detectType(StateError('test')), SystemErrorType.system);
    });

    test('UnsupportedError maps to SystemErrorType.unexpected', () {
      expect(
        detectType(UnsupportedError('test')),
        SystemErrorType.unexpected,
      );
    });

    test('ConcurrentModificationError maps to SystemErrorType.concurrency', () {
      expect(
        detectType(ConcurrentModificationError()),
        SystemErrorType.concurrency,
      );
    });
  });

  group('_detectErrorType — Async', () {
    test('AsyncError maps to AsyncErrorType.stream', () {
      expect(
        detectType(AsyncError('inner', StackTrace.current)),
        AsyncErrorType.stream,
      );
    });
  });

  group('_detectErrorType — Fallback', () {
    test('unknown Error falls back to SystemErrorType.unexpected', () {
      expect(detectType(UnimplementedError()), SystemErrorType.unexpected);
    });

    test('null falls back to SystemErrorType.unknown', () {
      final exception = null.toException();
      expect(exception.type, SystemErrorType.unknown);
    });

    test('plain String falls back to SystemErrorType.unknown', () {
      expect(detectType('just a string'), SystemErrorType.unknown);
    });
  });

  group('toCommonResultFailure defaults', () {
    test('uses SystemErrorType.unknown when no type given', () {
      final Exception? ex = Exception('test');
      final result = ex.toCommonResultFailure();
      expect(result.exception.type, SystemErrorType.unknown);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd dart_falmodel && dart test test/extensions/exception_extensions_test.dart`
Expected: Compilation errors — `_detectErrorType` still uses old `DefaultErrorType` values

- [ ] **Step 3: Update `_detectErrorType()` method**

In `dart_falmodel/lib/extensions/exception_extensions.dart`, replace the `_detectErrorType` method body (lines 129–155) with:

```dart
  Object _detectErrorType(Object? exception) {
    // ─── Connectivity (specific) ───
    if (exception is SocketException) return ConnectivityErrorType.socket;
    if (exception is TlsException) return ConnectivityErrorType.tls;
    if (exception is HandshakeException) return ConnectivityErrorType.tls;
    if (exception is CertificateException) return ConnectivityErrorType.tls;
    if (exception is HttpException) return ConnectivityErrorType.http;

    // ─── Storage (specific) ───
    if (exception is PathNotFoundException) return StorageErrorType.fileSystem;
    if (exception is FileSystemException) return StorageErrorType.fileSystem;

    // ─── Input ───
    if (exception is FormatException) return InputErrorType.invalidFormat;
    if (exception is TypeError) return InputErrorType.type;
    if (exception is RangeError) return InputErrorType.outOfRange;
    if (exception is ArgumentError) return InputErrorType.argument;
    if (exception is NoSuchMethodError) return InputErrorType.type;

    // ─── Timeout ───
    if (exception is TimeoutException) return TimeoutErrorType.timeout;

    // ─── System (specific) ───
    if (exception is ConcurrentModificationError) {
      return SystemErrorType.concurrency;
    }
    if (exception is OutOfMemoryError) return SystemErrorType.system;
    if (exception is StackOverflowError) return SystemErrorType.system;
    if (exception is StateError) return SystemErrorType.system;
    if (exception is UnsupportedError) return SystemErrorType.unexpected;

    // ─── Async ───
    if (exception is AsyncError) return AsyncErrorType.stream;

    // ─── Parent class fallback ───
    if (exception is IOException) return StorageErrorType.storage;
    if (exception is Error) return SystemErrorType.unexpected;

    return SystemErrorType.unknown;
  }
```

- [ ] **Step 4: Update `DefaultErrorType.unknown` references in same file**

Replace the two occurrences of `DefaultErrorType.unknown` (lines 51 and 74) with `SystemErrorType.unknown`:

Line 51 in `toCommonResultFailure`:
```dart
        type: type ?? SystemErrorType.unknown,
```

Line 74 in `toException`:
```dart
        type: type ?? SystemErrorType.unknown,
```

- [ ] **Step 5: Update `detectedType.defaultMessage` reference**

Line 99 — the existing check `detectedType is DefaultErrorType` still works because `DefaultErrorType` is now the sealed class. All sub-enums implement it. No change needed. Verify this compiles.

- [ ] **Step 6: Run test to verify it passes**

Run: `cd dart_falmodel && dart test test/extensions/exception_extensions_test.dart`
Expected: All tests PASS

- [ ] **Step 7: Commit**

```bash
git add dart_falmodel/lib/extensions/exception_extensions.dart dart_falmodel/test/extensions/exception_extensions_test.dart
git commit -m "feat(falmodel)!: update _detectErrorType to use new sealed error type sub-enums

BREAKING CHANGE: _detectErrorType now returns sub-enum values like
SystemErrorType.unknown instead of DefaultErrorType.unknown."
```

---

### Task 4: Update `result.dart` reference

**Files:**
- Modify: `dart_falmodel/lib/models/result.dart:239`

- [ ] **Step 1: Update the single reference**

In `dart_falmodel/lib/models/result.dart`, line 239, replace:

```dart
          type: DefaultErrorType.unexpected,
```

with:

```dart
          type: SystemErrorType.unexpected,
```

- [ ] **Step 2: Run full analyzer**

Run: `cd dart_falmodel && dart analyze`
Expected: No errors. This confirms no other references to the old `DefaultErrorType.xxx` values remain.

- [ ] **Step 3: Run all tests**

Run: `cd dart_falmodel && dart test`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add dart_falmodel/lib/models/result.dart
git commit -m "feat(falmodel)!: update Result.swap to use SystemErrorType.unexpected"
```

---

### Task 5: Final verification

- [ ] **Step 1: Run full package analysis**

Run: `cd dart_falmodel && dart analyze`
Expected: No errors, no warnings related to DefaultErrorType

- [ ] **Step 2: Run all tests in the package**

Run: `cd dart_falmodel && dart test`
Expected: All tests PASS

- [ ] **Step 3: Run analysis on dependent packages**

Run: `cd dart_falconnect && dart analyze`
Expected: No errors (dart_falconnect uses `NetworkErrorType`, not `DefaultErrorType` directly)

- [ ] **Step 4: Verify downstream re-export**

Run: `dart analyze dart_falmodel/lib/dart_falmodel.dart`
Expected: No errors — sealed class and all sub-enums are exported via `exceptions/exceptions.dart` → `common_exception.dart`
