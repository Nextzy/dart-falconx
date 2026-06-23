---
argument-hint: "[ optional: path to a specific CLAUDE.md, a package dir, or leave empty for whole repo ]"
description: "Audit, refresh, and scaffold CLAUDE.md files across the repo: update stale content, delete obsolete sections, and generate missing CLAUDE.md for sub-packages"
disable-model-invocation: true
---

# Update CLAUDE.md

Target: **$ARGUMENTS** (empty = entire repo).

This command is project-agnostic. Do NOT assume a specific stack, monorepo layout, or directory naming. Discover packages by their manifest files, not by hardcoded paths.

## Phase 0: Ground rules

- **`claude-md-management:claude-md-improver` is mandatory.** It is the **sole engine for every CLAUDE.md write in this command**, whether the write is an update, a deletion, or a brand-new file. Do not hand-roll a rubric, template, or diff format outside of it. If the skill does not cover a situation, ask the user rather than improvising.
- **Question cadence:** ask one question at a time when ambiguity arises. Never bundle.
- **No writes before approval:** every edit / create / delete must be in the Phase 4 plan and explicitly approved.
- **Project-agnostic reasoning:** if you catch yourself typing a path, repo name, or convention that only exists in *this* repo, stop and generalize. The command must be portable.
- **Evidence over recall:** verify every file path, command, and package reference against the live tree before trusting it. CLAUDE.md decays; assume every bullet may be stale until checked.
- **Size budget (~200 lines):** CLAUDE.md is loaded into every Claude conversation; every line costs context quota. Target ≤200 lines per file. When a section is bulky or rarely referenced, extract it to `.claude/rules/<topic>.md` (or a sibling `<topic>.md` colocated with the package) and reference it from CLAUDE.md.
  - **Link by plain path, not `@`:** e.g. `See .claude/rules/naming.md for naming rules.` Using `@.claude/rules/naming.md` force-loads the file into every session and defeats the extraction.
  - **Reserve `@` for content that truly must always be present** (existing `@shares/CLAUDE.md` style cross-links between CLAUDE.md files in a monorepo are fine; do not promote extracted rule files to `@`).
  - **What to extract:** long naming conventions, lint/format rules, layered-architecture deep dives, enumerated error catalogs, onboarding recipes. **What to keep inline:** purpose, top-level architecture, commands that differ from the root, non-obvious invariants.

## Phase 1: Discovery

Run **two** discovery passes in parallel:

### 1a. Existing CLAUDE.md files

```bash
find . -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .dart_tool -o -name target -o -name .venv \) -prune -o \
  -type f \( -name CLAUDE.md -o -name .claude.md -o -name .claude.local.md \) -print
```

### 1b. Package roots (candidates that *could* host a CLAUDE.md)

A directory is a package root if it contains ONE of:

