---
project_name: 'dart-falconx'
user_name: 'Nonthawit'
date: '2026-04-17'
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'code_quality', 'workflow_rules', 'critical_rules']
status: 'complete'
rule_count: 52
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

### Core
- **Dart SDK**: >=3.9.0 <4.0.0
- **Melos**: ^7.5.1 (workspace management)

### Monorepo Packages
| Package | Role | Version |
|---------|------|---------|
| dart_falconx | Umbrella (re-exports all) | 1.0.1 |
| dart_falconnect | Network layer (HTTP, WebSocket, RPC) | 1.0.1 |
| dart_falmodel | Models, exceptions, abstractions | 1.0.1 |
| dart_faltool | Utilities, extensions, helpers | 1.0.1 |

### Key Dependencies
- **Dio** ^5.9.2 — HTTP client
- **Retrofit** ^4.9.2 / retrofit_generator ^10.2.5 — Type-safe API client generation
- **Freezed** ^3.2.5 / freezed_annotation ^3.1.0 — Immutable models + unions
- **json_serializable** ^6.13.1 / json_annotation ^4.11.0 — JSON codegen
- **RxDart** ^0.28.0 — Reactive streams
- **fpdart** ^1.2.0 — Functional programming
- **web_socket_channel** ^3.0.3 — WebSocket
- **big_decimal** ^0.7.0 — Precision decimal math
- **dio_cache_interceptor** ^4.0.6 — HTTP cache layer

### Linting
- **very_good_analysis** ^10.2.0 — Base rules
- `strict-casts: true`, `strict-inference: true` — No implicit dynamic

### Workspace Resolution
- Dart workspace resolution enabled (not pub path overrides)
- dart_faltool ↔ dart_falmodel have circular dependency resolved via workspace

## Critical Implementation Rules

### Language-Specific Rules (Dart)

#### Import Convention
- **Internal files**: Always `import 'package:<pkg>/lib.dart'` — never import individual files
- **Public API**: Consumers use `import 'package:<pkg>/dart_<pkg>.dart'`
- `lib.dart` is NOT the public API — it's the internal prelude that re-exports dart:async, dart:convert, and sibling packages

#### Strict Analysis
- `strict-casts: true` and `strict-inference: true` are enabled — no implicit `dynamic` allowed
- All code must pass `dart analyze` with zero warnings
- Generated files (`*.g.dart`, `*.freezed.dart`, `**/generated/**`) are excluded from analysis

#### Extension Naming Pattern
- Non-null: `Falcon{Tool}{Type}Extension on Type` (e.g., `FalconToolStringExtension on String`)
- Nullable: `Falcon{Type}NullExtension on Type?` (e.g., `FalconStringNullExtension on String?`)
- Always provide both variants when the extension makes sense on nullable types

#### Barrel Exports
- Every module has a barrel file (e.g., `extensions.dart`, `interceptors.dart`, `exceptions.dart`)
- Exports MUST be sorted alphabetically — enforced by `directives_ordering` lint rule
- New files MUST be added to the appropriate barrel file

#### No dart:io
- This project is web-compatible — do NOT import `dart:io` directly
- Use `package:universal_io/io.dart` (re-exported via dart_faltool) when platform I/O is needed
- Dio's `httpClientAdapter` must remain as the auto factory (no `IOHttpClientAdapter`)

#### Null Safety & Type Safety
- Prefer `dynamic` over `Object?` for loosely-typed data from JSON/API responses (semantic clarity)
- Use `as` type casts only when the type is guaranteed — prefer pattern matching or coercion functions
- Never use `!` (null assertion) without an immediately preceding null check

### Framework-Specific Rules

#### Monorepo Package Architecture
- `dart_falconx` is umbrella only — NEVER add logic here, only re-exports
- `dart_falconnect` is the top layer — depends on falmodel + faltool
- `dart_falmodel` is the middle layer — depends on faltool only
- `dart_faltool` is the base utility layer — depends on falmodel (circular, resolved via workspace)
- New code goes in the appropriate layer — respect dependency direction

