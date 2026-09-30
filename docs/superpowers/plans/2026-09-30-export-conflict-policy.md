# Export Conflict Policy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove every export name collision between the FalconX barrels and the `dart:` libraries, Flutter, jaspr, and dart_frog, and give each repository a check that fails on any new collision.

**Architecture:** A standalone Dart package, `tool/export_check/`, reads export namespaces with `package:analyzer`, compares each barrel with its target libraries, and applies an allowlist. All three repositories carry the same engine (`lib/`, `test/`), and each has its own `bin/check.dart` configuration. `dart-falconx` 2.4.0 removes the collisions at the source: it hides `dart:math`'s `log` and renames three of its own declarations. `flutter-falconx` 4.1.0 and `jaspr-falconx` 2.0.0 then move to 2.4.0 and settle the framework-side hides.

**Tech Stack:** Dart 3.13, `analyzer` 14.4.0, `package:test`, melos 8 scripts, build_runner with freezed and json_serializable, git flow.

**Spec:** `docs/superpowers/specs/2026-09-30-export-conflict-policy-design.md`

## Global Constraints

- Every new pubspec sets `sdk: ">=3.13.0 <4.0.0"`.
- Tool dependencies: `analyzer: ^14.4.0` and `path: ^1.9.1`; dev dependencies `test: ^1.32.0` and `very_good_analysis: ^11.0.0`. Only the `dart-falconx` copy adds `dart_frog: ^1.2.6`.
- `tool/export_check/` never joins a workspace: its pubspec has no `resolution: workspace`, and no root `workspace:` list names it.
- `dart-falconx` packages stay pure Dart and never depend on Flutter.
- Renames: `SocketException` becomes `SocketClientException`, `RefreshCallback` becomes `TokenRefreshCallback`, `RemoteError` becomes `RemoteErrorBody`. No deprecated alias keeps an old name.
- The policy decides where each collision is fixed:
  - A declaration these repositories own collides with anything: rename it.
  - A re-exported name collides with a `dart:` library: hide it in the barrel that re-exports it.
  - A re-exported name collides with one framework: hide the non-framework side in that framework's adapter.
  - A re-exported name collides with dart_frog or shelf: the app-level barrel hides it.
  - Removing the collision breaks a supported use: allowlist it with a reason.
- Versions: `dart-falconx` 2.4.0, `flutter-falconx` 4.1.0, `jaspr-falconx` 2.0.0. The owner chose the two minor bumps on 2026-09-30 although both releases rename and remove public symbols.
- A public API change updates the repository's consumer skill in the same commit.
- Commit messages follow Conventional Commits, as in `git log`. Add no `Co-Authored-By` line or other AI attribution.
- Stage explicit paths, and commit with a pathspec (`git commit -m "…" -- <paths>`) so that nothing the owner staged rides along. Never run `git add -A`, `git add .`, or `git commit -a`. On 2026-09-30 the `dart-falconx` tree held the owner's unrelated edits: a staged deletion of `.claude/rules/communication-style.md`, and changes to `.claude/settings.json` and `.gitignore`. Task 1 records whatever such edits exist; Task 7 stashes them around the git flow release, which needs a clean tree, and restores them afterwards.
- Every command block starts at the repository root named in its Part heading.
- `git push` waits for the owner's explicit yes at execution time.
- Mark every test that imports `dart:io` with `@TestOn('vm')`.

## Review Focus

1. Running the check from a directory other than `tool/export_check` must fail; it must never pass because it loaded nothing. Task 1 pins this: a missing root directory throws a `StateError`.
2. A mistyped barrel URI, or a workspace nobody bootstrapped, must fail with a message that names the URI. Task 1 pins this: a library that does not resolve throws a `StateError`.
3. An allowlisted name that comes back in a barrel the entry does not name must fail, for example when someone drops `hide TextDirection` from `flutter_falconx`. Task 1 pins this with allowlist keys that name the subject barrel.
4. An allowlist entry that outlives its collision must fail, as the stale `hide Link` should have. Task 1 pins this with the stale-entry test.
5. App code that imports a barrel next to `dart:developer` or `dart:io` must get the SDK's `log` and `SocketException`. Tasks 3 and 4 pin both with tests written the way an app writes such code.

## Spec amendments made while planning

A prototype of the engine in this plan ran against all three repositories on 2026-09-30 and matched the expected output below. It surfaced four facts the first spec draft missed, and the spec now carries them:

- `flutter-falconx` is at 4.0.1, which stopped the sibling re-exports. intl's `TextDirection` reaches only `flutter_faltool`, so the allowlist names only that barrel.
- The uncommitted work in `jaspr-falconx` moves its refs to 2.3.1, and its barrels need an `HttpResponse` allowlist entry.
- `jaspr_falconx` keeps riverpod's `AsyncError` over `dart:async`'s, so the jaspr `frameworkOwned` list adds `package:jaspr_riverpod/` and `package:riverpod/`.
- The loader rejects a missing root directory (Review Focus 1).

## File map

**dart-falconx**

| Path | Action | Responsibility |
|---|---|---|
| `tool/export_check/pubspec.yaml`, `pubspec.lock` | Create | Standalone tool package |
| `tool/export_check/lib/export_check.dart` | Create | Library barrel |
| `tool/export_check/lib/src/collisions.dart` | Create | Pure collision and allowlist logic |
| `tool/export_check/lib/src/namespace_loader.dart` | Create | Reads export namespaces through `package:analyzer` |
| `tool/export_check/lib/src/run_check.dart` | Create | Runs a whole check, prints failures, returns the exit code |
| `tool/export_check/test/*.dart` | Create | Engine tests |
| `tool/export_check/bin/check.dart` | Create | This repository's subjects, targets, and allowlist |
| `pubspec.yaml` | Modify | `check:exports` melos script; release version |
| `CLAUDE.md` | Modify | Command, policy, release gate |
| `dart_faltool/lib/dart_faltool.dart` | Modify | `hide log` (plus the uncommitted `IterableFilter` hide) |
| `dart_faltool/test/sdk_name_collisions_test.dart` | Create | `dart:developer`'s `log` next to the barrel |
| `dart_falconnect/lib/engine/sockets/**` | Modify | `SocketClientException` rename |
| `dart_falconnect/test/engine/sockets/socket_client_exception_test.dart` | Create | Rename, and `dart:io`'s `SocketException` next to the barrel |
| `dart_falconnect/lib/engine/https/config/auth_config.dart` and its generated file | Modify | `TokenRefreshCallback` rename |
| `dart_falconnect/test/engine/https/interceptors/token_refresh_interceptor_test.dart` | Modify | Uses the new typedef |
| `dart_falmodel/lib/networks/https/responses/remote_error_body.dart` and its generated files | Create (move) | `RemoteErrorBody` rename |
| `dart_falmodel/lib/networks/https/responses/responses.dart` | Modify | Barrel export |
| `dart_falmodel/test/networks/https/remote_error_body_test.dart` | Create | `RemoteErrorBody` behaviour |
| `dart_falconnect/CLAUDE.md`, `skills/dart-falconx-package/**` | Modify | Docs |

**flutter-falconx:** `tool/export_check/` (engine copied, own `pubspec.yaml` and `bin/check.dart`), `pubspec.yaml`, `flutter_falconx/lib/flutter_falconx.dart`, `flutter_faltool/lib/flutter_faltool.dart`, three package pubspecs, `CLAUDE.md`, `CHANGELOG.md`, `skills/flutter-falconx-package/**`.

**jaspr-falconx:** `tool/export_check/` (same as above), `pubspec.yaml`, `jaspr_faltool/lib/jaspr_faltool.dart`, `jaspr_faltool/lib/lib.dart`, `jaspr_falkit/lib/lib.dart`, three package pubspecs, `CLAUDE.md`.

---

## Part 1: dart-falconx 2.4.0

Work in `/Users/nonthawit/Data/NTD OS/projects/FalconX/dart-falconx` unless a step says otherwise.

### Task 1: Export check engine

**Files:**
- Create: `tool/export_check/pubspec.yaml`
- Create: `tool/export_check/lib/export_check.dart`
- Create: `tool/export_check/lib/src/collisions.dart`
- Create: `tool/export_check/lib/src/namespace_loader.dart`
- Create: `tool/export_check/lib/src/run_check.dart`
- Test: `tool/export_check/test/collisions_test.dart`, `tool/export_check/test/namespace_loader_test.dart`, `tool/export_check/test/run_check_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces (every later task relies on these exact names):
  - `typedef ExportNamespace = Map<String, String>;` maps a name to the URI of its declaring library.
  - `typedef Collision = ({String subject, String name, String subjectDeclaration, String target, String targetDeclaration});`
  - `typedef AllowlistKey = ({String subject, String name});`
  - `typedef Verdict = ({List<Collision> unallowed, List<AllowlistKey> staleEntries});`
  - `typedef LibraryRef = ({String uri, String root});`
  - `List<Collision> findCollisions({required Map<String, ExportNamespace> subjects, required Map<String, ExportNamespace> targets, List<String> frameworkOwned = const []})`
  - `Verdict applyAllowlist(List<Collision> collisions, Map<AllowlistKey, String> allowlist)`
  - `String describeCollision(Collision collision)`
  - `Future<Map<String, ExportNamespace>> loadNamespaces(List<LibraryRef> refs)`
  - `Future<int> runCheck({required List<LibraryRef> subjects, required List<LibraryRef> targets, required Map<AllowlistKey, String> allowlist, List<String> frameworkOwned = const [], StringSink? out})`
  - Output lines: `FAIL <describeCollision>`, `STALE allowlist entry <name> in <subject> matches no collision`, and `OK: every collision is in the allowlist (<count>)`.

- [ ] **Step 1: Start the feature branch**

```bash
git switch -c feature/export-conflict-policy develop
git status --short
```

Expected: the branch `feature/export-conflict-policy`, with ` M dart_faltool/lib/dart_faltool.dart` still unstaged; Task 3 commits it. Write down every other path `git status --short` lists: those are the owner's unrelated edits, which no task commits and Task 7 stashes. A plain branch carries all of them without depending on git flow's clean-tree checks.

- [ ] **Step 2: Create the tool package**

Create `tool/export_check/pubspec.yaml`:

```yaml
name: export_check
description: >-
  Fails when a barrel exports a name that collides with a dart library or a
  supported framework and the allowlist does not record it.