| Manifest | Ecosystem |
|----------|-----------|
| `pubspec.yaml` | Dart / Flutter |
| `package.json` | Node / JS / TS |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pyproject.toml` / `setup.py` | Python |
| `composer.json` | PHP |
| `Gemfile` | Ruby |
| `mix.exs` | Elixir |
| `build.gradle` / `build.gradle.kts` / `pom.xml` | JVM |

Add more only if the current repo uses them. Skip vendored / generated dirs (`node_modules`, `.dart_tool`, `target`, `dist`, `build`, `.venv`, etc.).

### 1c. Gap set

`missing_claude_md = package_roots - package_roots_that_already_have_CLAUDE.md`

The root of the repo also counts as a package root even if it lacks a manifest.

Record the three sets: `existing`, `missing`, `orphaned` (CLAUDE.md that sits in a directory that is no longer a package root, a candidate for deletion).

## Phase 2: Audit existing CLAUDE.md

**REQUIRED SKILL:** invoke `claude-md-management:claude-md-improver` and follow its Phase 1–3 flow (Discovery, Quality Assessment, Quality Report) for every file in the `existing` set. This skill is the **sole engine** for both audit and update. Never hand-roll a rubric or diff format outside of it.

Extend the skill's rubric with these extra checks (tight focus on staleness):

- **Dead references:** every path, filename, command, env var, package name mentioned in CLAUDE.md must still exist. Grep / stat each one.
- **Superseded patterns:** patterns the CLAUDE.md advocates that the current code no longer follows. Cross-check with actual code samples.
- **Duplication:** blocks repeated in both root and sub-package CLAUDE.md where the sub-package one is strictly more specific. The redundant copy should be removed from the less specific file.
- **Framework / version drift:** named versions or tool flags that do not match the manifest (e.g. SDK version in CLAUDE.md ≠ version in the package manifest).
- **Oversize (>200 lines):** flag the file as a refactor candidate. Identify the bulkiest sections (long rule lists, exhaustive tables, copy-pasted error catalogs) and propose extracting them to `.claude/rules/<topic>.md` with a plain-path back-reference left in CLAUDE.md. Prefer extraction over aggressive deletion when the content is still accurate and useful; you are relocating it, not discarding it.

For each file, produce:

1. Skill's quality score (A–F with criterion breakdown).
2. **DELETE list:** explicit block(s) to remove with line ranges or quoted snippet plus reason.
3. **UPDATE list:** targeted additions or rewrites, as diffs.

## Phase 3: Scaffold missing CLAUDE.md

**REQUIRED SKILL:** `claude-md-management:claude-md-improver` is the **sole engine for both update AND create**. Every new file must be authored through it. Do not hand-roll structure, section ordering, or template choice outside of what the skill prescribes.

For each directory in the `missing` set:

1. **Feed the skill the package context first:** manifest file, primary entry point(s), and any README in that directory. The skill's quality rubric (actionability, architecture clarity, non-obvious patterns, conciseness, currency) is what you are writing *to*, not an afterthought. Pick the template variant from the skill's `references/templates.md` that best matches the package type.
2. **Minimal, evidence-backed content only.** Target ≤200 lines. If there is nothing non-obvious to say, write a very short file. A 10-line CLAUDE.md that scores well on the skill's rubric beats a 100-line padded one that scores poorly. If a package genuinely needs more, split reference-weight content to `.claude/rules/<topic>.md` and leave a plain-path link in CLAUDE.md. Never inflate the main file to hit a template.
3. **Draw content from the code**, not imagination. Every claim in the new file must be traceable to a line in the package.
4. **Sections to consider** (include only those with real content, in the order the skill's rubric prioritizes):
   - One-paragraph purpose of the package
   - Public API / main exports / entry points
   - Package-specific commands that differ from repo-wide commands
   - Non-obvious patterns, gotchas, or invariants inferred from the code
   - Dependencies on sibling packages, if cross-package coupling exists
5. **Never restate what the root CLAUDE.md already covers.** If the repo already documents build / test / lint at the root level, the sub-package file should not repeat it unless it genuinely differs.
6. **No project-specific scaffolding boilerplate.** Do not ship the same template across packages. Each file must reflect *that* package. The skill helps here: it evaluates conciseness and non-obvious patterns, which naturally punishes copy-pasted filler.
7. **Score the draft against the skill's rubric before proposing it.** If the draft would score below B (70), either find genuine content to raise it or accept that the file should be very short rather than inflate it.

## Phase 4: Present the consolidated plan

Output a single plan covering all three actions. Do not edit any file yet.

```
## Update CLAUDE.md Plan

### Files to UPDATE (N)
- path — quality grade X → Y — summary of change
  - DELETE: <snippet or reason>
  - ADD:    <snippet or diff>

### Files to CREATE (N)
- path — scaffold outline (sections it will contain)

### Files to DELETE (N, if any orphans)
- path — reason it is no longer applicable

### Rules to EXTRACT (N, if any CLAUDE.md exceeds budget)
- `<claude.md path>` §<section> → `.claude/rules/<topic>.md` — reason (size / rarely-referenced / deep-reference)
  - Replacement line left in CLAUDE.md: `See \`.claude/rules/<topic>.md\` for <topic>.`
  - Estimated line savings: Nnn

### Questions
- <only if something is ambiguous; one question at a time, one bullet each>
```

Wait for the user's approval / answers before any filesystem mutation.

## Phase 5: Apply

After approval:

- Use `Edit` for updates (preserve existing structure, match the file's own formatting voice).
- Use `Write` only for new CLAUDE.md files and for new `.claude/rules/<topic>.md` files.
- Apply deletions surgically. Remove only the blocks listed in the plan; do not rewrite whole files.
- For rule extractions: create `.claude/rules/<topic>.md` first, then `Edit` CLAUDE.md to replace the extracted block with the plain-path link. Verify the link is plain (no leading `@`).
- Commit boundary: leave the working tree clean of unrelated edits. Do NOT auto-commit.

## Phase 6: Verify

1. Re-run Phase 1 discovery. Confirm `missing` set is now empty (or the user explicitly accepted the remainder).
2. Re-score the updated files and report grade deltas (before → after).
3. Spot-check one updated file and one newly created file by reading it top-to-bottom and confirming every claim in it matches the code.
4. **Size check:** `wc -l` every touched CLAUDE.md. Flag any that still exceed ~200 lines and confirm with the user whether to defer or do a second extraction pass.
5. **Link hygiene:** grep every touched CLAUDE.md for `@.claude/rules/` (should be zero; those must be plain paths). The earlier `@shares/...` / `@bricks/...` style cross-CLAUDE.md links are left intact.
6. Summarize at the end:
   - Files updated / created / deleted
   - Grade deltas
   - Anything deferred (e.g. a stale reference that turned out to be an in-progress refactor; flag it, do not delete it)
   - Any generalization improvements to *this command* worth capturing for next run (drift from "project-agnostic")
