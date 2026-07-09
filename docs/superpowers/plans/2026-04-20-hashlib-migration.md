# Hashlib Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `crypto: ^3.0.7` and `uuid: ^4.5.3` with `hashlib: ^2.3.4` (+ `hashlib_codecs` conditionally) in `dart_faltool`, update the one SHA-256 call site, the UUID v4/v7 call sites, and the `DecodedTypeId.uuid` public field (breaking: `UuidValue` → `String`); then verify whether the TypeID-specific Base32 encoder can be replaced by `hashlib_codecs` Crockford Base32.

**Architecture:** Four atomic tasks, each ending in one commit that leaves the repository in a buildable state. Task 1 swaps `crypto` for `hashlib` in the one call site, `hashSha256`, after pinning its behavior with a characterization test. Task 2 migrates UUID generation and changes `DecodedTypeId.uuid` from `UuidValue` to `String`, regenerating the Freezed file. Task 3 runs a byte-for-byte verification test between the custom `Base32` and `hashlib_codecs`' Crockford Base32 and decides whether to keep or delete the custom encoder. Task 4 bumps the package to `2.0.0` and does final cleanup + monorepo-wide analysis.

**Tech Stack:** Dart SDK `>=3.9.0 <4.0.0`, Melos 7.x, Freezed 3.x, build_runner 2.x, `hashlib: ^2.3.4`, `hashlib_codecs` (latest on pub.dev)

**Spec:** `docs/superpowers/specs/2026-04-20-hashlib-migration-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `dart_faltool/pubspec.yaml` | Modify | Drop `crypto`, `uuid`; add `hashlib`, optionally `hashlib_codecs`; bump version to `2.0.0` |
| `dart_faltool/lib/dart_faltool.dart` | Modify | Replace `crypto` and `uuid` re-exports with `hashlib` re-export |
| `dart_faltool/lib/extensions/string_extensions.dart` | Modify | `hashSha256()` uses hashlib instead of `crypto.sha256` |
| `dart_faltool/lib/utils/uuid_generator.dart` | Modify | `UuidGenerator.getV4()` uses hashlib's `uuid.v4()` |
| `dart_faltool/lib/utils/typeid/typeid.dart` | Modify | Use hashlib `uuid.v7()`; convert string ↔ bytes without `UuidValue`; optionally delegate Base32 to `hashlib_codecs` (depends on Task 3) |
| `dart_faltool/lib/utils/typeid/decoded_typeid.dart` | Modify | Change `UuidValue uuid` field to `String uuid`; drop `package:uuid` import |
| `dart_faltool/lib/utils/typeid/generated/decoded_typeid.freezed.dart` | Regen | Regenerate via `dart run build_runner build -d` |
| `dart_faltool/lib/utils/typeid/base32.dart` | Possibly delete | Delete iff Task 3 verification passes; otherwise keep with rationale comment |
| `dart_faltool/test/extensions/string_extensions_test.dart` | Modify | Add characterization test for `hashSha256` before the swap |
| `dart_faltool/test/utils/typeid/base32_verify_test.dart` | Create, then delete | Temporary verification test between custom `Base32` and hashlib_codecs Crockford |
| `dart_faltool/test/utils/typeid/base32_test.dart` | Possibly modify or delete | Keep if Base32 is kept; redirect to `Base32Codec.crockford` or delete if Base32 is removed |

---

### Task 1: Migrate `hashSha256` from `crypto` to `hashlib`

Swap the single `sha256` call site, drop the `crypto` dependency, and stop re-exporting it. Keep `uuid` untouched in this task so that Task 2 remains independent.

**Files:**
- Modify: `dart_faltool/pubspec.yaml`
- Modify: `dart_faltool/lib/dart_faltool.dart` (only the `crypto` export; the `uuid` export stays until Task 2)
- Modify: `dart_faltool/lib/extensions/string_extensions.dart:28-44`
- Modify: `dart_faltool/test/extensions/string_extensions_test.dart` (append a new `group` for `hashSha256`)

- [ ] **Step 1: Add a characterization test for `hashSha256` using the existing `crypto`-based implementation**

There is currently NO test for `hashSha256`. Add one so the swap is behavior-preserving. Append this group to the bottom of `dart_faltool/test/extensions/string_extensions_test.dart`, inside the existing `group('FalconToolStringExtension', ...)`:

```dart
    group('hashSha256', () {
      // SHA-256 of 'hello' is deterministic across all implementations.
      const helloSha256 =
          '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';

      test('produces canonical SHA-256 hex for a known input', () {
        expect('hello'.hashSha256(), helloSha256);
      });

      test('truncates output when length is smaller than 64', () {
        expect('hello'.hashSha256(length: 8), helloSha256.substring(0, 8));
      });

      test('pads with zeros when length is larger than 64', () {
        final padded = 'hello'.hashSha256(length: 70);
        expect(padded.length, 70);
        expect(padded.startsWith(helloSha256), isTrue);
        expect(padded.substring(64), '000000');
      });

      test('ignores length when null or non-positive', () {
        expect('hello'.hashSha256(length: null), helloSha256);
        expect('hello'.hashSha256(length: 0), helloSha256);
      });

      test('empty string hashes to the canonical empty SHA-256', () {
        expect(
          ''.hashSha256(),
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        );
      });
    });