publish_to: none

environment:
  sdk: ">=3.13.0 <4.0.0"

dependencies:
  analyzer: ^14.4.0
  dart_frog: ^1.2.6
  path: ^1.9.1

dev_dependencies:
  test: ^1.32.0
  very_good_analysis: ^11.0.0
```

Run: `cd tool/export_check && dart pub get`
Expected: `Changed N dependencies!` and a new `tool/export_check/pubspec.lock`.

- [ ] **Step 3: Write the failing collision tests**

Create `tool/export_check/test/collisions_test.dart`:

```dart
import 'package:export_check/export_check.dart';
import 'package:test/test.dart';

Collision _collision(String subject, String name) => (
  subject: subject,
  name: name,
  subjectDeclaration: 'package:x/x.dart',
  target: 'dart:io',
  targetDeclaration: 'dart:io',
);

void main() {
  group('findCollisions', () {
    test('reports a name that both sides bind to different declarations', () {
      final collisions = findCollisions(
        subjects: {
          'package:a/a.dart': {'log': 'dart:math'},
        },
        targets: {
          'dart:developer': {'log': 'dart:developer'},
        },
      );

      expect(collisions, [
        (
          subject: 'package:a/a.dart',
          name: 'log',
          subjectDeclaration: 'dart:math',
          target: 'dart:developer',
          targetDeclaration: 'dart:developer',
        ),
      ]);
    });

    test('ignores a name that both sides bind to one declaration', () {
      final collisions = findCollisions(
        subjects: {
          'package:a/a.dart': {'Future': 'dart:async'},
        },
        targets: {
          'dart:async': {'Future': 'dart:async'},
        },
      );

      expect(collisions, isEmpty);
    });

    test('ignores a name that only one side exports', () {
      final collisions = findCollisions(
        subjects: {
          'package:a/a.dart': {'Foo': 'package:a/src/foo.dart'},
        },
        targets: {
          'dart:io': {'File': 'dart:io'},
        },
      );

      expect(collisions, isEmpty);
    });

    test('skips setter entries', () {
      final collisions = findCollisions(
        subjects: {
          'package:a/a.dart': {'x=': 'package:a/a.dart'},
        },
        targets: {
          'dart:io': {'x=': 'dart:io'},
        },
      );

      expect(collisions, isEmpty);
    });

    test('skips a subject declaration under a frameworkOwned prefix', () {
      final collisions = findCollisions(
        subjects: {
          'package:app/app.dart': {
            'Flow': 'package:flutter/src/widgets/basic.dart',
            'log': 'dart:math',
          },
        },
        targets: {
          'dart:developer': {'Flow': 'dart:developer', 'log': 'dart:developer'},
        },
        frameworkOwned: ['package:flutter/'],
      );

      expect(collisions.map((collision) => collision.name), ['log']);
    });

    test('sorts by subject, name, then target', () {
      final collisions = findCollisions(
        subjects: {
          'package:b/b.dart': {'Z': 'package:b/b.dart'},
          'package:a/a.dart': {
            'Z': 'package:a/a.dart',
            'A': 'package:a/a.dart',
          },
        },
        targets: {
          'dart:io': {'Z': 'dart:io', 'A': 'dart:io'},
          'dart:html': {'Z': 'dart:html'},
        },
      );

      expect(collisions.map((c) => '${c.subject} ${c.name} ${c.target}'), [
        'package:a/a.dart A dart:io',
        'package:a/a.dart Z dart:html',
        'package:a/a.dart Z dart:io',
        'package:b/b.dart Z dart:html',
        'package:b/b.dart Z dart:io',
      ]);
    });
  });

  group('applyAllowlist', () {
    test('fails a collision that the allowlist does not hold', () {
      final verdict = applyAllowlist([
        _collision('package:a/a.dart', 'Path'),
      ], {});

      expect(verdict.unallowed, [_collision('package:a/a.dart', 'Path')]);
      expect(verdict.staleEntries, isEmpty);
    });

    test('passes a collision that the allowlist holds for its subject', () {
      final verdict = applyAllowlist(
        [_collision('package:a/a.dart', 'Path')],
        {(subject: 'package:a/a.dart', name: 'Path'): 'reason'},
      );

      expect(verdict.unallowed, isEmpty);
      expect(verdict.staleEntries, isEmpty);
    });

    test('fails the same name in a subject that the entry does not name', () {
      final verdict = applyAllowlist(
        [
          _collision('package:a/a.dart', 'Path'),
          _collision('package:b/b.dart', 'Path'),
        ],
        {(subject: 'package:a/a.dart', name: 'Path'): 'reason'},
      );

      expect(verdict.unallowed, [_collision('package:b/b.dart', 'Path')]);
    });

    test('reports an entry that matches no collision as stale', () {
      final verdict = applyAllowlist([], {
        (subject: 'package:a/a.dart', name: 'Link'): 'reason',
      });

      expect(verdict.staleEntries, [
        (subject: 'package:a/a.dart', name: 'Link'),
      ]);
    });
  });

  test('describeCollision names both declarations', () {
    final line = describeCollision((
      subject: 'package:a/a.dart',
      name: 'log',
      subjectDeclaration: 'dart:math',
      target: 'dart:developer',
      targetDeclaration: 'dart:developer',
    ));

    expect(
      line,
      'package:a/a.dart: log is declared in dart:math, '
      'but dart:developer declares it in dart:developer',
    );
  });
}
```

- [ ] **Step 4: Run the tests to verify they fail**

Run: `cd tool/export_check && dart test test/collisions_test.dart`
Expected: a compilation error, because `lib/export_check.dart` does not exist.

- [ ] **Step 5: Implement the pure logic**

Create `tool/export_check/lib/src/collisions.dart`:

```dart
/// Maps each name a library exports to the URI of the library that declares
/// it.
typedef ExportNamespace = Map<String, String>;

/// A name that a subject barrel and a target library bind to different
/// declarations.
typedef Collision = ({
  String subject,
  String name,
  String subjectDeclaration,
  String target,
  String targetDeclaration,
});

/// One allowlist entry: a name that one subject barrel may keep exporting.
typedef AllowlistKey = ({String subject, String name});

/// What fails the check: collisions the allowlist does not hold, and
/// allowlist entries that match no collision.
typedef Verdict = ({
  List<Collision> unallowed,
  List<AllowlistKey> staleEntries,
});

/// Returns every name that a subject and a target bind to different
/// declarations, sorted by subject, name, and target.
///
/// Skips setter entries (`name=`), which mirror their getters, and names
/// whose subject-side declaration starts with a [frameworkOwned] prefix.
List<Collision> findCollisions({
  required Map<String, ExportNamespace> subjects,
  required Map<String, ExportNamespace> targets,
  List<String> frameworkOwned = const [],
}) {
  return [
    for (final MapEntry(key: subject, value: subjectNames) in subjects.entries)
      for (final MapEntry(key: target, value: targetNames) in targets.entries)
        for (final MapEntry(key: name, value: subjectDeclaration)
            in subjectNames.entries)
          if (!name.endsWith('=') &&
              !frameworkOwned.any(subjectDeclaration.startsWith))
            if (targetNames[name] case final targetDeclaration?
                when targetDeclaration != subjectDeclaration)
              (
                subject: subject,
                name: name,
                subjectDeclaration: subjectDeclaration,
                target: target,
                targetDeclaration: targetDeclaration,
              ),
  ]..sort(_compareCollisions);
}

/// Splits [collisions] against [allowlist]. A collision fails unless the
/// allowlist holds its subject and name; an entry fails when it matches no
/// collision.
Verdict applyAllowlist(
  List<Collision> collisions,
  Map<AllowlistKey, String> allowlist,
) {
  final matched = {
    for (final collision in collisions)
      (subject: collision.subject, name: collision.name),
  };
  return (
    unallowed: [
      for (final collision in collisions)
        if (!allowlist.containsKey((
          subject: collision.subject,
          name: collision.name,
        )))
          collision,
    ],
    staleEntries: [
      for (final key in allowlist.keys)
        if (!matched.contains(key)) key,
    ],
  );
}

/// Describes [collision] on one line.
String describeCollision(Collision collision) =>
    '${collision.subject}: ${collision.name} is declared in '
    '${collision.subjectDeclaration}, but ${collision.target} declares it in '
    '${collision.targetDeclaration}';

int _compareCollisions(Collision a, Collision b) {
  final bySubject = a.subject.compareTo(b.subject);
  if (bySubject != 0) return bySubject;
  final byName = a.name.compareTo(b.name);
  if (byName != 0) return byName;
  return a.target.compareTo(b.target);
}
```

Create `tool/export_check/lib/export_check.dart` with only the pure part for now:

```dart
/// Finds names that a barrel exports with a different declaration than a
/// `dart:` library or a framework library does.
library;

export 'src/collisions.dart';
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `cd tool/export_check && dart test test/collisions_test.dart`
Expected: `+11: All tests passed!`

- [ ] **Step 7: Write the failing loader and runner tests**

Create `tool/export_check/test/namespace_loader_test.dart`:

```dart
@TestOn('vm')
library;

import 'package:export_check/export_check.dart';
import 'package:test/test.dart';

void main() {
  test('maps each exported name to the library that declares it', () async {
    final namespaces = await loadNamespaces([
      (uri: 'dart:math', root: '.'),
      (uri: 'package:path/path.dart', root: '.'),
    ]);

    expect(namespaces['dart:math']!['Random'], 'dart:math');
    expect(
      namespaces['package:path/path.dart']!['Context'],
      'package:path/src/context.dart',
    );
  });

  test('throws a StateError when a library does not resolve', () {
    expect(
      loadNamespaces([
        (uri: 'package:missing_package/missing.dart', root: '.'),
      ]),
      throwsStateError,
    );
  });

  test('throws a StateError when a root directory does not exist', () {
    expect(
      loadNamespaces([(uri: 'dart:math', root: 'missing_directory')]),
      throwsStateError,
    );
  });
}
```

Create `tool/export_check/test/run_check_test.dart`:

```dart
@TestOn('vm')
library;

import 'package:export_check/export_check.dart';
import 'package:test/test.dart';

const LibraryRef _math = (uri: 'dart:math', root: '.');
const LibraryRef _developer = (uri: 'dart:developer', root: '.');

void main() {
  test('fails on a collision that the allowlist does not hold', () async {
    final out = StringBuffer();

    final code = await runCheck(
      subjects: [_math],
      targets: [_developer],
      allowlist: const {},
      out: out,
    );

    expect(code, 1);
    expect(
      out.toString(),
      contains(
        'FAIL dart:math: log is declared in dart:math, '
        'but dart:developer declares it in dart:developer',
      ),
    );
  });

  test('passes when the allowlist holds every collision', () async {
    final out = StringBuffer();

    final code = await runCheck(
      subjects: [_math],
      targets: [_developer],
      allowlist: const {(subject: 'dart:math', name: 'log'): 'test'},
      out: out,
    );

    expect(code, 0);
    expect(out.toString(), contains('OK: every collision is in the allowlist'));
  });

  test('fails on an allowlist entry that matches no collision', () async {
    final out = StringBuffer();

    final code = await runCheck(
      subjects: [_math],
      targets: [_developer],
      allowlist: const {
        (subject: 'dart:math', name: 'log'): 'test',
        (subject: 'dart:math', name: 'Random'): 'test',
      },
      out: out,
    );

    expect(code, 1);
    expect(
      out.toString(),
      contains('STALE allowlist entry Random in dart:math matches no collision'),
    );
  });
}
```

- [ ] **Step 8: Run the tests to verify they fail**

Run: `cd tool/export_check && dart test`
Expected: compilation errors: `loadNamespaces`, `runCheck`, and `LibraryRef` are not defined.

- [ ] **Step 9: Implement the loader and the runner**

Create `tool/export_check/lib/src/namespace_loader.dart`:

```dart
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:export_check/src/collisions.dart';
import 'package:path/path.dart' as p;

/// A library to read, and a directory whose package config resolves it.
typedef LibraryRef = ({String uri, String root});

/// Reads the export namespace of every library in [refs], keyed by URI.
///
/// A relative root resolves against the current directory. Throws a
/// [StateError] when a root directory does not exist or a library does not
/// resolve from its root.
Future<Map<String, ExportNamespace>> loadNamespaces(
  List<LibraryRef> refs,
) async {
  String rootOf(LibraryRef ref) => p.normalize(p.absolute(ref.root));

  final roots = {for (final ref in refs) rootOf(ref)};
  for (final root in roots) {
    if (!Directory(root).existsSync()) {
      throw StateError('Root directory $root does not exist');
    }
  }
  final collection = AnalysisContextCollection(includedPaths: roots.toList());
  try {
    final namespaces = <String, ExportNamespace>{};
    for (final ref in refs) {
      final session = collection.contextFor(rootOf(ref)).currentSession;
      final result = await session.getLibraryByUri(ref.uri);
      if (result is! LibraryElementResult) {
        throw StateError(
          '${ref.uri} does not resolve from ${ref.root}: '
          '${result.runtimeType}',
        );
      }
      final names = result.element.exportNamespace.definedNames2;
      namespaces[ref.uri] = {
        for (final MapEntry(:key, :value) in names.entries)
          key: value.library?.uri.toString() ?? '',
      };
    }
    return namespaces;
  } finally {
    await collection.dispose();
  }
}
```

Create `tool/export_check/lib/src/run_check.dart`:

```dart
import 'dart:io';

import 'package:export_check/src/collisions.dart';
import 'package:export_check/src/namespace_loader.dart';

/// Loads [subjects] and [targets], writes every failure to [out], and
/// returns the process exit code: 0 when nothing fails, 1 otherwise.
Future<int> runCheck({
  required List<LibraryRef> subjects,
  required List<LibraryRef> targets,
  required Map<AllowlistKey, String> allowlist,
  List<String> frameworkOwned = const [],
  StringSink? out,
}) async {
  final sink = out ?? stdout;
  final namespaces = await loadNamespaces([...subjects, ...targets]);
  final collisions = findCollisions(
    subjects: {for (final ref in subjects) ref.uri: namespaces[ref.uri]!},
    targets: {for (final ref in targets) ref.uri: namespaces[ref.uri]!},
    frameworkOwned: frameworkOwned,
  );
  final verdict = applyAllowlist(collisions, allowlist);
  for (final collision in verdict.unallowed) {
    sink.writeln('FAIL ${describeCollision(collision)}');
  }
  for (final key in verdict.staleEntries) {
    sink.writeln(
      'STALE allowlist entry ${key.name} in ${key.subject} '
      'matches no collision',
    );
  }
  if (verdict.unallowed.isEmpty && verdict.staleEntries.isEmpty) {
    sink.writeln(
      'OK: every collision is in the allowlist (${collisions.length})',
    );
    return 0;
  }
  return 1;
}
```

Replace `tool/export_check/lib/export_check.dart` with:

```dart
/// Finds names that a barrel exports with a different declaration than a
/// `dart:` library or a framework library does.
library;

export 'src/collisions.dart';
export 'src/namespace_loader.dart';
export 'src/run_check.dart';
```

- [ ] **Step 10: Run the tests to verify they pass**

Run: `cd tool/export_check && dart test`
Expected: `+17: All tests passed!` (about 25 s; each loader test builds an analysis context).

- [ ] **Step 11: Analyze and format**

Run: `cd tool/export_check && dart analyze && dart format --set-exit-if-changed .`
Expected: `No issues found!` and exit code 0. The root `analysis_options.yaml` (very_good_analysis) applies to the tool.

- [ ] **Step 12: Commit**

```bash
git add tool/export_check/pubspec.yaml tool/export_check/pubspec.lock tool/export_check/lib tool/export_check/test
git commit -m "feat(tool): add the export conflict check engine"
```

### Task 2: dart-falconx check configuration, melos script, and docs

**Files:**
- Create: `tool/export_check/bin/check.dart`
- Modify: `pubspec.yaml` (append a melos script)
- Modify: `CLAUDE.md`
- Modify: `skills/dart-falconx-package/SKILL.md`

**Interfaces:**
- Consumes: `runCheck`, `LibraryRef`, and `AllowlistKey` from Task 1.
- Produces: `melos run check:exports`. Tasks 3 to 7 read its output.

- [ ] **Step 1: Write this repository's configuration**

Create `tool/export_check/bin/check.dart`:

```dart
import 'dart:io';

import 'package:export_check/export_check.dart';

/// A workspace member; its package config resolves every package and every
/// `dart:` library in this repository.
const _workspace = '../../dart_falconx';

/// This tool's own directory, whose package config resolves `dart_frog`.
const _tool = '.';

const List<LibraryRef> _subjects = [
  (uri: 'package:dart_falconx/dart_falconx.dart', root: _workspace),
  (uri: 'package:dart_falconnect/dart_falconnect.dart', root: _workspace),
  (uri: 'package:dart_falmodel/dart_falmodel.dart', root: _workspace),
  (uri: 'package:dart_faltool/dart_faltool.dart', root: _workspace),
];

const List<LibraryRef> _targets = [
  (uri: 'dart:async', root: _workspace),
  (uri: 'dart:collection', root: _workspace),
  (uri: 'dart:convert', root: _workspace),
  (uri: 'dart:core', root: _workspace),
  (uri: 'dart:developer', root: _workspace),
  (uri: 'dart:ffi', root: _workspace),
  (uri: 'dart:io', root: _workspace),
  (uri: 'dart:isolate', root: _workspace),
  (uri: 'dart:js_interop', root: _workspace),
  (uri: 'dart:js_interop_unsafe', root: _workspace),
  (uri: 'dart:math', root: _workspace),
  (uri: 'dart:typed_data', root: _workspace),
  (uri: 'package:dart_frog/dart_frog.dart', root: _tool),
];

const _retrofitHttpResponse =
    "Retrofit's HttpResponse; code that Retrofit generates for a method "
    'returning HttpResponse<T> needs it. Server apps hide it in their '
    'app-level barrel.';
const _dartFrogName =
    "dio's or Retrofit's name; dart_frog apps hide it in their app-level "
    'barrel.';

const Map<AllowlistKey, String> _allowlist = {
  (subject: 'package:dart_falconx/dart_falconx.dart', name: 'HttpResponse'):
      _retrofitHttpResponse,
  (subject: 'package:dart_falconx/dart_falconx.dart', name: 'Response'):
      _dartFrogName,
  (subject: 'package:dart_falconx/dart_falconx.dart', name: 'FormData'):
      _dartFrogName,
  (subject: 'package:dart_falconx/dart_falconx.dart', name: 'HttpMethod'):
      _dartFrogName,
  (
    subject: 'package:dart_falconnect/dart_falconnect.dart',
    name: 'HttpResponse',
  ): _retrofitHttpResponse,
  (subject: 'package:dart_falconnect/dart_falconnect.dart', name: 'Response'):
      _dartFrogName,
  (subject: 'package:dart_falconnect/dart_falconnect.dart', name: 'FormData'):
      _dartFrogName,
  (subject: 'package:dart_falconnect/dart_falconnect.dart', name: 'HttpMethod'):
      _dartFrogName,
};

Future<void> main() async {
  exitCode = await runCheck(
    subjects: _subjects,
    targets: _targets,
    allowlist: _allowlist,
  );
}
```

- [ ] **Step 2: Add the melos script**

`pubspec.yaml` ends with the `outdated` script inside `melos:` → `scripts:`. Append, keeping the four-space indentation of the other scripts:

```yaml

    check:exports:
      description: Fail when a barrel exports a name that collides with a dart library or dart_frog and tool/export_check/bin/check.dart does not allowlist it.
      run: cd tool/export_check && dart pub get && dart run bin/check.dart
```

- [ ] **Step 3: Run the check and confirm the known collisions**

Run: `time melos run check:exports`
Expected: exit code 1, about 25 s, and exactly these six lines:

```text
FAIL package:dart_falconnect/dart_falconnect.dart: SocketException is declared in package:dart_falconnect/engine/sockets/exceptions/socket_exception.dart, but dart:io declares it in dart:io
FAIL package:dart_falconx/dart_falconx.dart: RemoteError is declared in package:dart_falmodel/networks/https/responses/remote_error.dart, but dart:isolate declares it in dart:isolate
FAIL package:dart_falconx/dart_falconx.dart: SocketException is declared in package:dart_falconnect/engine/sockets/exceptions/socket_exception.dart, but dart:io declares it in dart:io
FAIL package:dart_falconx/dart_falconx.dart: log is declared in dart:math, but dart:developer declares it in dart:developer
FAIL package:dart_falmodel/dart_falmodel.dart: RemoteError is declared in package:dart_falmodel/networks/https/responses/remote_error.dart, but dart:isolate declares it in dart:isolate
FAIL package:dart_faltool/dart_faltool.dart: log is declared in dart:math, but dart:developer declares it in dart:developer
```

No `STALE` line may appear. A `StateError` means the workspace needs `melos bootstrap`.

- [ ] **Step 4: Document the command and the policy in `CLAUDE.md`**

In the Commands table, add this row after the `melos run build_runner:watch` row:

```markdown
| `melos run check:exports`                | `tool/export_check`: fails on an export name collision that its allowlist does not settle (about 25 s) |
```

Between the last Code generation bullet ("Run `melos run build_runner` after editing …") and `## Gotchas`, insert:

```markdown
### Export conflicts

A barrel that re-exports a name another library also exports either replaces a `dart:` declaration without any diagnostic or breaks apps with `ambiguous_import`. `melos run check:exports` compares the export namespace of every barrel with the `dart:` libraries and `dart_frog`. It fails on a collision that `_allowlist` in `tool/export_check/bin/check.dart` does not hold, and on an allowlist entry that no longer matches. Settle a collision by this table:

| Collision | Fixed in | How |
|---|---|---|
| A declaration owned by this repository collides with anything | The declaring package | Rename; add no deprecated alias under the old name |
| A re-exported name collides with a `dart:` library | The barrel that re-exports it | `hide` |
| A re-exported name collides with one framework (Flutter, jaspr) | That framework's adapter repository | `hide` the non-framework side |
| A re-exported name collides with dart_frog or shelf | The app-level barrel | `hide` there; allowlist it here |
| Removing the collision breaks a supported use | `_allowlist` | Record the reason |

The design is in `docs/superpowers/specs/2026-09-30-export-conflict-policy-design.md`.
```

Under Skill maintenance, replace:

```markdown
Before bumping a version, confirm the skill still matches the source. A bump sets the same version in all five pubspecs and in every sibling `ref:`.
```

with:

```markdown
Before bumping a version, confirm the skill still matches the source and `melos run check:exports` passes. A bump sets the same version in all five pubspecs and in every sibling `ref:`.
```

- [ ] **Step 5: Document the dart_frog barrel in the consumer skill**

In `skills/dart-falconx-package/SKILL.md`, under `## Gotchas`, after the bullet that starts "- `dart_falmodel` alone does not re-export `dio`", add:

````markdown
- dart_frog apps: dio's `Response` and `FormData` and Retrofit's `HttpMethod` collide with dart_frog's, and Retrofit's `HttpResponse` replaces `dart:io`'s without any diagnostic. Import both through one app-level barrel, and reach dio's `Response` through `import 'package:dio/dio.dart' as dio;` where a route calls an HTTP client:

  ```dart
  export 'package:dart_falconx/dart_falconx.dart'
      hide FormData, HttpMethod, HttpResponse, Response;
  export 'package:dart_frog/dart_frog.dart';
  ```
````

- [ ] **Step 6: Format and commit**

```bash
dart format tool/export_check/bin
git add tool/export_check/bin/check.dart pubspec.yaml CLAUDE.md skills/dart-falconx-package/SKILL.md
git commit -m "feat(tool): check dart-falconx barrels for export name collisions"
```

### Task 3: Hide `dart:math`'s `log`

**Files:**
- Modify: `dart_faltool/lib/dart_faltool.dart`
- Test: `dart_faltool/test/sdk_name_collisions_test.dart`
- Modify: `skills/dart-falconx-package/SKILL.md`, `skills/dart-falconx-package/references/third-party.md`

**Interfaces:**
- Consumes: `melos run check:exports` from Task 2.
- Produces: `dart_faltool` exports `dart:math` without `log`, and no longer exports dartx's `IterableFilter` (the uncommitted hide).

- [ ] **Step 1: Write the failing test**

Create `dart_faltool/test/sdk_name_collisions_test.dart`:

```dart
import 'dart:developer';

import 'package:dart_faltool/dart_faltool.dart';
import 'package:test/test.dart';

void main() {
  test("dart:developer's log stays reachable next to the barrel", () {
    expect(() => log('dart_faltool'), returnsNormally);
  });

  test('the barrel still re-exports the rest of dart:math', () {
    expect(max(1, 2), 2);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd dart_faltool && dart test test/sdk_name_collisions_test.dart`
Expected: a compilation error, because `log` is imported from both `dart:developer` and `dart:math`.

- [ ] **Step 3: Hide `log`**

In `dart_faltool/lib/dart_faltool.dart`, replace:

```dart
export 'dart:math';
```

with:

```dart
export 'dart:math' hide log;
```

- [ ] **Step 4: Run the test and the check**

Run: `cd dart_faltool && dart test test/sdk_name_collisions_test.dart`
Expected: `+2: All tests passed!`

Run: `melos run check:exports`
Expected: exit code 1 with only the four `SocketException` and `RemoteError` lines of Task 2, Step 3; both `log` lines are gone.

- [ ] **Step 5: Update the consumer skill**

In `skills/dart-falconx-package/SKILL.md`, replace the start of the Hidden symbols bullet:

```markdown
- Hidden symbols: `dart_faltool` hides `dartx` `IterableAll`, `IterableAppend`, `IterableNumAverageExtension`,
```

with:

```markdown
- Hidden symbols: `dart_faltool` hides `dart:math` `log`, which collides with `dart:developer`'s (write `import 'dart:math' as math;` and `math.log`), and `dartx` `IterableAll`, `IterableAppend`, `IterableFilter` (use `where`), `IterableNumAverageExtension`,
```

In `skills/dart-falconx-package/references/third-party.md`, replace:

```markdown
`dart:` libraries re-exported by `dart_faltool`: `dart:async`, `dart:convert`, `dart:math`, `dart:typed_data`.
```

with:

```markdown
`dart:` libraries re-exported by `dart_faltool`: `dart:async`, `dart:convert`, `dart:math` (without `log`), `dart:typed_data`.
```

- [ ] **Step 6: Commit**

`git diff dart_faltool/lib/dart_faltool.dart` must show two hunks: `IterableFilter` added to the dartx hide list (the earlier uncommitted edit) and `hide log`. Commit both:

```bash
git add dart_faltool/lib/dart_faltool.dart dart_faltool/test/sdk_name_collisions_test.dart skills/dart-falconx-package/SKILL.md skills/dart-falconx-package/references/third-party.md
git commit -m "refactor(faltool)!: stop re-exporting dart:math's log and dartx's IterableFilter"
```

### Task 4: Rename `SocketException` to `SocketClientException`

**Files:**
- Move: `dart_falconnect/lib/engine/sockets/exceptions/socket_exception.dart` to `socket_client_exception.dart` in the same folder
- Modify: `dart_falconnect/lib/engine/sockets/exceptions/exceptions.dart`, `socket_retry_exception.dart`, `socket_operation_not_found.dart`
- Modify: `dart_falconnect/lib/engine/sockets/socket_client.dart`, `interceptors/socket_interceptor.dart`, `interceptors/socket_log_interceptor.dart`
- Test: `dart_falconnect/test/engine/sockets/socket_client_exception_test.dart`
- Modify: `dart_falconnect/CLAUDE.md`, `skills/dart-falconx-package/references/websocket.md`

**Interfaces:**
- Consumes: `melos run check:exports`.
- Produces: `class SocketClientException implements Exception` with `const new({SocketResponse? response, String? message, Exception? exception, StackTrace? stackTrace})`. `SocketRetryException` and `SocketOperationNotFound` extend it. `SocketInterceptor.onError(SocketClientException err, SocketOptions options)`.

- [ ] **Step 1: Write the failing test**

Create `dart_falconnect/test/engine/sockets/socket_client_exception_test.dart`:

```dart
@TestOn('vm')
library;

import 'dart:io';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

void main() {
  test('SocketClientException names itself in toString', () {
    const exception = SocketClientException(message: 'closed');

    expect(
      exception.toString(),
      startsWith('SocketClientException{message: closed'),
    );
  });

  test('retry and unknown-operation errors are SocketClientExceptions', () {
    expect(
      const SocketRetryException(retryCount: 1),
      isA<SocketClientException>(),
    );
    expect(const SocketOperationNotFound(), isA<SocketClientException>());
  });

  test("dart:io's SocketException stays reachable next to the barrel", () {
    const exception = SocketException('refused');

    expect(exception.osError, isNull);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd dart_falconnect && dart test test/engine/sockets/socket_client_exception_test.dart`
Expected: compilation errors: `SocketClientException` is not defined, and `SocketException('refused')` resolves to the barrel's class, which takes no positional argument.

- [ ] **Step 3: Rename**

```bash
cd dart_falconnect/lib/engine/sockets
git mv exceptions/socket_exception.dart exceptions/socket_client_exception.dart
perl -pi -e 's/\bSocketException\b/SocketClientException/g' \
  exceptions/socket_client_exception.dart \
  exceptions/socket_retry_exception.dart \
  exceptions/socket_operation_not_found.dart \
  socket_client.dart \
  interceptors/socket_interceptor.dart \
  interceptors/socket_log_interceptor.dart
perl -pi -e "s/'socket_exception\.dart'/'socket_client_exception.dart'/" exceptions/exceptions.dart
cd -
```

`exceptions/exceptions.dart` now reads:

```dart
export 'socket_client_exception.dart';
export 'socket_operation_not_found.dart';
export 'socket_retry_exception.dart';
```

The `toString` of `SocketClientException` now starts with `'SocketClientException{message: $message,\n'`. Leave the doc example in `dart_faltool/lib/extensions/future_extensions.dart` (`error is SocketException`) unchanged: it now refers to `dart:io`'s class, as intended.

- [ ] **Step 4: Run the test, the analyzer, and the check**

