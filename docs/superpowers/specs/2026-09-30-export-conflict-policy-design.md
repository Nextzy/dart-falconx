# Export conflict policy

**Date:** 2026-09-30
**Repositories:** `dart-falconx` (all four packages), `flutter-falconx`, `jaspr-falconx`.
**Versions:** `dart-falconx` 2.3.1 to 3.0.0; `flutter-falconx` 4.0.1 to 5.0.0; `jaspr-falconx` 1.0.5 to 2.0.0. Each bump is major because each repository removes or renames public symbols.
**Builds on:** a throwaway probe run on 2026-09-30 (section 1.2). The probe lived in `/tmp/falconx_probe/` and is not part of any repository.

## 1. Context

### 1.1 How Dart resolves a name that two libraries export

The barrels of all three repositories re-export `dart:` libraries and third-party packages next to their own code. When an app imports such a barrel next to another library that exports the same name, Dart applies one of four rules. Small analyzer tests in the probe confirmed rules 1 to 3 on Dart 3.13.3; rule 4 is the ordinary case.

| # | Situation | Result |
|---|---|---|
| 1 | An import brings a package declaration and a `dart:` declaration with the same name, directly or through a package that re-exports the `dart:` library | The `dart:` declaration is hidden without any diagnostic. `TextDirection.ltr` then resolves to intl's class, and `on SocketException` catches the wrong type. |
| 2 | Two imports bring two different `dart:` declarations, at least one through a re-export | `ambiguous_import` at every use. Example: a barrel that re-exports `dart:math`, imported next to `dart:developer`, breaks `log('x')`. |
| 3 | One barrel exports two different declarations with the same name, `dart:` or not | `ambiguous_export` in the barrel itself. A barrel therefore never shadows a `dart:` name silently. |
| 4 | Two imports bring two different package declarations | `ambiguous_import` at every use. |

Rule 1 costs the most: nothing reports it, and the symptom surfaces far from the cause.

### 1.2 Probe

The probe used `package:analyzer` 14.4.0 to read the export namespace of every `dart-falconx` barrel from the local working copy, including the uncommitted `IterableFilter` hide in `dart_faltool`. It compared each name against:

- every `dart:` library of the Dart SDK, plus `dart:ui` from the Flutter SDK;
- `package:flutter/` `material`, `cupertino`, `widgets`, `services`, `foundation`, `rendering`, `painting`, `animation`, `gestures`, `physics`, `scheduler`, and `semantics`;
- `package:jaspr/` `jaspr`, `dom`, `server`, and `client`, at 0.22.4 (the version `jaspr-falconx` resolves) and at 0.23.1;
- `package:dart_frog/dart_frog.dart` 1.2.6.

It also read the export namespaces of the `flutter_falconx`, `flutter_faltool`, `jaspr_falkit`, and `jaspr_faltool` barrels to see which side each adapter keeps.

### 1.3 Findings

A name collides when both sides export it with different declaring libraries.

| Name | Exported by | Declared in | Collides with | Rule | Handled today by |
|---|---|---|---|---|---|
| `log` | `dart_faltool` | `dart:math` | `dart:developer` | 2 | nothing |
| `SocketException` | `dart_falconnect` | `dart_falconnect` | `dart:io` | 1 | nothing in this repository; `brick_dartfrog`'s example app hides it |
| `RemoteError` | `dart_falmodel` | `dart_falmodel` | `dart:isolate` | 1 | nothing |
| `HttpResponse` | `dart_falconnect` | `retrofit` | `dart:io` | 1 | `brick_dartfrog`'s example app hides it |
| `TextDirection` | `dart_faltool` | `intl` | `dart:ui`, and every Flutter library that re-exports it | 1 | `flutter_falconx` |
| `Path` | `dart_falconnect` | `retrofit` | `dart:ui`, and every Flutter library that re-exports it | 1 | `flutter_falconx` |
| `Codec` | `dart_faltool` | `dart:convert` | `dart:ui` | 2 | `flutter_falconx`, which hides the `dart:ui` side |
| `RefreshCallback` | `dart_falconnect` | `dart_falconnect` | Flutter `material` and `cupertino` | 4 | `flutter_falconx` |
| `Unit` | `dart_faltool` | `fpdart` | `jaspr/dom.dart` | 4 | `jaspr_falkit`, which keeps jaspr's |
| `option` | `dart_faltool` | `fpdart` | `jaspr/dom.dart` | 4 | `jaspr_falkit`, which keeps fpdart's |
| `Response` | `dart_falconnect` | `dio` | `dart_frog`; `jaspr/server.dart` (shelf) | 4 | `brick_dartfrog`'s example app hides it |
| `FormData` | `dart_falconnect` | `dio` | `dart_frog` | 4 | `brick_dartfrog`'s example app hides it |
| `HttpMethod` | `dart_falconnect` | `retrofit` | `dart_frog` | 4 | `brick_dartfrog`'s example app hides it |