```

- [ ] **Step 2: Run the new test to confirm it passes against the current `crypto` implementation**

Run:

```bash
cd dart_faltool && dart test test/extensions/string_extensions_test.dart -n "hashSha256"
```

Expected: all 5 tests PASS. This locks the current behavior.

- [ ] **Step 3: Add `hashlib` to `dart_faltool/pubspec.yaml` and remove `crypto`**

In `dart_faltool/pubspec.yaml`, under `dependencies:`, replace the `crypto` line with `hashlib`. Keep every other line unchanged. After edit, the affected block should look like this (alphabetical order; `hashlib` sits between `freezed_annotation` and `intl`):

```yaml
dependencies:
  dart_falmodel:
    path: ../dart_falmodel

  #PLATFORM: All
  ansicolor: ^2.0.3
  big_decimal: ^0.7.0
  data: ^0.15.2
  dartx: ^1.2.0
  enum_to_string: ^2.2.1
  equatable: ^2.0.8
  fpdart: ^1.2.0
  freezed_annotation: ^3.1.0
  hashlib: ^2.3.4
  intl: ^0.20.2
  json_annotation: ^4.12.0
  logger: ^2.7.0
  meta: ^1.18.3
  numeral: ^3.1.2
  retry: ^3.1.2
  rxdart: ^0.28.0
  stack_trace: ^1.12.1
  timeago: ^3.7.1
  universal_io: ^2.3.1
  uuid: ^4.5.3
  version: ^3.0.2
  web: ^1.1.1
  yaml: ^3.1.3
```

Do NOT bump the `version:` yet — that happens in Task 4 after all changes land.

- [ ] **Step 4: Run `melos get` to resolve dependencies**

Run (from repo root):

```bash
melos get
```

Expected: `Got dependencies!` across all packages, no unresolvable conflicts.

- [ ] **Step 5: Replace the implementation of `hashSha256`**

In `dart_faltool/lib/extensions/string_extensions.dart`, replace the method body (lines 28–44, keeping the method signature and doc placement identical):

```dart
  String hashSha256({int? length}) {
    // Generate hash using hashlib's SHA-256 implementation.
    final hash = sha256.string(this).hex();

    // Adjust length if specified
    if (length != null && length > 0) {
      if (length > hash.length) {
        // Pad with zeros if requested length is longer
        return hash.padRight(length, '0');
      }
      return hash.substring(0, length);
    }

    return hash;
  }
```

Note: `sha256` and `utf8` were both previously in scope via `dart_faltool/lib.dart` (which re-exports `dart:convert` and `package:crypto/crypto.dart`). After Step 6, `sha256` will resolve to `hashlib`'s `sha256`. `utf8.encode(this)` is no longer needed because `sha256.string(...)` accepts a `String` directly.

- [ ] **Step 6: Remove the `crypto` re-export from `dart_faltool/lib/dart_faltool.dart`**

Delete line 7:

```dart
export 'package:crypto/crypto.dart' hide Hash;
```

Add a new line (alphabetical position, right above `intl`):

```dart
export 'package:hashlib/hashlib.dart';
```

Keep `export 'package:uuid/uuid.dart';` untouched for now (Task 2 removes it).

- [ ] **Step 7: Run the `hashSha256` tests again to confirm behavior is preserved**

Run:

```bash
cd dart_faltool && dart test test/extensions/string_extensions_test.dart -n "hashSha256"
```

Expected: all 5 tests PASS. Identical outputs to Step 2.

- [ ] **Step 8: Run the full `dart_faltool` test suite**

Run:

```bash
cd dart_faltool && dart test
```

Expected: all existing tests PASS (no regressions).

- [ ] **Step 9: Run analyzer across the monorepo**

Run (from repo root):

```bash
dart analyze
```

Expected: 0 issues. If there is a transitive consumer that imported `sha256` from the old re-export, it should still resolve because `hashlib` exports a top-level `sha256` symbol too; if it somehow breaks, fix the import site in the same commit.

- [ ] **Step 10: Commit**

```bash
git add dart_faltool/pubspec.yaml dart_faltool/pubspec.lock dart_faltool/lib/dart_faltool.dart dart_faltool/lib/extensions/string_extensions.dart dart_faltool/test/extensions/string_extensions_test.dart
git commit -m "$(cat <<'EOF'
refactor(faltool)!: migrate hashSha256 from crypto to hashlib

