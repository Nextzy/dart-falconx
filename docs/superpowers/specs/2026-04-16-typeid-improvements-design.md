# TypeID Improvements Design

## Context

The `dart_faltool/lib/utils/typeid/` directory contains a TypeID implementation (base32 encoding, generation, decoding) that is newly added (not yet committed). Since there are no consumers yet, we can freely change the API.

## Goals

- **Code quality & Dart idioms** — Freezed, proper return types, idiomatic patterns
- **API usability** — keep static class, add convenience methods
- **Robustness** — strict spec compliance, explicit error handling, no magic numbers

## Changes

### 1. `DecodedTypeId` — Freezed model

**Current:** Plain class with no `==`, `hashCode`, `toString()`.

**Change:** Convert to Freezed with custom `toString()` that reconstructs the TypeID string.

```dart
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

**Files:** `decoded_typeid.dart`, new `generated/decoded_typeid.freezed.dart`

### 2. `TypeId` — API improvements

**2a. Move `separator` to private scope**

Move top-level `const separator = '_'` to `TypeId._separator`.

**2b. Fix `_checkPrefix` — strict spec compliance**

- Add `void` return type
- Remove `|| code == 95` (underscore allowance) — prefix must be `[a-z]` only per TypeID spec
- Fix comment from `[a-z_]` to `[a-z]`
- Fix error message to match validation

**2c. Add `isValid(String typeid)` method**

Returns `bool` without throwing. Wraps `decode` in try-catch on `FormatException` and `ArgumentError`.

**2d. Add `decodeOrNull(String typeid)` method**

Returns `DecodedTypeId?` — `null` on invalid input instead of throwing.

**2e. Fix catch clause in `decode`**

Change `catch (e)` to `on FormatException catch (e)` + `on ArgumentError catch (e)` — don't swallow unexpected exceptions.

**Files:** `typeid.dart`

### 3. `Base32` — Code quality & clarity

**3a. Doc comment on `decode`**

Change `//` to `///` to match `encode`.

**3b. Named constant for magic number**

Replace `s.codeUnitAt(0) > 55` with a named constant:

```dart
static const int _maxFirstCharCode = 55; // '7' in ASCII — values above overflow 128 bits
```

**3c. `encode` — use `StringBuffer`**

Replace `List<String>.filled(26, "")` + `.join("")` with `StringBuffer` + `writeCharCode` for idiomatic string building.

**Files:** `base32.dart`

## Files Affected

| File | Action |
|------|--------|
| `dart_faltool/lib/utils/typeid/decoded_typeid.dart` | Rewrite as Freezed model |
| `dart_faltool/lib/utils/typeid/typeid.dart` | API improvements, strict validation |
| `dart_faltool/lib/utils/typeid/base32.dart` | Code quality fixes |
| `dart_faltool/build.yaml` | May need to add generated output config |

## Out of Scope

- Changing `TypeId` from static class to instance-based
- Adding UUID version validation on decode
- Performance benchmarking
