# Migrate `crypto` → `hashlib` (Maximal + Breaking)

**Date:** 2026-04-20
**Package:** `dart_faltool`
**Version bump:** 1.0.1 → 2.0.0 (major — breaking API)

## 1. Scope & Goals

Consolidate hash, UUID, and encoder concerns onto a single modern dependency (`hashlib: ^2.3.4` + `hashlib_codecs`) and drop the two narrowly-used packages it supersedes.

### Package changes (`dart_faltool/pubspec.yaml`)

- Remove `crypto: ^3.0.7`
- Remove `uuid: ^4.5.3`
- Add `hashlib: ^2.3.4`
- Add `hashlib_codecs` (latest on pub.dev at implementation time; required only if the Base32 verification in §3 passes)

### Affected files (confirmed via `grep`)

1. `dart_faltool/lib/extensions/string_extensions.dart` — `hashSha256()`
2. `dart_faltool/lib/dart_faltool.dart` — re-export
3. `dart_faltool/lib/lib.dart` — internal re-export (verify no `crypto`/`uuid` leakage)
4. `dart_faltool/lib/utils/uuid_generator.dart` — `UuidGenerator.getV4()`
5. `dart_faltool/lib/utils/typeid/typeid.dart` — `TypeId.generate()` / `decode()`
6. `dart_faltool/lib/utils/typeid/decoded_typeid.dart` — field `uuid` type
7. `dart_faltool/lib/utils/typeid/generated/decoded_typeid.freezed.dart` — regen via `melos build_runner`
8. `dart_faltool/lib/utils/typeid/base32.dart` — candidate for deletion pending verification (§3)
9. `dart_faltool/test/**` — existing tests must keep passing

No other package in the monorepo (`dart_falconnect`, `dart_falmodel`, `dart_falconx`) currently imports `crypto` or `uuid`; grep confirmed a single `sha256` call site in `string_extensions.dart:31`.

## 2. API Changes

### 2.1 `String.hashSha256({int? length})` — non-breaking

Signature unchanged. Internal implementation swap:

```dart
// old
final digest = sha256.convert(bytes);
final hash = digest.toString();

// new (hashlib chainable API)
final hash = sha256.string(this).hex();
```

Length padding/truncation logic is preserved as-is. SHA-256 is deterministic, so existing test assertions remain valid.

### 2.2 `UuidGenerator.getV4()` — non-breaking

Signature unchanged. Import source swapped from `package:uuid` to `package:hashlib/random.dart`; both expose `uuid.v4()` returning a canonical UUID string.

### 2.3 `TypeId.generate()` / `TypeId.decode()` — non-breaking

External signatures and output format unchanged. Internals:

```dart
// old
final v7 = uuid.v7obj();
final base32Encoded = Base32.encode(v7.toBytes());

// new
final v7String = uuid.v7();                  // hashlib: canonical string
final bytes = _uuidStringToBytes(v7String);  // helper: 16-byte Uint8List
final base32Encoded = Base32.encode(bytes);  // or Base32Codec.crockford if §3 passes
```

`decode()` mirror change: replace `UuidValue.fromByteList(bytes)` with canonical-string formatting.

### 2.4 `DecodedTypeId.uuid` — BREAKING

```dart
// old
@freezed
abstract class DecodedTypeId {
  const factory DecodedTypeId({
    required String prefix,
    required String suffix,
    required UuidValue uuid,  // from package:uuid
  }) = _DecodedTypeId;
}

// new
@freezed
abstract class DecodedTypeId {
  const factory DecodedTypeId({
    required String prefix,
    required String suffix,
    required String uuid,     // canonical form, e.g. '018f7d3a-....'
  }) = _DecodedTypeId;
}
```

**Consumer migration:** if bytes are needed, callers add a local extension method — not in scope here (YAGNI).

### 2.5 Re-export in `dart_faltool.dart` — BREAKING

```dart
// old
export 'package:crypto/crypto.dart' hide Hash;

// new
export 'package:hashlib/hashlib.dart';
// export 'package:hashlib/codecs.dart';  // add only if consumers need codec API
```