Swaps the single SHA-256 call site in String.hashSha256 over to
hashlib and drops the crypto dependency plus its re-export from
dart_faltool.dart. Adds characterization tests for hashSha256 first
so the behavior swap is verifiable.

The uuid package remains for now; it is removed in a follow-up commit.
The dart_faltool re-export now exposes hashlib symbols instead of
crypto symbols, which is a breaking change for downstream consumers
that relied on the crypto API shape.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Migrate UUID usage from `uuid` package to `hashlib`

Replace `UuidGenerator.getV4()`, rewrite `TypeId.generate`/`decode` to work with canonical-string UUIDs instead of `UuidValue`, change the `DecodedTypeId.uuid` field to `String`, regenerate Freezed code, and drop the `uuid` dependency + re-export.

**Files:**
- Modify: `dart_faltool/pubspec.yaml`
- Modify: `dart_faltool/lib/dart_faltool.dart`
- Modify: `dart_faltool/lib/utils/uuid_generator.dart`
- Modify: `dart_faltool/lib/utils/typeid/typeid.dart`
- Modify: `dart_faltool/lib/utils/typeid/decoded_typeid.dart`
- Regen: `dart_faltool/lib/utils/typeid/generated/decoded_typeid.freezed.dart`
- Modify (if necessary): `dart_faltool/test/utils/typeid/typeid_test.dart`

- [ ] **Step 1: Rewrite `UuidGenerator` to use `package:hashlib/random.dart`**

Replace the entire content of `dart_faltool/lib/utils/uuid_generator.dart` with:

```dart
import 'package:hashlib/random.dart';

class UuidGenerator {
  static String getV4() => uuid.v4();
}
```

Notes:
- The top-level `const uuid = Uuid();` is gone. hashlib's `uuid` is a top-level singleton exported from `package:hashlib/random.dart`.
- This file does NOT import `package:dart_faltool/lib.dart` — hashlib is imported directly to avoid the transitive `dart:async`/`dart:convert` baggage for this tiny utility.

- [ ] **Step 2: Rewrite `DecodedTypeId` to expose the UUID as `String`**

Replace the entire content of `dart_faltool/lib/utils/typeid/decoded_typeid.dart` with:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/decoded_typeid.freezed.dart';

@freezed
abstract class DecodedTypeId with _$DecodedTypeId {
  const factory DecodedTypeId({
    required String prefix,
    required String suffix,
    required String uuid,
  }) = _DecodedTypeId;

  const DecodedTypeId._();

  @override
  String toString() => prefix.isEmpty ? suffix : '${prefix}_$suffix';
}
```

- [ ] **Step 3: Rewrite `TypeId` to use hashlib's `uuid.v7()` and canonical-string UUID handling**

Replace the entire content of `dart_faltool/lib/utils/typeid/typeid.dart` with:

```dart
import 'dart:typed_data';

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

    final v7String = uuid.v7();
    final bytes = _uuidStringToBytes(v7String);
    final base32Encoded = Base32.encode(bytes);

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
      throw const FormatException(
        'Invalid typeid. prefix cannot contain _',
      );
    }

    final prefix = parts[0];
    final suffix = parts[1];

    _checkPrefix(prefix);

    try {
      final base32Decoded = Base32.decode(suffix);
      final uuidString = _uuidBytesToString(base32Decoded);

      return DecodedTypeId(prefix: prefix, suffix: suffix, uuid: uuidString);
    } on FormatException {
      rethrow;
    }
  }

  /// Returns `true` if the given string is a valid TypeID.
  static bool isValid(String typeid) {
    try {
      decode(typeid);
      return true;
    } on FormatException {
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
    }
  }

  static void _checkPrefix(String prefix) {
    if (prefix.length > 63) {
      throw const FormatException('Prefix too long');
    }

    if (prefix.startsWith(_separator) || prefix.endsWith(_separator)) {
      throw const FormatException('Prefix cannot start or end with _');
    }

    // ensure all characters fall within [a-z]
    final isValidChars = prefix.runes.every(
      (code) => code > 96 && code < 123,
    );

    if (!isValidChars) {
      throw const FormatException(
        'Prefix must only contain lowercase letters [a-z]',
      );
    }
  }

  static List<String> _splitLast(String input, String delimiter) {
    final lastIndex = input.lastIndexOf(delimiter);
    if (lastIndex == -1) {
      return [input];
    }
    final beforeLast = input.substring(0, lastIndex);
    final afterLast = input.substring(lastIndex + delimiter.length);
    return [beforeLast, afterLast];
  }
}

