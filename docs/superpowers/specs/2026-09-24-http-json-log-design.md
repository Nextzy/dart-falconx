# Server-mode JSON HTTP log

**Date:** 2026-09-24
**Packages:** `dart_falconnect`
**Version:** 2.1.0. The owner accepted one small, documented break for this minor release (section 11).
**Builds on:** the client-config core (`2026-09-24-default-http-client-config-design.md`), which defines `HttpClientConfig`, the `log` box, and the chain order.

## 1. Context

`HttpLogInterceptor` was written for a developer watching a phone's console. On a server it fails in these ways:

1. It prints many lines per request: about 30 for a small `GET` with two headers, and about 500 for a response holding a 50-item list, because every request option, header, and pretty-printed JSON field gets its own line. A log aggregator bills and stores each stdout line as one entry.
2. Lines of concurrent requests interleave, and nothing ties a line to its request.
3. ANSI colour codes are on, and the constructor writes `ansiColorDisabled`, a process-wide global of the `ansicolor` package.
4. `Authorization`, `Cookie`, and every other header are printed as is.
5. The status code is printed only when `responseHeader` is on, which it is not by default, and no duration is printed.
6. `_logPrintLong` cuts lines at 1,020 characters, a fix for Android's logcat that breaks JSON in the middle on a server.

A second gap affects every response interceptor. `CacheInterceptor` answers a hit with `handler.resolve(cachedEntry.response)`. Without `callFollowingResponseInterceptor`, dio 5.11.1 skips every response interceptor for that request (`dio_mixin.dart`, lines 460 to 486), including the ones placed before the cache. The log shows a request with no response, and `PerformanceInterceptor` never records the hit. The cached `Response` also still carries the `RequestOptions` of the first request, so anything that reads `response.requestOptions` gets the wrong request.

## 2. Goals and non-goals

**Goals**

- A server can log each HTTP attempt as one JSON line on stdout, readable by any log aggregator without a vendor-specific schema.
- The field names follow the OpenTelemetry semantic conventions for HTTP clients, so an OpenTelemetry Collector, the Datadog agent, or Cloud Logging can ingest the lines with little or no mapping.
- The JSON log is turned on and off at run time through `configure`, like any other box.
- Sensitive headers and query values never reach the log unless the app removes them from the redaction lists.
- A cache hit passes through the response interceptors, bound to the request that asked for it.
- The pretty log keeps its current output for apps, fixed in the points above that are wrong in every environment.

**Non-goals**

- An OpenTelemetry SDK dependency, spans, metrics, or an OTLP exporter. A separate `dart_falconnect_otel` package was considered and is not scheduled.
- A request id or trace context (`traceparent`). The header and request ID spec of the `dart-falconx-client-extensions` phase owns them.
- Vendor-specific fields such as Cloud Logging's `severity` and `httpRequest`.
- Sampling, rate-limiting the log itself, or writing to files.

## 3. `LogConfig`

`LogConfig` becomes a sealed freezed union, following `RateLimitConfig`. The unnamed factory stays the pretty variant, so `LogConfig()` and `LogConfig(request: false)` keep compiling.

```dart
@freezed
sealed class LogConfig with _$LogConfig {
  /// Multi-line console log; builds `HttpLogInterceptor`.
  const factory LogConfig({
    @Default(true) bool request,
    @Default(true) bool requestHeader,
    @Default(true) bool requestBody,
    @Default(false) bool responseHeader,
    @Default(true) bool responseBody,
    @Default(true) bool error,
    @Default(defaultRedactedHeaders) Set<String> redactHeaders,
    @Default(defaultRedactedQueryParameters) Set<String> redactQueryParameters,
    void Function(Object? object)? logPrint,
    @Default(true) bool diagnostics,
  }) = PrettyLogConfig;

  /// One JSON line per attempt; builds `HttpJsonLogInterceptor`.
  const factory LogConfig.json({
    @Default(false) bool requestHeaders,
    @Default(false) bool responseHeaders,
    @Default(false) bool requestBody,
    @Default(false) bool responseBody,
    @Default(4096) int maxBodyBytes,
    @Default(defaultRedactedHeaders) Set<String> redactHeaders,
    @Default(defaultRedactedQueryParameters) Set<String> redactQueryParameters,
    void Function(Object? object)? logPrint,
    @Default(true) bool diagnostics,
  }) = JsonLogConfig;
}
```

