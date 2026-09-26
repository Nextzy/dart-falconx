# Internal Files Under lib/src Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the seven files under `lib/` that no barrel exports into `lib/src/`, with no change to any barrel or behavior.

**Architecture:** Each package's internal prelude `lib/lib.dart` becomes `lib/src/src.dart`, and the four platform files of two conditional imports move to `lib/src/` without their leading underscore. A script rewrites every import of a package's own prelude, and `dart analyze` proves that no import was missed. One commit per package, in dependency order, then one documentation commit.

**Tech Stack:** Dart 3.13, melos, `very_good_analysis` (`implementation_imports`, `directives_ordering`), git.

**Spec:** `docs/superpowers/specs/2026-09-25-lib-src-internal-files-design.md`

## Global Constraints

- Version 2.2.0, unreleased. This plan never bumps the version, pushes, merges, or tags.
- No barrel (`lib/<package>.dart`) changes what it exports, and no class or function changes.
- `dart_falconx` is not touched.
- Every move uses `git mv`.
- A package never imports another package's `lib/src/` file.
- The preludes are named `src.dart`; the platform files drop their leading underscore.
- No new dependency.
- Commit with `git add <paths>` then `git commit -m "..." -- <paths>`. No `Co-Authored-By` or AI attribution.

## Review Focus

1. **An app that imports a moved file by path**, such as `package:dart_falmodel/lib.dart`. Expected: no local consumer does; the 2.2.0 release notes say where the preludes went. Task 4 step "Search the local consumers" pins it.
2. **The web and wasm builds of the two moved conditional imports** (`exception_extensions.dart`, `app_info.dart`). Expected: `dart compile js`, `wasm`, and `exe` of `compile_smoke.dart`, which reaches both through the `dart_falconnect` barrel, and the Chrome tests under dart2js and dart2wasm pass. Task 4 step "Run the platform gates".
3. **A package that imports a sibling package's `src/` file**, as `base64_extensions.dart` would after the move. Expected: none. Task 1 switches it to its own prelude; Task 4 step "Check that no package reaches into another's src" pins it.
4. **An import order that `directives_ordering` flags after the rename**: `src/src.dart` sorts after `src/engine/...`. `melos run analyze` exits 0 on infos, so only the per-package "No issues found!" line shows it. Expected: four "No issues found!" lines. Task 3 step "Sort the imports" and Task 4 step "Run every gate".
5. **Generated `part` files**, which never import the prelude. Expected: `melos run build_runner:check` passes unchanged. Task 4 step "Run every gate".

## Provenance

Every block below comes from a throwaway prototype cut from `develop` at `fa5b139`, then replayed on a second throwaway worktree by applying this plan's own blocks; the replay matched the prototype with zero diff lines. Gates on the prototype after each task: `melos run analyze` clean with "No issues found!" for every package, `melos run test` falconnect 439 (1 skip), faltool 771, falmodel 71, falconx 1. After Task 4: `melos run format` and `build_runner:check` clean, `melos run test:platforms` passes with falconnect 404 under dart2js and dart2wasm, no import of any `lib.dart` remains, and the export-graph scan finds no unexported file outside `lib/src/` (it finds the seven files on `develop`). Both throwaway worktrees are deleted.

Prototype findings, for owner review:

1. Renaming the falconnect prelude reorders two import lists: in `http_client.dart` and `log_interceptor.dart`, `src/src.dart` now sorts after `src/engine/...`. `dart fix --apply --code=directives_ordering` sorts them (Task 3).
2. `melos run analyze` exits 0 on infos, so every gate reads the per-package "No issues found!" line, not only the exit code.

## Execution setup

```bash
cd "/Users/nonthawit/Data/NTD OS/projects/FalconX/dart-falconx"
git worktree add -b feature/lib-src .claude/worktrees/lib-src develop
cd .claude/worktrees/lib-src
dart pub get
```

Run every `dart` command from the package directory a task names, and every `melos` or `git` command from the worktree root.

## File map

