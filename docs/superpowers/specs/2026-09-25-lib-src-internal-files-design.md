# Internal files under lib/src

**Date:** 2026-09-25
**Packages:** `dart_falconnect`, `dart_falmodel`, `dart_faltool`; `dart_falconx` is unchanged.
**Version:** 2.2.0, unreleased. This change bumps no version and changes no behavior.
**Builds on:** the platform adapter spec (`2026-09-25-http-platform-adapter-design.md`), which put its private files in `dart_falconnect/lib/src/`.

## 1. Context

By Dart convention, the files under a package's `lib/src/` are its private implementation. A package that imports another package's `src` file triggers the `implementation_imports` lint, which `very_good_analysis` enables. Every other file under `lib/` can be imported by path, so it reads as public API even when no barrel exports it.

`dart_falconnect/lib/src/` already holds eleven files: six helpers and the five platform adapter files. A scan of the export graph of the three packages, starting from each barrel (`lib/<package>.dart`), found seven files outside `lib/src/` that no barrel exports:

| Package | File | Role | Imported by |
|---|---|---|---|
| `dart_falconnect` | `lib/lib.dart` | internal prelude: re-exports `dart:async`, `dart:convert`, `ansicolor`, the sibling barrels, `freezed_annotation`, and its own barrel | 19 files in `lib/`, 2 in `test/` |
| `dart_falmodel` | `lib/lib.dart` | internal prelude: re-exports `dart:async`, `dart:convert`, `dart_faltool`, `dio`, `freezed_annotation`, `json_annotation`, and its own barrel | 73 files in `lib/`, 5 in `test/`, and 1 file in `dart_faltool` |
| `dart_falmodel` | `lib/extensions/_io_stubs.dart`, `lib/extensions/_io_real.dart` | the web and `dart:io` sides of a conditional import | `lib/extensions/exception_extensions.dart` |
| `dart_faltool` | `lib/lib.dart` | internal prelude: re-exports `dart:async`, `dart:convert`, `ansicolor`, `dart_falmodel`, `yaml`, and its own barrel | 15 files in `lib/`, 20 in `test/` |
| `dart_faltool` | `lib/utils/_app_info_web.dart`, `lib/utils/_app_info_io.dart` | the web and `dart:io` sides of a conditional import | `lib/utils/app_info.dart` |

Every other file outside `lib/src/` is reachable from its package barrel.

A leading underscore in a file name hides nothing: Dart imports `_io_real.dart` like any other file, and `implementation_imports` ignores it. Only `lib/src/` carries the convention that tools check.

The four local projects that depend on dart-falconx (`getdoit_service`, `brick_dartfrog`, `jaspr-falconx`, and the other repositories under `projects/FalconX`) import none of the seven files. The consumer skill tells apps to import only the barrels.

## 2. Goals and non-goals

**Goals**

- Every package follows one rule: a file that no app imports lives under `lib/src/`.
- The seven files of section 1 move there.
- No barrel changes what it exports, and no class or function changes.

**Non-goals**

- Hiding exported classes that look internal, such as `AuthSession`, `RequestStampInterceptor`, `TokenRefreshInterceptor`, or `Base32`. Removing them from a barrel removes public API and needs a major version.
- Moving every implementation file under `lib/src/` with the barrels re-exporting them, the layout of Flutter and dio.
- `@internal` annotations.
- A test that enforces the rule; the `CLAUDE.md` rule of section 5 carries it.
- A forwarding `lib/lib.dart` that re-exports the moved prelude.

## 3. File moves

Each move uses `git mv`, so history follows the file.

| Package | From | To |
|---|---|---|
| `dart_falconnect` | `lib/lib.dart` | `lib/src/src.dart` |
| `dart_falmodel` | `lib/lib.dart` | `lib/src/src.dart` |
| `dart_falmodel` | `lib/extensions/_io_stubs.dart` | `lib/src/extensions/io_stubs.dart` |
| `dart_falmodel` | `lib/extensions/_io_real.dart` | `lib/src/extensions/io_real.dart` |
| `dart_faltool` | `lib/lib.dart` | `lib/src/src.dart` |
| `dart_faltool` | `lib/utils/_app_info_web.dart` | `lib/src/utils/app_info_web.dart` |
| `dart_faltool` | `lib/utils/_app_info_io.dart` | `lib/src/utils/app_info_io.dart` |

- The prelude is named `src.dart`, the owner's choice.
- The platform files drop the leading underscore, since `lib/src/` already marks them private, as `platform_adapter_io.dart` is named.
- A moved file keeps the folder it had outside `lib/src/`, as `lib/src/engine/https/` mirrors `lib/engine/https/`.

## 4. Content changes

### 4.1 The preludes

Each prelude ends with a relative export of its own barrel, such as `export 'dart_falconnect.dart';`. In `lib/src/` that path no longer resolves, so it becomes a package URI:

```dart
export 'package:dart_falconnect/dart_falconnect.dart';
```

and the same for `dart_falmodel` and `dart_faltool`. The other exports of each prelude stay as they are.