Run: `cd dart_falconnect && dart test test/engine/sockets/socket_client_exception_test.dart && dart analyze`
Expected: `+3: All tests passed!` and `No issues found!`

Run: `melos run check:exports`
Expected: exit code 1 with only the two `RemoteError` lines.

- [ ] **Step 5: Update the docs**

In `dart_falconnect/CLAUDE.md`, replace:

```markdown
- Socket errors: `SocketException` and its subclasses `SocketRetryException` and `SocketOperationNotFound`.
```

with:

```markdown
- Socket errors: `SocketClientException` and its subclasses `SocketRetryException` and `SocketOperationNotFound`.
```

In `skills/dart-falconx-package/references/websocket.md`:

```bash
perl -pi -e 's/\bSocketException\b/SocketClientException/g' skills/dart-falconx-package/references/websocket.md
perl -pi -e "s/: base; not \`dart:io\`'s class\./: base./" skills/dart-falconx-package/references/websocket.md
```

Expected: `grep -n "SocketException\|dart:io" skills/dart-falconx-package/references/websocket.md` prints nothing, and the Exceptions list starts with ``- `SocketClientException({response, message, exception, stackTrace})`: base.``

- [ ] **Step 6: Commit**

```bash
git add dart_falconnect/lib/engine/sockets dart_falconnect/test/engine/sockets dart_falconnect/CLAUDE.md skills/dart-falconx-package/references/websocket.md
git commit -m "refactor(falconnect)!: rename SocketException to SocketClientException"
```

### Task 5: Rename `RefreshCallback` to `TokenRefreshCallback`