| File | Task | Change |
|---|---|---|
| `dart_faltool/lib/lib.dart` → `lib/src/src.dart` | 1 | move; self-export becomes a package URI |
| `dart_faltool/lib/utils/_app_info_web.dart`, `_app_info_io.dart` → `lib/src/utils/app_info_web.dart`, `app_info_io.dart` | 1 | move |
| `dart_faltool/lib/utils/app_info.dart` | 1 | conditional import points at the moved files |
| `dart_faltool/lib/extensions/base64_extensions.dart` | 1 | imports its own prelude instead of `dart_falmodel`'s |
| 35 files in `dart_faltool/lib` and `test` | 1 | prelude import rewritten |
| `dart_falmodel/lib/lib.dart` → `lib/src/src.dart` | 2 | move; self-export becomes a package URI |
| `dart_falmodel/lib/extensions/_io_stubs.dart`, `_io_real.dart` → `lib/src/extensions/io_stubs.dart`, `io_real.dart` | 2 | move |
| `dart_falmodel/lib/extensions/exception_extensions.dart` | 2 | conditional import points at the moved files |
| 78 files in `dart_falmodel/lib` and `test` | 2 | prelude import rewritten |
| `dart_falconnect/lib/lib.dart` → `lib/src/src.dart` | 3 | move; self-export becomes a package URI |
| 21 files in `dart_falconnect/lib` and `test`; `http_client.dart`, `log_interceptor.dart` | 3 | prelude import rewritten; two import lists sorted |
| `CLAUDE.md`, `dart_falconnect/CLAUDE.md`, `dart_falmodel/CLAUDE.md`, `dart_faltool/CLAUDE.md` | 4 | the new rule and the prelude path |

---

### Task 1: dart_faltool

`dart_faltool` goes first: its `base64_extensions.dart` imports the `dart_falmodel` prelude, so it must stop before Task 2 moves that prelude.

**Files:**
- Move: `dart_faltool/lib/lib.dart`, `dart_faltool/lib/utils/_app_info_web.dart`, `dart_faltool/lib/utils/_app_info_io.dart`
- Modify: `dart_faltool/lib/src/src.dart`, `dart_faltool/lib/utils/app_info.dart`, `dart_faltool/lib/extensions/base64_extensions.dart`, and the 35 files that import the prelude

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `package:dart_faltool/src/src.dart`, the faltool prelude, with the same exports as the old `lib.dart`.

- [ ] **Step 1: Move the files**

Run from `dart_faltool/`:

```bash
mkdir -p lib/src/utils
git mv lib/lib.dart lib/src/src.dart
git mv lib/utils/_app_info_web.dart lib/src/utils/app_info_web.dart
git mv lib/utils/_app_info_io.dart lib/src/utils/app_info_io.dart
```

- [ ] **Step 2: Run the analyzer to verify it fails**

Run: `dart analyze | grep -c uri_does_not_exist`
Expected: `38`: the 35 imports of `package:dart_faltool/lib.dart`, the relative self-export in `lib/src/src.dart`, and both URIs of the conditional import in `lib/utils/app_info.dart`.

- [ ] **Step 3: Write the prelude**

The self-export becomes a package URI, sorted among the other package exports.

<!-- file: dart_faltool/lib/src/src.dart -->
```dart
export 'dart:async';
export 'dart:convert';

export 'package:ansicolor/ansicolor.dart';
export 'package:dart_falmodel/dart_falmodel.dart';
export 'package:dart_faltool/dart_faltool.dart';
export 'package:yaml/yaml.dart';
```

- [ ] **Step 4: Rewrite the imports of the prelude**

Run from `dart_faltool/`:

```bash
python3 - <<'EOF'
import pathlib
old, new = "package:dart_faltool/lib.dart'", "package:dart_faltool/src/src.dart'"
n = 0
for root in ('lib', 'test'):
    for p in pathlib.Path(root).rglob('*.dart'):
        s = p.read_text()
        if old in s:
            p.write_text(s.replace(old, new))
            n += s.count(old)
print(f'rewrote {n} imports')
EOF
```

Expected: `rewrote 35 imports`.

- [ ] **Step 5: Point the conditional import at the moved files**

