# FalconDynamicTypeCastExtension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement smart type coercion extension on `dynamic` for JSON parsing, providing `asType`, `asTypeOrNull`, and `asTypeOr(default)` methods for 11 types (33 methods total).

**Architecture:** Single extension `FalconDynamicTypeCastExtension on dynamic` with private top-level coercion functions per type. Each coercion function contains the smart conversion logic; the public methods delegate to it and handle exceptions. Tests grouped by target type.

**Tech Stack:** Dart, `big_decimal` package (already a dependency), `test` package

**Spec:** `docs/superpowers/specs/2026-04-16-dynamic-type-cast-extension-design.md`

---

### Task 1: Scaffold extension file, export, and test file

**Files:**
- Modify: `dart_faltool/lib/extensions/dynamic_extensions.dart`
- Modify: `dart_faltool/lib/extensions/extensions.dart`
- Create: `dart_faltool/test/extensions/dynamic_extensions_test.dart`

- [ ] **Step 1: Write the extension scaffold with the helper and asString group**

Replace the contents of `dart_faltool/lib/extensions/dynamic_extensions.dart` with:

```dart
import 'package:dart_faltool/lib.dart';
import 'package:big_decimal/big_decimal.dart';

Never _throwFormatException(dynamic value, String targetType) {
  throw FormatException(
    "Cannot convert '$value' (${value.runtimeType}) to $targetType",
  );
}

extension FalconDynamicTypeCastExtension on dynamic {
  // ── String ──────────────────────────────────────────────

  String get asString {
    final v = this;
    if (v == null) _throwFormatException(v, 'String');
    return v.toString();
  }

  String? get asStringOrNull {
    final v = this;
    if (v == null) return null;
    return v.toString();
  }

  String asStringOr(String defaultValue) {
    final v = this;
    if (v == null) return defaultValue;
    return v.toString();
  }
}
```

- [ ] **Step 2: Add export to extensions barrel**

In `dart_faltool/lib/extensions/extensions.dart`, add `export 'dynamic_extensions.dart';` in alphabetical order (after `date_time_extension.dart`):

```dart
export 'base64_extensions.dart';
export 'date_time_extension.dart';
export 'dynamic_extensions.dart';
export 'enum_extensions.dart';
```

- [ ] **Step 3: Write test scaffold with asString tests**

Create `dart_faltool/test/extensions/dynamic_extensions_test.dart`:

```dart
import 'package:big_decimal/big_decimal.dart';
import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

void main() {
  group('FalconDynamicTypeCastExtension', () {
    // ── asString ──────────────────────────────────────────

    group('asString', () {
      test('converts non-null values to String via toString()', () {
        expect((42 as dynamic).asString, '42');
        expect((3.14 as dynamic).asString, '3.14');
        expect((true as dynamic).asString, 'true');
        expect(('hello' as dynamic).asString, 'hello');
      });

      test('throws FormatException for null', () {
        expect(() => (null as dynamic).asString, throwsFormatException);
      });
    });

    group('asStringOrNull', () {
      test('converts non-null values to String', () {
        expect((42 as dynamic).asStringOrNull, '42');
      });

      test('returns null for null', () {
        expect((null as dynamic).asStringOrNull, isNull);
      });
    });

    group('asStringOr', () {
      test('converts non-null values to String', () {
        expect((42 as dynamic).asStringOr('fallback'), '42');
      });

      test('returns default for null', () {
        expect((null as dynamic).asStringOr('fallback'), 'fallback');
      });
    });
  });
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd dart_faltool && dart test test/extensions/dynamic_extensions_test.dart`
Expected: All 6 tests PASS

- [ ] **Step 5: Run analyze**

Run: `cd dart_faltool && dart analyze lib/extensions/dynamic_extensions.dart`
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add dart_faltool/lib/extensions/dynamic_extensions.dart \
       dart_faltool/lib/extensions/extensions.dart \
       dart_faltool/test/extensions/dynamic_extensions_test.dart