#### Circular Dependency: dart_faltool ↔ dart_falmodel
- Intentional design: utilities need models (Result, CommonException) for error wrapping; models need utilities for extensions
- `dart_faltool/lib/utils/functions.dart` uses `Result<T>` and `CommonException` from dart_falmodel
- `dart_faltool/lib/extensions/dynamic_extensions.dart` uses `BigDecimal` from dart_falmodel
- Resolved via Dart workspace resolution — NOT a layering violation

#### HTTP Client (Dio + Retrofit)
- All HTTP methods in `BaseHttpClient` require a `converter: (Map<String, dynamic>) → T` parameter — no raw response API
- POST/PUT/PATCH/DELETE data must be `BaseRequestBody` (requires `.toJson()`)
- Interceptor order matters: auth → retry → cache → logging
- New interceptors must be exported in `interceptors/interceptors.dart` (alphabetically)

#### Code Generation (Freezed + Retrofit)
- Generated files go to `lib/{{path}}/generated/{{file}}.{freezed|g}.dart`
- Use `part 'generated/<file>.freezed.dart'` and `part 'generated/<file>.g.dart'`
- Run `dart run build_runner build -d` after modifying annotated files
- Run `melos build_runner` for all packages at once

#### Exception Architecture (Three Systems — Do NOT Mix)
1. **CommonException** + `DefaultErrorType` — general purpose
2. **NetworkException** + `NetworkErrorType` — HTTP-specific, maps to status codes
3. **JsonRpc exceptions** + `JsonRpcErrorCategory` — RPC-specific
- NetworkException uses NetworkErrorType, NOT DefaultErrorType
- Each HTTP exception class sets default type via `super.type = NetworkErrorType.xxx`

#### Result<T> Pattern
- Success/Failure union without throwing — use `map`, `flatMap`, `when`, `resolve`
- Wrap async ops with `runCatching()`, `runDomainCatching()`, `runDataCatching()`
- Each wraps into the appropriate layer exception automatically

#### WebSocket (RxDart Streams)
- `SocketClient` uses `PublishSubject<SocketResponse>` (not ReplaySubject despite var name)
- Stream-based filtering for specific response types
- Auto-reconnection handled by the base class

### Testing Rules

#### Test Organization
- Tests mirror source structure: `lib/extensions/foo.dart` → `test/extensions/foo_test.dart`
- Each package has `test/unit_test.dart` as a stub entry point — real tests live in subdirectories
- **dart_faltool** is the only package with comprehensive tests; other packages have stubs only

#### Test Structure
- Use `group()` to organize by extension/class name, then by feature area
- Import from `package:<pkg>/lib.dart` in tests (same as source files)
- Use `package:test/test.dart` — NOT flutter_test (this is a pure Dart project)

#### Test Naming
- File: `<source_file>_test.dart`
- Top-level group: Class or extension name (e.g., `'FalconToolStringExtension'`)
- Sub-groups: Feature area (e.g., `'Whitespace and Formatting'`)
- Test descriptions: Imperative present tense (e.g., `'removes all whitespace'`)

#### When Writing New Code
- New extension files MUST have a corresponding test file
- New utility functions MUST have tests
- Run `dart test` in the specific package directory, not from monorepo root

### Code Quality & Style Rules

#### Linting
- Base: `very_good_analysis` with customizations per package
- `strict-casts: true`, `strict-inference: true` — zero tolerance for implicit dynamic
- `prefer_single_quotes: true` — always use single quotes
- `avoid_print: true` — use Logger package instead
- `avoid_relative_lib_imports: true` — use package imports only
- Relaxed: `public_member_api_docs`, `file_names`, `constant_identifier_names`

#### File & Folder Structure
- All files: `snake_case.dart`
- Extensions: one file per Dart type (e.g., `string_extensions.dart`, `list_extensions.dart`)
- Generated code: `lib/<path>/generated/<file>.{g|freezed}.dart`
- Barrel files at each module level aggregate exports

