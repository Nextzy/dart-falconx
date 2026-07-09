# TypeID Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve TypeID implementation with Freezed model, strict spec compliance, idiomatic Dart patterns, and convenience API methods.

**Architecture:** Three files in `dart_faltool/lib/utils/typeid/` are modified independently: `Base32` gets code quality fixes, `DecodedTypeId` becomes a Freezed model, `TypeId` gets strict validation and new convenience methods. A `build.yaml` is added to configure generated file output paths.

**Tech Stack:** Dart, Freezed, uuid package, build_runner

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `dart_faltool/pubspec.yaml` | Modify | Add `freezed` dev dependency |
| `dart_faltool/build.yaml` | Create | Configure generated file output to `generated/` subdirectory |
| `dart_faltool/lib/utils/typeid/base32.dart` | Modify | Code quality: doc comment, named constant, StringBuffer |
| `dart_faltool/lib/utils/typeid/decoded_typeid.dart` | Rewrite | Convert to Freezed model with `toString()` |
| `dart_faltool/lib/utils/typeid/typeid.dart` | Modify | Strict prefix validation, explicit catch, `isValid`, `decodeOrNull` |
| `dart_faltool/test/utils/typeid/base32_test.dart` | Create | Tests for Base32 encode/decode |
| `dart_faltool/test/utils/typeid/typeid_test.dart` | Create | Tests for TypeId generate/decode/isValid/decodeOrNull |

---

### Task 1: Add Freezed dev dependency and build.yaml

**Files:**
- Modify: `dart_faltool/pubspec.yaml`
- Create: `dart_faltool/build.yaml`

- [ ] **Step 1: Add `freezed` to dev_dependencies in pubspec.yaml**

In `dart_faltool/pubspec.yaml`, add `freezed` under `dev_dependencies` (matching the version used in `dart_falmodel`):

```yaml
dev_dependencies:
  build_runner: ^2.15.1
  freezed: ^4.0.0-dev.3
  test: ^1.31.2
  very_good_analysis: ^10.3.0
```

- [ ] **Step 2: Create build.yaml for generated file output paths**

Create `dart_faltool/build.yaml` matching the pattern used in `dart_falmodel/build.yaml`:

```yaml
targets:
  $default:
    builders:
      freezed:
        enabled: true
        options:
          build_extensions:
            'lib/{{path}}/{{file}}.dart': 'lib/{{path}}/generated/{{file}}.freezed.dart'
```

- [ ] **Step 3: Run `dart pub get` to install the new dependency**

Run: `cd dart_faltool && dart pub get`
Expected: Resolving dependencies... Got dependencies!

- [ ] **Step 4: Commit**

```bash
git add dart_faltool/pubspec.yaml dart_faltool/build.yaml
git commit -m "build(faltool): add freezed dev dependency and build.yaml"
```

---

### Task 2: Improve Base32 — code quality fixes

**Files:**
- Modify: `dart_faltool/lib/utils/typeid/base32.dart`
- Create: `dart_faltool/test/utils/typeid/base32_test.dart`

- [ ] **Step 1: Write failing tests for Base32**

Create `dart_faltool/test/utils/typeid/base32_test.dart`:

```dart
import 'dart:typed_data';

import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

void main() {
  group('Base32', () {
    group('encode', () {
      test('encodes 16-byte UUID to 26-char base32 string', () {
        // All zeros
        final zeros = Uint8List(16);
        expect(Base32.encode(zeros), '00000000000000000000000000');

        // All 0xFF (max value)
        final maxBytes = Uint8List.fromList(List.filled(16, 0xFF));
        expect(Base32.encode(maxBytes).length, 26);
      });

      test('throws ArgumentError for non-16-byte input', () {
        expect(() => Base32.encode(Uint8List(0)), throwsArgumentError);
        expect(() => Base32.encode(Uint8List(15)), throwsArgumentError);
        expect(() => Base32.encode(Uint8List(17)), throwsArgumentError);
      });

      test('encode and decode are inverse operations', () {
        final original = Uint8List.fromList([
          0x01, 0x89, 0x6b, 0x3a, 0x56, 0x80, //
          0x72, 0x1c, 0x10, 0x2e, 0x31, 0x5e,
          0x6f, 0xab, 0xc3, 0x40,
        ]);
        final encoded = Base32.encode(original);
        final decoded = Base32.decode(encoded);
        expect(decoded, original);
      });
    });

    group('decode', () {
      test('decodes 26-char base32 string to 16 bytes', () {
        final result = Base32.decode('00000000000000000000000000');
        expect(result, Uint8List(16));
      });

      test('throws FormatException for wrong length', () {
        expect(() => Base32.decode('short'), throwsFormatException);
        expect(
          () => Base32.decode('000000000000000000000000000'),
          throwsFormatException,
        );
      });

      test('throws FormatException for overflow (exceeds 128 bits)', () {
        // First char '8' (code 56) exceeds max '7' (code 55)
        expect(
          () => Base32.decode('80000000000000000000000000'),
          throwsFormatException,
        );
      });

      test('throws FormatException for invalid characters', () {
        // 'l', 'i', 'o', 'u' are not in the TypeID base32 alphabet
        expect(
          () => Base32.decode('l0000000000000000000000000'),
          throwsFormatException,
        );
      });
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they pass (existing encode/decode logic is correct)**

Run: `cd dart_faltool && dart test test/utils/typeid/base32_test.dart`
Expected: All tests pass (the underlying logic is correct, we're only changing code style)

- [ ] **Step 3: Apply code quality fixes to base32.dart**

Replace the full contents of `dart_faltool/lib/utils/typeid/base32.dart` with:

```dart
import 'dart:typed_data';