/// Parses a canonical 36-character UUID string (with dashes) into the
/// 16-byte representation expected by [Base32.encode].
Uint8List _uuidStringToBytes(String uuidString) {
  final hex = uuidString.replaceAll('-', '');
  if (hex.length != 32) {
    throw FormatException('Invalid UUID string: $uuidString');
  }
  final bytes = Uint8List(16);
  for (var i = 0; i < 16; i++) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}

/// Formats a 16-byte UUID into the canonical 8-4-4-4-12 lowercase hex string.
String _uuidBytesToString(Uint8List bytes) {
  assert(bytes.length == 16, 'UUID must be exactly 16 bytes');
  final hex = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}
```

Notes:
- `uuid.v7()` (from `hashlib/random.dart`) is in scope because `dart_faltool.dart` re-exports `package:hashlib/hashlib.dart` (which transitively exposes `uuid`). If a naming collision shows up at analyze time, fall back to `import 'package:hashlib/random.dart' as hl;` and call `hl.uuid.v7()` — but verify first that the default path works.
- `dart:typed_data` is imported explicitly for `Uint8List`; it is NOT brought in by `lib.dart`.
- The helpers are file-private (underscore-prefixed) and intentionally outside the class.

- [ ] **Step 4: Regenerate the Freezed file for `DecodedTypeId`**

Run (from repo root):

```bash
cd dart_faltool && dart run build_runner build -d
```

Expected: exits with `[INFO] Succeeded` and updates `dart_faltool/lib/utils/typeid/generated/decoded_typeid.freezed.dart` so that the `uuid` getter returns `String` (not `UuidValue`). After the run, `grep UuidValue dart_faltool/lib/utils/typeid/generated/decoded_typeid.freezed.dart` must return zero matches.

- [ ] **Step 5: Update any `typeid_test.dart` assertions that rely on `UuidValue`**

Run:

```bash
grep -n 'UuidValue\|\.uuid\.' dart_faltool/test/utils/typeid/typeid_test.dart || echo 'no matches'
```

If the grep returns matches, update those assertions so they compare against canonical UUID strings (36 chars, lowercase hex, 8-4-4-4-12 pattern). If `no matches`, nothing to do.

Example of the shape the new assertion should take, if needed:

```dart
expect(decoded.uuid, matches(RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
)));
```

- [ ] **Step 6: Run the full `dart_faltool` test suite**

Run:

```bash
cd dart_faltool && dart test
```

Expected: all existing tests (string_extensions, typeid, base32) PASS. Specifically, TypeID round-trip tests (`generate` → `decode` → compare suffix) must still pass — this proves the byte pipeline is intact.

- [ ] **Step 7: Remove the `uuid` dependency from `dart_faltool/pubspec.yaml`**

Delete the line `uuid: ^4.5.3` from `dependencies:` in `dart_faltool/pubspec.yaml`. The block should now look like this (no `uuid` line):

```yaml
  timeago: ^3.7.1
  universal_io: ^2.3.1
  version: ^3.0.2
  web: ^1.1.1
  yaml: ^3.1.3