**Consumer migration:** replace `sha256.convert(bytes).toString()` with `sha256.convert(bytes).hex()` or the string form `sha256.string(text).hex()`.

## 3. Base32 Verification Strategy

TypeID's `Base32` uses the Crockford alphabet but a TypeID-specific bit-packing (3-bit top padding on the first char; fixed 16-byte → 26-char mapping). Standard Crockford encoders typically pad on the low-order side, so byte-for-byte equivalence is **not assumed**.

### 3.1 Verification steps (before deleting `base32.dart`)

Add a temporary test at `dart_faltool/test/utils/typeid/base32_verify_test.dart`:

```dart
test('hashlib_codecs Base32Codec.crockford matches TypeID Base32', () {
  final testCases = <Uint8List>[
    Uint8List(16),                                    // all zeros
    Uint8List.fromList(List.filled(16, 0xFF)),        // note: byte 0 must be <= 0x7F
    Uint8List.fromList(List.generate(16, (i) => i)),  // 0..15
    // + 50 random UUIDv7 bytes from uuid.v7()
  ];
  for (final bytes in testCases) {
    final ours = Base32.encode(bytes);
    final theirs = /* hashlib_codecs Crockford encode 16 bytes */;
    expect(ours, equals(theirs), reason: 'bytes=$bytes');
  }
});
```

### 3.2 Decision matrix

| Verification result | Action |
|---|---|
| All cases match | Delete `base32.dart` + `base32_test.dart`; `TypeId` calls `Base32Codec.crockford` directly |
| Any mismatch | **Keep `base32.dart` as-is**; add a file-level comment explaining why (TypeID spec ≠ standard Crockford) |

### 3.3 Hard invariants

- Do not delete `base32.dart` unless verification passes **and** the existing `base32_test.dart` still passes against the replacement.
- `TypeId.generate()` → `TypeId.decode()` round-trip must return the original bytes/prefix regardless of which path is chosen.
- Option B ("force hashlib even if output differs") is explicitly rejected — it would invalidate TypeIDs persisted in downstream databases.

## 4. File-by-File Changes & Testing Plan

### 4.1 File changes

| # | File | Change |
|---|---|---|
| 1 | `dart_faltool/pubspec.yaml` | drop `crypto`/`uuid`; add `hashlib: ^2.3.4` (+ `hashlib_codecs` if §3 passes); bump `version: 2.0.0` |
| 2 | `dart_faltool/lib/dart_faltool.dart` | remove `export 'package:crypto/crypto.dart' hide Hash;`; add `export 'package:hashlib/hashlib.dart';` |
| 3 | `dart_faltool/lib/lib.dart` | verify no stale `crypto`/`uuid` re-exports |
| 4 | `dart_faltool/lib/extensions/string_extensions.dart` | rewrite `hashSha256()` using hashlib |
| 5 | `dart_faltool/lib/utils/uuid_generator.dart` | import hashlib random; call `uuid.v4()` |
| 6 | `dart_faltool/lib/utils/typeid/typeid.dart` | replace `v7obj().toBytes()`; replace `UuidValue.fromByteList` with canonical string formatting |
| 7 | `dart_faltool/lib/utils/typeid/decoded_typeid.dart` | `UuidValue uuid` → `String uuid`; drop `package:uuid` import |
| 8 | `dart_faltool/lib/utils/typeid/generated/decoded_typeid.freezed.dart` | regen via `dart run build_runner build -d` |
| 9 | `dart_faltool/lib/utils/typeid/base32.dart` | delete iff §3 passes, else keep with rationale comment |
| 9b | `dart_faltool/lib/utils/typeid/typeid.dart` | if `base32.dart` is deleted, also remove `export 'base32.dart';` (line 3). This drops `Base32` from the public API — acceptable under the 2.0.0 major bump |
| 10 | `dart_faltool/test/extensions/string_extensions_test.dart` | assertions remain valid (SHA-256 deterministic); confirm |
| 11 | `dart_faltool/test/utils/typeid/*_test.dart` | all round-trip tests pass; if §3 passes and `base32.dart` is removed, either redirect or remove `base32_test.dart` |
| 12 | `dart_faltool/test/utils/typeid/base32_verify_test.dart` | temporary; delete after §3 decision |

