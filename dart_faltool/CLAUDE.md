# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

`dart_faltool` is a **core utility package** in the dart_falconx monorepo. It provides utility extensions and helper functions consumed by all other packages. It has a **circular dependency** with `dart_falmodel` (each depends on the other, resolved via Dart workspace resolution) and re-exports many third-party packages for convenience.

## Commands

```bash
# Run all tests
dart test

# Run a specific test file
dart test test/extensions/string_extensions_test.dart

# Run tests matching a name pattern
dart test -n "StringExtension"

# Analyze
dart analyze

# Format
dart format .
```

No code generation (`build_runner`) is needed in this package — it has no generated files.

## Architecture

### Two Entry Points

- **`lib/lib.dart`** — Internal entry point used within the monorepo. Re-exports `dart_falmodel`, `dart:async`, `dart:convert`, `ansicolor`, `intl`, `yaml`, and `dart_faltool.dart`. Extension source files import this.
- **`lib/dart_faltool.dart`** — Public entry point for external consumers. Re-exports ~15 third-party packages (fpdart, rxdart, freezed_annotation, equatable, logger, uuid, etc.) plus all extensions, type_def, and utils.

When writing extension code in this package, import `lib.dart`. Consumers of this package import `dart_faltool.dart`.

### Extensions (`lib/extensions/`)

Each extension file targets one Dart type (or nullable variant). The barrel file `extensions.dart` exports all of them. Every extension file has a corresponding test file in `test/extensions/`.

Extensions provide both non-null and nullable variants (e.g., `FalconToolStringExtension on String` and `FalconStringNullExtension on String?`).

Some extensions deliberately overlap with `dartx` — the `dartx` package is re-exported but certain members are hidden in `dart_faltool.dart` to avoid conflicts (see the `hide` clause on the `dartx` export).

### Utils (`lib/utils/`)

- **`app_info.dart`** — `AppInfo`: Static class that reads app version from `pubspec.yaml`. Call `AppInfo.init()` at startup, then access `AppInfo.version`.
- **`functions.dart`** — `runCatching`, `runDomainCatching`, `runDataCatching`: Execute async operations and catch exceptions into `Result<T>` failures. Each wraps exceptions into the appropriate layer exception (`CommonException`, `DomainLayerException`, `DataLayerException`).
- **`uuid_generator.dart`** — `UuidGenerator.getV4()`: Static UUID v4 generation.

### Type Definitions (`lib/type_def.dart`)

Contains shared typedefs like `VoidErrorCallback`.

## Gotchas

- When adding a new extension file, add its export to `lib/extensions/extensions.dart` and create a matching test file in `test/extensions/`.
- The `dartx` re-export hides specific members (`IterableAll`, `IterableAppend`, `MapOrEmpty`, etc.) — if you add an extension that conflicts with `dartx`, add a `hide` entry in `lib/dart_faltool.dart`.
- Linting uses `very_good_analysis` with `strict-casts` and `strict-inference` enabled — no implicit casts or dynamic inference allowed.
- `test/unit_test.dart` is a placeholder stub — real tests live in `test/extensions/`.