/// Implements base32 encoding and decoding modified to conform with the
/// [TypeID specification](https://github.com/jetify-com/typeid/tree/main/spec#base32-encoding)
class Base32 {
  static const String alphabet = '0123456789abcdefghjkmnpqrstvwxyz';

  /// ASCII code of '7' — the highest valid first character.
  /// Values above this would produce a UUID exceeding 128 bits.
  static const int _maxFirstCharCode = 55;

  static final Uint8List dec = (() {
    final dec = List<int>.filled(256, 0xFF);

    for (int i = 0; i < alphabet.length; i++) {
      dec[alphabet.codeUnitAt(i)] = i;
    }

    return Uint8List.fromList(dec);
  })();

  /// Encodes a UUID to a base32 string
  static String encode(Uint8List src) {
    if (src.length != 16) {
      throw ArgumentError('Invalid length: source must be 16 bytes');
    }

    final dst = StringBuffer();

    // 10 byte timestamp
    dst.writeCharCode(alphabet.codeUnitAt((src[0] & 224) >> 5));
    dst.writeCharCode(alphabet.codeUnitAt(src[0] & 31));
    dst.writeCharCode(alphabet.codeUnitAt((src[1] & 248) >> 3));
    dst.writeCharCode(alphabet.codeUnitAt(((src[1] & 7) << 2) | ((src[2] & 192) >> 6)));
    dst.writeCharCode(alphabet.codeUnitAt((src[2] & 62) >> 1));
    dst.writeCharCode(alphabet.codeUnitAt(((src[2] & 1) << 4) | ((src[3] & 240) >> 4)));
    dst.writeCharCode(alphabet.codeUnitAt(((src[3] & 15) << 1) | ((src[4] & 128) >> 7)));
    dst.writeCharCode(alphabet.codeUnitAt((src[4] & 124) >> 2));
    dst.writeCharCode(alphabet.codeUnitAt(((src[4] & 3) << 3) | ((src[5] & 224) >> 5)));
    dst.writeCharCode(alphabet.codeUnitAt(src[5] & 31));

    // 16 bytes of randomness
    dst.writeCharCode(alphabet.codeUnitAt((src[6] & 248) >> 3));
    dst.writeCharCode(alphabet.codeUnitAt(((src[6] & 7) << 2) | ((src[7] & 192) >> 6)));
    dst.writeCharCode(alphabet.codeUnitAt((src[7] & 62) >> 1));
    dst.writeCharCode(alphabet.codeUnitAt(((src[7] & 1) << 4) | ((src[8] & 240) >> 4)));
    dst.writeCharCode(alphabet.codeUnitAt(((src[8] & 15) << 1) | ((src[9] & 128) >> 7)));
    dst.writeCharCode(alphabet.codeUnitAt((src[9] & 124) >> 2));
    dst.writeCharCode(alphabet.codeUnitAt(((src[9] & 3) << 3) | ((src[10] & 224) >> 5)));
    dst.writeCharCode(alphabet.codeUnitAt(src[10] & 31));
    dst.writeCharCode(alphabet.codeUnitAt((src[11] & 248) >> 3));
    dst.writeCharCode(alphabet.codeUnitAt(((src[11] & 7) << 2) | ((src[12] & 192) >> 6)));
    dst.writeCharCode(alphabet.codeUnitAt((src[12] & 62) >> 1));
    dst.writeCharCode(alphabet.codeUnitAt(((src[12] & 1) << 4) | ((src[13] & 240) >> 4)));
    dst.writeCharCode(alphabet.codeUnitAt(((src[13] & 15) << 1) | ((src[14] & 128) >> 7)));
    dst.writeCharCode(alphabet.codeUnitAt((src[14] & 124) >> 2));
    dst.writeCharCode(alphabet.codeUnitAt(((src[14] & 3) << 3) | ((src[15] & 224) >> 5)));
    dst.writeCharCode(alphabet.codeUnitAt(src[15] & 31));

    return dst.toString();
  }

