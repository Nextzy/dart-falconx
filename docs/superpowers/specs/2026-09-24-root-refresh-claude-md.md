# Root CLAUDE.md refresh — spec

target: ./CLAUDE.md
kind: claude-md
mode: edit
layout: CLAUDE.md only (no AGENTS.md; do not introduce one)
load: always
budget: 1600
words_before: 1540
net: ≤ 0 (words_before is 96% of budget); expected result ~1,000 words

## Intent

Owner request: bring the root `CLAUDE.md` in line with the code as it is now, and state that every package works in any
Dart project (client and server) on every platform. Approach chosen by the owner: "Refresh + dedupe".

## bundle:

Always-on files loaded with the target (counted, never edited):

- ./CLAUDE.md — 1540 (target)
- ./.claude/rules/communication-style.md — 132
- ../../CLAUDE.md (projects/CLAUDE.md) — 176
- ../../../CLAUDE.md (NTD OS root) — 1026
- ../../../.wiki/CLAUDE.md — 1172
- ../../../.agent-style/claude-code.md — 360
- ../../../.claude/rules/my-assistant-main-session.md — 299
- ../../../.claude/rules/auto-memory.md — 611
- ~/.claude-code-router/profiles/default-claude-code/claude/CLAUDE.md — 19
- ~/.agents/AGENTS.md — 73
- ~/.agents/rules/memory-hygiene.md — 370
- ~/.agents/rules/memory-roadmap.md — 599

Bundle total: 6,377 words, 261 directive lines. Owned by other files: 4,837 words.

On-demand files (read for duplication and altitude only):

- dart_falconnect/CLAUDE.md — 1069 (over its 800 cap; out of scope)
- dart_falmodel/CLAUDE.md — 627
- dart_faltool/CLAUDE.md — 511
- dart_falconx/CLAUDE.md — 207

## Verified facts (evidence for the edit)

- Root `pubspec.yaml`: `sdk: ">=3.13.0 <4.0.0"`, `melos: ^8.9.0`. Scripts: `analyze` (plain `dart analyze`), `format`,
  `fix`, `fix:format`, `test`, `build_runner`, `build_runner:fast`, `build_runner:watch`, `get`, `upgrade`, `outdated`.
  There is no `check` script.
- `melos get` fails: `Could not find a command named "get"`. Scripts run only through `melos run <name>`. Built-in
  melos commands include `bootstrap`, `clean`, `analyze`, `format`, `test`, `exec`, `list`.
- No package depends on the Flutter SDK, and no file under `dart_*/lib` imports `package:flutter`.
- No file under `dart_*/lib` imports `dart:io`, `dart:html`, `dart:ffi`, `dart:isolate`, `dart:mirrors`, or `dart:js*`.
  Platform code is split by `if (dart.library.io)` conditional imports in
  `dart_falmodel/lib/extensions/exception_extensions.dart`, `dart_faltool/lib/dart_faltool.dart` (logger export), and
  `dart_faltool/lib/utils/app_info.dart`.
- `dart_falconnect/test/web/compile_smoke.dart` compiles with `dart compile js`, `dart compile wasm`, and
  `dart compile exe` (Dart 3.13.3). `dart_falconnect/test/web/engine_web_test.dart` is `@TestOn('browser')` and runs with
  `dart test -p chrome`. No melos script runs these gates.
- `analysis_options.yaml` sets `strict-casts: false` and `strict-inference: false`. `analysis_options.ci.yaml` sets both
  `true`, but `dart analyze` has no flag to select an options file and no script references it.
- Test files: dart_falconnect 16, dart_falmodel 6, dart_faltool 17, dart_falconx 1 (stub).
- `Result<T>` (`dart_falmodel/lib/models/result.dart`) is `class Result<T> extends Equatable` with `success`, `failure`,
  and `dataFailure` factories. It is not a sealed union.
- No `ErrorType` class or enum exists under `dart_*/lib`. `DefaultErrorType` is a `sealed class` implemented by nine enums.
- `dart_faltool/lib/dart_faltool.dart` re-exports `clock` (show `Clock`, `clock`, `withClock`), `rrule`, `time`, and
  `fpdart` hiding `State` and `Task`. It does not re-export `universal_io`, `web`, `yaml`, or `ansicolor`.
- `skills/dart-falconx-package/references/third-party.md` (406 words) already documents the re-exported packages.
- All three `build.yaml` files set `checked: true` and `explicit_to_json: true`.

## cut:

- cut: Package Management — rewrite `melos get|upgrade|outdated` as `melos run get|upgrade|outdated`; drop `flutter clean`; keep the `melos clean` + `melos bootstrap` reset (−6)
- cut: Code Generation section — delete; the melos scripts table already covers `build_runner` and `build_runner:fast` (−39)
- cut: Testing — keep `melos run test` plus one single-file example; drop `-n` and `--coverage` flags; replace the "dart_faltool has real tests; other packages have stubs" claim with the fact that only `dart_falconx/test/unit_test.dart` is a stub (−25)
- cut: Code Quality section — delete (generic `dart analyze`, `dart fix --apply`, `dart format .`) (−19)
- cut: Melos scripts table — `analyze` row becomes plain `dart analyze` (concurrency 4); delete the `check` row; add `outdated` beside `get`/`upgrade` (−7)
- cut: Core Components — compress; keep one line each for `https/`, `sockets/`, `rpc/` naming the main types (`BaseHttpClient` + `configure(HttpClientConfig)`, `SocketClient`, `JsonRpcService`/`DefaultJsonRpcService`, `BatchJsonRpcItem`); leave detail to `dart_falconnect/CLAUDE.md` (−40)
- cut: Code Generation Structure — drop the `**Important**` label; keep the `generated/` output path and the "run `melos run build_runner` after editing annotated files" rule (−8)
- cut: Exception Architecture — compress; replace `MUST` and `do NOT` with plain imperatives; replace the stale `ErrorType` reference: a `NetworkException` carries a `NetworkErrorType`, never a `DefaultErrorType` enum (−40)
- cut: Key Design Patterns — keep the interceptor-order pointer to `skills/dart-falconx-package/references/http.md`; rewrite Result as "`Result<T>` class with `success`/`failure`/`dataFailure` factories"; delete the Extension Methods and Stream-Based Communication bullets (generic) (−55)
- cut: Gotchas — delete "exports in barrel files must be sorted alphabetically (directives_ordering)"; the lint enforces it (−15)
- cut: Linting Rules — replace with two facts: one root `analysis_options.yaml` (base `very_good_analysis`) covers every package; local analysis runs with `strict-casts`/`strict-inference` off, and `analysis_options.ci.yaml` turns them on but nothing selects it (−25)
- cut: Build Configuration — compress to `build.yaml` location, checked mode + `explicit_to_json`, and "melos scripts live under the `melos:` key of the root `pubspec.yaml`" (−20)
- cut: Environment Requirements — delete; the manifest states SDK and melos versions (−17)
- cut: Third-Party Packages (three tables) — replace with one pointer line: `skills/dart-falconx-package/references/third-party.md` — open when choosing or calling a re-exported third-party package (−330)

## add:

- add: `## Platform support`, placed right after Project Overview (+95). Text, adjust only for budget or phrasing checks:

```markdown
## Platform support

- Every package serves any Dart project: Flutter apps (Android, iOS, macOS, Windows, Linux, web) and pure-Dart servers and CLIs.
- Keep every package pure Dart: never depend on the Flutter SDK or import `package:flutter`.
- Never import `dart:io`, `dart:html`, `dart:ffi`, or `dart:isolate` under `lib/`; split platform code with an `if (dart.library.io)` conditional import, as `dart_faltool/lib/utils/app_info.dart` does.
- Platform gates, from `dart_falconnect/`: `dart compile js test/web/compile_smoke.dart -o /tmp/smoke.js` (repeat with `wasm` and `exe`), then `dart test -p chrome test/web/engine_web_test.dart`.
```

- add: Gotchas — one line for web integer semantics, which bind every package that compiles to web: on web, `int` bitwise and shift operators truncate to 32 bits, so never shift or mask a value that may exceed 32 bits; cover such a path with a `dart test -p chrome` test (+30). `dart_falconnect/CLAUDE.md` keeps its own copy (on-demand file, left unedited).

## moved:

- none

## net

Cuts ≈ −646; adds ≈ +125; net ≈ −521. Expected result ≈ 1,000 words.

## sections

1. `# dart-falconx` title
2. Project Overview (with Package Architecture diagram)
3. Platform support
4. Commands (package management, testing, melos scripts table)
5. Architecture (core components, code generation structure, exception architecture, key design patterns)
6. Gotchas
7. Skill maintenance (keep; compress only if needed)
8. Configuration (linting, build)
9. Third-party packages (pointer)

## Out of scope

- `dart_falconnect/CLAUDE.md` over its 800-word cap (1069).
- `analysis_options.ci.yaml` is dead config: delete it or wire it into CI (owner decision).
- A melos script running the platform gates (hook or script candidate; the CLAUDE.md gate line would then become a pointer).
- Editing any nested CLAUDE.md, rule file, memory, or the consumer skill.
- Git commits.