**Files:**
- Modify: `dart_falconnect/lib/engine/https/config/auth_config.dart`
- Regenerate: `dart_falconnect/lib/engine/https/config/generated/auth_config.freezed.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/token_refresh_interceptor_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `typedef TokenRefreshCallback = Future<bool> Function();`. `AuthConfig.refresh` has type `TokenRefreshCallback`.

- [ ] **Step 1: Point the test at the new name**

In `dart_falconnect/test/engine/https/interceptors/token_refresh_interceptor_test.dart`, replace:

```dart
  AuthConfig config({RefreshCallback? refresh}) => AuthConfig(
```

with:

```dart
  AuthConfig config({TokenRefreshCallback? refresh}) => AuthConfig(
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/token_refresh_interceptor_test.dart`
Expected: a compilation error: `TokenRefreshCallback` isn't a type.

- [ ] **Step 3: Rename and regenerate**

```bash
cd dart_falconnect
perl -pi -e 's/\bRefreshCallback\b/TokenRefreshCallback/g' lib/engine/https/config/auth_config.dart
dart run build_runner build
grep -n "RefreshCallback" lib/engine/https/config/auth_config.dart lib/engine/https/config/generated/auth_config.freezed.dart | grep -v TokenRefreshCallback
cd ..
```

Expected: the typedef reads `typedef TokenRefreshCallback = Future<bool> Function();`, the field reads `required TokenRefreshCallback refresh,`, and the final `grep` prints nothing.

- [ ] **Step 4: Run the tests and the analyzer**

Run: `cd dart_falconnect && dart test && dart analyze`
Expected: all tests pass and `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add dart_falconnect/lib/engine/https/config/auth_config.dart dart_falconnect/lib/engine/https/config/generated/auth_config.freezed.dart dart_falconnect/test/engine/https/interceptors/token_refresh_interceptor_test.dart
git commit -m "refactor(falconnect)!: rename RefreshCallback to TokenRefreshCallback"
```

### Task 6: Rename `RemoteError` to `RemoteErrorBody`

**Files:**
- Move: `dart_falmodel/lib/networks/https/responses/remote_error.dart` to `remote_error_body.dart` in the same folder
- Delete: `dart_falmodel/lib/networks/https/responses/generated/remote_error.freezed.dart`, `generated/remote_error.g.dart`
- Generate: `generated/remote_error_body.freezed.dart`, `generated/remote_error_body.g.dart`
- Modify: `dart_falmodel/lib/networks/https/responses/responses.dart`
- Test: `dart_falmodel/test/networks/https/remote_error_body_test.dart`
- Modify: `skills/dart-falconx-package/references/models.md`

**Interfaces:**
- Consumes: `melos run check:exports`.
- Produces: `RemoteErrorBody` (Freezed) with `const RemoteErrorBody({int? code, String? message, String? userMessage, String? developerMessage})`, `RemoteErrorBody.fromJson(Map<String, dynamic>)`, `RemoteErrorBody.fromData(dynamic)`, and `toJson()`.

- [ ] **Step 1: Write the failing test**

Create `dart_falmodel/test/networks/https/remote_error_body_test.dart`:

```dart
import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteErrorBody', () {
    test('fromData reads a JSON map', () {
      final body = RemoteErrorBody.fromData(<String, dynamic>{
        'code': 42,
        'message': 'broken',
        'userMessage': 'Try again',
        'developerMessage': 'upstream timeout',
      });

      expect(
        body,
        const RemoteErrorBody(
          code: 42,
          message: 'broken',
          userMessage: 'Try again',
          developerMessage: 'upstream timeout',
        ),
      );
    });

    test('fromData turns any other value into the message', () {
      expect(
        RemoteErrorBody.fromData(404),
        const RemoteErrorBody(message: '404'),
      );
    });

    test('toJson round-trips through fromJson', () {
      const body = RemoteErrorBody(code: 1, message: 'm');

      expect(RemoteErrorBody.fromJson(body.toJson()), body);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd dart_falmodel && dart test test/networks/https/remote_error_body_test.dart`
Expected: a compilation error: `RemoteErrorBody` is not defined.

- [ ] **Step 3: Rename the model**

```bash
cd dart_falmodel/lib/networks/https/responses
git mv remote_error.dart remote_error_body.dart
git rm -q generated/remote_error.freezed.dart generated/remote_error.g.dart
perl -pi -e "s/'remote_error\.dart'/'remote_error_body.dart'/" responses.dart
cd -
```

Replace the whole content of `dart_falmodel/lib/networks/https/responses/remote_error_body.dart` with:

```dart
import 'package:dart_falmodel/src/src.dart';

part 'generated/remote_error_body.freezed.dart';

part 'generated/remote_error_body.g.dart';

/// Freezed model representing an error payload returned by a remote API.
///
/// Used to deserialize structured error bodies from HTTP responses.
@freezed
abstract class RemoteErrorBody with _$RemoteErrorBody {
  /// Creates a [RemoteErrorBody] with optional code, message, and
  /// developer/user messages.
  const factory({
    int? code,
    String? message,
    String? userMessage,
    String? developerMessage,
  }) = _RemoteErrorBody;

  /// Deserializes a [RemoteErrorBody] from a JSON map.
  factory fromJson(Map<String, dynamic> json) =>
      _$RemoteErrorBodyFromJson(json);

  /// Creates a [RemoteErrorBody] from an arbitrary [data] value.
  ///
  /// If [data] is a `Map<String, dynamic>`, delegates to `fromJson`;
  /// otherwise converts the value to a string message.
  factory fromData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return RemoteErrorBody.fromJson(data);
    } else {
      return RemoteErrorBody(message: data.toString());
    }
  }
}
```

`responses.dart` now reads:

```dart
export 'base_response.dart';
export 'paginated_response.dart';
export 'remote_error_body.dart';
```

Regenerate:

```bash
cd dart_falmodel && dart run build_runner build && cd ..
ls dart_falmodel/lib/networks/https/responses/generated/
```

Expected: `paginated_response.g.dart`, `remote_error_body.freezed.dart`, and `remote_error_body.g.dart`.

- [ ] **Step 4: Run the test, the analyzer, and the check**

Run: `cd dart_falmodel && dart test && dart analyze`
Expected: all tests pass, including the three new ones, and `No issues found!`

Run: `melos run check:exports`
Expected: exit code 0 and `OK: every collision is in the allowlist (8)`.

- [ ] **Step 5: Update the consumer skill**

In `skills/dart-falconx-package/references/models.md`, replace:

```markdown
- `RemoteError({code, message, userMessage, developerMessage})` (Freezed): `fromJson`, `fromData(dynamic)`.
```

with:

```markdown
- `RemoteErrorBody({code, message, userMessage, developerMessage})` (Freezed; `RemoteError` before 2.4.0): `fromJson`, `fromData(dynamic)`.
```

- [ ] **Step 6: Commit**

```bash
git add dart_falmodel/lib/networks/https/responses dart_falmodel/test/networks/https/remote_error_body_test.dart skills/dart-falconx-package/references/models.md
git commit -m "refactor(falmodel)!: rename RemoteError to RemoteErrorBody"
```

### Task 7: dart-falconx gates and the 2.4.0 release

**Files:**
- Modify: `pubspec.yaml`, `dart_falconnect/pubspec.yaml`, `dart_falconx/pubspec.yaml`, `dart_falmodel/pubspec.yaml`, `dart_faltool/pubspec.yaml`, `skills/dart-falconx-package/SKILL.md`

**Interfaces:**
- Consumes: Tasks 1 to 6.
- Produces: tag `2.4.0` on `main`, merged back into `develop`. Parts 2 and 3 depend on the tag.

- [ ] **Step 1: Run every gate**

```bash
melos run analyze && melos run format && melos run test && melos run build_runner:check && melos run check:exports
melos run test:platforms
```

Expected: every command exits 0. `test:platforms` needs Chrome.

- [ ] **Step 2: Merge the feature**

```bash
git stash push --include-untracked -m "owner-edits" -- <every path recorded in Task 1, Step 1>
git status --short
git switch develop
git merge --no-ff feature/export-conflict-policy -m "Merge branch 'feature/export-conflict-policy' into develop"
git branch -d feature/export-conflict-policy
```

Skip the `git stash` line when Task 1 recorded no such path. Expected: `git status --short` prints nothing before the merge, and the feature branch is merged into `develop` and deleted.

- [ ] **Step 3: Bump to 2.4.0**

```bash
git flow release start 2.4.0
perl -pi -e 's/^version: 2\.3\.1$/version: 2.4.0/; s/^(\s+ref: )2\.3\.1$/${1}2.4.0/' pubspec.yaml dart_*/pubspec.yaml
perl -pi -e 's/# e\.g\. 2\.3\.1 /# e.g. 2.4.0 /' skills/dart-falconx-package/SKILL.md
grep -rn "2\.3\.1" pubspec.yaml dart_*/pubspec.yaml skills/dart-falconx-package/SKILL.md
```

Expected: the final `grep` prints nothing.

- [ ] **Step 4: Verify the release**

Run: `melos run get && melos run analyze && melos run test && melos run check:exports`
Expected: all pass; `dart_falconx/test/internal_dependencies_test.dart` confirms every version and sibling `ref:` reads 2.4.0.

- [ ] **Step 5: Commit and finish the release**

```bash
git status --short
git add pubspec.yaml dart_falconnect/pubspec.yaml dart_falconx/pubspec.yaml dart_falmodel/pubspec.yaml dart_faltool/pubspec.yaml skills/dart-falconx-package/SKILL.md
git commit -m "chore(release): bump to 2.4.0"
git flow release finish -m "2.4.0" 2.4.0
```

If `git status` also lists `pubspec.lock`, add it to the same commit.

Restore the owner's unrelated edits: `git switch develop && git stash pop --index`. Expected: `git status --short` lists the paths recorded in Task 1, Step 1 again, staged as they were.

- [ ] **Step 6: Ask the owner before pushing**

Show the owner `git log --oneline -8 main develop` and ask for a yes. After the yes, run `git push origin main develop --tags`.

---

## Part 2: flutter-falconx 4.1.0

Work in `/Users/nonthawit/Data/NTD OS/projects/FalconX/flutter-falconx`. Start only after tag `2.4.0` is on origin: `git ls-remote --tags https://github.com/Nextzy/dart-falconx 2.4.0` prints one line.

### Task 8: flutter-falconx export check

**Files:**
- Create: `tool/export_check/lib/**` and `tool/export_check/test/**` (copied), `tool/export_check/pubspec.yaml`, `pubspec.lock`, and `bin/check.dart`
- Modify: `pubspec.yaml` (append a melos script), `CLAUDE.md`

**Interfaces:**
- Consumes: the engine of Task 1, copied unchanged.
- Produces: `melos run check:exports` for this repository.

- [ ] **Step 1: Branch from a clean tree**

```bash
git switch develop
git status --short
git flow feature start export-conflict-policy
```

Expected: `git status --short` prints nothing before the branch starts. If it prints anything, stop and ask the owner.

- [ ] **Step 2: Copy the engine and create the package**

```bash
mkdir -p tool/export_check/bin
cp -R ../dart-falconx/tool/export_check/lib ../dart-falconx/tool/export_check/test tool/export_check/
```

Create `tool/export_check/pubspec.yaml`:

```yaml
name: export_check
description: >-
  Fails when a barrel exports a name that collides with a dart library or
  Flutter and the allowlist does not record it.
publish_to: none

environment:
  sdk: ">=3.13.0 <4.0.0"

dependencies:
  analyzer: ^14.4.0
  path: ^1.9.1

dev_dependencies:
  test: ^1.32.0
  very_good_analysis: ^11.0.0
```

Run: `cd tool/export_check && dart pub get && dart test && dart analyze`
Expected: `+17: All tests passed!` and `No issues found!`

- [ ] **Step 3: Write this repository's configuration**

Create `tool/export_check/bin/check.dart`:

```dart
import 'dart:io';

import 'package:export_check/export_check.dart';

/// A workspace member; its package config resolves every package in this
/// repository, every `dart:` library, and Flutter.
const _workspace = '../../flutter_falconx';

const List<LibraryRef> _subjects = [
  (uri: 'package:flutter_falconx/flutter_falconx.dart', root: _workspace),
  (uri: 'package:flutter_falconnect/flutter_falconnect.dart', root: _workspace),
  (uri: 'package:flutter_falmodel/flutter_falmodel.dart', root: _workspace),
  (uri: 'package:flutter_falstore/flutter_falstore.dart', root: _workspace),
  (uri: 'package:flutter_faltool/flutter_faltool.dart', root: _workspace),
];

const List<LibraryRef> _targets = [
  (uri: 'dart:async', root: _workspace),
  (uri: 'dart:collection', root: _workspace),
  (uri: 'dart:convert', root: _workspace),
  (uri: 'dart:core', root: _workspace),
  (uri: 'dart:developer', root: _workspace),
  (uri: 'dart:ffi', root: _workspace),
  (uri: 'dart:io', root: _workspace),
  (uri: 'dart:isolate', root: _workspace),
  (uri: 'dart:js_interop', root: _workspace),
  (uri: 'dart:js_interop_unsafe', root: _workspace),
  (uri: 'dart:math', root: _workspace),
  (uri: 'dart:typed_data', root: _workspace),
  (uri: 'dart:ui', root: _workspace),
  (uri: 'package:flutter/cupertino.dart', root: _workspace),
  (uri: 'package:flutter/foundation.dart', root: _workspace),
  (uri: 'package:flutter/material.dart', root: _workspace),
  (uri: 'package:flutter/services.dart', root: _workspace),
];

/// Flutter owns these declarations; their collisions with `dart:` libraries,
/// such as the `Flow` widget against `dart:developer`, are Flutter's.
const _frameworkOwned = ['package:flutter/', 'dart:ui'];

const _retrofitHttpResponse =
    "Retrofit's HttpResponse; code that Retrofit generates for a method "
    'returning HttpResponse<T> needs it.';
const _convertCodec =
    "dart:convert's Codec; apps reach dart:ui's image Codec through "
    'instantiateImageCodec without naming it, and switching would break '
    'apps that name the encoding Codec.';
const _singlePackageName =
    'This single-package barrel imports no Flutter library; the '
    'flutter-falconx-package skill tells apps to hide the name when they '
    'import the barrel next to material.';

const Map<AllowlistKey, String> _allowlist = {
  (
    subject: 'package:flutter_falconx/flutter_falconx.dart',
    name: 'HttpResponse',
  ): _retrofitHttpResponse,
  (
    subject: 'package:flutter_falconnect/flutter_falconnect.dart',
    name: 'HttpResponse',
  ): _retrofitHttpResponse,
  (subject: 'package:flutter_falconx/flutter_falconx.dart', name: 'Codec'):
      _convertCodec,
  (subject: 'package:flutter_faltool/flutter_faltool.dart', name: 'Codec'):
      _convertCodec,
  (
    subject: 'package:flutter_faltool/flutter_faltool.dart',
    name: 'TextDirection',
  ): _singlePackageName,
  (subject: 'package:flutter_falconnect/flutter_falconnect.dart', name: 'Path'):
      _singlePackageName,
};

Future<void> main() async {
  exitCode = await runCheck(
    subjects: _subjects,
    targets: _targets,
    allowlist: _allowlist,
    frameworkOwned: _frameworkOwned,
  );
}
```

- [ ] **Step 4: Add the melos script**

`pubspec.yaml` ends with the `outdated` script. Append:

```yaml

    check:exports:
      description: Fail when a barrel exports a name that collides with a dart library or Flutter and tool/export_check/bin/check.dart does not allowlist it.
      run: cd tool/export_check && dart pub get && dart run bin/check.dart
```

- [ ] **Step 5: Run the check and confirm the known collisions**

Run: `time melos run check:exports`
Expected: exit code 1, about 55 s, no `STALE` line, and `FAIL` lines for exactly these pairs:

| Subject | Names |
|---|---|
| `flutter_falconnect` | `RefreshCallback` (against `cupertino` and `material`), `SocketException` |
| `flutter_falconx` | `RemoteError`, `SocketException`, `log` |
| `flutter_falmodel` | `RemoteError` |
| `flutter_faltool` | `log` |

- [ ] **Step 6: Document the command**

In `CLAUDE.md`, add this row to the Commands table after the `melos run build_runner` row:

```markdown
| `melos run check:exports` | `tool/export_check`: fails on an export name collision with a `dart:` library or Flutter that its allowlist does not settle (about 55 s) |
```

In the Release block, replace:

```bash
melos run get && melos run analyze && melos run test
```

with:

```bash
melos run get && melos run analyze && melos run test && melos run check:exports
```

- [ ] **Step 7: Format and commit**

```bash
dart format tool/export_check
git add tool/export_check/pubspec.yaml tool/export_check/pubspec.lock tool/export_check/lib tool/export_check/test tool/export_check/bin pubspec.yaml CLAUDE.md
git commit -m "feat(tool): check flutter-falconx barrels for export name collisions"
```

### Task 9: flutter-falconx on dart-falconx 2.4.0

**Files:**
- Modify: `flutter_falconnect/pubspec.yaml`, `flutter_falmodel/pubspec.yaml`, `flutter_faltool/pubspec.yaml`
- Modify: `flutter_falconx/lib/flutter_falconx.dart`, `flutter_faltool/lib/flutter_faltool.dart`
- Modify: `CLAUDE.md`, `skills/flutter-falconx-package/SKILL.md`, `skills/flutter-falconx-package/references/third-party.md`

**Interfaces:**
- Consumes: `dart-falconx` 2.4.0 and `melos run check:exports` from Task 8.
- Produces: `flutter_falconx` exports `TokenRefreshCallback`, and `dart:math` without `log`.

- [ ] **Step 1: Move to 2.4.0**

```bash
perl -pi -e 's/^(\s+ref: )2\.3\.1$/${1}2.4.0/' flutter_falconnect/pubspec.yaml flutter_falmodel/pubspec.yaml flutter_faltool/pubspec.yaml
grep -rn "ref: 2\.3\.1" */pubspec.yaml
melos run get
```

Expected: the `grep` prints nothing, and `melos run get` resolves `dart_falconnect`, `dart_falmodel`, and `dart_faltool` at 2.4.0.

- [ ] **Step 2: Run the analyzer to see the stale hides**

Run: `melos run analyze`
Expected: it fails with `undefined_hidden_name` for `RefreshCallback` in `flutter_falconx/lib/flutter_falconx.dart` and for `IterableFilter` in `flutter_faltool/lib/flutter_faltool.dart`.

- [ ] **Step 3: Settle the barrels**

In `flutter_falconx/lib/flutter_falconx.dart`, replace:

```dart
export 'dart:math';
```

with:

```dart
export 'dart:math' hide log;
```

and replace:

```dart
export 'package:flutter_falconnect/flutter_falconnect.dart'
    hide Path, RefreshCallback;
```

with:

```dart
export 'package:flutter_falconnect/flutter_falconnect.dart' hide Path;
```

In `flutter_faltool/lib/flutter_faltool.dart`, replace:

```dart
export 'package:dart_faltool/dart_faltool.dart' hide IterableFilter;
```

with:

```dart
export 'package:dart_faltool/dart_faltool.dart';
```

- [ ] **Step 4: Run every gate**

Run: `melos run analyze && melos run test && melos run check:exports`
Expected: `No issues found!` in every package, all tests pass, and the check prints a line that starts with `OK: every collision is in the allowlist`.

- [ ] **Step 5: Update the docs**

In `CLAUDE.md`, replace the Gotchas bullet that starts "- `flutter_falconx.dart` keeps `hide Path, RefreshCallback` on its `flutter_falconnect` export" with:

```markdown
- `flutter_falconx.dart` keeps `hide Path` on its `flutter_falconnect` export (Retrofit's `@Path` collides with `dart:ui`'s `Path`), `hide TextDirection` on its `flutter_faltool` export (intl's `TextDirection` collides with `dart:ui`'s), and `hide log` on `dart:math` (it collides with `dart:developer`'s `log`). Since 4.1.0 `dart_falconnect`'s auth typedef is `TokenRefreshCallback`, which collides with nothing, so the umbrella exports it. `melos run check:exports` fails on a new collision and on an allowlist entry that no longer matches; an `undefined_hidden_name` warning on a `hide` means that entry no longer hides anything and should be dropped.
```

In the next Gotchas bullet ("- Single-package hide, re-derived per package …"), replace:

```markdown
`flutter_falconnect` needs `hide RefreshCallback` (`ambiguous_import`, a real compile error) and should also `hide Path` —
```

with:

```markdown
`flutter_falconnect` should `hide Path` —
```

In `skills/flutter-falconx-package/SKILL.md`, replace the bullet that starts "- `flutter_falconx` hides `Path` and `RefreshCallback` on its `flutter_falconnect` export" with:

```markdown
- `flutter_falconx` hides `Path` on its `flutter_falconnect` export, `TextDirection` on its `flutter_faltool` export, and `log` on `dart:math`. `Path` is Retrofit's annotation; `TextDirection` is intl's; `log` would collide with `dart:developer`'s. Import `package:retrofit/retrofit.dart` directly for `@Path`/`@Headers`, `package:intl/intl.dart` for intl's `TextDirection`, or write `import 'dart:math' as math;` for `math.log`. `dart_falconnect`'s auth typedef is `TokenRefreshCallback` since 4.1.0 and is exported.
```

In the following bullet ("- Importing a single package next to `package:flutter/material.dart` …"), replace:

```markdown
`flutter_falconnect` should `hide Path, RefreshCallback` — `RefreshCallback` is a real `ambiguous_import` compile error, and `Path` silently shadows
```

with:

```markdown
`flutter_falconnect` should `hide Path` — `Path` silently shadows
```

In `skills/flutter-falconx-package/references/third-party.md`, delete the table row that starts ``| `dart_falconnect` | `RefreshCallback` typedef``.

Expected: `grep -rnw "RefreshCallback" CLAUDE.md skills/` prints nothing; `-w` skips `TokenRefreshCallback`.

- [ ] **Step 6: Commit**

```bash
git add flutter_falconnect/pubspec.yaml flutter_falmodel/pubspec.yaml flutter_faltool/pubspec.yaml flutter_falconx/lib/flutter_falconx.dart flutter_faltool/lib/flutter_faltool.dart CLAUDE.md skills/flutter-falconx-package
git status --short
git commit -m "refactor!: move to dart-falconx 2.4.0 and settle export collisions"
```

If `git status --short` lists `pubspec.lock` as modified, add it before committing.

### Task 10: flutter-falconx 4.1.0 release

**Files:**
- Modify: `pubspec.yaml` and the five package pubspecs, `CHANGELOG.md`

- [ ] **Step 1: Finish the feature and start the release**

```bash
git flow feature finish export-conflict-policy
git flow release start 4.1.0
perl -pi -e 's/^version: 4\.0\.1$/version: 4.1.0/; s/^(\s+ref: )4\.0\.1$/${1}4.1.0/' pubspec.yaml flutter_*/pubspec.yaml
grep -rn "4\.0\.1" pubspec.yaml flutter_*/pubspec.yaml
```

Expected: the `grep` prints nothing.

- [ ] **Step 2: Add the changelog entry**

In `CHANGELOG.md`, insert after `# Changelog` and its blank line (use today's date in `YYYY-MM-DD` form):

```markdown
## 4.1.0 — YYYY-MM-DD

### Breaking

1. Every `dart-falconx` dependency moves to 2.4.0, whose barrels changed:
   - `dart_faltool` no longer exports `dart:math`'s `log`, which collided with `dart:developer`'s; write `import 'dart:math' as math;` and call `math.log`.
   - `dart_falconnect`'s `SocketException` is now `SocketClientException`, so `SocketException` next to `dart:io` means `dart:io`'s class again.
   - `dart_falconnect`'s `RefreshCallback` is now `TokenRefreshCallback`.
   - `dart_falmodel`'s `RemoteError` is now `RemoteErrorBody`.
2. `flutter_falconx` hides `log` on its `dart:math` export for the same reason.
3. `flutter_falconx` no longer hides the auth typedef on its `flutter_falconnect` export; it exports `TokenRefreshCallback`.

### Changed

- `melos run check:exports` (`tool/export_check/`) fails when a barrel exports a name that collides with a `dart:` library or Flutter and the allowlist in `tool/export_check/bin/check.dart` does not record it.

```

- [ ] **Step 3: Verify, commit, and finish**

```bash
melos run get && melos run analyze && melos run test && melos run check:exports
git status --short
git add pubspec.yaml flutter_falconnect/pubspec.yaml flutter_falconx/pubspec.yaml flutter_falmodel/pubspec.yaml flutter_falstore/pubspec.yaml flutter_faltool/pubspec.yaml CHANGELOG.md
git commit -m "chore: release 4.1.0"
git flow release finish -m "4.1.0" 4.1.0
```

Add `pubspec.lock` to the commit if `git status` lists it.

- [ ] **Step 4: Ask the owner before pushing**

Show `git log --oneline -6 main develop`, ask for a yes, then run `git push origin main develop --tags`.

---

## Part 3: jaspr-falconx 2.0.0

Work in `/Users/nonthawit/Data/NTD OS/projects/FalconX/jaspr-falconx`. Start only after tag `2.4.0` is on origin.

### Task 11: jaspr-falconx precondition and export check

**Files:**
- Create: `tool/export_check/` (engine copied, own `pubspec.yaml`, `pubspec.lock`, `bin/check.dart`)
- Modify: `pubspec.yaml` (append a melos script), `CLAUDE.md`

**Interfaces:**
- Consumes: the engine of Task 1, copied unchanged.
- Produces: `melos run check:exports` for this repository.

- [ ] **Step 1: Check the preconditions**

```bash
git switch develop
git status --short
grep -n "ref:" jaspr_falconnect/pubspec.yaml jaspr_falmodel/pubspec.yaml jaspr_faltool/pubspec.yaml
cat jaspr_faltool/lib/jaspr_faltool.dart jaspr_faltool/lib/lib.dart jaspr_falkit/lib/lib.dart
```

Continue only when all of these hold; otherwise stop and ask the owner:

- `git status --short` prints nothing. The owner's in-flight work, which moves the refs to 2.3.1, has been committed.
- The three `ref:` lines read `2.3.1`.
- `jaspr_faltool/lib/jaspr_faltool.dart` exports `package:dart_faltool/dart_faltool.dart` with `hide Link`.
- `jaspr_faltool/lib/lib.dart` exports `package:jaspr/jaspr.dart` with `hide IterableFilter`.
- `jaspr_falkit/lib/lib.dart` exports `package:jaspr/dom.dart` with `hide option`, `package:jaspr/jaspr.dart` with `hide IterableFilter`, and `package:jaspr_faltool/jaspr_faltool.dart` with `hide Unit`.

Then branch: `git switch -c feature/export-conflict-policy`

- [ ] **Step 2: Copy the engine and create the package**

```bash
mkdir -p tool/export_check/bin
cp -R ../dart-falconx/tool/export_check/lib ../dart-falconx/tool/export_check/test tool/export_check/
```

Create `tool/export_check/pubspec.yaml`:

```yaml
name: export_check
description: >-
  Fails when a barrel exports a name that collides with a dart library or
  jaspr and the allowlist does not record it.
publish_to: none

environment:
  sdk: ">=3.13.0 <4.0.0"

dependencies:
  analyzer: ^14.4.0
  path: ^1.9.1

dev_dependencies:
  test: ^1.32.0
  very_good_analysis: ^11.0.0
```

Run: `cd tool/export_check && dart pub get && dart test && dart analyze`
Expected: `+17: All tests passed!` and `No issues found!`

- [ ] **Step 3: Write this repository's configuration**

Create `tool/export_check/bin/check.dart`:

```dart
import 'dart:io';

import 'package:export_check/export_check.dart';

/// A workspace member; its package config resolves every package in this
/// repository, every `dart:` library, and jaspr.
const _workspace = '../../jaspr_falconx';

const List<LibraryRef> _subjects = [
  (uri: 'package:jaspr_falconx/jaspr_falconx.dart', root: _workspace),
  (uri: 'package:jaspr_falconnect/lib.dart', root: _workspace),
  (uri: 'package:jaspr_falkit/lib.dart', root: _workspace),
  (uri: 'package:jaspr_faltool/lib.dart', root: _workspace),
];

const List<LibraryRef> _targets = [
  (uri: 'dart:async', root: _workspace),
  (uri: 'dart:collection', root: _workspace),
  (uri: 'dart:convert', root: _workspace),
  (uri: 'dart:core', root: _workspace),
  (uri: 'dart:developer', root: _workspace),
  (uri: 'dart:ffi', root: _workspace),
  (uri: 'dart:io', root: _workspace),
  (uri: 'dart:isolate', root: _workspace),
  (uri: 'dart:js_interop', root: _workspace),
  (uri: 'dart:js_interop_unsafe', root: _workspace),
  (uri: 'dart:math', root: _workspace),
  (uri: 'dart:typed_data', root: _workspace),
  (uri: 'package:jaspr/client.dart', root: _workspace),
  (uri: 'package:jaspr/dom.dart', root: _workspace),
  (uri: 'package:jaspr/jaspr.dart', root: _workspace),
  (uri: 'package:jaspr/server.dart', root: _workspace),
];

/// jaspr, its router, and riverpod own these declarations; their collisions
/// with `dart:` libraries, such as riverpod's `AsyncError`, are theirs.
const _frameworkOwned = [
  'package:jaspr/',
  'package:jaspr_router/',
  'package:jaspr_riverpod/',
  'package:riverpod/',
];

const _shelfResponse =
    "dio's Response; it collides with shelf's from jaspr/server.dart, which "
    'no barrel exports, so server code hides it at the import.';
const _retrofitHttpResponse =
    "Retrofit's HttpResponse; code that Retrofit generates for a method "
    'returning HttpResponse<T> needs it.';

const Map<AllowlistKey, String> _allowlist = {
  (subject: 'package:jaspr_falconx/jaspr_falconx.dart', name: 'Response'):
      _shelfResponse,
  (subject: 'package:jaspr_falconnect/lib.dart', name: 'Response'):
      _shelfResponse,
  (subject: 'package:jaspr_falconx/jaspr_falconx.dart', name: 'HttpResponse'):
      _retrofitHttpResponse,
  (subject: 'package:jaspr_falconnect/lib.dart', name: 'HttpResponse'):
      _retrofitHttpResponse,
};

Future<void> main() async {
  exitCode = await runCheck(
    subjects: _subjects,
    targets: _targets,
    allowlist: _allowlist,
    frameworkOwned: _frameworkOwned,
  );
}
```

- [ ] **Step 4: Add the melos script**

`pubspec.yaml` ends with the `build_runner` script. Append:

```yaml

    check:exports:
      description: Fail when a barrel exports a name that collides with a dart library or jaspr and tool/export_check/bin/check.dart does not allowlist it.
      run: cd tool/export_check && dart pub get && dart run bin/check.dart
```

- [ ] **Step 5: Run the check and confirm the known collisions**

Run: `time melos run check:exports`
Expected: exit code 1, about 45 s, no `STALE` line, and `FAIL` lines for exactly these pairs; `IterableFilter` appears once for each of `jaspr/client.dart`, `jaspr/jaspr.dart`, and `jaspr/server.dart`:

| Subject | Names |
|---|---|
| `jaspr_falconnect/lib.dart` | `IterableFilter`, `RemoteError`, `SocketException`, `Unit`, `log`, `option` |
| `jaspr_falconx/jaspr_falconx.dart` | `IterableFilter`, `RemoteError`, `SocketException`, `Unit`, `log`, `option` |
| `jaspr_falkit/lib.dart` | `IterableFilter`, `RemoteError`, `log`, `option` |
| `jaspr_faltool/lib.dart` | `IterableFilter`, `Unit`, `log`, `option` |

The prototype resolved the jaspr version pinned in the `pubspec.lock` of 2026-09-30. If a newer jaspr now resolves and adds pairs, settle each one under the policy in Global Constraints and record it in this table before you continue.

- [ ] **Step 6: Document the command**

In `CLAUDE.md`, after the `### Linting and Analysis` code block, add:

````markdown
### Export conflicts
```bash
# Fail on an export name collision with a dart: library or jaspr that the
# allowlist in tool/export_check/bin/check.dart does not settle (about 45 s)
melos run check:exports
```
````

- [ ] **Step 7: Format and commit**

```bash
dart format tool/export_check
git add tool/export_check/pubspec.yaml tool/export_check/pubspec.lock tool/export_check/lib tool/export_check/test tool/export_check/bin pubspec.yaml CLAUDE.md
git commit -m "feat(tool): check jaspr-falconx barrels for export name collisions"
```

### Task 12: jaspr-falconx on dart-falconx 2.4.0

**Files:**
- Modify: `jaspr_falconnect/pubspec.yaml`, `jaspr_falmodel/pubspec.yaml`, `jaspr_faltool/pubspec.yaml`
- Modify: `jaspr_faltool/lib/jaspr_faltool.dart`, `jaspr_faltool/lib/lib.dart`, `jaspr_falkit/lib/lib.dart`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `dart-falconx` 2.4.0 and `melos run check:exports` from Task 11.
- Produces: every jaspr barrel keeps jaspr's `Unit`, `option`, and `IterableFilter`.

- [ ] **Step 1: Move to 2.4.0**

```bash
perl -pi -e 's/^(\s+ref: )2\.3\.1$/${1}2.4.0/' jaspr_falconnect/pubspec.yaml jaspr_falmodel/pubspec.yaml jaspr_faltool/pubspec.yaml
dart pub get
dart analyze
```

If `dart analyze` reports errors that do not name `Link`, `Unit`, `option`, or `IterableFilter`, the 2.4.0 move broke something unrelated. Fix it in its own commit before Step 2, as the spec requires.

- [ ] **Step 2: Run the check to see what 2.4.0 left**

Run: `melos run check:exports`
Expected: exit code 1 with `FAIL` lines only for `Unit` and `option`: `Unit` in `jaspr_falconnect/lib.dart`, `jaspr_falconx.dart`, and `jaspr_faltool/lib.dart`; `option` in all four subjects. The `log`, `SocketException`, `RemoteError`, and `IterableFilter` lines are gone.

- [ ] **Step 3: Let jaspr's names win**

Replace the whole content of `jaspr_faltool/lib/jaspr_faltool.dart` with:

```dart
// jaspr's `Unit` and `option` win over fpdart's in every jaspr barrel.
export 'package:dart_faltool/dart_faltool.dart' hide Unit, option;

export 'src/src.dart';
```

In `jaspr_faltool/lib/lib.dart`, replace:

```dart
export 'package:jaspr/jaspr.dart' hide IterableFilter;
```

with:

```dart
export 'package:jaspr/jaspr.dart';
```

In `jaspr_falkit/lib/lib.dart`, replace:

```dart
export 'package:jaspr/dom.dart' hide option;
export 'package:jaspr/jaspr.dart' hide IterableFilter;
```

with:

```dart
export 'package:jaspr/dom.dart';
export 'package:jaspr/jaspr.dart';
```

and replace:

```dart
export 'package:jaspr_faltool/jaspr_faltool.dart' hide Unit;
```

with:

```dart
export 'package:jaspr_faltool/jaspr_faltool.dart';
```

- [ ] **Step 4: Run every gate**

```bash
dart analyze
melos exec --dir-exists=test -- dart test
melos run check:exports
```

Expected: `No issues found!` with no `undefined_hidden_name`, all tests pass, and the check prints a line that starts with `OK: every collision is in the allowlist`.

- [ ] **Step 5: Document the hides**

In `CLAUDE.md`, under the `### Export conflicts` subsection from Task 11, after its code block, add:

```markdown
- `jaspr_faltool/lib/jaspr_faltool.dart`, the one file that re-exports `dart_faltool`, hides fpdart's `Unit` and `option` so jaspr's CSS `Unit` and `<option>` element win; write `Option.of(...)` or `some(...)` for fpdart's option.
- `jaspr_falconx.dart` hides `AsyncError` on its `jaspr_faltool` export so riverpod's `AsyncError` wins over `dart:async`'s.
- Since 2.0.0, `dart-falconx` 2.4.0 no longer exports `dart:math`'s `log` or dartx's `IterableFilter`, and renames `SocketException`, `RefreshCallback`, and `RemoteError` to `SocketClientException`, `TokenRefreshCallback`, and `RemoteErrorBody`.
```

- [ ] **Step 6: Commit**

```bash
git add jaspr_falconnect/pubspec.yaml jaspr_falmodel/pubspec.yaml jaspr_faltool/pubspec.yaml jaspr_faltool/lib/jaspr_faltool.dart jaspr_faltool/lib/lib.dart jaspr_falkit/lib/lib.dart CLAUDE.md
git status --short
git commit -m "refactor!: move to dart-falconx 2.4.0 and let jaspr's Unit and option win"
```

Add `pubspec.lock` to the commit if `git status` lists it.

### Task 13: jaspr-falconx 2.0.0 release

**Files:**
- Modify: `pubspec.yaml` and every package pubspec at `version: 1.0.5`

- [ ] **Step 1: Merge and branch the release**

```bash
git switch develop
git merge --no-ff feature/export-conflict-policy -m "Merge branch 'feature/export-conflict-policy' into develop"
git branch -d feature/export-conflict-policy
git switch -c release/2.0.0
perl -pi -e 's/^version: 1\.0\.5$/version: 2.0.0/' pubspec.yaml jaspr_*/pubspec.yaml
grep -rn "^version:" pubspec.yaml jaspr_*/pubspec.yaml
```

Expected: every version reads `2.0.0` except `jaspr_falmonitor`, which keeps its own `0.0.1`.

- [ ] **Step 2: Verify and commit**

```bash
dart pub get && dart analyze && melos exec --dir-exists=test -- dart test && melos run check:exports
git status --short
git add pubspec.yaml jaspr_*/pubspec.yaml
git commit -m "chore: release 2.0.0"
```

Add `pubspec.lock` to the commit if `git status` lists it.

- [ ] **Step 3: Merge into main, tag, and merge back**

```bash
git switch main
git merge --no-ff release/2.0.0 -m "Merge branch 'release/2.0.0'"
git tag 2.0.0
git switch develop
git merge --no-ff 2.0.0 -m "Merge tag '2.0.0' into develop"
git branch -d release/2.0.0
```

- [ ] **Step 4: Ask the owner before pushing**

Show `git log --oneline -6 main develop`, ask for a yes, then run `git push origin main develop --tags`.

---

## Follow-ups outside these repositories

The spec (section 8) lists these. They are not tasks in this plan:

- `brick_dartfrog`: drop `SocketException` from the hide in `example-app/packages/core/lib/core.dart` when the app moves to 2.4.0, or `dart analyze` reports `undefined_hidden_name`.
- `getdoit_service`: it depends on another clone of `dart-falconx` by path, so it changes only when that clone moves to 2.4.0.