#### Naming Conventions
- Extensions: `Falcon{Tool}{Type}Extension` / `Falcon{Type}NullExtension`
- Exception classes: `Network{Name}Exception` for HTTP, `JsonRpc{Layer}Exception` for RPC
- Enums: PascalCase type, camelCase values (e.g., `NetworkErrorType.badRequest`)
- Private helpers: `_camelCase` prefix (e.g., `_coerceToInt`, `_throwFormatException`)

#### Formatting
- Run `dart format .` before committing
- Run `dart fix --apply` to auto-resolve lint issues
- Run `dart analyze` must produce zero warnings

### Development Workflow Rules

#### Git Conventions
- Branches: `main` (stable), `develop` (active development)
- Commit format: Conventional Commits — `type(scope): description`
- Types: `feat`, `fix`, `refactor`, `test`, `style`, `docs`, `chore`, `build`, `perf`, `ci`
- Scope: package name without `dart_` prefix (e.g., `faltool`, `falmodel`, `falconnect`)

#### Development Cycle
1. `melos get` — install all dependencies
2. Write code in the appropriate package
3. `dart run build_runner build -d` — if modifying annotated files
4. `dart analyze` — must pass with zero warnings
5. `dart format .` — format before committing
6. `dart test` — run in the specific package directory
7. Commit with conventional commit message

#### Dependency Management
- `melos get` / `melos upgrade` / `melos outdated` for workspace-wide operations
- `melos clean && flutter clean && melos bootstrap` when dependencies are corrupted
- `dart pub get` before `dart analyze` after large changes to clear stale analyzer state

### Critical Don't-Miss Rules

#### Anti-Patterns — NEVER Do These
- NEVER import `dart:io` — breaks web compatibility; use `universal_io` instead
- NEVER set `IOHttpClientAdapter` on Dio — breaks web; let auto factory resolve
- NEVER mix exception systems: NetworkException uses NetworkErrorType, NOT DefaultErrorType
- NEVER import individual files within a package — always use `lib.dart`
- NEVER add logic to `dart_falconx` umbrella package — it only re-exports
- NEVER forget to add exports to barrel files — causes misleading analyzer errors

#### Known Gotchas
- Missing barrel exports cause errors like "method can't be unconditionally invoked because receiver can be 'null'" — NOT a null safety issue, it's a missing export
- `NetworkNotImplementException` (501) — typo preserved for backward compatibility, do NOT rename
- Both `NetworkAuthenticationException` and `UnauthorizedException` exist for 401 — both intentional
- `RateLimiter` in dart_falconnect `utils/` is a placeholder (all code commented out) — do not use
- WebSocket var named `_replaySubject` is actually a `PublishSubject` — ignore the name
- `dart_falconnect` test file is a stub with empty test — no real tests exist

#### Barrel File Rules
- New exception files → add to `networks/exceptions/exceptions.dart`
- New interceptors → add to `interceptors/interceptors.dart`
- New extensions → add to `extensions/extensions.dart`
- ALL exports must be alphabetically sorted (enforced by `directives_ordering` lint)

#### Adding New HTTP Exceptions
1. Create class extending `BaseHttpException` in `code4XX/` or `code5XX/`
2. Set default `NetworkErrorType` via `super.type`
3. Add export to `networks/exceptions/exceptions.dart` (alphabetical)
4. If new status code: update `NetworkErrorType` enum — `statusCode` getter, `fromStatusCode` factory, `defaultMessage` getter

#### Web Compatibility Checklist
- No `dart:io` imports
- No `IOHttpClientAdapter`
- Dio httpClientAdapter left as auto factory
- Verify with `melos run verify:web` after changes to dart_falconnect

---

## Usage Guidelines

**For AI Agents:**
- Read this file before implementing any code
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Update this file if new patterns emerge

**For Humans:**
- Keep this file lean and focused on agent needs
- Update when technology stack changes
- Review quarterly for outdated rules
- Remove rules that become obvious over time

Last Updated: 2026-04-17
