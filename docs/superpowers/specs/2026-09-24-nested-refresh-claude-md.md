# Nested CLAUDE.md refresh — spec

kind: claude-md
mode: edit (one dispatch per target)
layout: CLAUDE.md only per package (no AGENTS.md)
load: on-demand (each file loads when a file under its package is read, on top of the root file)
budget: 800 per file
targets:

| target                    | words_before | expected after |
|---------------------------|--------------|----------------|
| dart_falconnect/CLAUDE.md | 1069         | ≤ 780          |
| dart_falmodel/CLAUDE.md   | 627          | ~450           |
| dart_faltool/CLAUDE.md    | 511          | ~400           |
| dart_falconx/CLAUDE.md    | 207          | ~120           |

net: every target ends at or under its words_before; dart_falconnect ends at or under 800.

## Intent

Owner request: refresh the four nested files after the root `CLAUDE.md` refresh
(`docs/superpowers/specs/2026-09-24-root-refresh-claude-md.md`). Policy chosen by the owner: **package-only**. A nested
file keeps only facts about its own package and deletes anything the root file already states, because a nested file
always loads on top of the root file.

## bundle:

Always-on files loaded with every target (counted, never edited):

- ./CLAUDE.md — 872 (refreshed root; the duplication baseline for this spec)
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

Bundle total: 5,709 words.

## Root facts every target must not repeat

The root `CLAUDE.md` already states: melos commands and the `melos clean` + `melos bootstrap` reset; running one test
file; the Platform support section (pure Dart, the `dart:io` conditional-import rule, and the js/wasm/exe/chrome gates);
the network-engine summary; the exception-system table, `CommonException` fields (no `category`), `NetworkException`
carries `NetworkErrorType`, the 501 typo and the two 401 classes, the `Result<T>` factories; the generated-file path and
"run `melos run build_runner` after editing annotated classes"; the barrel-export gotcha with its misleading analyzer
error; `dart pub get` before `dart analyze`; the 32-bit web `int` gotcha; the skill-maintenance rule; strict-casts and
strict-inference off locally with the unused `analysis_options.ci.yaml`; `build.yaml` checked mode; the
`dart_faltool` ↔ `dart_falmodel` cycle; "`dart_falconx` holds only the stub `test/unit_test.dart`".

## Shared edits (all four targets)

- Title `# dart_<package>` in place of `# CLAUDE.md`.
- Delete the "This file provides guidance to Claude Code…" line.
- Delete the commands block; the root owns every command.
- Delete every line the root already states (list above).
- Replace `MUST`, `**Critical**`, `do not`/`NOT` intensifiers, and bold-label warnings with plain imperatives.
- Sentence-case headings.
- Delete any line a lint already enforces (for example "alphabetically sorted (directives_ordering)").

## dart_falconnect/CLAUDE.md

Verified facts:

- `lib.dart` exports `dart:async`, `dart:convert`, `ansicolor`, `dart_falmodel`, `dart_faltool`, `freezed_annotation`,
  and `dart_falconnect.dart`.
- `RequestApiService` exists (`engine/https/request_api_service.dart`). Config boxes `LogConfig`, `PerformanceConfig`,
  `CacheConfig`, `ConcurrencyConfig`, `RateLimitConfig`, `RetryConfig` exist under `engine/https/config/`;
  `HttpClientConfig.rateLimit` defaults to `RateLimitConfig.none()` (re-verify the "null box turns its feature off" claim
  per box before keeping it).
- `mapJson`, `catchWhenError`, `unwrapResponse`, `transformData` live in `engine/https/extensions/response_extensions.dart`.
- `SocketBoundResource`, `SocketException`, `SocketRetryException`, `SocketInterceptor`, `SocketLogInterceptor` exist.
  `SocketOperationNotFoundException` does not exist.
- `JsonRpcService` has `request`, `notify`, `notifySync`, `batch`.
- `engine/datasource_bound_state.dart` has `asLocalResultStream`, `asLocalResultFuture`, `asRemoteResultStream`,
  `asRemoteResultFuture`, `asResultStream`, `shouldFetch`.
- `interceptors/interceptors.dart` exports nine interceptor files plus `local_rate_limit.dart` (an extension on
  `Response<dynamic>`).
- `lib/src/engine/https/interceptors/retry_after_pause.dart`, `lib/src/engine/https/interceptors/host_key.dart`, and
  `lib/src/engine/https/cancel_watch.dart` exist.