The probe found no collision with `dart:core`, `dart:async`, `dart:convert`, `dart:collection`, or `dart:typed_data`.

Collisions left out of scope:

- `Body`, `FormData`, `Headers`, and `Range` with `dart:html`; `Matrix` and `Point` with `dart:svg`; `Query` with `dart:web_gl`. These libraries are deprecated in favour of `package:web`.
- `Flow` (Flutter widget) with `dart:developer`, `Size` (`dart:ui`) with `dart:ffi`, and `Link` (`jaspr_router`) with `dart:io`. These collisions come from the frameworks, not from `dart-falconx`.

### 1.4 Stale hides

- `jaspr_faltool/lib/jaspr_faltool.dart` hides `Link`, which `dart_faltool` no longer exports. `dart analyze` reports `undefined_hidden_name` today.
- The uncommitted change in `dart_faltool/lib/dart_faltool.dart` hides dartx's `IterableFilter`, whose only member, `filter`, duplicates `where`. After `dart-falconx` releases it:
  - `flutter_faltool`'s `hide IterableFilter` turns into an `undefined_hidden_name` warning.
  - `jaspr_faltool/lib/lib.dart` and `jaspr_falkit/lib/lib.dart` hide jaspr's `IterableFilter`, so neither side reaches jaspr apps.

### 1.5 Downstream evidence

`brick_dartfrog/example-app/packages/core/lib/core.dart`, a dart_frog app, already exports `dart_falconx` with `hide FormData, HttpMethod, HttpResponse, Response, SocketException`. That list matches the dart_frog and `dart:io` rows of section 1.3. The app hides `SocketException` because it needs `dart:io`'s class.

## 2. Goals and non-goals

**Goals**

- One written policy decides where each collision is fixed (section 3).
- No declaration owned by these repositories collides with a `dart:` library or a supported framework.
- No barrel carries a stale hide.
- Each repository has a check that fails on any collision the policy has not settled, including collisions that a future dependency upgrade introduces (section 4.3).

**Non-goals**

- An adapter package for dart_frog. Apps keep an app-level barrel, as `brick_dartfrog` does; revisit when a second dart_frog app appears.
- Hiding Retrofit's `HttpResponse` in `dart_falconnect`. Code that Retrofit generates for a method returning `HttpResponse<T>` needs the name in scope.
- The deprecated web libraries and the framework-owned collisions of section 1.3.
- CI workflows. None of the three repositories has one; the check becomes a release gate.
- Edits to apps outside these repositories. Section 8 lists the follow-ups.

## 3. Policy

| Collision | Fixed in | How |
|---|---|---|
| A declaration owned by these repositories collides with anything | The package that declares it | Rename. A deprecated alias under the old name would keep the collision, so none is added. |
| A re-exported third-party name collides with a `dart:` library available on every platform | The `dart-falconx` barrel that re-exports it | Hide |
| A re-exported `dart:` name collides with another `dart:` library | Every barrel that re-exports the first library | Hide |
| A re-exported name collides with one framework (Flutter, jaspr) | That framework's adapter barrel | Hide the non-framework side: the framework's name wins |
| A re-exported name collides with dart_frog or shelf | The app-level barrel | Hide |
| The collision cannot be removed without breaking a supported use | The check's allowlist | Record the reason |

Framework-specific hides stay out of `dart-falconx` for two reasons. A hide there removes the name from every other platform that has no collision. The `dart-falconx` workspace also has no Flutter or jaspr dependency, so its check cannot verify such a hide.