<!-- replace: dart_faltool/lib/utils/app_info.dart -->
```dart
import 'package:dart_faltool/utils/_app_info_web.dart'
    if (dart.library.io) '_app_info_io.dart'
    as impl;
```

with:

<!-- with -->
```dart
import 'package:dart_faltool/src/utils/app_info_web.dart'
    if (dart.library.io) 'package:dart_faltool/src/utils/app_info_io.dart'
    as impl;
```

- [ ] **Step 6: Import the package's own prelude in `base64_extensions.dart`**

The faltool prelude re-exports `dart:convert` and `dart_faltool.dart`, which re-exports `dart:typed_data`, so it covers `base64`, `base64Decode`, `base64Encode`, `base64Url`, `utf8`, and `Uint8List`.

<!-- replace: dart_faltool/lib/extensions/base64_extensions.dart -->
```dart
import 'package:dart_falmodel/lib.dart';
```

with:

<!-- with -->
```dart
import 'package:dart_faltool/src/src.dart';
```

- [ ] **Step 7: Run the package checks to verify they pass**

Run from `dart_faltool/`: `dart analyze && dart format --set-exit-if-changed . && dart test`
Expected: `No issues found!`, `Formatted 56 files (0 changed)`, and `+771: All tests passed!`.

- [ ] **Step 8: Run the repository gates**

Run from the worktree root: `melos run analyze && melos run test`
Expected: SUCCESS; "No issues found!" for each of the four packages; falconnect 439 (1 skip), faltool 771, falmodel 71, falconx 1.

- [ ] **Step 9: Commit**

```bash
git add dart_faltool/lib dart_faltool/test
git commit -m "refactor(dart_faltool): move the internal prelude and platform files under lib/src" -m "lib/lib.dart becomes lib/src/src.dart, and the two sides of the AppInfo conditional import move to lib/src/utils/ without their leading underscore, so no file outside lib/src/ is left unexported. base64_extensions.dart imports its own package's prelude instead of dart_falmodel's, which would be another package's src file once that prelude moves." -- dart_faltool/lib dart_faltool/test
```

---

### Task 2: dart_falmodel

**Files:**
- Move: `dart_falmodel/lib/lib.dart`, `dart_falmodel/lib/extensions/_io_stubs.dart`, `dart_falmodel/lib/extensions/_io_real.dart`
- Modify: `dart_falmodel/lib/src/src.dart`, `dart_falmodel/lib/extensions/exception_extensions.dart`, and the 78 files that import the prelude

**Interfaces:**
- Consumes: Task 1, which removed the only import of this prelude from another package.
- Produces: `package:dart_falmodel/src/src.dart`, the falmodel prelude, with the same exports as the old `lib.dart`.

- [ ] **Step 1: Move the files**

Run from `dart_falmodel/`:

```bash
mkdir -p lib/src/extensions
git mv lib/lib.dart lib/src/src.dart
git mv lib/extensions/_io_stubs.dart lib/src/extensions/io_stubs.dart
git mv lib/extensions/_io_real.dart lib/src/extensions/io_real.dart
```

- [ ] **Step 2: Run the analyzer to verify it fails**

Run: `dart analyze | grep -c uri_does_not_exist`
Expected: `81`: the 78 imports of `package:dart_falmodel/lib.dart`, the relative self-export in `lib/src/src.dart`, and both URIs of the conditional import in `lib/extensions/exception_extensions.dart`.

- [ ] **Step 3: Write the prelude**

<!-- file: dart_falmodel/lib/src/src.dart -->
```dart
export 'dart:async';
export 'dart:convert';

export 'package:dart_falmodel/dart_falmodel.dart';
export 'package:dart_faltool/dart_faltool.dart';
export 'package:dio/dio.dart';
export 'package:freezed_annotation/freezed_annotation.dart';
export 'package:json_annotation/json_annotation.dart';
```

- [ ] **Step 4: Rewrite the imports of the prelude**

Run from `dart_falmodel/`:

```bash
python3 - <<'EOF'
import pathlib
old, new = "package:dart_falmodel/lib.dart'", "package:dart_falmodel/src/src.dart'"
n = 0
for root in ('lib', 'test'):
    for p in pathlib.Path(root).rglob('*.dart'):
        s = p.read_text()
        if old in s:
            p.write_text(s.replace(old, new))
            n += s.count(old)
print(f'rewrote {n} imports')
EOF
```

Expected: `rewrote 78 imports`.

- [ ] **Step 5: Point the conditional import at the moved files**

<!-- replace: dart_falmodel/lib/extensions/exception_extensions.dart -->
```dart
import 'package:dart_falmodel/extensions/_io_stubs.dart'
    if (dart.library.io) '_io_real.dart';
```

with:

<!-- with -->
```dart
import 'package:dart_falmodel/src/extensions/io_stubs.dart'
    if (dart.library.io) 'package:dart_falmodel/src/extensions/io_real.dart';
```

- [ ] **Step 6: Run the package checks to verify they pass**

Run from `dart_falmodel/`: `dart analyze && dart format --set-exit-if-changed . && dart test`
Expected: `No issues found!`, `Formatted 116 files (0 changed)`, and `+71: All tests passed!`.

- [ ] **Step 7: Run the repository gates**

Run from the worktree root: `melos run analyze && melos run test`
Expected: SUCCESS; "No issues found!" for each of the four packages; falconnect 439 (1 skip), faltool 771, falmodel 71, falconx 1.

- [ ] **Step 8: Commit**

```bash
git add dart_falmodel/lib dart_falmodel/test
git commit -m "refactor(dart_falmodel): move the internal prelude and platform files under lib/src" -m "lib/lib.dart becomes lib/src/src.dart, and the two sides of the exception extensions' conditional import move to lib/src/extensions/ without their leading underscore, so no file outside lib/src/ is left unexported." -- dart_falmodel/lib dart_falmodel/test
```

---

### Task 3: dart_falconnect

**Files:**
- Move: `dart_falconnect/lib/lib.dart`
- Modify: `dart_falconnect/lib/src/src.dart`, the 21 files that import the prelude, and the import order of `lib/engine/https/http_client.dart` and `lib/engine/https/interceptors/log_interceptor.dart`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `package:dart_falconnect/src/src.dart`, the falconnect prelude, with the same exports as the old `lib.dart`.

- [ ] **Step 1: Move the prelude**

Run from `dart_falconnect/`:

```bash
git mv lib/lib.dart lib/src/src.dart
```

- [ ] **Step 2: Run the analyzer to verify it fails**

Run: `dart analyze | grep -c uri_does_not_exist`
Expected: `22`: the 21 imports of `package:dart_falconnect/lib.dart` and the relative self-export in `lib/src/src.dart`.

- [ ] **Step 3: Write the prelude**

<!-- file: dart_falconnect/lib/src/src.dart -->
```dart
export 'dart:async';
export 'dart:convert';

export 'package:ansicolor/ansicolor.dart';
export 'package:dart_falconnect/dart_falconnect.dart';
export 'package:dart_falmodel/dart_falmodel.dart';
export 'package:dart_faltool/dart_faltool.dart';
export 'package:freezed_annotation/freezed_annotation.dart';
```

- [ ] **Step 4: Rewrite the imports of the prelude**

Run from `dart_falconnect/`:

```bash
python3 - <<'EOF'
import pathlib
old, new = "package:dart_falconnect/lib.dart'", "package:dart_falconnect/src/src.dart'"
n = 0
for root in ('lib', 'test'):
    for p in pathlib.Path(root).rglob('*.dart'):
        s = p.read_text()
        if old in s:
            p.write_text(s.replace(old, new))
            n += s.count(old)
print(f'rewrote {n} imports')
EOF
```

Expected: `rewrote 21 imports`.

- [ ] **Step 5: Run the analyzer to see the import order it flags**

Run: `dart analyze`
Expected: `2 issues found.`, both `directives_ordering` infos, in `lib/engine/https/http_client.dart` and `lib/engine/https/interceptors/log_interceptor.dart`: `package:dart_falconnect/src/src.dart` now sorts after `package:dart_falconnect/src/engine/...`.