```

- [ ] **Step 8: Remove the `uuid` re-export from `dart_faltool/lib/dart_faltool.dart`**

Delete line `export 'package:uuid/uuid.dart';` (it used to be line 33 of the original file; after Task 1's edits the line number may shift — delete by content, not position).

- [ ] **Step 9: Run `melos get` and re-run tests + analyzer**

Run (from repo root):

```bash
melos get
dart analyze
cd dart_faltool && dart test
```

Expected: analyzer reports 0 issues and tests still pass. If anything references `package:uuid` or `UuidValue`, fix it now in the same commit — it should not be reached at this point.

- [ ] **Step 10: Confirm no residual `uuid`/`UuidValue` references in `dart_faltool`**

Run (from repo root):

```bash
grep -rn 'package:uuid\|UuidValue\|Uuid()' dart_faltool/lib dart_faltool/test || echo 'clean'
```

Expected: `clean`. (The spec file under `docs/` is allowed to mention these terms.)

- [ ] **Step 11: Commit**

```bash
git add dart_faltool/pubspec.yaml dart_faltool/pubspec.lock dart_faltool/lib/dart_faltool.dart dart_faltool/lib/utils/uuid_generator.dart dart_faltool/lib/utils/typeid/typeid.dart dart_faltool/lib/utils/typeid/decoded_typeid.dart dart_faltool/lib/utils/typeid/generated/decoded_typeid.freezed.dart dart_faltool/test/utils/typeid/typeid_test.dart
git commit -m "$(cat <<'EOF'
refactor(faltool)!: migrate uuid package to hashlib random.uuid

Replaces package:uuid with hashlib's built-in uuid generator for
v4 (UuidGenerator.getV4) and v7 (TypeId.generate). Changes
DecodedTypeId.uuid from UuidValue to String (canonical 36-char form),
regenerates the Freezed file, and drops the uuid dependency plus its
re-export from dart_faltool.dart.

BREAKING CHANGE: DecodedTypeId.uuid is now a canonical UUID String
instead of UuidValue. Consumers that needed the bytes representation
must add a local helper; removing UuidValue from the public surface
is an intentional consequence of dropping the uuid dependency.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Verify and decide whether to delete the custom `Base32`

Add a one-shot verification test comparing the custom TypeID `Base32` encoder byte-for-byte against `hashlib_codecs`' Crockford Base32. Keep the custom encoder if they disagree; delete it if they match.

**Files:**
- Modify: `dart_faltool/pubspec.yaml` (add `hashlib_codecs`; possibly remove again after decision)
- Create, then delete: `dart_faltool/test/utils/typeid/base32_verify_test.dart`
- Possibly delete: `dart_faltool/lib/utils/typeid/base32.dart`
- Possibly modify: `dart_faltool/lib/utils/typeid/typeid.dart` (to call `Base32Codec.crockford` directly)
- Possibly delete: `dart_faltool/test/utils/typeid/base32_test.dart`

- [ ] **Step 1: Add `hashlib_codecs` to `dart_faltool/pubspec.yaml`**

Add `hashlib_codecs: ^<latest>` to the `dependencies:` block (alphabetical position right after `hashlib`). Look up the latest published version on pub.dev before adding — as of writing, `^2.x.x` is the line; use the current latest.

- [ ] **Step 2: Run `melos get` to fetch the new dep**

Run (from repo root):

```bash
melos get
```

Expected: resolves cleanly; `hashlib_codecs` is in `dart_faltool/.dart_tool/package_config.json`.

- [ ] **Step 3: Create the verification test**

Create `dart_faltool/test/utils/typeid/base32_verify_test.dart` with the following content. The exact `hashlib_codecs` API call (`Base32Codec.crockford.encode` vs `toBase32(bytes, type: Base32Type.crockford)` vs a top-level function) is package-version-specific; use the first form that compiles against the installed `hashlib_codecs` — check the package's `README`/`example` if unsure.

```dart
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_faltool/lib.dart';
import 'package:hashlib_codecs/hashlib_codecs.dart';
import 'package:test/test.dart';

void main() {
  group('Base32 verification vs hashlib_codecs Crockford', () {
    // The TypeID spec limits the first byte to <= 0x7F so the encoded
    // string never exceeds 128 bits. All test vectors respect that.
    final vectors = <Uint8List>[
      Uint8List(16),
      Uint8List.fromList([
        0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
      ]),
      Uint8List.fromList(List.generate(16, (i) => i)),
    ];

    // Add 50 random 16-byte vectors with byte 0 clamped to <= 0x7F.
    final rng = Random(0xDEADBEEF);
    for (var i = 0; i < 50; i++) {
      final bytes = Uint8List(16);
      for (var j = 0; j < 16; j++) {
        bytes[j] = rng.nextInt(256);
      }
      bytes[0] &= 0x7F;
      vectors.add(bytes);
    }

    for (final bytes in vectors) {
      test('matches for ${bytes.toString()}', () {
        final ours = Base32.encode(bytes);
        // Replace with the real API once verified:
        //   final theirs = toBase32(bytes, type: Base32Type.crockford);
        //   final theirs = Base32Codec.crockford.encode(bytes);
        final theirs = toBase32(bytes, type: Base32Type.crockford);
        expect(theirs, equals(ours),
            reason: 'bytes=$bytes ours=$ours theirs=$theirs');
      });
    }
  });
}
```