## 4. dart-falconx 3.0.0

### 4.1 Barrel changes

`dart_faltool/lib/dart_faltool.dart`:

```dart
export 'dart:math' hide log;
```

The `IterableFilter` hide on the dartx export, uncommitted today, ships in this release. No file under `lib/` in the four packages calls `dart:math`'s `log`, so no internal code changes.

### 4.2 Renames

| Package | Old name | New name | File renamed to |
|---|---|---|---|
| `dart_falconnect` | `SocketException` | `SocketClientException` | `engine/sockets/exceptions/socket_client_exception.dart` |
| `dart_falconnect` | `RefreshCallback` | `TokenRefreshCallback` | (typedef stays in `engine/https/config/auth_config.dart`) |
| `dart_falmodel` | `RemoteError` | `RemoteErrorBody` | `networks/https/responses/remote_error_body.dart` |

- `SocketClientException` matches `SocketClient`. Its subclasses `SocketRetryException` and `SocketOperationNotFound` keep their names, and its `toString` prints the new name.
- `TokenRefreshCallback` sits next to `AccessTokenCallback` and `AuthFailedCallback` in `AuthConfig`.
- `RemoteErrorBody` keeps the old name as a prefix, so a search for `RemoteError` still finds it. It describes what the class models: the error payload of a response body.
- After the renames, `melos run build_runner` regenerates the Freezed and JSON files, and every usage, test, doc comment, and `CLAUDE.md` mention moves to the new names.
- The doc example `retryIf: (error) => error is SocketException` in `dart_faltool/lib/extensions/future_extensions.dart` stays as it is: after the rename it refers to `dart:io`'s class, as intended.

### 4.3 Export check

A standalone package at `tool/export_check/`:

- Its own `pubspec.yaml`, outside the workspace, with dependencies on `analyzer` and `dart_frog`. Keeping it outside the workspace keeps both packages out of the workspace resolution that the four library packages share. A test on 2026-09-30 confirmed that a standalone package nested in a pub workspace resolves on its own and leaves the workspace resolution unchanged.
- `bin/check.dart` holds four constants:
  - `subjects`: the barrels to check, each with the directory whose package config resolves it.
  - `targets`: the libraries to check against, each with its directory.
  - `frameworkOwned`: URI prefixes of framework libraries. A collision whose subject-side declaration comes from one of them belongs to the framework, such as Flutter's `Flow` widget against `dart:developer`, and the script skips it.
  - `allowlist`: a map from a `(subject barrel, name)` record to the reason the collision stays. One entry covers every target the name collides with, and a regression in another barrel still fails.
- For each subject and target, the script reads both export namespaces through `AnalysisContextCollection` and `getLibraryByUri`. It skips setter entries (`name=`) and reports every name whose declaring library URI differs.
- It throws when a root directory does not exist or a library does not resolve, so a run from the wrong directory fails instead of passing.
- It exits with code 1 when a collision is missing from the allowlist, or when an allowlist entry matches no collision. The second condition keeps the allowlist from going stale, as the `Link` hide did.
- Each reported line names the collision, the subject barrel and its declaring library, and the target and its declaring library.

`dart-falconx` configuration:

- Subjects: `dart_falconx`, `dart_faltool`, `dart_falconnect`, and `dart_falmodel`, since an app may depend on any one package alone.
- Targets: `dart:async`, `dart:collection`, `dart:convert`, `dart:core`, `dart:developer`, `dart:ffi`, `dart:io`, `dart:isolate`, `dart:math`, `dart:typed_data`, `dart:js_interop`, `dart:js_interop_unsafe`, and `package:dart_frog/dart_frog.dart`.
- `frameworkOwned`: empty.
- Allowlist, for both `dart_falconx` and `dart_falconnect`:
  - `HttpResponse` (collides with `dart:io`; section 2, non-goals)
  - `Response`, `FormData`, and `HttpMethod` (collide with `dart_frog`; the app-level barrel hides them)

A root melos script runs it:

```yaml
    check:exports:
      description: Fail when a barrel exports a name that collides with a dart library or a supported framework and the allowlist does not record it.
      run: cd tool/export_check && dart pub get && dart run bin/check.dart
```