- `redactHeaders`, `redactQueryParameters`, `logPrint`, and `diagnostics` exist in both variants, so code can read them through the `LogConfig` type.
- Names in both sets compare case-insensitively.
- `defaultRedactedHeaders` is `{'authorization', 'cookie', 'proxy-authorization', 'set-cookie', 'x-api-key'}`.
- `defaultRedactedQueryParameters` is `{'access_token', 'api_key', 'apikey', 'awsaccesskeyid', 'key', 'password', 'secret', 'sig', 'signature', 'token', 'x-amz-signature', 'x-goog-signature'}`. It includes the defaults of the OpenTelemetry `url.full` guidance (`AWSAccessKeyId`, `Signature`, `sig`, `X-Goog-Signature`).
- Both constants are public and exported from `log_config.dart`, so an app can extend them: `redactHeaders: {...defaultRedactedHeaders, 'x-tenant-secret'}`.
- A `logPrint` of null prints to stdout with `print`.

## 4. `HttpJsonLogInterceptor`

```dart
class HttpJsonLogInterceptor extends Interceptor {
  new({this.config = const JsonLogConfig()});

  final JsonLogConfig config;
}
```

- `onRequest` stamps the attempt's start time, `clock.now()` from `dart_faltool`, into `options.extra` under `dart_falconnect.log.start`, then calls `handler.next`.
- `onResponse` and `onError` each print one line, then call `handler.next`. The interceptor never resolves or rejects, so it keeps the slot-safety rule of the chain.
- It keeps no state between requests, so `configure` may rebuild it freely.
- At chain position 2 it sits before `RetryInterceptor`, so every attempt passes it once: a request retried twice prints three lines. Its `onRequest` runs before the limiters, so the duration includes the time spent in their queues, which is the time the caller waited.
- It works on a bare `Dio` as well as inside a `BaseHttpClient`.
- It imports no `dart:io` and compiles to the web.

## 5. The line

The interceptor prints `jsonEncode(fields)`: one line, no indentation, keys in the order below. Example, wrapped here for reading:

```json
{"timestamp":"2026-09-24T07:12:03.184Z","severity_text":"WARN",
 "body":"GET https://api.example.com/users/7?token=REDACTED 404 0.184s",
 "http.request.method":"GET","url.full":"https://api.example.com/users/7?token=REDACTED",
 "server.address":"api.example.com","server.port":443,
 "http.response.status_code":404,"error.type":"404",
 "http.client.request.duration":0.184}
```

**Core fields**

| Field | Value | Present |
|---|---|---|
| `timestamp` | Completion time of the attempt, `clock.now().toUtc().toIso8601String()` | always |
| `severity_text` | Section 5.1 | always |
| `body` | `"<method> <url.full> <status or error.type> <seconds>s"`, plus `" (cache)"` on a cache hit | always |
| `http.request.method` | `options.method`, upper case | always |
| `url.full` | `options.uri` after redaction (section 5.2) | always |
| `server.address` | `options.uri.host` | always |
| `server.port` | `options.uri.port` | always |
| `http.response.status_code` | `response.statusCode` | when a response exists |
| `error.type` | Section 5.1 | on error |
| `http.client.request.duration` | Seconds since the attempt's start, `inMicroseconds / 1e6` | always |
| `http.request.resend_count` | `options.retryAttempt` | when it is above 0 |
| `falconx.cache.hit` | `true` | on a cache hit |
| `falconx.rate_limit.local` | `true` | on a 429 built by a limiter (`isLocalRateLimit`) |

`body` and `severity_text` are the names of the OpenTelemetry log data model. The `falconx.` prefix marks attributes the semantic conventions do not define.