  /// Decodes a base32 string to a UUID
  static Uint8List decode(String s) {
    if (s.length != 26) {
      throw FormatException('Invalid length');
    }

    if (s.codeUnitAt(0) > _maxFirstCharCode) {
      throw FormatException('Exceeds 128 bits');
    }

    // Convert the string to a list of its character codes.
    final List<int> v = s.codeUnits;

    // Validate all characters are valid base32 characters
    for (var charCode in v) {
      if (dec[charCode] == 0xFF) {
        throw FormatException('Invalid base32 character');
      }
    }

    // Prepare the output byte array.
    final Uint8List id = Uint8List(16);

    // Decode the base32 string back to bytes.
    id[0] = (dec[v[0]] << 5) | dec[v[1]];
    id[1] = (dec[v[2]] << 3) | (dec[v[3]] >> 2);
    id[2] = ((dec[v[3]] & 3) << 6) | (dec[v[4]] << 1) | (dec[v[5]] >> 4);
    id[3] = ((dec[v[5]] & 15) << 4) | (dec[v[6]] >> 1);
    id[4] = ((dec[v[6]] & 1) << 7) | (dec[v[7]] << 2) | (dec[v[8]] >> 3);
    id[5] = ((dec[v[8]] & 7) << 5) | dec[v[9]];

    id[6] = (dec[v[10]] << 3) | (dec[v[11]] >> 2);
    id[7] = ((dec[v[11]] & 3) << 6) | (dec[v[12]] << 1) | (dec[v[13]] >> 4);
    id[8] = ((dec[v[13]] & 15) << 4) | (dec[v[14]] >> 1);
    id[9] = ((dec[v[14]] & 1) << 7) | (dec[v[15]] << 2) | (dec[v[16]] >> 3);
    id[10] = ((dec[v[16]] & 7) << 5) | dec[v[17]];
    id[11] = (dec[v[18]] << 3) | (dec[v[19]] >> 2);
    id[12] = ((dec[v[19]] & 3) << 6) | (dec[v[20]] << 1) | (dec[v[21]] >> 4);
    id[13] = ((dec[v[21]] & 15) << 4) | (dec[v[22]] >> 1);
    id[14] = ((dec[v[22]] & 1) << 7) | (dec[v[23]] << 2) | (dec[v[24]] >> 3);
    id[15] = ((dec[v[24]] & 7) << 5) | dec[v[25]];

    return id;
  }
}
```

- [ ] **Step 4: Run tests to verify nothing broke**

Run: `cd dart_faltool && dart test test/utils/typeid/base32_test.dart`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add dart_faltool/lib/utils/typeid/base32.dart dart_faltool/test/utils/typeid/base32_test.dart
git commit -m "refactor(faltool): improve Base32 code quality — doc comment, named constant, StringBuffer"
```

---

### Task 3: Convert DecodedTypeId to Freezed model

**Files:**
- Rewrite: `dart_faltool/lib/utils/typeid/decoded_typeid.dart`

- [ ] **Step 1: Rewrite decoded_typeid.dart as Freezed model**

Replace the full contents of `dart_faltool/lib/utils/typeid/decoded_typeid.dart` with:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'generated/decoded_typeid.freezed.dart';

@freezed
class DecodedTypeId with _$DecodedTypeId {
  const DecodedTypeId._();

  const factory DecodedTypeId({
    required String prefix,
    required String suffix,
    required UuidValue uuid,
  }) = _DecodedTypeId;