### 4.2 Imports of a package's own prelude

Every `import 'package:<package>/lib.dart';` inside the same package becomes `import 'package:<package>/src/src.dart';`.

| Package | `lib/` | `test/` |
|---|---|---|
| `dart_falconnect` | 19 | 2 |
| `dart_falmodel` | 73 | 5 |
| `dart_faltool` | 15 | 20 |

A test importing its own package's `src` file raises no lint; `implementation_imports` checks only other packages.

### 4.3 Conditional imports

`dart_falmodel/lib/extensions/exception_extensions.dart`:

```dart
import 'package:dart_falmodel/src/extensions/io_stubs.dart'
    if (dart.library.io) 'package:dart_falmodel/src/extensions/io_real.dart';
```

`dart_faltool/lib/utils/app_info.dart`:

```dart
import 'package:dart_faltool/src/utils/app_info_web.dart'
    if (dart.library.io) 'package:dart_faltool/src/utils/app_info_io.dart'
    as impl;
```

Both conditions and the `as impl` prefix stay as they are.

### 4.4 The one import across packages

`dart_faltool/lib/extensions/base64_extensions.dart` imports `package:dart_falmodel/lib.dart`. After the move that path would be another package's `src` file, which `implementation_imports` rejects. The file switches to its own package's prelude, `package:dart_faltool/src/src.dart`, like every other file in `dart_faltool`. That prelude re-exports `dart:convert` and `dart_faltool.dart`, and the barrel re-exports `dart:typed_data`, which covers every symbol the file uses: `base64`, `base64Decode`, `base64Encode`, `base64Url`, `utf8`, and `Uint8List`.

## 5. Documentation

| File | Change |
|---|---|
| `dart_falconnect/CLAUDE.md` | The entry-point bullet for `lib.dart` names `lib/src/src.dart`; the import rule reads "Import `package:dart_falconnect/src/src.dart` in a new file", with its exceptions unchanged |
| `dart_falmodel/CLAUDE.md` | The prelude bullet names `lib/src/src.dart`; "never at `lib.dart`" becomes "never at `src/src.dart`" |
| `dart_faltool/CLAUDE.md` | The entry-point bullet names `lib/src/src.dart`; the import rule names `package:dart_faltool/src/src.dart` |
| `CLAUDE.md` (root) | A new rule: put a file that no app imports under `lib/src/`, at the folder it would have outside `lib/src/`, and export from a barrel only what apps use |

The consumer skill never mentions `lib.dart`, so it needs no change. The repository has no `CHANGELOG` file; the owner adds one line to the 2.2.0 release notes: "The internal preludes `lib.dart` moved to `lib/src/src.dart`; import the package barrels."

## 6. Verification

Run from the repository root after each commit:

- `melos run analyze`: an unresolved import or an `implementation_imports` violation fails it.
- `melos run format` and `melos run build_runner:check`: generated `part` files are untouched, and the check proves it.
- `melos run test`: the counts match the baseline, falconnect 439 (1 skip), faltool 771, falmodel 71, falconx 1.

Once at the end:

- `melos run test:platforms`: the two conditional imports moved, so the js, wasm, and exe compile gate and the Chrome tests under dart2js and dart2wasm must pass.
- `grep -rn "/lib.dart'" dart_*/lib dart_*/test` prints nothing.
- The export-graph scan of section 1 finds no file outside `lib/src/` that its barrel does not export.

## 7. Implementation logistics

- Execute in a git worktree on branch `feature/lib-src` from `develop`.
- Commit in this order, so every commit leaves analyze and tests green:
  1. `dart_faltool`: its prelude, its platform files, and `base64_extensions.dart`, which stops depending on the `dart_falmodel` prelude before that prelude moves.
  2. `dart_falmodel`: its prelude and its platform files.
  3. `dart_falconnect`: its prelude.
  4. Documentation.
- Rewrite the import lines with a script that replaces the exact string `package:<package>/lib.dart'`, then let `melos run analyze` catch any line the script missed.
- Commit with `git add <paths>` and `git commit -m "..." -- <paths>`. No `Co-Authored-By` or AI attribution.
- Do not bump the version, push, merge, or tag.

## 8. Risks

| Risk | Mitigation |
|---|---|
| An app outside this machine imports a moved file by path | The barrels are unchanged, the consumer skill names only the barrels, and the 2.2.0 release notes say where the preludes went |
| A moved conditional import breaks one platform | `melos run test:platforms` covers js, wasm, and native |
| The import rewrite misses a line | `melos run analyze` fails on the unresolved import |

## 9. Details decided in this spec, for owner review

1. `base64_extensions.dart` switches to its own package's prelude rather than to the `dart_falmodel` barrel plus `dart:` imports, as the chat design said; the prelude already covers every symbol it uses, and every other `dart_faltool` file imports it.
2. The self-export of each prelude uses a package URI.
3. The commits go `dart_faltool`, `dart_falmodel`, `dart_falconnect`, documentation.
4. With no `CHANGELOG` in the repository, the note about the move goes into the 2.2.0 release notes, which the owner writes at release.