The tool code follows the root `analysis_options.yaml`, so it writes to `stdout` and `stderr` instead of calling `print`.

### 4.4 Documentation

- `CLAUDE.md`:
  - Add an "Export conflicts" subsection under Architecture that holds the policy table of section 3 and the `check:exports` command.
  - Add `melos run check:exports` to the Commands table and to the "Before bumping a version" rule.
- `skills/dart-falconx-package/SKILL.md`:
  - Add `log` and `IterableFilter` to the hidden-symbols line.
  - Add a "Server apps (dart_frog)" note with the app-level barrel:

    ```dart
    export 'package:dart_falconx/dart_falconx.dart'
        hide FormData, HttpMethod, HttpResponse, Response;
    export 'package:dart_frog/dart_frog.dart';
    ```

- `skills/dart-falconx-package/references/`:
  - Apply the renames wherever an old name appears: today `websocket.md` names `SocketException` and `models.md` names `RemoteError`.
  - Drop the websocket note "not `dart:io`'s class".
- `dart_falconnect/CLAUDE.md`: apply the `SocketClientException` rename.

## 5. flutter-falconx 5.0.0

`flutter-falconx` 4.0.1, released on 2026-09-30, stopped `flutter_falconnect`, `flutter_falmodel`, and `flutter_falstore` from re-exporting sibling packages, so intl's `TextDirection` now reaches only `flutter_faltool`.

- Set every `dart-falconx` `ref:` to `3.0.0`.
- `flutter_falconx/lib/flutter_falconx.dart`:
  - Change `export 'dart:math';` to `export 'dart:math' hide log;`.
  - Drop `RefreshCallback` from the hide on the `flutter_falconnect` export, which then exports `TokenRefreshCallback`.
- `flutter_faltool/lib/flutter_faltool.dart`: drop `hide IterableFilter`.
- Add `tool/export_check/` with this configuration:
  - Subjects: `flutter_falconx`, `flutter_faltool`, `flutter_falconnect`, `flutter_falmodel`, and `flutter_falstore`.
  - Targets: the `dart:` list of section 4.3 without `dart_frog`, plus `dart:ui`, `package:flutter/material.dart`, `package:flutter/cupertino.dart`, `package:flutter/services.dart`, and `package:flutter/foundation.dart`.
  - `frameworkOwned`: `package:flutter/` and `dart:ui`.
  - Allowlist:
    - `HttpResponse` in `flutter_falconx` and `flutter_falconnect` (collides with `dart:io`)
    - `Codec` in `flutter_falconx` and `flutter_faltool`, which keep `dart:convert`'s. Section 3 would pick `dart:ui`'s image `Codec`, but apps reach that one through `instantiateImageCodec` without naming it, and switching would break apps that name the encoding `Codec`.
    - `TextDirection` in `flutter_faltool` and `Path` in `flutter_falconnect`. These single-package barrels carry no Flutter import, and the package skill tells apps to hide both names when they import one next to `material`.
  - A prototype run on 2026-09-30 against 4.0.1 reported exactly the collisions this section removes: `log`, `SocketException`, `RemoteError`, and, in `flutter_falconnect`, `RefreshCallback`.
- Add the `check:exports` melos script and put it in the release steps of `CLAUDE.md`.
- Update `CHANGELOG.md`, `CLAUDE.md`, and `skills/flutter-falconx-package/` (`SKILL.md` and `references/third-party.md`) for the removed `log`, the three renames, and `TokenRefreshCallback`, now exported.

## 6. jaspr-falconx 2.0.0

Precondition: the uncommitted work in `jaspr-falconx` lands first. That work moves its `dart-falconx` refs from commit `72e44f5` to 2.3.1; moving on to 3.0.0 may still surface breakages unrelated to this spec. Fix those in a separate commit before the changes below.