  @override
  String toString() => prefix.isEmpty ? suffix : '${prefix}_$suffix';
}
```

- [ ] **Step 2: Run build_runner to generate the Freezed code**

Run: `cd dart_faltool && dart run build_runner build -d`
Expected: Generates `dart_faltool/lib/utils/typeid/generated/decoded_typeid.freezed.dart` successfully

- [ ] **Step 3: Verify the generated file exists**

Run: `ls dart_faltool/lib/utils/typeid/generated/decoded_typeid.freezed.dart`
Expected: File exists

- [ ] **Step 4: Run dart analyze to check for errors**

Run: `cd dart_faltool && dart analyze`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add dart_faltool/lib/utils/typeid/decoded_typeid.dart dart_faltool/lib/utils/typeid/generated/
git commit -m "refactor(faltool): convert DecodedTypeId to Freezed model with toString()"
```

---

### Task 4: Improve TypeId — strict validation, explicit catch, convenience methods

**Files:**
- Modify: `dart_faltool/lib/utils/typeid/typeid.dart`
- Create: `dart_faltool/test/utils/typeid/typeid_test.dart`

- [ ] **Step 1: Write failing tests for TypeId improvements**

Create `dart_faltool/test/utils/typeid/typeid_test.dart`:

```dart
import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

void main() {
  group('TypeId', () {
    group('generate', () {
      test('generates valid TypeID with prefix', () {
        final id = TypeId.generate('user');
        expect(id.startsWith('user_'), isTrue);
        // prefix(4) + separator(1) + base32(26) = 31
        expect(id.length, 31);
      });

      test('generates valid TypeID without prefix', () {
        final id = TypeId.generate('');
        // base32 only, no separator
        expect(id.length, 26);
        expect(id.contains('_'), isFalse);
      });

      test('throws FormatException for prefix with underscore', () {
        expect(
          () => TypeId.generate('user_account'),
          throwsFormatException,
        );
      });

      test('throws FormatException for uppercase prefix', () {
        expect(() => TypeId.generate('User'), throwsFormatException);
      });

      test('throws FormatException for prefix longer than 63 chars', () {
        expect(
          () => TypeId.generate('a' * 64),
          throwsFormatException,
        );
      });

      test('accepts max length prefix of 63 chars', () {
        final id = TypeId.generate('a' * 63);
        expect(id.startsWith('${'a' * 63}_'), isTrue);
      });
    });

    group('decode', () {
      test('decodes TypeID with prefix', () {
        final generated = TypeId.generate('order');
        final decoded = TypeId.decode(generated);

        expect(decoded.prefix, 'order');
        expect(decoded.suffix.length, 26);
        expect(decoded.toString(), generated);
      });

      test('decodes TypeID without prefix', () {
        final generated = TypeId.generate('');
        final decoded = TypeId.decode(generated);

        expect(decoded.prefix, isEmpty);
        expect(decoded.suffix.length, 26);
        expect(decoded.toString(), generated);
      });

      test('throws FormatException for empty suffix with separator', () {
        expect(() => TypeId.decode('_'), throwsFormatException);
      });

      test('throws FormatException for invalid base32 suffix', () {
        expect(
          () => TypeId.decode('user_!!!!!!!!!!!!!!!!!!!!!!!!!!'),
          throwsFormatException,
        );
      });
    });

    group('isValid', () {
      test('returns true for valid TypeID with prefix', () {
        final id = TypeId.generate('user');
        expect(TypeId.isValid(id), isTrue);
      });

      test('returns true for valid TypeID without prefix', () {
        final id = TypeId.generate('');
        expect(TypeId.isValid(id), isTrue);
      });

      test('returns false for invalid TypeID', () {
        expect(TypeId.isValid(''), isFalse);
        expect(TypeId.isValid('not-valid!!'), isFalse);
        expect(TypeId.isValid('user_short'), isFalse);
      });
    });

    group('decodeOrNull', () {
      test('returns DecodedTypeId for valid input', () {
        final id = TypeId.generate('test');
        final decoded = TypeId.decodeOrNull(id);
        expect(decoded, isNotNull);
        expect(decoded!.prefix, 'test');
      });

      test('returns null for invalid input', () {
        expect(TypeId.decodeOrNull(''), isNull);
        expect(TypeId.decodeOrNull('invalid!!'), isNull);
        expect(TypeId.decodeOrNull('user_short'), isNull);
      });
    });

    group('DecodedTypeId', () {
      test('toString reconstructs TypeID with prefix', () {
        final id = TypeId.generate('user');
        final decoded = TypeId.decode(id);
        expect(decoded.toString(), id);
      });

      test('toString returns suffix only when no prefix', () {
        final id = TypeId.generate('');
        final decoded = TypeId.decode(id);
        expect(decoded.toString(), id);
      });

      test('equality works via Freezed', () {
        final id = TypeId.generate('user');
        final a = TypeId.decode(id);
        final b = TypeId.decode(id);
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail (isValid and decodeOrNull don't exist yet)**

Run: `cd dart_faltool && dart test test/utils/typeid/typeid_test.dart`
Expected: Compilation error — `isValid` and `decodeOrNull` are not defined

- [ ] **Step 3: Update typeid.dart with all improvements**

Replace the full contents of `dart_faltool/lib/utils/typeid/typeid.dart` with:

```dart
import 'package:dart_faltool/lib.dart';