### 5.1 Severity and `error.type`

| Outcome | `severity_text` | `error.type` |
|---|---|---|
| Response, status below 400 | `INFO` | absent |
| Status 400 to 499, whether from `onResponse` or a `badResponse` error | `WARN` | the status as a string, such as `"404"` |
| Status 500 and above | `ERROR` | the status as a string |
| `DioExceptionType.cancel` | `INFO` | `"cancel"` |
| Any other error without a response | `ERROR` | the `DioExceptionType` name, such as `"connectionTimeout"` |

A status of 400 or above reaches `onResponse` only through a custom `validateStatus`. It gets the same severity and `error.type` as it would in `onError`: a 4xx that `validateStatus` accepts still gets `WARN`.

### 5.2 URL redaction

- User info in the URL (`https://user:pass@host`) becomes `REDACTED:REDACTED@host`.
- The value of every query parameter whose name is in `redactQueryParameters` becomes `REDACTED`. Names are compared case-insensitively. Other parameters and their order are kept.
- The same redacted URL appears in `url.full` and in `body`.

### 5.3 Opt-in headers and bodies

- With `requestHeaders`, each request header appears as `http.request.header.<name>`. With `responseHeaders`, each response header appears as `http.response.header.<name>`. The name is lower case, and the value is a list of strings, as the semantic conventions require. A header named in `redactHeaders` gets the value `["REDACTED"]`.
- With `requestBody`, `options.data` appears as `falconx.request.body`. With `responseBody`, `response.data` appears as `falconx.response.body`.
- A body is converted to a string first: a `Map` or `List` through `jsonEncode`, a `String` as is, `FormData` as its field names and file names like the pretty log, and anything else, including a value `jsonEncode` rejects, through `toString()`.
- A body longer than `maxBodyBytes` UTF-8 bytes is cut at the last whole character within the limit, and `falconx.request.body.truncated` or `falconx.response.body.truncated` is set to `true`.
- A body of `ResponseType.stream` is logged as `"<stream>"`, because reading it would consume it.

## 6. Diagnostics in JSON mode

`BaseHttpClient._diagnostic` wraps each diagnostic message as a JSON line when `log` is a `JsonLogConfig` and `diagnostics` is on:

```json
{"timestamp":"2026-09-24T07:12:03.184Z","severity_text":"DEBUG","body":"[TokenBucketRateLimitInterceptor] Paused a.test for 5000ms"}
```

With a `PrettyLogConfig`, diagnostics stay plain text. An interceptor built by hand with its own `logPrint` gets plain text in both cases.

## 7. `HttpLogInterceptor` fixes

- The constructor no longer writes `ansiColorDisabled`. Each instance applies its colour pens only when it is enabled. Colour stays on by default.
- The constructor gains `redactHeaders` and `redactQueryParameters`, defaulting to the public constants. The URL and request headers are printed redacted, with the rules of section 5.2 and section 5.3.
- `statusCode` and the duration are printed for every response and every error, whatever `responseHeader` says. The start time uses the same `extra` key as the JSON log.
- The class doc stops telling the reader to add the interceptor at the tail; it states that `BaseHttpClient` places it at position 2.
- `_logPrintLong` and its 1,020-character chunks stay, for Android's logcat.

## 8. `CacheInterceptor` changes

- On a hit, `onRequest` builds a new `Response` from the cached entry: the cached `data`, `headers`, `statusCode`, and `statusMessage`, the current request's `options`, and `extra` with the cache-hit marker added. It resolves with `handler.resolve(hit, true)`, so every response interceptor runs.
- `onResponse` does not store a response that carries the cache-hit marker. Without this guard, each hit would store the entry again and renew its lifetime, and an entry that is read often would never expire.
- A public getter `Response.isCacheHit` in `FalconCacheHitResponseExtensions`, next to `isLocalRateLimit`, reads the marker from `response.extra`.

## 9. `BaseHttpClient` changes