- Set every `dart-falconx` ref to `3.0.0`.
- `jaspr_faltool/lib/jaspr_faltool.dart`, the one file that re-exports `dart_faltool` into this repository: replace the stale `hide Link` so jaspr's `Unit` and `option` win everywhere, as section 3 requires:

  ```dart
  export 'package:dart_faltool/dart_faltool.dart' hide Unit, option;
  ```

  Apps write `Option.of(...)` or `some(...)` for fpdart's option and `unit` for fpdart's unit value. The `jaspr-falconx` packages have already migrated from `Either` to `Result`, so they no longer need fpdart's `Unit` type.
- `jaspr_faltool/lib/lib.dart` and `jaspr_falkit/lib/lib.dart`: drop `hide IterableFilter` from the `package:jaspr/jaspr.dart` exports.
- `jaspr_falkit/lib/lib.dart`: drop `hide option` from the `package:jaspr/dom.dart` export and `hide Unit` from the `jaspr_faltool` export; both hides turn stale once `jaspr_faltool.dart` hides the names.
- Add `tool/export_check/` with this configuration:
  - Subjects: `package:jaspr_falconx/jaspr_falconx.dart`, `package:jaspr_falkit/lib.dart`, `package:jaspr_faltool/lib.dart`, and `package:jaspr_falconnect/lib.dart`.
  - Targets: the `dart:` list of section 4.3 without `dart_frog`, plus `package:jaspr/jaspr.dart`, `dom.dart`, `server.dart`, and `client.dart`.
  - `frameworkOwned`: `package:jaspr/`, `package:jaspr_router/`, `package:jaspr_riverpod/`, and `package:riverpod/`. These cover `jaspr_router`'s `Link` against `dart:io` and riverpod's `AsyncError`, which `jaspr_falconx` keeps over `dart:async`'s.
  - Allowlist, in `jaspr_falconx.dart` and `jaspr_falconnect/lib.dart`, the two subjects that export `dart_falconnect`:
    - `Response`: it collides with shelf's `Response` from `jaspr/server.dart`, which no barrel exports, so server code hides it at the import.
    - `HttpResponse`: it collides with `dart:io`, as in section 4.3.
- Add the `check:exports` script to `melos.yaml` and document it in `CLAUDE.md`.

## 7. Testing

- The check is its own red-green test. Written before the barrel changes and renames, `dart-falconx`'s `check:exports` must fail and list `log`, `SocketException`, and `RemoteError`; after them it must pass. `flutter-falconx` must first fail on `log`, `SocketException`, `RemoteError`, and `RefreshCallback` (in `flutter_falconnect`), and `jaspr-falconx` on `log`, `SocketException`, `RemoteError`, `IterableFilter`, `option`, and `Unit`; each must pass after its changes. `RefreshCallback` collides only with Flutter, so only `flutter-falconx` can see it.
- `dart-falconx` gates: `melos run analyze`, `format`, `test`, `build_runner:check`, `test:platforms`, and `check:exports`.
- `flutter-falconx` and `jaspr-falconx` gates: `melos run analyze`, `test`, and `check:exports`. `analyze` also catches stale hides, because `dart analyze` fails on the `undefined_hidden_name` warning.
- Record the run time of `check:exports` in each repository's `CLAUDE.md`. A prototype took 25 s for `dart-falconx`, 54 s for `flutter-falconx`, and 44 s for `jaspr-falconx`.

## 8. Rollout

1. `dart-falconx`: feature branch, merge into `develop`, then `git flow release` 3.0.0.
2. `flutter-falconx` and `jaspr-falconx`, in parallel, after tag 3.0.0 exists.
3. Follow-ups outside these repositories:
   - `brick_dartfrog`: drop `SocketException` from the hide in `example-app/packages/core/lib/core.dart`, or `dart analyze` reports `undefined_hidden_name`.
   - `getdoit_service`: it depends on another clone of `dart-falconx` by path, so it changes only when that clone moves to 3.0.0.

## 9. Risks

- The check reads `exportNamespace.definedNames2`, analyzer API whose `Namespace` type lives under `src/`. A new analyzer major may break the tool; fix it when bumping `analyzer` in `tool/export_check/pubspec.yaml`.
- `analyzer` 14.4.0 requires Dart `^3.11.0`. A later SDK may need a newer `analyzer`.
- An allowlist entry settles a name for one subject barrel against every target. A new collision of an allowlisted name with a newly added target passes unnoticed; review the allowlist whenever a target is added.
