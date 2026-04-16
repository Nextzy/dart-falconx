# Dynamic Type Cast Extension Design

**Date:** 2026-04-16
**Package:** dart_faltool
**File:** `lib/extensions/dynamic_extensions.dart`

## Purpose

Provide smart type coercion methods on `dynamic` values for JSON parsing use cases. When working with `Map<String, dynamic>` from `json.decode`, API responses, or manual JSON handling (without Freezed/JsonSerializable), these extensions reduce boilerplate and provide safe, predictable type conversion.

## API Surface

### Method Pattern

Every supported type has 3 methods:

| Method | Behavior |
|---|---|
| `as{{Type}}` | Smart coerce, throw `FormatException` on failure |
| `as{{Type}}OrNull` | Smart coerce, return `null` on failure |
| `as{{Type}}Or(defaultValue)` | Smart coerce, return `defaultValue` on failure |

### Null Handling

- `asType` on `null` → throw `FormatException`
- `asTypeOrNull` on `null` → return `null`
- `asTypeOr(default)` on `null` → return `default`

### Supported Types (33 methods total)

**Primitives:**
- `asString`, `asStringOrNull`, `asStringOr(String)`
- `asInt`, `asIntOrNull`, `asIntOr(int)`
- `asDouble`, `asDoubleOrNull`, `asDoubleOr(double)`
- `asNum`, `asNumOrNull`, `asNumOr(num)`
- `asBool`, `asBoolOrNull`, `asBoolOr(bool)`

**Large Numbers:**
- `asBigInt`, `asBigIntOrNull`, `asBigIntOr(BigInt)`
- `asBigDecimal`, `asBigDecimalOrNull`, `asBigDecimalOr(BigDecimal)`

**Temporal:**
- `asDateTime`, `asDateTimeOrNull`, `asDateTimeOr(DateTime)`
- `asDuration`, `asDurationOrNull`, `asDurationOr(Duration)`

**Collections:**
- `asList`, `asListOrNull`, `asListOr(List)`
- `asMap`, `asMapOrNull`, `asMapOr(Map<String, dynamic>)`

## Smart Coercion Rules

### `asString`
- Any non-null value → `toString()`
- Never throws for non-null values (provided for API consistency)

### `asInt`
| Source | Conversion |
|---|---|
| `int` | direct |
| `num` / `double` | `.toInt()` |
| `String` | `int.parse()` |
| `bool` | `true` → `1`, `false` → `0` |
| `BigInt` | `.toInt()` |

### `asDouble`
| Source | Conversion |
|---|---|
| `double` | direct |
| `num` / `int` | `.toDouble()` |
| `String` | `double.parse()` |
| `bool` | `true` → `1.0`, `false` → `0.0` |
| `BigDecimal` | `.toDouble()` |

### `asNum`
| Source | Conversion |
|---|---|
| `num` | direct |
| `String` | `num.parse()` |
| `bool` | `true` → `1`, `false` → `0` |

### `asBool`
| Source | Conversion |
|---|---|
| `bool` | direct |
| `String` | `'true'`/`'1'` → true, `'false'`/`'0'` → false (case-insensitive) |
| `num` | `0` → false, non-zero → true |

### `asBigInt`
| Source | Conversion |
|---|---|
| `BigInt` | direct |
| `int` | `BigInt.from()` |
| `String` | `BigInt.parse()` |

### `asBigDecimal`
| Source | Conversion |
|---|---|
| `BigDecimal` | direct |
| `num` / `int` / `double` | `BigDecimal.fromNum()` |
| `String` | `BigDecimal.parse()` |

### `asDateTime`
| Source | Conversion |
|---|---|
| `DateTime` | direct |
| `String` | `DateTime.parse()` (ISO 8601) |
| `int` | `DateTime.fromMillisecondsSinceEpoch()` |

### `asDuration`
| Source | Conversion |
|---|---|
| `Duration` | direct |
| `int` | `Duration(milliseconds: n)` |
| `String` | numeric string → `Duration(milliseconds: int.parse(s))`, otherwise try `HH:MM:SS` regex → `Duration(hours, minutes, seconds)` |

### `asList`
| Source | Conversion |
|---|---|
| `List` | `List<dynamic>.from()` |
| `String` | `json.decode()` if valid JSON array |

### `asMap`
| Source | Conversion |
|---|---|
| `Map` | `Map<String, dynamic>.from()` |
| `String` | `json.decode()` if valid JSON object |

## Exception Handling

All `asType` methods throw `FormatException` with a descriptive message when coercion fails:

```dart
FormatException("Cannot convert '$value' (${value.runtimeType}) to int")
```

## Extension Structure

```dart
extension FalconDynamicTypeCastExtension on dynamic {
  // Each type follows this internal pattern:
  //
  // 1. asType (getter) → _coerceToType() which throws on failure
  // 2. asTypeOrNull (getter) → try _coerceToType(), catch → null
  // 3. asTypeOr(default) → try _coerceToType(), catch → default
}
```

Private helper for consistent error messages:

```dart
Never _throwFormatException(dynamic value, String targetType) {
  throw FormatException(
    "Cannot convert '$value' (${value.runtimeType}) to $targetType",
  );
}
```

## File Changes

1. **Edit** `lib/extensions/dynamic_extensions.dart` — implement the extension
2. **Edit** `lib/extensions/extensions.dart` — add `export 'dynamic_extensions.dart';`
3. **Create** `test/extensions/dynamic_extensions_test.dart` — comprehensive tests

## Testing Strategy

Each type needs tests for:
- Direct type (value is already the target type)
- Each coercion path (e.g., String → int, double → int, bool → int)
- Null value handling (all 3 method variants)
- Invalid value → throw / null / default (all 3 method variants)
- Edge cases per type (e.g., overflow for BigInt→int, invalid date string)