- `_buildLog` switches on the variant: `PrettyLogConfig` builds `HttpLogInterceptor` with its flags, redaction sets, and printer; `JsonLogConfig` builds `HttpJsonLogInterceptor`.
- Box equality still decides reuse. Switching between the two variants rebuilds only the log interceptor, and the limiters keep their state.
- The log keeps position 2 of the chain.

## 10. Interceptors that now see cache hits

With `callFollowingResponseInterceptor`, every interceptor's `onResponse` runs for a hit, including the ones after the cache that never saw its `onRequest`.

| Interceptor | Effect of a hit |
|---|---|
| Custom interceptors, `HttpLogInterceptor`, `HttpJsonLogInterceptor` | Their `onResponse` now pairs with the `onRequest` they already saw |
| `PerformanceInterceptor` | Records the hit. Before this change the stale `requestOptions` pointed at the first request's metrics object |
| `ConcurrencyLimitInterceptor` | No permit in `extra`, so `_permitOf(...)?.release()` does nothing |
| `TokenBucketRateLimitInterceptor`, `RetryAfterPauseInterceptor` | A cached response is 2xx, so no pause starts. Tests must confirm that no counter moves |
| `RetryInterceptor`, the exception handler | Pass the response on |

## 11. Migration to 2.1.0

| # | Change | Action |
|---|---|---|
| 1 | `LogConfig` is a sealed union. The pretty-only fields (`request`, `requestHeader`, `responseHeader`, `error`) are not on the `LogConfig` type, nor in its `copyWith`; `requestBody` and `responseBody` exist in both variants, so they stay on it | Match or cast to `PrettyLogConfig` before reading or copying them. This is the one source break of the release |
| 2 | A cache hit reaches every response interceptor, and its `requestOptions` are the current request's | Custom interceptors that count responses now count hits; use `response.isCacheHit` to tell them apart |
| 3 | The pretty log redacts sensitive headers and query values | Pass `redactHeaders: const {}` to see them in development |
| 4 | The pretty log no longer changes the global `ansiColorDisabled` | Set it yourself if other code relied on the side effect |
| 5 | The pretty log prints status and duration for every response | Nothing |

## 12. Testing plan

TDD. Tests use a real `Dio` with the scripted adapter. Timing tests run under `fakeAsync` and advance with `async.elapse(Duration.zero)`.

**`test/engine/https/interceptors/http_json_log_interceptor_test.dart` (new)**

- One line per attempt, and each line decodes with `jsonDecode`.
- A request retried twice prints three lines, with `http.request.resend_count` 1 and 2 on the retries.
- The rows of section 5.1: 200, 404, 500, a connection error, and a cancel.
- The duration matches the time elapsed under `fakeAsync`.
- URL redaction of user info and of a listed query parameter; an unlisted parameter is kept.
- Opted-in headers appear lower case as lists, and a listed header reads `["REDACTED"]` whatever its case.
- A long body is cut within `maxBodyBytes` at a character boundary and flagged as truncated; a body `jsonEncode` rejects falls back to `toString()`.
- `falconx.rate_limit.local` on a local 429; `falconx.cache.hit` on a hit.
- Headers and bodies are absent by default.

**`test/engine/https/config/log_config_test.dart` (new)**

- `LogConfig()` is a `PrettyLogConfig`; an exhaustive `switch` over both variants; value equality; the default redaction sets.

**`test/engine/https/interceptors/cache_interceptor_test.dart` (new)**

- A hit carries the current request's `options` and reaches a response interceptor placed before and after the cache.
- A hit does not renew the entry: under `fakeAsync`, an entry read every minute still expires at its original time.
- `isCacheHit` is true for a hit and false for a network response.

**Existing tests**

- `base_http_client_configure_test.dart`: switching `log` from pretty to JSON rebuilds only the log interceptor and keeps a token bucket; a limiter diagnostic prints as a JSON line in JSON mode.
- A pretty log test: the constructor leaves `ansiColorDisabled` unchanged; a listed header is redacted; the status prints with `responseHeader` off.
- The concurrency and rate-limit tests gain a case where a cache hit passes their `onResponse` without moving a counter.
- `test/web/compile_smoke.dart` and `test/web/engine_web_test.dart` build `HttpJsonLogInterceptor`.