- `RetryInterceptor._backoff`, `_replaySubject` + `PublishSubject`, `err.toException()`, and
  `RequestMetrics.dnsLookupTime` exist. No file under `lib/` imports `package:dio/io.dart` or uses `IOHttpClientAdapter`.
- No `@RestApi` (Retrofit client) exists under any `lib/`.
- Test files: 15 under `test/engine/` (7 in `test/engine/https/interceptors/`), 1 in `test/web/`, plus the stub.

cut / fix:

- cut: Development Commands block (−55)
- cut: boilerplate line (−15)
- cut: Key Patterns "No `dart:io` dependency" bullet; root Platform support covers it (−40)
- cut: Web Support gate block (the two commands); keep the three web caveats (PerformanceInterceptor timing nulls, SocketClient compile-only coverage, Dio auto adapter) under a `## Web caveats` heading (−55)
- cut: Gotchas 32-bit `int` bullet; root states it (−55)
- cut: Gotchas generated-files bullet; root states it (−12)
- cut: "(alphabetically sorted per lint rules)" (−5)
- cut: compress the nine-interceptor list to one line per interceptor naming its role; keep the order line and the three `lib/src/` pointers (−60)
- fix: delete `SocketOperationNotFoundException` from the socket exception list
- fix: `Result<DataType>` wording — drop "success/failure union"
- fix: test-location wording — interceptor tests under `test/engine/https/interceptors/`, other engine tests under `test/engine/`, web gate under `test/web/`; drop "real tests live under test/web/"
- fix: drop `@retrofit` from any codegen trigger list

keep: entry points, the three engines, datasource bound state, interceptor order, gotchas for `TokenBucketRateLimitInterceptor.dispose()`, `watchCancel`, `PublishSubject`, `toException()`, the converter-required API, `BaseRequestBody`, error propagation.

## dart_falmodel/CLAUDE.md

Verified facts:

- `lib.dart` exports `dart:async`, `dart:convert`, `dart_faltool`, `dio`, `freezed_annotation`, `json_annotation`,
  `dart_falmodel.dart`. `dart_falmodel.dart` exports exceptions, extensions, feedbacks, models, networks.
- `CommonException` has no `category` field; `toJsonRpcError()` resolves a category (`common_exception.dart` near line
  331). `DefaultErrorType` is a `sealed class` implemented by nine enums.
- `TodoException`, `DataLayerException`, `DomainLayerException`, `BaseHttpException` exist.
- `JsonRpcErrorCategory` values: `API_ERROR`, `EXTERNAL_API_ERROR`, `INVALID_REQUEST_ERROR`, `UNKNOWN`.
- `ErrorType`, `RemoteExternalApiErrorType`, and `RawJsonRpcResult` do not exist.
- `JsonRpcResult` exists (`networks/rpc/json_rpc_result.dart`). `JsonRpcResponse` and `JsonRpcErrorResponse` live in
  `networks/rpc/json_rpc_response.dart`. `JsonRpcError` factories: `invalidRequest`, `external`, `methodNotImplement`,
  `invalidParams`, `internal`.
- `Result<T>` methods: `map`, `resolve`, `when`, `flatMap`, `recover`.
- `UserFeedback` factories `success`, `warning`, `failure`, `information`, each with a `FeedbackLevel` (default
  `medium`); custom `match` exists. `FeedbackLevel` is declared in `exceptions/common_exception.dart`.
- Generated outputs with a live source: `feedbacks/feedback.dart`, `networks/https/responses/remote_error.dart`,
  `networks/rpc/json_rpc_error.dart`, `networks/rpc/json_rpc_request.dart`, `networks/rpc/json_rpc_response.dart`.
  `networks/rpc/exceptions/generated/json_rpc_error.*` has no source (orphan; out of scope).
- Test files: 5 real tests under `test/exceptions/`, `test/extensions/`, `test/networks/`, plus the stub.

cut / fix:

- cut: Common Commands block, boilerplate line (−45)
- cut: Gotchas — 501 typo, 401 duplicates, misleading barrel-export error, strict-casts line; root states them (−70)
- cut: "**Critical**: These three systems must not be mixed…" paragraph; the root table and `NetworkException` line cover it (−35)
- cut: "alphabetically sorted (enforced by `directives_ordering` lint)" from Adding New Network Exceptions (−8)
- cut: Code Generation heading's "Generated files go to …" sentence; root states the path (−10)
- fix: `CommonException` — no `category` field; `toJsonRpcError()` resolves the category from `type`
- fix: `DefaultErrorType` — sealed class implemented by nine enums, not an enum
- fix: delete `RemoteExternalApiErrorType` and `RawJsonRpcResult`
- fix: `MUST be added here` → imperative
- fix: codegen file list — the five live sources above

keep: entry points (`lib.dart` internal vs `dart_falmodel.dart` public), per-system detail (subclasses, `BaseHttpException`, `code4XX/`/`code5XX/`, RPC enums), the four-step "adding a network exception" recipe, `Result` methods, JSON-RPC models, `UserFeedback`, the `lib.dart`-is-not-public gotcha.

Owner ruling: the four-step recipe stays whole even though steps 2 (`super.type` default) and 3 (barrel export) repeat root lines. A procedure with missing middle steps is easy to misapply; this is the one accepted exception to the package-only policy.

## dart_faltool/CLAUDE.md

Verified facts:

- `lib.dart` exports `dart:async`, `dart:convert`, `ansicolor`, `dart_falmodel`, `yaml`, `dart_faltool.dart`. It does not
  export `intl`.
- `dart_faltool.dart` has 24 `export 'package:…'` lines.
- `lib/utils/` holds `app_info.dart` (+ `_app_info_io.dart`, `_app_info_web.dart`), `functions.dart`,
  `json_serialize.dart`, `token_bucket_policy.dart`, `typeid/`, `uuid_generator.dart`, `utils.dart`.
  `token_bucket_policy.dart` is a `@freezed` source (`TokenBucketPolicy`).
- `runCatching`, `nowUtc`, `constantTimeEquals`, `randomDelay`, `UuidGenerator.getV4`, `VoidErrorCallback`, `TypeId`
  (`decode`, `decodeOrNull`, `isValid`), `DecodedTypeId`, `Base32` exist.
- Extension files without a test: `base64_extensions`, `datetime_validator_extension`, `int_validator_extensions`,
  `string_validator_extensions`. Tests live in `test/extensions/` (12) and `test/utils/` (4).

cut / fix / add:

- cut: both commands blocks, boilerplate line (−60)
- cut: Package Overview circular-dependency sentence; root states it (−25)
- cut: Gotchas strict-casts line and `test/unit_test.dart` stub line (−35)
- fix: `lib/lib.dart` export list — drop `intl`
- fix: drop the "~15" count; say "re-exports third-party packages" or give the verified count
- fix: "Every extension file has a corresponding test file" is false; keep the rule as an imperative ("add a matching test file in `test/extensions/`") and state no coverage claim
- add: Utils bullet for `token_bucket_policy.dart` — `TokenBucketPolicy`, a freezed policy consumed by `dart_falconnect`'s token-bucket rate limiter (verify the consumer before writing) (+20)
- add: note that `app_info.dart` picks `_app_info_io.dart` or `_app_info_web.dart` by conditional import, only if budget allows and the root does not already cover it (+15)

keep: two entry points and which one to import, extension naming (non-null + nullable variants), the `dartx` hide rule, utils list, TypeID detail, `type_def.dart`.

## dart_falconx/CLAUDE.md

Verified facts:

- `lib/dart_falconx.dart` is three `export` lines for the sibling packages.
- No `@RestApi` or other Retrofit client exists in any package.
- `dart_falconnect` holds 15 engine tests plus one web test; `dart_faltool` holds 16; `dart_falmodel` holds 5.

cut / fix:

- cut: boilerplate line (−15)
- cut: "`test/unit_test.dart` is a stub" bullet; root states it (−30)
- cut: Commands section pointing to root; the root always loads (−30)
- fix: drop `@retrofit` from the codegen bullet

keep: umbrella purpose, "consumers import `dart_falconx.dart`, not the siblings", no code generation here, add a re-export only when a new sibling package appears.

## Out of scope

- Four extension files without tests (code gap).
- Orphan `dart_falmodel/lib/networks/rpc/exceptions/generated/json_rpc_error.*`.
- `analysis_options.ci.yaml` fate; a melos script for the platform gates.
- Editing the root `CLAUDE.md`, rule files, the consumer skill, or memory.
- Git commits.
