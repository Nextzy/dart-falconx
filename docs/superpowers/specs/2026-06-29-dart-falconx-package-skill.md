# Spec: `dart-falconx-package` skill

Date: 2026-06-29
Status: approved (design), pending implementation

## Skill name

`dart-falconx-package`

## Trigger description (frontmatter `description`)

Use when writing Dart/Flutter code in a project that depends on `dart_falconx`,
`dart_falconnect`, `dart_falmodel`, or `dart_faltool` — covers the single umbrella
import, HTTP/WebSocket/JSON-RPC clients, the Result error-handling pattern, the
exception systems, data models, and the utility extensions. Helps an agent call
the public API correctly while reading few tokens.

## Scope

- **Portable / self-contained.** The skill is authored here but **manually copied**
  into other consumer projects' skill directories. It MUST stand alone.
- **Audience:** AI agents implementing features in downstream apps that import
  these packages (NOT monorepo contributors).
- **Install location of authored copy:** `skills/dart-falconx-package/` in this
  repo, committed to git, serving as the source of truth to copy from.

## Core behavior — progressive disclosure

Lean `SKILL.md` loaded every recall; per-package detail files loaded only when the
task touches that package.

```
SKILL.md                      # index / decision-map, ~80-150 lines
packages/dart_falconnect.md   # network impl: HTTP, WebSocket, JSON-RPC
packages/dart_falmodel.md     # models, exceptions, Result pattern
packages/dart_faltool.md      # extensions, re-exported libs, TypeID
```

(No `dart_falconx.md` — it is only the umbrella re-export, covered in SKILL.md.)

### SKILL.md contents

- Single import that covers everything:
  `import 'package:dart_falconx/dart_falconx.dart';` — re-exports all four packages
  plus their transitive third-party libs.
- Package map table: each package → one-line purpose → "for X, read `packages/Y.md`".
- Top cross-cutting gotchas only, e.g.:
  - HTTP methods require converter functions (no implicit JSON typing).
  - Do NOT mix `NetworkException` with `DefaultErrorType`; `NetworkException extends
    CommonException`.
  - Some re-exported third-party members are `hide`-n to avoid clashing with local
    extensions (e.g. parts of `dartx`, `fpdart` `State`/`Task`).
- Routing rules: which kind of task → which package file to open.

### Per-package detail files

Each holds task-oriented recipes with real snippets drawn from the **public API
surface** (what is reachable through the umbrella import). Keep each focused and
concise; lead with the most common usage.

- **dart_falconnect.md**
  - `BaseHttpClient`: typed methods + required converter functions.
  - Interceptor chain and order (auth → retry → cache → logging).
  - `SocketClient`: reactive stream, filtering for a response type, reconnection.
  - JSON-RPC: `JsonRpcService` / `DefaultJsonRpcService`; `BatchJsonRpcItem` sealed
    class with `resolve`, `map`, `responseOrNull`, `errorOrNull`.
- **dart_falmodel.md**
  - Result pattern: Success/Failure union, pattern matching, key transform helpers.
  - Three exception systems and when to use which: `DefaultErrorType`,
    `NetworkErrorType`, JSON-RPC exceptions; `CommonException.category` /
    `toJsonRpcError()`.
  - Models: freezed + json_serializable usage from a consumer's view (constructing,
    `fromJson`/`toJson`).
- **dart_faltool.md**
  - Extension catalog: String, StringValidator, DateTime, Number, Future, Stream,
    Iterable, List, Map, Enum, Object.
  - Notable re-exported third-party available transitively: `fpdart`
    (`Either`/`Option`), `rxdart`, `intl`, `big_decimal`, `numeral`, `timeago`,
    `equatable`, `meta` — and which members are hidden.
  - TypeID utility.

## Portability rules (hard constraints for the author)

- Reference ONLY the public API reachable through `package:dart_falconx/...`
  imports.
- Do NOT reference in-repo source paths (e.g. `dart_falconnect/lib/...`).
- Do NOT include this repo's `melos` / `build_runner` / contributor commands.
- Snippets must compile against the published package surface, not internal files.

## Out of scope

- build_runner / melos / codegen workflow (that is the repo's CLAUDE.md).
- Editing or contributing to the packages themselves.
- A `dart_falconx.md` detail file (umbrella has no own API beyond re-exports).

## Author guidance

The skill-engineer should mine the actual public API from each package's main
`lib/<pkg>.dart` export and the exported barrel files to ensure snippets match real
class/method names, then compress to recipes. Verify names against source but never
cite source paths in the skill output.