## 13. Documentation

Per the skill maintenance rule, in the same change:

| File | Change |
|---|---|
| `skills/dart-falconx-package/references/http.md` | A "Server logging" section: `LogConfig.json()`, the field table of section 5, an example line, the redaction lists, and a note that an OpenTelemetry Collector's filelog receiver with a JSON parser ingests the lines. The box table gains `LogConfig.json`. The interceptor catalog gains `HttpJsonLogInterceptor`. The facts of section 11 written as current-state text; the skill carries no migration section, and section 11 feeds the release notes. |
| `skills/dart-falconx-package/SKILL.md` | The interceptor and client-configuration rows. |
| `dart_falconnect/CLAUDE.md` | The interceptor list gains `HttpJsonLogInterceptor`; the `HttpClientConfig` line names the `LogConfig` union. |
| `CLAUDE.md` (root) | The interceptor summary, if it lists interceptors by name. |

## 14. Implementation logistics

- Work in a git worktree on branch `feature/json-log` from the `develop` commit that holds this spec.
- Run `dart run build_runner build --delete-conflicting-outputs` in `dart_falconnect` after changing `LogConfig`.
- Export new public files from the barrels in alphabetical order.
- Commit with `git commit -- <paths>`. No `Co-Authored-By` or AI attribution.
- Do not push or tag. The owner bumps the version to 2.1.0 on `release/2.1.0`, merges, and tags.

## 15. Risks

| Risk | Mitigation |
|---|---|
| Code reads a pretty-only field through `LogConfig` and stops compiling in a minor release | Migration row 1; the owner accepted the break for 2.1.0. |
| A custom interceptor that counts responses double-counts cache hits | Migration row 2 and `isCacheHit`. |
| A body logged on purpose carries personal data | Bodies are off by default; the docs say header redaction does not reach bodies. |
| Cloud Logging reads stdout without a Collector and ignores `severity_text` | Non-goal; documented. A vendor field can be added later without a break. |
| A cache hit renews its own entry | The guard of section 8 and its test. |
| Many cached reads add many short lines | Each line is flagged `falconx.cache.hit`, so aggregators can drop them. |

## 16. Success criteria

- With `log: const LogConfig.json()`, every attempt prints exactly one line that `jsonDecode` accepts, with the core fields of section 5.
- No listed header or query value appears in either log format.
- Switching `log` between pretty, JSON, and null never rebuilds a limiter.
- A cache hit prints a line flagged `falconx.cache.hit`, and a cached entry expires on time however often it is read.
- `HttpLogInterceptor` no longer writes `ansiColorDisabled`, and it prints the status and duration of every response.
- `melos run analyze`, `melos run test`, `dart compile js`, and the Chrome web test pass.
- Every file in section 13 matches the code.

## 17. Details decided in this spec, for owner review

The brainstorm settled the design; these points were chosen while writing and are open to change at review.

1. The start-time key is `dart_falconnect.log.start`, shared by both log interceptors.
2. `maxBodyBytes` defaults to 4,096 and counts UTF-8 bytes.
3. The default redaction sets are those of section 3, and both are public constants.
4. `REDACTED` is the replacement value, as the semantic conventions suggest.
5. A cancel is `INFO`; a 4xx is `WARN` even when `validateStatus` accepts it.
6. `body` ends with `" (cache)"` on a hit, so a person reading the raw terminal sees it.
7. A stream response body is logged as `"<stream>"`.
8. `HttpJsonLogInterceptor` takes `JsonLogConfig` directly; its default is `const JsonLogConfig()`.
9. The pretty log keeps colour on by default; only the global side effect goes.
10. Diagnostics become JSON only inside a `BaseHttpClient`; a hand-built interceptor's `logPrint` still gets plain text.