### 4.2 Pre-merge grep checklist

- `package:crypto` and `package:uuid` → zero matches under `dart_faltool/lib` and `dart_faltool/test`
- `UuidValue`, `sha256.convert`, `v7obj`, `v4()` (from `package:uuid`) — confirm no stale references
- `export 'package:crypto` / `export 'package:uuid` — zero matches in any barrel file

### 4.3 Testing plan

**Unit (existing):**

1. `dart test` in `dart_faltool` — all existing tests pass
2. `hashSha256` — expected hashes unchanged
3. `base32_test.dart` — all round-trips pass (against whichever implementation is kept)
4. TypeID tests — `generate → decode` round-trip equivalence

**Temporary verification:**

5. `base32_verify_test.dart` — must run and produce a clear pass/fail before §3 decision

**Integration / manual:**

6. `melos build_runner` clean
7. `dart analyze` across the monorepo — zero warnings/errors
8. `melos get` clean (no orphaned deps)

### 4.4 Rollout (split commits for easy review/revert)

1. **Commit 1 — deps & re-export:** `pubspec.yaml` + `dart_faltool.dart` + version bump
2. **Commit 2 — replace `crypto`:** `hashSha256()` rewrite + test confirm
3. **Commit 3 — replace `uuid`:** `UuidGenerator`, `TypeId`, `DecodedTypeId` (+ freezed regen)
4. **Commit 4 — Base32 decision:** adds `base32_verify_test.dart`, then either deletes `base32.dart` or keeps it with rationale; deletes the verify test afterward

## 5. Risks, Non-goals, Success Criteria

### 5.1 Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `hashlib_codecs` Crockford Base32 ≠ TypeID spec | High (~80%) | High — persisted TypeIDs would become undecodable | §3 verify; keep custom Base32 on mismatch |
| hashlib `uuid.v7()` has no direct bytes API | Medium | Low | parse canonical hex string → `Uint8List(16)` helper |
| Internal monorepo consumer relies on re-exported `sha256`/`UuidValue` | Low (grep currently clean) | Medium | re-grep each package before merge; fix in same commit if found |
| `very_good_analysis` strict rules flag hashlib API | Low | Low | explicit type annotations; narrow `// ignore` only if unavoidable |
| `.freezed.dart` regen drift after field type change | Low | Low | `build_runner build -d` + review git diff |
| Lingering `UuidValue` references in generated files | Low | Medium | grep `UuidValue` across entire `dart_faltool` before merge |

### 5.2 Non-goals

- Do not migrate other hashlib features (HMAC, PBKDF2, OTP, password hashing) — separate feature work if ever needed
- Do not bump version of other packages unless they fail to compile
- Do not change `TypeId` / `UuidGenerator` public signatures
- Do not add `String.toUuidBytes()` or similar helpers — consumer-side concern (YAGNI)
- Do not touch `dart:convert` usage (base64/utf8) — stays on SDK built-ins

### 5.3 Success Criteria

1. `grep -r 'package:crypto\|package:uuid' dart_faltool/` returns no matches (excluding this spec/changelog)
2. `dart_faltool/pubspec.yaml` contains `hashlib: ^2.3.4`, no `crypto`, no `uuid`
3. `melos get` and `melos build_runner` both succeed cleanly
4. `dart test` in `dart_faltool` passes 100%
5. `dart analyze` across the monorepo reports 0 warnings and 0 errors
6. `dart_faltool/lib/dart_faltool.dart` re-exports `hashlib` in place of `crypto`
7. `DecodedTypeId.uuid` field type is `String`
8. `dart_faltool/pubspec.yaml` version is `2.0.0`
9. Base32 decision is documented (either `base32.dart` deleted after verify pass, or kept with a rationale comment)