git commit -m "feat(faltool): scaffold dynamic type cast extension with asString"
```

---

### Task 2: Implement numeric coercions (asInt, asDouble, asNum)

**Files:**
- Modify: `dart_faltool/lib/extensions/dynamic_extensions.dart`
- Modify: `dart_faltool/test/extensions/dynamic_extensions_test.dart`

- [ ] **Step 1: Write failing tests for asInt**

Append inside the `FalconDynamicTypeCastExtension` group in the test file:

```dart
    // ── asInt ──────────────────────────────────────────

    group('asInt', () {
      test('returns int directly', () {
        expect((42 as dynamic).asInt, 42);
        expect((-1 as dynamic).asInt, -1);
        expect((0 as dynamic).asInt, 0);
      });

      test('truncates double to int', () {
        expect((3.14 as dynamic).asInt, 3);
        expect((3.99 as dynamic).asInt, 3);
        expect((-2.7 as dynamic).asInt, -2);
      });

      test('parses String to int', () {
        expect(('123' as dynamic).asInt, 123);
        expect(('-456' as dynamic).asInt, -456);
      });

      test('converts bool to int', () {
        expect((true as dynamic).asInt, 1);
        expect((false as dynamic).asInt, 0);
      });

      test('converts BigInt to int', () {
        expect((BigInt.from(99) as dynamic).asInt, 99);
      });

      test('throws FormatException for null', () {
        expect(() => (null as dynamic).asInt, throwsFormatException);
      });

      test('throws FormatException for invalid String', () {
        expect(() => ('abc' as dynamic).asInt, throwsFormatException);
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (<int>[] as dynamic).asInt, throwsFormatException);
      });
    });

    group('asIntOrNull', () {
      test('returns int for valid values', () {
        expect((42 as dynamic).asIntOrNull, 42);
        expect(('123' as dynamic).asIntOrNull, 123);
      });

      test('returns null for null', () {
        expect((null as dynamic).asIntOrNull, isNull);
      });

      test('returns null for invalid value', () {
        expect(('abc' as dynamic).asIntOrNull, isNull);
      });
    });

    group('asIntOr', () {
      test('returns int for valid values', () {
        expect((42 as dynamic).asIntOr(-1), 42);
      });

      test('returns default for null', () {
        expect((null as dynamic).asIntOr(-1), -1);
      });

      test('returns default for invalid value', () {
        expect(('abc' as dynamic).asIntOr(-1), -1);
      });
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd dart_faltool && dart test test/extensions/dynamic_extensions_test.dart`
Expected: FAIL — `asInt` not defined

- [ ] **Step 3: Implement asInt coercion**

Add to `dynamic_extensions.dart` inside the extension, after the String group:

```dart
  // ── int ─────────────────────────────────────────────

  int get asInt {
    final v = this;
    if (v == null) _throwFormatException(v, 'int');
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is bool) return v ? 1 : 0;
    if (v is BigInt) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    _throwFormatException(v, 'int');
  }

  int? get asIntOrNull {
    try {
      return asInt;
    } on FormatException {
      return null;
    }
  }

  int asIntOr(int defaultValue) {
    try {
      return asInt;
    } on FormatException {
      return defaultValue;
    }
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd dart_faltool && dart test test/extensions/dynamic_extensions_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Write failing tests for asDouble**

Append inside the `FalconDynamicTypeCastExtension` group:

```dart
    // ── asDouble ──────────────────────────────────────

    group('asDouble', () {
      test('returns double directly', () {
        expect((3.14 as dynamic).asDouble, 3.14);
      });

      test('converts int to double', () {
        expect((42 as dynamic).asDouble, 42.0);
      });

      test('parses String to double', () {
        expect(('3.14' as dynamic).asDouble, 3.14);
        expect(('42' as dynamic).asDouble, 42.0);
      });

      test('converts bool to double', () {
        expect((true as dynamic).asDouble, 1.0);
        expect((false as dynamic).asDouble, 0.0);
      });

      test('converts BigDecimal to double', () {
        expect(
          (BigDecimal.parse('3.14') as dynamic).asDouble,
          closeTo(3.14, 0.001),
        );
      });

      test('throws FormatException for null', () {
        expect(() => (null as dynamic).asDouble, throwsFormatException);
      });

      test('throws FormatException for invalid String', () {
        expect(() => ('abc' as dynamic).asDouble, throwsFormatException);
      });
    });

    group('asDoubleOrNull', () {
      test('returns double for valid values', () {
        expect((3.14 as dynamic).asDoubleOrNull, 3.14);
      });

      test('returns null for null', () {
        expect((null as dynamic).asDoubleOrNull, isNull);
      });

      test('returns null for invalid value', () {
        expect(('abc' as dynamic).asDoubleOrNull, isNull);
      });
    });

    group('asDoubleOr', () {
      test('returns double for valid values', () {
        expect((3.14 as dynamic).asDoubleOr(0.0), 3.14);
      });

      test('returns default for null', () {
        expect((null as dynamic).asDoubleOr(0.0), 0.0);
      });

      test('returns default for invalid value', () {
        expect(('abc' as dynamic).asDoubleOr(0.0), 0.0);
      });
    });
```

- [ ] **Step 6: Implement asDouble coercion**

Add to the extension after the int group:

```dart
  // ── double ──────────────────────────────────────────

  double get asDouble {
    final v = this;
    if (v == null) _throwFormatException(v, 'double');
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is bool) return v ? 1.0 : 0.0;
    if (v is BigDecimal) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
    _throwFormatException(v, 'double');
  }

  double? get asDoubleOrNull {
    try {
      return asDouble;
    } on FormatException {
      return null;
    }
  }

  double asDoubleOr(double defaultValue) {
    try {
      return asDouble;
    } on FormatException {
      return defaultValue;
    }
  }
```

- [ ] **Step 7: Write failing tests for asNum**

Append inside the group:

```dart
    // ── asNum ─────────────────────────────────────────

    group('asNum', () {
      test('returns num directly', () {
        expect((42 as dynamic).asNum, 42);
        expect((3.14 as dynamic).asNum, 3.14);
      });

      test('parses String to num', () {
        expect(('42' as dynamic).asNum, 42);
        expect(('3.14' as dynamic).asNum, 3.14);
      });

      test('converts bool to num', () {
        expect((true as dynamic).asNum, 1);
        expect((false as dynamic).asNum, 0);
      });

      test('throws FormatException for null', () {
        expect(() => (null as dynamic).asNum, throwsFormatException);
      });

      test('throws FormatException for invalid String', () {
        expect(() => ('abc' as dynamic).asNum, throwsFormatException);
      });
    });

    group('asNumOrNull', () {
      test('returns num for valid values', () {
        expect((42 as dynamic).asNumOrNull, 42);
      });

      test('returns null for null', () {
        expect((null as dynamic).asNumOrNull, isNull);
      });

      test('returns null for invalid value', () {
        expect(('abc' as dynamic).asNumOrNull, isNull);
      });
    });

    group('asNumOr', () {
      test('returns num for valid values', () {
        expect((42 as dynamic).asNumOr(0), 42);
      });

      test('returns default for null', () {
        expect((null as dynamic).asNumOr(0), 0);
      });

      test('returns default for invalid value', () {
        expect(('abc' as dynamic).asNumOr(0), 0);
      });
    });
```

- [ ] **Step 8: Implement asNum coercion**

Add to the extension after the double group:

```dart
  // ── num ─────────────────────────────────────────────

  num get asNum {
    final v = this;
    if (v == null) _throwFormatException(v, 'num');
    if (v is num) return v;
    if (v is bool) return v ? 1 : 0;
    if (v is String) {
      final parsed = num.tryParse(v);
      if (parsed != null) return parsed;
    }
    _throwFormatException(v, 'num');
  }

  num? get asNumOrNull {
    try {
      return asNum;
    } on FormatException {
      return null;
    }
  }

  num asNumOr(num defaultValue) {
    try {
      return asNum;
    } on FormatException {
      return defaultValue;
    }
  }
```

- [ ] **Step 9: Run all tests and analyze**

Run: `cd dart_faltool && dart test test/extensions/dynamic_extensions_test.dart && dart analyze lib/extensions/dynamic_extensions.dart`
Expected: All tests PASS, no analysis issues

- [ ] **Step 10: Commit**

```bash
git add dart_faltool/lib/extensions/dynamic_extensions.dart \
       dart_faltool/test/extensions/dynamic_extensions_test.dart
git commit -m "feat(faltool): add asInt, asDouble, asNum to dynamic extension"
```

---

### Task 3: Implement asBool

**Files:**
- Modify: `dart_faltool/lib/extensions/dynamic_extensions.dart`
- Modify: `dart_faltool/test/extensions/dynamic_extensions_test.dart`

- [ ] **Step 1: Write failing tests for asBool**

Append inside the `FalconDynamicTypeCastExtension` group:

```dart
    // ── asBool ────────────────────────────────────────

    group('asBool', () {
      test('returns bool directly', () {
        expect((true as dynamic).asBool, true);
        expect((false as dynamic).asBool, false);
      });

      test('parses String to bool', () {
        expect(('true' as dynamic).asBool, true);
        expect(('TRUE' as dynamic).asBool, true);
        expect(('1' as dynamic).asBool, true);
        expect(('false' as dynamic).asBool, false);
        expect(('FALSE' as dynamic).asBool, false);
        expect(('0' as dynamic).asBool, false);
      });

      test('converts num to bool', () {
        expect((1 as dynamic).asBool, true);
        expect((0 as dynamic).asBool, false);
        expect((42 as dynamic).asBool, true);
        expect((-1 as dynamic).asBool, true);
        expect((0.0 as dynamic).asBool, false);
        expect((0.1 as dynamic).asBool, true);
      });

      test('throws FormatException for null', () {
        expect(() => (null as dynamic).asBool, throwsFormatException);
      });

      test('throws FormatException for invalid String', () {
        expect(() => ('maybe' as dynamic).asBool, throwsFormatException);
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (<int>[] as dynamic).asBool, throwsFormatException);
      });
    });

    group('asBoolOrNull', () {
      test('returns bool for valid values', () {
        expect((true as dynamic).asBoolOrNull, true);
        expect(('false' as dynamic).asBoolOrNull, false);
      });

      test('returns null for null', () {
        expect((null as dynamic).asBoolOrNull, isNull);
      });

      test('returns null for invalid value', () {
        expect(('maybe' as dynamic).asBoolOrNull, isNull);
      });
    });

    group('asBoolOr', () {
      test('returns bool for valid values', () {
        expect((true as dynamic).asBoolOr(false), true);
      });

      test('returns default for null', () {
        expect((null as dynamic).asBoolOr(true), true);
      });

      test('returns default for invalid value', () {
        expect(('maybe' as dynamic).asBoolOr(true), true);
      });
    });
```

- [ ] **Step 2: Implement asBool coercion**

Add to the extension:

```dart
  // ── bool ────────────────────────────────────────────

  bool get asBool {
    final v = this;
    if (v == null) _throwFormatException(v, 'bool');
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final lower = v.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    _throwFormatException(v, 'bool');
  }

  bool? get asBoolOrNull {
    try {
      return asBool;
    } on FormatException {
      return null;
    }
  }

  bool asBoolOr(bool defaultValue) {
    try {
      return asBool;
    } on FormatException {
      return defaultValue;
    }
  }
```

- [ ] **Step 3: Run tests and analyze**

Run: `cd dart_faltool && dart test test/extensions/dynamic_extensions_test.dart && dart analyze lib/extensions/dynamic_extensions.dart`
Expected: All tests PASS, no analysis issues

- [ ] **Step 4: Commit**

```bash
git add dart_faltool/lib/extensions/dynamic_extensions.dart \
       dart_faltool/test/extensions/dynamic_extensions_test.dart
git commit -m "feat(faltool): add asBool to dynamic extension"
```

---

### Task 4: Implement large number coercions (asBigInt, asBigDecimal)

**Files:**
- Modify: `dart_faltool/lib/extensions/dynamic_extensions.dart`
- Modify: `dart_faltool/test/extensions/dynamic_extensions_test.dart`

- [ ] **Step 1: Write failing tests for asBigInt**

Append inside the group:

```dart
    // ── asBigInt ──────────────────────────────────────

    group('asBigInt', () {
      test('returns BigInt directly', () {
        expect((BigInt.from(42) as dynamic).asBigInt, BigInt.from(42));
      });

      test('converts int to BigInt', () {
        expect((42 as dynamic).asBigInt, BigInt.from(42));
        expect((0 as dynamic).asBigInt, BigInt.zero);
        expect((-1 as dynamic).asBigInt, BigInt.from(-1));
      });

      test('parses String to BigInt', () {
        expect(
          ('999999999999999999999' as dynamic).asBigInt,
          BigInt.parse('999999999999999999999'),
        );
      });

      test('throws FormatException for null', () {
        expect(() => (null as dynamic).asBigInt, throwsFormatException);
      });

      test('throws FormatException for invalid String', () {
        expect(() => ('abc' as dynamic).asBigInt, throwsFormatException);
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (3.14 as dynamic).asBigInt, throwsFormatException);
      });
    });

    group('asBigIntOrNull', () {
      test('returns BigInt for valid values', () {
        expect((42 as dynamic).asBigIntOrNull, BigInt.from(42));
      });

      test('returns null for null', () {
        expect((null as dynamic).asBigIntOrNull, isNull);
      });

      test('returns null for invalid value', () {
        expect(('abc' as dynamic).asBigIntOrNull, isNull);
      });
    });

    group('asBigIntOr', () {
      test('returns BigInt for valid values', () {
        expect((42 as dynamic).asBigIntOr(BigInt.zero), BigInt.from(42));
      });

      test('returns default for null', () {
        expect((null as dynamic).asBigIntOr(BigInt.zero), BigInt.zero);
      });

      test('returns default for invalid value', () {
        expect(('abc' as dynamic).asBigIntOr(BigInt.zero), BigInt.zero);
      });
    });
```

- [ ] **Step 2: Implement asBigInt coercion**

Add to the extension:

```dart
  // ── BigInt ──────────────────────────────────────────

  BigInt get asBigInt {
    final v = this;
    if (v == null) _throwFormatException(v, 'BigInt');
    if (v is BigInt) return v;
    if (v is int) return BigInt.from(v);
    if (v is String) {
      final parsed = BigInt.tryParse(v);
      if (parsed != null) return parsed;
    }
    _throwFormatException(v, 'BigInt');
  }

  BigInt? get asBigIntOrNull {
    try {
      return asBigInt;
    } on FormatException {
      return null;
    }
  }

  BigInt asBigIntOr(BigInt defaultValue) {
    try {
      return asBigInt;
    } on FormatException {
      return defaultValue;
    }
  }
```

- [ ] **Step 3: Run tests to verify asBigInt passes**

Run: `cd dart_faltool && dart test test/extensions/dynamic_extensions_test.dart`
Expected: All tests PASS

- [ ] **Step 4: Write failing tests for asBigDecimal**

Append inside the group:

```dart
    // ── asBigDecimal ──────────────────────────────────

    group('asBigDecimal', () {
      test('returns BigDecimal directly', () {
        final bd = BigDecimal.parse('3.14');
        expect((bd as dynamic).asBigDecimal, bd);
      });

      test('converts int to BigDecimal', () {
        expect(
          (42 as dynamic).asBigDecimal,
          BigDecimal.parse('42'),
        );
      });

      test('converts double to BigDecimal', () {
        expect(
          (3.14 as dynamic).asBigDecimal.toDouble(),
          closeTo(3.14, 0.001),
        );
      });

      test('parses String to BigDecimal', () {
        expect(
          ('123.456' as dynamic).asBigDecimal,
          BigDecimal.parse('123.456'),
        );
      });

      test('throws FormatException for null', () {
        expect(() => (null as dynamic).asBigDecimal, throwsFormatException);
      });

      test('throws FormatException for invalid String', () {
        expect(() => ('abc' as dynamic).asBigDecimal, throwsFormatException);
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (true as dynamic).asBigDecimal, throwsFormatException);
      });
    });

    group('asBigDecimalOrNull', () {
      test('returns BigDecimal for valid values', () {
        expect(
          (42 as dynamic).asBigDecimalOrNull,
          BigDecimal.parse('42'),
        );
      });

      test('returns null for null', () {
        expect((null as dynamic).asBigDecimalOrNull, isNull);
      });

      test('returns null for invalid value', () {
        expect(('abc' as dynamic).asBigDecimalOrNull, isNull);
      });
    });

    group('asBigDecimalOr', () {
      test('returns BigDecimal for valid values', () {
        expect(
          (42 as dynamic).asBigDecimalOr(BigDecimal.zero),
          BigDecimal.parse('42'),
        );
      });

      test('returns default for null', () {
        expect(
          (null as dynamic).asBigDecimalOr(BigDecimal.zero),
          BigDecimal.zero,
        );
      });

      test('returns default for invalid value', () {
        expect(
          ('abc' as dynamic).asBigDecimalOr(BigDecimal.zero),
          BigDecimal.zero,
        );
      });
    });
```

- [ ] **Step 5: Implement asBigDecimal coercion**

Note: `BigDecimal` has no `fromNum()` factory. Use `BigDecimal.parse(v.toString())` for `num` values and `BigDecimal.tryParse(v)` for strings.

Add to the extension:

```dart
  // ── BigDecimal ──────────────────────────────────────

  BigDecimal get asBigDecimal {
    final v = this;
    if (v == null) _throwFormatException(v, 'BigDecimal');
    if (v is BigDecimal) return v;
    if (v is num) {
      final parsed = BigDecimal.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    if (v is String) {
      final parsed = BigDecimal.tryParse(v);
      if (parsed != null) return parsed;
    }
    _throwFormatException(v, 'BigDecimal');
  }

  BigDecimal? get asBigDecimalOrNull {
    try {
      return asBigDecimal;
    } on FormatException {
      return null;
    }
  }

  BigDecimal asBigDecimalOr(BigDecimal defaultValue) {
    try {
      return asBigDecimal;
    } on FormatException {
      return defaultValue;
    }
  }
```

- [ ] **Step 6: Run all tests and analyze**

Run: `cd dart_faltool && dart test test/extensions/dynamic_extensions_test.dart && dart analyze lib/extensions/dynamic_extensions.dart`
Expected: All tests PASS, no analysis issues

- [ ] **Step 7: Commit**

```bash
git add dart_faltool/lib/extensions/dynamic_extensions.dart \
       dart_faltool/test/extensions/dynamic_extensions_test.dart
git commit -m "feat(faltool): add asBigInt, asBigDecimal to dynamic extension"
```

---

### Task 5: Implement temporal coercions (asDateTime, asDuration)

**Files:**
- Modify: `dart_faltool/lib/extensions/dynamic_extensions.dart`
- Modify: `dart_faltool/test/extensions/dynamic_extensions_test.dart`

- [ ] **Step 1: Write failing tests for asDateTime**

Append inside the group:

```dart
    // ── asDateTime ────────────────────────────────────

    group('asDateTime', () {
      test('returns DateTime directly', () {
        final dt = DateTime(2026, 4, 16);
        expect((dt as dynamic).asDateTime, dt);
      });

      test('parses ISO 8601 String to DateTime', () {
        expect(
          ('2026-04-16T10:30:00.000Z' as dynamic).asDateTime,
          DateTime.utc(2026, 4, 16, 10, 30),
        );
      });

      test('parses date-only String to DateTime', () {
        expect(
          ('2026-04-16' as dynamic).asDateTime,
          DateTime(2026, 4, 16),
        );
      });

      test('converts int (milliseconds since epoch) to DateTime', () {
        final epoch = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;
        expect(
          (epoch as dynamic).asDateTime,
          DateTime.fromMillisecondsSinceEpoch(epoch),
        );
      });

      test('throws FormatException for null', () {
        expect(() => (null as dynamic).asDateTime, throwsFormatException);
      });

      test('throws FormatException for invalid String', () {
        expect(
          () => ('not-a-date' as dynamic).asDateTime,
          throwsFormatException,
        );
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (true as dynamic).asDateTime, throwsFormatException);
      });
    });

    group('asDateTimeOrNull', () {
      test('returns DateTime for valid values', () {
        expect(
          ('2026-04-16' as dynamic).asDateTimeOrNull,
          DateTime(2026, 4, 16),
        );
      });

      test('returns null for null', () {
        expect((null as dynamic).asDateTimeOrNull, isNull);
      });

      test('returns null for invalid value', () {
        expect(('not-a-date' as dynamic).asDateTimeOrNull, isNull);
      });
    });

    group('asDateTimeOr', () {
      final fallback = DateTime(2000);

      test('returns DateTime for valid values', () {
        expect(
          ('2026-04-16' as dynamic).asDateTimeOr(fallback),
          DateTime(2026, 4, 16),
        );
      });

      test('returns default for null', () {
        expect((null as dynamic).asDateTimeOr(fallback), fallback);
      });

      test('returns default for invalid value', () {
        expect(('not-a-date' as dynamic).asDateTimeOr(fallback), fallback);
      });
    });
```

- [ ] **Step 2: Implement asDateTime coercion**

Add to the extension:

```dart
  // ── DateTime ────────────────────────────────────────

  DateTime get asDateTime {
    final v = this;
    if (v == null) _throwFormatException(v, 'DateTime');
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
    }
    _throwFormatException(v, 'DateTime');
  }

  DateTime? get asDateTimeOrNull {
    try {
      return asDateTime;
    } on FormatException {
      return null;
    }
  }

  DateTime asDateTimeOr(DateTime defaultValue) {
    try {
      return asDateTime;
    } on FormatException {
      return defaultValue;
    }
  }
```

- [ ] **Step 3: Run tests to verify asDateTime passes**

Run: `cd dart_faltool && dart test test/extensions/dynamic_extensions_test.dart`
Expected: All tests PASS

- [ ] **Step 4: Write failing tests for asDuration**

Append inside the group:

```dart
    // ── asDuration ────────────────────────────────────

    group('asDuration', () {
      test('returns Duration directly', () {
        const d = Duration(hours: 1, minutes: 30);
        expect((d as dynamic).asDuration, d);
      });

      test('converts int (milliseconds) to Duration', () {
        expect(
          (5000 as dynamic).asDuration,
          const Duration(milliseconds: 5000),
        );
        expect((0 as dynamic).asDuration, Duration.zero);
      });

      test('parses numeric String as milliseconds', () {
        expect(
          ('5000' as dynamic).asDuration,
          const Duration(milliseconds: 5000),
        );
      });

      test('parses HH:MM:SS String to Duration', () {
        expect(
          ('01:30:00' as dynamic).asDuration,
          const Duration(hours: 1, minutes: 30),
        );
        expect(
          ('00:05:30' as dynamic).asDuration,
          const Duration(minutes: 5, seconds: 30),
        );
      });

      test('throws FormatException for null', () {
        expect(() => (null as dynamic).asDuration, throwsFormatException);
      });

      test('throws FormatException for invalid String', () {
        expect(
          () => ('not-a-duration' as dynamic).asDuration,
          throwsFormatException,
        );
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (true as dynamic).asDuration, throwsFormatException);
      });
    });

    group('asDurationOrNull', () {
      test('returns Duration for valid values', () {
        expect(
          (5000 as dynamic).asDurationOrNull,
          const Duration(milliseconds: 5000),
        );
      });

      test('returns null for null', () {
        expect((null as dynamic).asDurationOrNull, isNull);
      });

      test('returns null for invalid value', () {
        expect(('not-a-duration' as dynamic).asDurationOrNull, isNull);
      });
    });

    group('asDurationOr', () {
      test('returns Duration for valid values', () {
        expect(
          (5000 as dynamic).asDurationOr(Duration.zero),
          const Duration(milliseconds: 5000),
        );
      });

      test('returns default for null', () {
        expect((null as dynamic).asDurationOr(Duration.zero), Duration.zero);
      });

      test('returns default for invalid value', () {
        expect(
          ('not-a-duration' as dynamic).asDurationOr(Duration.zero),
          Duration.zero,
        );
      });
    });
```

- [ ] **Step 5: Implement asDuration coercion**

Add the `_hhmmssPattern` regex as a top-level private constant and add to the extension:

Top-level (next to `_throwFormatException`):

```dart
final _hhmmssPattern = RegExp(r'^(\d{1,2}):(\d{2}):(\d{2})$');
```

In the extension:

```dart
  // ── Duration ────────────────────────────────────────

  Duration get asDuration {
    final v = this;
    if (v == null) _throwFormatException(v, 'Duration');
    if (v is Duration) return v;
    if (v is int) return Duration(milliseconds: v);
    if (v is String) {
      final ms = int.tryParse(v);
      if (ms != null) return Duration(milliseconds: ms);
      final match = _hhmmssPattern.firstMatch(v);
      if (match != null) {
        return Duration(
          hours: int.parse(match.group(1)!),
          minutes: int.parse(match.group(2)!),
          seconds: int.parse(match.group(3)!),
        );
      }
    }
    _throwFormatException(v, 'Duration');
  }

  Duration? get asDurationOrNull {
    try {
      return asDuration;
    } on FormatException {
      return null;
    }
  }

  Duration asDurationOr(Duration defaultValue) {
    try {
      return asDuration;
    } on FormatException {
      return defaultValue;
    }
  }
```

- [ ] **Step 6: Run all tests and analyze**

Run: `cd dart_faltool && dart test test/extensions/dynamic_extensions_test.dart && dart analyze lib/extensions/dynamic_extensions.dart`
Expected: All tests PASS, no analysis issues

- [ ] **Step 7: Commit**

```bash
git add dart_faltool/lib/extensions/dynamic_extensions.dart \
       dart_faltool/test/extensions/dynamic_extensions_test.dart
git commit -m "feat(faltool): add asDateTime, asDuration to dynamic extension"
```

---

### Task 6: Implement collection coercions (asList, asMap)

**Files:**
- Modify: `dart_faltool/lib/extensions/dynamic_extensions.dart`
- Modify: `dart_faltool/test/extensions/dynamic_extensions_test.dart`

- [ ] **Step 1: Write failing tests for asList**

Append inside the group:

```dart
    // ── asList ────────────────────────────────────────

    group('asList', () {
      test('returns List directly', () {
        expect((<int>[1, 2, 3] as dynamic).asList, [1, 2, 3]);
      });

      test('creates a new List from source (not same reference)', () {
        final source = <int>[1, 2, 3];
        final result = (source as dynamic).asList;
        expect(identical(result, source), isFalse);
      });

      test('parses JSON array String to List', () {
        expect(('[1, 2, 3]' as dynamic).asList, [1, 2, 3]);
        expect(('["a", "b"]' as dynamic).asList, ['a', 'b']);
      });

      test('throws FormatException for null', () {
        expect(() => (null as dynamic).asList, throwsFormatException);
      });

      test('throws FormatException for non-list JSON String', () {
        expect(
          () => ('{"key": "value"}' as dynamic).asList,
          throwsFormatException,
        );
      });

      test('throws FormatException for invalid JSON String', () {
        expect(() => ('not json' as dynamic).asList, throwsFormatException);
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (42 as dynamic).asList, throwsFormatException);
      });
    });

    group('asListOrNull', () {
      test('returns List for valid values', () {
        expect((<int>[1, 2] as dynamic).asListOrNull, [1, 2]);
      });

      test('returns null for null', () {
        expect((null as dynamic).asListOrNull, isNull);
      });

      test('returns null for invalid value', () {
        expect((42 as dynamic).asListOrNull, isNull);
      });
    });

    group('asListOr', () {
      test('returns List for valid values', () {
        expect((<int>[1, 2] as dynamic).asListOr(<dynamic>[]), [1, 2]);
      });

      test('returns default for null', () {
        expect((null as dynamic).asListOr(<dynamic>[]), <dynamic>[]);
      });

      test('returns default for invalid value', () {
        expect((42 as dynamic).asListOr(<dynamic>[]), <dynamic>[]);
      });
    });
```

- [ ] **Step 2: Implement asList coercion**

Add to the extension:

```dart
  // ── List ────────────────────────────────────────────

  List<dynamic> get asList {
    final v = this;
    if (v == null) _throwFormatException(v, 'List');
    if (v is List) return List<dynamic>.from(v);
    if (v is String) {
      try {
        final decoded = json.decode(v);
        if (decoded is List) return List<dynamic>.from(decoded);
      } on FormatException {
        // fall through to throw
      }
    }
    _throwFormatException(v, 'List');
  }

  List<dynamic>? get asListOrNull {
    try {
      return asList;
    } on FormatException {
      return null;
    }
  }

  List<dynamic> asListOr(List<dynamic> defaultValue) {
    try {
      return asList;
    } on FormatException {
      return defaultValue;
    }
  }
```

- [ ] **Step 3: Run tests to verify asList passes**

Run: `cd dart_faltool && dart test test/extensions/dynamic_extensions_test.dart`
Expected: All tests PASS

- [ ] **Step 4: Write failing tests for asMap**

Append inside the group:

```dart
    // ── asMap ─────────────────────────────────────────

    group('asMap', () {
      test('returns Map directly', () {
        expect(
          (<String, dynamic>{'a': 1} as dynamic).asMap,
          {'a': 1},
        );
      });

      test('creates a new Map from source (not same reference)', () {
        final source = <String, dynamic>{'a': 1};
        final result = (source as dynamic).asMap;
        expect(identical(result, source), isFalse);
      });

      test('parses JSON object String to Map', () {
        expect(
          ('{"name": "John", "age": 30}' as dynamic).asMap,
          {'name': 'John', 'age': 30},
        );
      });

      test('throws FormatException for null', () {
        expect(() => (null as dynamic).asMap, throwsFormatException);
      });

      test('throws FormatException for non-object JSON String', () {
        expect(
          () => ('[1, 2, 3]' as dynamic).asMap,
          throwsFormatException,
        );
      });

      test('throws FormatException for invalid JSON String', () {
        expect(() => ('not json' as dynamic).asMap, throwsFormatException);
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (42 as dynamic).asMap, throwsFormatException);
      });
    });

    group('asMapOrNull', () {
      test('returns Map for valid values', () {
        expect(
          (<String, dynamic>{'a': 1} as dynamic).asMapOrNull,
          {'a': 1},
        );
      });

      test('returns null for null', () {
        expect((null as dynamic).asMapOrNull, isNull);
      });

      test('returns null for invalid value', () {
        expect((42 as dynamic).asMapOrNull, isNull);
      });
    });

    group('asMapOr', () {
      test('returns Map for valid values', () {
        expect(
          (<String, dynamic>{'a': 1} as dynamic)
              .asMapOr(<String, dynamic>{}),
          {'a': 1},
        );
      });

      test('returns default for null', () {
        expect(
          (null as dynamic).asMapOr(<String, dynamic>{}),
          <String, dynamic>{},
        );
      });

      test('returns default for invalid value', () {
        expect(
          (42 as dynamic).asMapOr(<String, dynamic>{}),
          <String, dynamic>{},
        );
      });
    });
```

- [ ] **Step 5: Implement asMap coercion**

Add to the extension:

```dart
  // ── Map ─────────────────────────────────────────────

  Map<String, dynamic> get asMap {
    final v = this;
    if (v == null) _throwFormatException(v, 'Map');
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String) {
      try {
        final decoded = json.decode(v);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        // fall through to throw
      }
    }
    _throwFormatException(v, 'Map');
  }

  Map<String, dynamic>? get asMapOrNull {
    try {
      return asMap;
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> asMapOr(Map<String, dynamic> defaultValue) {
    try {
      return asMap;
    } on FormatException {
      return defaultValue;
    }
  }
```

- [ ] **Step 6: Run all tests and analyze**

Run: `cd dart_faltool && dart test test/extensions/dynamic_extensions_test.dart && dart analyze lib/extensions/dynamic_extensions.dart`
Expected: All tests PASS, no analysis issues

- [ ] **Step 7: Commit**

```bash
git add dart_faltool/lib/extensions/dynamic_extensions.dart \
       dart_faltool/test/extensions/dynamic_extensions_test.dart
git commit -m "feat(faltool): add asList, asMap to dynamic extension"
```

---

### Task 7: Final validation — format, full test suite, analyze

**Files:**
- All files from Tasks 1-6

- [ ] **Step 1: Format all changed files**

Run: `cd dart_faltool && dart format lib/extensions/dynamic_extensions.dart test/extensions/dynamic_extensions_test.dart`
Expected: Formatted successfully (or already formatted)

- [ ] **Step 2: Run full project analysis**

Run: `cd dart_faltool && dart analyze`
Expected: No issues found

- [ ] **Step 3: Run full test suite to check for regressions**

Run: `cd dart_faltool && dart test`
Expected: All tests PASS (both existing and new)

- [ ] **Step 4: Commit formatting changes (if any)**

```bash
git add dart_faltool/lib/extensions/dynamic_extensions.dart \
       dart_faltool/test/extensions/dynamic_extensions_test.dart
git commit -m "style(faltool): dart format dynamic extension files"
```
