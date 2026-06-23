# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

`dart_falconx` is the **umbrella package** of the monorepo. It contains no logic of its own — its sole job is to give external consumers a single import that pulls in `dart_falconnect`, `dart_falmodel`, and `dart_faltool` together. All real code lives in those three sibling packages.

## Public API

`lib/dart_falconx.dart` is three lines — re-exports of the three sibling packages. Consumers do `import 'package:dart_falconx/dart_falconx.dart';` and get everything; they should not depend on the siblings directly.

## Non-Obvious Patterns

- **No code generation in this package.** All `@freezed`, `@JsonSerializable`, and `@retrofit` annotated types live in the siblings. Do not run `build_runner` here — there is nothing to generate.
- **`test/unit_test.dart` is a stub.** Real tests live in the sibling packages (`dart_faltool` has the bulk; `dart_falconnect` has web tests under `test/web/`).
- **Add new exports with care.** Anything exported from a sibling automatically reaches consumers through this umbrella. There is no need to re-list individual symbols here — only add a new sibling package re-export when one is introduced.

## Commands

Build, test, lint, and code-generation commands are repo-wide; see the root `CLAUDE.md`. Nothing in this package needs a package-specific command.