- [ ] **Step 4: Run the verification test**

Run:

```bash
cd dart_faltool && dart test test/utils/typeid/base32_verify_test.dart
```

**Record the outcome.** One of the two branches below applies.

- [ ] **Step 5 (BRANCH A — every test passes): Replace usage of custom `Base32` with `hashlib_codecs`**

If and only if every vector passed, proceed with this branch. Otherwise skip to Step 5 (BRANCH B).

Modify `dart_faltool/lib/utils/typeid/typeid.dart`:

- Replace the `export 'base32.dart';` line with `// Base32 is now delegated to hashlib_codecs.`
- Replace calls to `Base32.encode(bytes)` with `toBase32(bytes, type: Base32Type.crockford)` (or whichever API shape the verification used).
- Replace calls to `Base32.decode(suffix)` with the matching decode call (`fromBase32(suffix, type: Base32Type.crockford)` or analogous).
- Add `import 'package:hashlib_codecs/hashlib_codecs.dart';` at the top.

Delete:

```bash
rm dart_faltool/lib/utils/typeid/base32.dart
rm dart_faltool/test/utils/typeid/base32_test.dart
```

Run tests to confirm TypeID round-trip still works:

```bash
cd dart_faltool && dart test
```

Expected: all tests PASS. Proceed to Step 6.

- [ ] **Step 5 (BRANCH B — any test fails): Keep the custom `Base32`, drop `hashlib_codecs`**

If any vector mismatched, the custom TypeID encoder is not byte-for-byte compatible with `hashlib_codecs`. Keep the custom encoder and roll back the `hashlib_codecs` dep.

1. Remove `hashlib_codecs` from `dart_faltool/pubspec.yaml`.
2. Run `melos get`.
3. Add a file-level comment to `dart_faltool/lib/utils/typeid/base32.dart` explaining why the custom encoder is kept. Insert above line 5 (above the existing doc comment):

   ```dart
   // NOTE: This encoder is intentionally custom rather than delegated to
   // `hashlib_codecs` Crockford Base32. TypeID uses a fixed-width
   // 16-byte -> 26-char encoding with 3-bit top-of-byte padding on the
   // first character, which does not match the bit packing produced by
   // `hashlib_codecs`. Verification was done in
   // docs/superpowers/specs/2026-04-20-hashlib-migration-design.md §3.
   ```

4. Run the full test suite:

   ```bash
   cd dart_faltool && dart test
   ```

   Expected: all existing tests PASS.

Proceed to Step 6.

- [ ] **Step 6: Delete the temporary verification test**

Regardless of which branch was taken:

```bash
rm dart_faltool/test/utils/typeid/base32_verify_test.dart
```

Re-run tests to confirm nothing else depends on it:

```bash
cd dart_faltool && dart test
```

Expected: all tests PASS.

- [ ] **Step 7: Confirm final Base32 state and commit**

Run:

```bash
dart analyze
```

Expected: 0 issues across the monorepo.

Then commit. The commit body differs based on branch taken; pick the right one.

**If BRANCH A (Base32 removed):**

```bash
git add dart_faltool/pubspec.yaml dart_faltool/pubspec.lock dart_faltool/lib/utils/typeid/typeid.dart dart_faltool/lib/utils/typeid/base32.dart dart_faltool/test/utils/typeid/base32_test.dart dart_faltool/test/utils/typeid/base32_verify_test.dart
git commit -m "$(cat <<'EOF'
refactor(faltool)!: replace custom TypeID Base32 with hashlib_codecs

Verified byte-for-byte that hashlib_codecs' Crockford Base32
produces identical output to the custom TypeID encoder across
both edge-case and random vectors. Deletes the custom Base32
class and its tests; TypeId now delegates encoding to
hashlib_codecs directly.

BREAKING CHANGE: `Base32` is no longer exported from
dart_faltool's typeid namespace.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

**If BRANCH B (Base32 kept):**

```bash
git add dart_faltool/pubspec.yaml dart_faltool/pubspec.lock dart_faltool/lib/utils/typeid/base32.dart dart_faltool/test/utils/typeid/base32_verify_test.dart
git commit -m "$(cat <<'EOF'
docs(faltool): verify custom Base32 differs from hashlib_codecs Crockford