- [ ] **Step 6: Sort the imports**

Run: `dart fix --apply --code=directives_ordering`
Expected: `2 fixes made in 2 files.`

- [ ] **Step 7: Run the package checks to verify they pass**

Run from `dart_falconnect/`: `dart analyze && dart format --set-exit-if-changed . && dart test`
Expected: `No issues found!`, `Formatted 118 files (0 changed)`, and `+439 ~1: All tests passed!`.

- [ ] **Step 8: Run the repository gates**

Run from the worktree root: `melos run analyze && melos run test`
Expected: SUCCESS; "No issues found!" for each of the four packages; falconnect 439 (1 skip), faltool 771, falmodel 71, falconx 1.

- [ ] **Step 9: Commit**

```bash
git add dart_falconnect/lib dart_falconnect/test
git commit -m "refactor(dart_falconnect): move the internal prelude under lib/src" -m "lib/lib.dart becomes lib/src/src.dart, so no file outside lib/src/ is left unexported. Two import lists are re-sorted, since src/src.dart now sorts after src/engine/." -- dart_falconnect/lib dart_falconnect/test
```

---

### Task 4: Documentation and final gates

**Files:**
- Modify: `CLAUDE.md`, `dart_falconnect/CLAUDE.md`, `dart_falmodel/CLAUDE.md`, `dart_faltool/CLAUDE.md`

**Interfaces:**
- Consumes: the three preludes at `lib/src/src.dart` (Tasks 1 to 3).
- Produces: no code.

- [ ] **Step 1: Add the rule to the root `CLAUDE.md`**

<!-- replace: CLAUDE.md -->
```markdown
- Leave the `dart_faltool` ↔ `dart_falmodel` cycle in place: Dart workspace resolution resolves it, and it breaks no layering rule.
```

with:

<!-- with -->
```markdown
- Leave the `dart_faltool` ↔ `dart_falmodel` cycle in place: Dart workspace resolution resolves it, and it breaks no layering rule.
- Put a file that no app imports under `lib/src/`, in the folder it would have outside `lib/src/`, and export from a barrel only what apps use. Each package's internal prelude is `lib/src/src.dart`; files inside the package import it, and consumers import the barrel.
```

- [ ] **Step 2: Name the new prelude path in the package `CLAUDE.md` files**

<!-- replace: dart_falconnect/CLAUDE.md -->
```markdown
- `lib.dart`: internal import; re-exports
```

with:

<!-- with -->
```markdown
- `lib/src/src.dart`: internal prelude; re-exports
```

<!-- replace: dart_falconnect/CLAUDE.md -->
```markdown
- Import `package:dart_falconnect/lib.dart` in a new file,
```

with:

<!-- with -->
```markdown
- Import `package:dart_falconnect/src/src.dart` in a new file,
```

<!-- replace: dart_falmodel/CLAUDE.md -->
```markdown
- `lib/lib.dart` is the internal prelude:
```

with:

<!-- with -->
```markdown
- `lib/src/src.dart` is the internal prelude:
```

<!-- replace: dart_falmodel/CLAUDE.md -->
```markdown
never at `lib.dart`.
```

with:

<!-- with -->
```markdown
never at `src/src.dart`.
```

<!-- replace: dart_faltool/CLAUDE.md -->
```markdown
- `lib/lib.dart`: internal entry point;
```

with:

<!-- with -->
```markdown
- `lib/src/src.dart`: internal entry point;
```

<!-- replace: dart_faltool/CLAUDE.md -->
```markdown
- Import `package:dart_faltool/lib.dart` from source files
```

with:

<!-- with -->
```markdown
- Import `package:dart_faltool/src/src.dart` from source files
```

- [ ] **Step 3: Check that no document names the old prelude**

Run from the worktree root: `grep -rn "lib\.dart" CLAUDE.md dart_*/CLAUDE.md skills/ | grep -v "src/src"`
Expected: no output.

- [ ] **Step 4: Run every gate**

Run from the worktree root:

```bash
melos run analyze
melos run format
melos run build_runner:check
melos run test
melos run test:platforms
```

Expected: each prints SUCCESS; `melos run analyze` shows "No issues found!" for all four packages. VM: falconnect 439 (1 skip), faltool 771, falmodel 71, falconx 1. Chrome: falconnect 404 under dart2js and under dart2wasm. The compile gate builds `compile_smoke.dart`, which reaches both moved conditional imports through the `dart_falconnect` barrel, to js, wasm, and exe.

- [ ] **Step 5: Check that no import of an old prelude remains**

Run from the worktree root: `grep -rn "/lib.dart'" dart_*/lib dart_*/test`
Expected: no output.

- [ ] **Step 6: Check that no package reaches into another's src**

Run from the worktree root:

```bash
for p in dart_falconnect dart_falmodel dart_faltool dart_falconx; do
  grep -rnE "package:dart_fal[a-z]+/src/" $p/lib $p/test 2>/dev/null | grep -v "package:$p/src/"
done
```

Expected: no output.

- [ ] **Step 7: Run the export-graph scan**

Run from the worktree root:

```bash
python3 - <<'EOF'
import os, re
PK = ['dart_falconnect', 'dart_falmodel', 'dart_faltool']
exp = re.compile(r"^\s*export\s+'([^']+)'((?:\s+if\s*\([^)]*\)\s*'[^']+')*)", re.M)
cond = re.compile(r"'([^']+)'")
def target(pkg, frm, uri):
    if uri.startswith('dart:'): return None
    if uri.startswith('package:'):
        p, rest = uri[8:].split('/', 1)
        return (p, os.path.normpath(rest)) if p in PK else None
    return (pkg, os.path.normpath(os.path.join(os.path.dirname(frm), uri)))
bad = 0
for p in PK:
    files = set()
    for root, _, fs in os.walk(f'{p}/lib'):
        for f in fs:
            full = os.path.join(root, f)
            if f.endswith('.dart') and not re.search(r'^part of', open(full).read(), re.M):
                files.add(os.path.relpath(full, f'{p}/lib'))
    seen, stack = set(), [(p, f'{p}.dart')]
    while stack:
        n = stack.pop()
        if n in seen or n[0] != p: continue
        seen.add(n)
        for m in exp.finditer(open(f'{p}/lib/{n[1]}').read()):
            for u in [m.group(1)] + cond.findall(m.group(2) or ''):
                t = target(p, n[1], u)
                if t: stack.append(t)
    left = sorted(r for r in files if not r.startswith('src/') and (p, r) not in seen)
    bad += len(left)
    print(f'{p}: unexported files outside lib/src: {left or "none"}')
print(f'total: {bad}')
EOF
```

Expected: `none` for each package and `total: 0`. On `develop` before this plan the same scan lists the seven moved files.

- [ ] **Step 8: Search the local consumers**

Run: `cd ~/Data && rg -l --glob '*.dart' --glob '!**/dart-falconx/**' --glob '!**/.dart_tool/**' --glob '!**/build/**' "package:dart_fal(connect|model|tool)/(lib\.dart|extensions/_|utils/_)" .`
Expected: no output: no local project imports a moved file by its old path.

- [ ] **Step 9: Commit**

```bash
git add CLAUDE.md dart_falconnect/CLAUDE.md dart_falmodel/CLAUDE.md dart_faltool/CLAUDE.md
git commit -m "docs: put files no app imports under lib/src" -m "The root CLAUDE.md gains the rule that a file no app imports lives under lib/src/, in the folder it would have outside it, and that each package's internal prelude is lib/src/src.dart. The package CLAUDE.md files name the new prelude path." -- CLAUDE.md dart_falconnect/CLAUDE.md dart_falmodel/CLAUDE.md dart_faltool/CLAUDE.md
```

- [ ] **Step 10: Hand over the release note**

The repository has no `CHANGELOG`. Give the owner this line for the 2.2.0 release notes: "The internal preludes `lib.dart` moved to `lib/src/src.dart`; import the package barrels." Do not merge, push, or tag.