export 'base32.dart';
export 'decoded_typeid.dart';

/// A class to generate and decode TypeIDs per the [specification](https://github.com/jetify-com/typeid/tree/main/spec)
class TypeId {
  static const _separator = '_';

  /// Generates a TypeID with the given prefix. Provide an empty string for
  /// no prefix. Prefixes must be lowercase letters [a-z] and less than 64
  /// characters.
  static String generate(String prefix) {
    _checkPrefix(prefix);

    final v7 = uuid.v7obj();
    final base32Encoded = Base32.encode(v7.toBytes());

    if (prefix.isEmpty) {
      return base32Encoded;
    } else {
      return '$prefix$_separator$base32Encoded';
    }
  }

  /// Decodes a TypeID into a [DecodedTypeId]. Throws [FormatException] if
  /// the provided TypeID is invalid.
  static DecodedTypeId decode(String typeid) {
    final parts = _splitLast(typeid, _separator);

    if (parts.length == 1) {
      parts.insert(0, '');
    } else if (parts.length == 2) {
      if (parts[0].isEmpty) {
        throw const FormatException(
          'Invalid typeid. separator cannot be present if prefix is empty',
        );
      }
    } else {
      throw FormatException('Invalid typeid. prefix cannot contain $_separator');
    }

    final prefix = parts[0];
    final suffix = parts[1];

    _checkPrefix(prefix);

    try {
      final base32Decoded = Base32.decode(suffix);
      final uuidValue = UuidValue.fromByteList(base32Decoded);

      return DecodedTypeId(prefix: prefix, suffix: suffix, uuid: uuidValue);
    } on FormatException {
      rethrow;
    } on ArgumentError catch (e) {
      throw FormatException('Invalid suffix: $e');
    }
  }

  /// Returns `true` if the given string is a valid TypeID.
  static bool isValid(String typeid) {
    try {
      decode(typeid);
      return true;
    } on FormatException {
      return false;
    } on ArgumentError {
      return false;
    }
  }

  /// Decodes a TypeID, returning `null` if the input is invalid
  /// instead of throwing.
  static DecodedTypeId? decodeOrNull(String typeid) {
    try {
      return decode(typeid);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static void _checkPrefix(String prefix) {
    if (prefix.length > 63) {
      throw FormatException('Prefix too long');
    }

    if (prefix.startsWith(_separator) || prefix.endsWith(_separator)) {
      throw FormatException('Prefix cannot start or end with $_separator');
    }

    // ensure all characters fall within [a-z]
    final isValid = prefix.runes.every(
      (code) => code > 96 && code < 123,
    );

    if (!isValid) {
      throw FormatException('Prefix must only contain lowercase letters [a-z]');
    }
  }

  static List<String> _splitLast(String input, String delimiter) {
    int lastIndex = input.lastIndexOf(delimiter);
    if (lastIndex == -1) {
      return [input];
    }
    String beforeLast = input.substring(0, lastIndex);
    String afterLast = input.substring(lastIndex + delimiter.length);
    return [beforeLast, afterLast];
  }
}
```

- [ ] **Step 4: Run all TypeID tests**

Run: `cd dart_faltool && dart test test/utils/typeid/`
Expected: All tests pass

- [ ] **Step 5: Run dart analyze**

Run: `cd dart_faltool && dart analyze`
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add dart_faltool/lib/utils/typeid/typeid.dart dart_faltool/test/utils/typeid/typeid_test.dart
git commit -m "feat(faltool): improve TypeId — strict prefix validation, isValid, decodeOrNull"
```

---

### Task 5: Final verification

**Files:** None (verification only)

- [ ] **Step 1: Run all dart_faltool tests**

Run: `cd dart_faltool && dart test`
Expected: All tests pass (existing + new)

- [ ] **Step 2: Run dart analyze on entire package**

Run: `cd dart_faltool && dart analyze`
Expected: No issues found

- [ ] **Step 3: Verify build_runner still works clean**

Run: `cd dart_faltool && dart run build_runner build -d`
Expected: Succeeds with no errors