Ran a byte-for-byte verification between TypeID's custom Base32
encoder and hashlib_codecs' Crockford Base32. Outputs did not match,
which is expected — TypeID uses a fixed 16-byte -> 26-char encoding
with 3-bit top-of-byte padding on the first character that differs
from the standard Crockford bit layout. Keeps the custom encoder and
adds a NOTE comment pointing at the verification for future readers.
The temporary hashlib_codecs dep and verification test are removed.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Version bump to 2.0.0 and final cleanup

Bump `dart_faltool` to `2.0.0`, do a clean grep for any residual `crypto`/`uuid` references, rerun the full monorepo analysis + tests.

**Files:**
- Modify: `dart_faltool/pubspec.yaml`

- [ ] **Step 1: Bump version to `2.0.0`**

In `dart_faltool/pubspec.yaml`, change:

```yaml
version: 1.0.6
```

to:

```yaml
version: 2.0.0
```

- [ ] **Step 2: Run `melos get` to refresh pubspec.lock**

Run (from repo root):

```bash
melos get
```

Expected: clean resolve, no unexpected version warnings.

- [ ] **Step 3: Final grep for residual references**

Run (from repo root):

```bash
grep -rn 'package:crypto\|package:uuid' dart_faltool/lib dart_faltool/test
```

Expected: zero output (documentation files under `docs/` are excluded from this grep).

```bash
grep -rn 'UuidValue\|sha256\.convert\|v7obj\|Uuid()' dart_faltool/lib dart_faltool/test
```

Expected: zero output.

If either grep has matches, STOP and fix them as a separate commit before proceeding.

- [ ] **Step 4: Run the full `dart_faltool` test suite one more time**

Run:

```bash
cd dart_faltool && dart test
```

Expected: all tests PASS.

- [ ] **Step 5: Run analyzer across the entire monorepo**

Run (from repo root):

```bash
dart analyze
```

Expected: 0 warnings and 0 errors across every package (`dart_falconnect`, `dart_falmodel`, `dart_faltool`, `dart_falconx`).

- [ ] **Step 6: Confirm pubspec.yaml end state**

Open `dart_faltool/pubspec.yaml` and confirm:

- `version:` is `2.0.0`
- `dependencies:` contains `hashlib: ^2.3.4`
- `dependencies:` does NOT contain `crypto` or `uuid`
- `dependencies:` contains `hashlib_codecs` **only if** Task 3 BRANCH A was taken

- [ ] **Step 7: Commit**

```bash
git add dart_faltool/pubspec.yaml dart_faltool/pubspec.lock
git commit -m "$(cat <<'EOF'
chore(faltool)!: bump to 2.0.0 for hashlib migration

Major bump to reflect the breaking changes introduced in the
hashlib migration series:
- crypto re-export removed from dart_faltool.dart
- uuid re-export removed from dart_faltool.dart
- DecodedTypeId.uuid changed from UuidValue to String
- Base32 may or may not be in the public API depending on the
  verification outcome in the previous commit.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Success Criteria

After all four tasks are complete, each of the following must be true:

1. `grep -rn 'package:crypto\|package:uuid' dart_faltool/lib dart_faltool/test` returns no matches
2. `dart_faltool/pubspec.yaml` contains `hashlib: ^2.3.4` and `version: 2.0.0`; does NOT contain `crypto` or `uuid`
3. `melos get` succeeds cleanly from repo root
4. `cd dart_faltool && dart test` passes 100%
5. `dart analyze` across the monorepo reports 0 warnings and 0 errors
6. `dart_faltool/lib/dart_faltool.dart` re-exports `hashlib` in place of both `crypto` and `uuid`
7. `DecodedTypeId.uuid` is typed as `String`
8. Base32 decision is reflected in the repo: either `base32.dart` is gone and `typeid.dart` uses `hashlib_codecs`, or `base32.dart` is present with a NOTE comment explaining why
9. `melos build_runner` (or `dart run build_runner build -d` inside `dart_faltool`) completes without errors
