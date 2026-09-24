# Configurable `DefaultHttpClient` (client-config core)

**Date:** 2026-09-24
**Packages:** `dart_falconnect`, `dart_faltool`
**Version:** no bump. Every package is already 2.0.0.
**Series:** the first spec of the `dart-falconx-client-config` phase. It builds on SP1 (`2026-09-23-token-bucket-rate-limit-design.md`), SP2 (`2026-09-23-token-bucket-429-pause-design.md`), and SP3 (`2026-09-23-concurrency-limit-design.md`). Owner ruling 2026-09-24: 2.0.0 is held until this spec lands, so users migrate once. Breaking changes are allowed until the tag.
**Contract:** the SP1, SP2, and SP3 specs describe what exists. Section 12 lists every change this spec makes to them.

## 1. Context

`DefaultHttpClient.instance` has fixed options: JSON content type, 20 s connect and receive timeouts, and one `DefaultNetworkExceptionHandlerInterceptor`. An app that needs anything else must subclass `BaseHttpClient` and assemble the interceptor chain by hand. A code reading on 2026-09-23 found six gaps:

1. `HttpClientConfig` is not exported. `https.dart` does not export `config/`, yet six interceptors require the class in their constructors.
2. `DefaultNetworkExceptionHandlerInterceptor` calls `handler.reject` for every error, which skips every later interceptor (dio 5.11.1, `ErrorInterceptorHandler.reject`). `addInterceptors` appends after it, so an interceptor added at run time never sees an error.
3. `applyTo` sets `validateStatus` to `status < 500`. A 4xx then arrives in `onResponse`, so 408, 409, and 429 never reach `RetryInterceptor` and `onClientError` never runs. SP2 left this fix to this phase.
4. Four fields are never read: `maxConnectionsPerHost`, `idleConnectionTimeout`, `validateCertificates`, and `logBodies`.
5. Every interceptor takes the whole `HttpClientConfig`, and all six read `enableLogging`.
6. Retrofit-generated code reads `dio.options.baseUrl` on every call, but an absolute `baseUrl` given to the API factory or to `@RestApi(baseUrl:)` wins (`retrofit_generator` 10.2.11, `_combineBaseUrls`). The skill's own example passes one, so switching the base URL on the client has no effect for that API.

## 2. Goals and non-goals

**Goals**

- Configure `DefaultHttpClient.instance` at app start, and change it at any time, without subclassing.
- A change applies to requests that start after `configure` returns. Requests already running finish on the configuration they started with.
- A change rebuilds only the interceptors whose settings changed. Token buckets, 429 pauses, concurrency slots, cache entries, and performance statistics survive an unrelated change, such as turning logging on.
- One configuration type: `HttpClientConfig`, restructured into freezed per-feature boxes. Every interceptor takes only its own box.
- The client fixes the chain order. The app cannot misorder it.
- An app that never calls `configure` keeps today's behaviour.

**Non-goals**

- Platform adapter options: connection pool size, idle timeout, certificate pinning, proxy, and `withCredentials`. They belong to the `dart-falconx-client-extensions` phase.
- Auth with 401 refresh, `isUseToken`, a header provider, and a request ID. Same phase.
- Tracking, draining, or migrating running requests at a switch.
- Configuration presets. `production()`, `development()`, and `test()` are removed; apps define their own configurations.
- A second custom slot after `ConcurrencyLimitInterceptor` for interceptors that re-send from `onError`. The auth spec decides.
- Guarding against `dio.interceptors.add(...)` called directly. Documented only.

## 3. `HttpClientConfig`

`HttpClientConfig` becomes a freezed class. It holds the dio options and one box per feature. A null box turns its feature off.

```dart
@freezed
abstract class HttpClientConfig with _$HttpClientConfig {
  const HttpClientConfig._();

  const factory({
    @Default('') String baseUrl,
    @Default(Duration(seconds: 20)) Duration connectTimeout,
    @Default(Duration(seconds: 20)) Duration receiveTimeout,
    Duration? sendTimeout,
    @Default(Headers.jsonContentType) String contentType,
    @Default(<String, String>{}) Map<String, String> headers,
    String? userAgent,
    @Default(true) bool followRedirects,
    @Default(5) int maxRedirects,
    ValidateStatus? validateStatus,
    LogConfig? log,
    PerformanceConfig? performance,
    CacheConfig? cache,
    ConcurrencyConfig? concurrency,
    @Default(RateLimitConfig.none()) RateLimitConfig rateLimit,
    RetryConfig? retry,
    @Default(<Interceptor>[]) List<Interceptor> interceptors,
    NetworkExceptionHandlerInterceptor? exceptionHandler,
  }) = _HttpClientConfig;

  BaseOptions toBaseOptions() { ... }

  void applyTo(Dio dio) { ... }
}
```

| Field | Default | Notes |
|---|---|---|
| `baseUrl` | `''` | |
| `connectTimeout`, `receiveTimeout` | 20 s | Was 30 s in the old class; 20 s matches today's `DefaultHttpClient`. |
| `sendTimeout` | null | No limit, as today. |
| `contentType` | `Headers.jsonContentType` | Today's `DefaultHttpClient` value. |
| `headers` | empty | |
| `userAgent` | null | Sets `User-Agent` when not null. |
| `followRedirects`, `maxRedirects` | true, 5 | |
| `validateStatus` | null | Null leaves dio's default: only 2xx succeeds. |
| `log`, `performance`, `cache`, `concurrency`, `retry` | null | Off. |
| `rateLimit` | `RateLimitConfig.none()` | No limit. |
| `interceptors` | empty | The custom slot (section 9). |
| `exceptionHandler` | null | Null means `DefaultNetworkExceptionHandlerInterceptor`. |

- `toBaseOptions()` builds a fresh `BaseOptions` from the dio fields. `headers` plus `User-Agent` become the whole header map.
- `applyTo(dio)` keeps its role for `BaseHttpClient` subclasses. It sets each dio field on `dio.options` and merges `headers` into the existing map, as today. It no longer forces `validateStatus`; it sets one only when the field is not null.
- The class has no JSON methods.

**Removed fields**

| Old field | Now |
|---|---|
| `maxRetryAttempts`, `retryDelay`, `maxRetryDelay`, `maxRetryDuration` | `RetryConfig` |
| `enableCache`, `maxCacheSize`, `cacheDuration` | `CacheConfig`; a null box means off |
| `enablePerformanceMonitoring` | `PerformanceConfig`; a null box means off |
| `enableLogging` | `LogConfig.diagnostics` and the `logPrint` parameter (section 10) |
| `defaultHeaders` | `headers` |
| `maxConnectionsPerHost`, `idleConnectionTimeout`, `validateCertificates` | Removed; the adapter spec reintroduces what it needs |
| `logBodies` | Removed; `LogConfig.requestBody` and `responseBody` cover it |
| `production()`, `development()`, `test()` | Removed |

## 4. Feature boxes

Every box is a freezed class with `==`, `hashCode`, and `copyWith`. Defaults come from the current constructors, so a box built with no arguments behaves like today's interceptor built with no arguments.

| Box | Fields and defaults | Builds |
|---|---|---|
| `LogConfig` | `request` true, `requestHeader` true, `requestBody` true, `responseHeader` false, `responseBody` true, `error` true, `void Function(Object?)? logPrint` null, `diagnostics` true | `HttpLogInterceptor` |
| `PerformanceConfig` | `maxMetricsHistory` 1000, `collectDetailedTimings` true | `PerformanceInterceptor` |
| `CacheConfig` | `duration` 15 min, `maxSize` 50 MB | `CacheInterceptor` |
| `ConcurrencyConfig` | `int? global` null, `int? perHost` null, `Map<String, int?> hosts` empty, `queueRequests` true, `maxQueueSize` 50, `maxGlobalQueueSize` 500 | `ConcurrencyLimitInterceptor` |
| `RetryConfig` | `maxAttempts` 3, `delay` 1 s, `maxDelay` 30 s, `maxDuration` 60 s, `RetryCallback? onRetry` null | `RetryInterceptor` |
| `PauseConfig` | `maxPauseWait` 10 s, `maxPause` 10 min, `Duration? defaultPause` 5 s | Used inside `RateLimitConfig` |

`RateLimitConfig` is a sealed freezed union, following the `JsonRpcResponse` pattern. The two limiters must never share a chain (SP2), and the union makes that impossible.

```dart
@freezed
sealed class RateLimitConfig with _$RateLimitConfig {
  const factory none() = NoRateLimitConfig;

  const factory pauseOnly({
    @Default(PauseConfig()) PauseConfig pause,
    @Default(50) int maxQueueSize,
  }) = PauseOnlyRateLimitConfig;

  const factory tokenBucket({
    @Default(<TokenBucketPolicy>[]) List<TokenBucketPolicy> global,
    @Default(<TokenBucketPolicy>[]) List<TokenBucketPolicy> perHost,
    @Default(<String, List<TokenBucketPolicy>>{})
    Map<String, List<TokenBucketPolicy>> hosts,
    @Default(true) bool queueRequests,
    @Default(50) int maxQueueSize,
    @Default(500) int maxGlobalQueueSize,
    @Default(PauseConfig()) PauseConfig pause,
  }) = TokenBucketRateLimitConfig;
}
```

`pauseOnly` builds `RetryAfterPauseInterceptor`; `tokenBucket` builds `TokenBucketRateLimitInterceptor`; `none` builds nothing.

**Equality of non-value fields.** `logPrint`, `onRetry`, `validateStatus`, `interceptors`, and `exceptionHandler` compare by identity. A lambda written inline on every `configure` call makes its box unequal each time, so that box is rebuilt. This costs nothing for log and retry, which keep no state between requests. The docs advise top-level functions and long-lived interceptor instances.

## 5. Interceptor constructors

Each interceptor takes its own box instead of `HttpClientConfig`, plus an optional diagnostics printer. Behaviour is otherwise unchanged.

| Interceptor | Before | After |
|---|---|---|
| `RetryInterceptor` | `(config:, dio:, onRetry:, random:)` | `(config: RetryConfig, dio:, random:, logPrint:)`; `onRetry` moves into `RetryConfig` |
| `CacheInterceptor` | `(config:)` | `(config: CacheConfig, logPrint:)` |
| `PerformanceInterceptor` | `(config:, maxMetricsHistory:, collectDetailedTimings:)` | `(config: PerformanceConfig, logPrint:)` |
| `ConcurrencyLimitInterceptor` | `(config:, global:, perHost:, hosts:, queueRequests:, maxQueueSize:, maxGlobalQueueSize:)` | `(config: ConcurrencyConfig, logPrint:)` |
| `RetryAfterPauseInterceptor` | `(config:, maxPauseWait:, maxPause:, defaultPause:, maxQueueSize:)` | `(config: PauseOnlyRateLimitConfig, logPrint:)` |
| `TokenBucketRateLimitInterceptor` | `(config:, global:, perHost:, hosts:, queueRequests:, maxQueueSize:, maxGlobalQueueSize:, maxPauseWait:, maxPause:, defaultPause:)` | `(config: TokenBucketRateLimitConfig, logPrint:)` |

- `logPrint` has type `void Function(String message)?` and defaults to null, which prints nothing. Today's default `enableLogging` is false, so the default output does not change. Messages keep their `[ClassName]` prefix.
- `CacheInterceptor` and `PerformanceInterceptor` lose their `enableCache` and `enablePerformanceMonitoring` checks: the interceptor exists only when its box is not null.
- `HttpLogInterceptor` keeps its constructor. The client maps `LogConfig` onto its named parameters.
- Validation stays where it is: lowercase `hosts` keys, `TokenBucketPolicy.validate()`, and the concurrency checks still throw from the constructors.

## 6. `TokenBucketPolicy`

`TokenBucketPolicy` in `dart_faltool` becomes freezed, so rate-limit boxes compare by value.

```dart
@freezed
abstract class TokenBucketPolicy with _$TokenBucketPolicy {
  const TokenBucketPolicy._();

  const factory({
    required int permits,
    required Duration per,
    int? burst,
  }) = _TokenBucketPolicy;

  int get effectiveBurst => burst ?? math.max(1, permits ~/ 10);

  void validate() { ... }                                  // uses effectiveBurst
  RateLimiter toRateLimiter({int? maxQueueLength}) { ... } // uses effectiveBurst
}
```

- The constructor stays `const`, so `const [TokenBucketPolicy(...)]` in apps and docs keeps compiling.
- `burst` now returns what the caller passed, possibly null. The computed value moves to `effectiveBurst`. Only the `dart_faltool` tests read `burst` today.
- A policy with no `burst` and one with the computed value behave alike but are unequal. Switching between the two rebuilds the limiter. Rare; documented.

## 7. `DefaultHttpClient` API

```dart
class DefaultHttpClient extends BaseHttpClient {
  static final DefaultHttpClient instance = ...;

  /// The configuration new requests use.
  HttpClientConfig get currentConfig;

  /// Applies [config] to requests that start after this call returns.
  /// Throws, and keeps the current configuration, when an interceptor
  /// cannot be built from [config].
  void configure(HttpClientConfig config);

  /// Adds [interceptors] to the custom slot of the current configuration.
  @override
  void addInterceptors(Interceptors interceptors);

  /// Sets the base URL of the current configuration.
  @override
  void setupBaseUrl(String baseUrl);

  /// Disposes the stateful interceptors of the current configuration.
  /// Needed at the end of a test or a CLI; a Flutter app never calls it.
  void dispose();
}
```

- The field holding the configuration is initialized in its declaration with `const HttpClientConfig()`. Dart runs field initializers before the super constructor, so it is set when `BaseHttpClient` calls `setupOptions` and `setupInterceptors`. Those hooks apply it, which reproduces today's behaviour.
- `addInterceptors` calls `configure(currentConfig.copyWith(interceptors: [...currentConfig.interceptors, ...interceptors]))`. The added interceptors survive later `configure` calls and move from the end of the chain to the custom slot, so they now see errors (gap 2). `BaseHttpClient.addInterceptors` is unchanged for subclasses.
- `setupBaseUrl` calls `configure(currentConfig.copyWith(baseUrl: baseUrl))`, so `currentConfig` always matches `dio.options`.
- `BaseHttpClient.config` still returns the dio `BaseOptions`.

## 8. `configure` semantics

`configure(next)` runs synchronously in four steps:

1. Compare each box of `next` with the same box of `currentConfig`.
2. Build a new interceptor for every box that changed. Keep the current instance for every box that is equal. If a constructor throws, the call rethrows and nothing changes.
3. Assemble the chain in the order of section 9.
4. Swap in one synchronous block: `dio.options = next.toBaseOptions()`, then `dio.interceptors.clear()` (which keeps dio's `ImplyContentTypeInterceptor`) and `addAll(chain)`. Then store `next`.

| Box | Interceptor | State kept when the box is equal |
|---|---|---|
| `log` | `HttpLogInterceptor` | none |
| `performance` | `PerformanceInterceptor` | metrics and statistics |
| `cache` | `CacheInterceptor` | cache entries |
| `concurrency` | `ConcurrencyLimitInterceptor` | active slots and queues |
| `rateLimit` | `TokenBucketRateLimitInterceptor` or `RetryAfterPauseInterceptor` | tokens, queues, and 429 pauses |
| `retry` | `RetryInterceptor` | none |
| `interceptors` | the app's instances | the app's |
| `exceptionHandler` | the given handler, or one shared `DefaultNetworkExceptionHandlerInterceptor` | its queue |

**Running requests.** dio builds the request, response, and error phases of a request from the interceptor list when `fetch` starts (`dio_mixin.dart`, lines 534 to 582). A request that started before the swap runs to the end on the old interceptors. The client does not track it.

**Replaced interceptors are not disposed.** A replaced limiter still serves its running requests. Its timers end on their own: token bucket refills stop when every bucket is full, and a pause keeps a timer only while it holds requests, each for at most about `maxPauseWait`. A test that swaps a limiter while a request waits must let that request finish before the test ends, or `testWidgets` reports a pending timer.

**Retries cross the swap.** `RetryInterceptor` sends each attempt with `dio.fetch`, which reads the current list. The next attempt of an old request therefore passes the new chain, while the retry count and deadline stay those of the old `RetryConfig`. Documented as the contract: every attempt uses the chain current when the attempt starts.

**Overlap after a limit change.** When `rateLimit` or `concurrency` changes, the old limiter drains its queue under the old limits while the new one starts empty. For a short time the two together can exceed either limit, by at most the old queue size. A 429 pause active in the old limiter is not carried over. Documented.

## 9. Interceptor order

The client assembles the chain in this order. Positions 4 to 8 are the SP3 order.

| # | Interceptor | Reason |
|---|---|---|
| 0 | `ImplyContentTypeInterceptor` | dio's default; kept by `clear()` |
| 1 | `interceptors` (custom slot) | Runs first, so an auth header is stamped before `CacheInterceptor` builds its key, which includes `authorization` |
| 2 | `HttpLogInterceptor` | Sees stamped headers, and sees each retry attempt's error exactly once (before `RetryInterceptor`) |
| 3 | `PerformanceInterceptor` | Measures the wait in the limiter queues, which the user also waits |
| 4 | `CacheInterceptor` | A hit answers without taking a slot or a token |
| 5 | `ConcurrencyLimitInterceptor` | Slot before tokens (SP3) |
| 6 | `TokenBucketRateLimitInterceptor` or `RetryAfterPauseInterceptor` | Sees a server 429 before `RetryInterceptor` (SP2) |
| 7 | `RetryInterceptor` | |
| 8 | exception handler | Last, because it rejects without calling later error interceptors |

Custom interceptors run before `ConcurrencyLimitInterceptor`, so they must follow the SP3 slot-safety rule: end `onResponse` and `onError` with `handler.next(...)` or `handler.reject(err, true)`. The docs state the rule next to the custom slot.

## 10. Diagnostics

The client passes one printer to every interceptor it builds:

```dart
void _diagnostic(String message) {
  final log = _config.log;
  if (log != null && log.diagnostics) (log.logPrint ?? print)(message);
}
```

The printer reads the current configuration on every call. Turning logging on or off changes only the `log` box, so stateful interceptors are kept and still print, or stop printing, at once. A `BaseHttpClient` subclass passes `logPrint: print`, or nothing for silence.

## 11. Migration

An app that only uses `DefaultHttpClient.instance` needs no change. A `BaseHttpClient` subclass that builds interceptors changes as follows.

```dart
// Before
final config = HttpClientConfig.production();
RetryInterceptor(config: config, dio: dio);
CacheInterceptor(config: config);

// After
RetryInterceptor(config: const RetryConfig(), dio: dio);
CacheInterceptor(config: const CacheConfig());
```

| # | Breaking change | Action |
|---|---|---|
| 1 | Six interceptor constructors take their own box | Pass the box; see section 5 |
| 2 | `HttpClientConfig` fields moved into boxes | `config.maxRetryAttempts` becomes `config.retry?.maxAttempts`, and so on (section 3) |
| 3 | Presets removed | Build your own configuration values |
| 4 | Default timeouts are 20 s, were 30 s | Set them explicitly to keep 30 s |
| 5 | `applyTo` no longer sets `validateStatus` to `status < 500` | 4xx now fails in `onError`; set `validateStatus` to keep the old behaviour |
| 6 | Four unread fields removed | Delete them |
| 7 | `enableLogging` removed | Pass `logPrint:` to each interceptor |
| 8 | `TokenBucketPolicy.burst` is nullable | Read `effectiveBurst` for the computed value |
| 9 | `DefaultHttpClient.addInterceptors` adds to the front of the chain, was the end | Nothing, unless an interceptor relied on running after the exception handler, where it never saw errors |

## 12. Changes to the SP1, SP2, and SP3 contracts

- Constructors of `TokenBucketRateLimitInterceptor` (SP1, SP2), `RetryInterceptor` and `RetryAfterPauseInterceptor` (SP2), and `ConcurrencyLimitInterceptor` (SP3) change as in section 5.
- `TokenBucketPolicy` becomes freezed; `burst` becomes nullable (section 6).
- `enableLogging` diagnostics become the `logPrint` parameter.
- The chain order of SP3 section 12 gains positions 1 to 3 (section 9).
- `applyTo` stops forcing `validateStatus`. The known gap in SP2 section 16, a server 429 never reaching `RetryInterceptor` under `applyTo`, closes.

## 13. Documentation

Per the skill maintenance rule, in the same change:

| File | Change |
|---|---|
| `skills/dart-falconx-package/SKILL.md` | The `DefaultHttpClient` and interceptor rows: `configure`, `currentConfig`, the boxes, and the new constructors. |
| `skills/dart-falconx-package/references/http.md` | Rewrite the `DefaultHttpClient` section around `configure`, with the dev and prod example and the runtime switch. Rewrite the custom client example and the interceptor catalog with box constructors. Replace the `HttpClientConfig` paragraph. Add the fixed order of section 9, the custom-slot slot-safety rule, the Retrofit rule (never give the API an absolute `baseUrl` when the client switches base URLs), the warning against `dio.interceptors.add(...)`, the section 8 contract, and a 2.0.0 migration note built from section 11. |
| `skills/dart-falconx-package/references/models.md` | `TokenBucketPolicy.effectiveBurst`. |
| `dart_falconnect/CLAUDE.md` | Line 40: `HttpClientConfig` holds freezed boxes and has no presets. The order line. |
| `CLAUDE.md` (root) | The order line, if it still lists the old order. |

## 14. Testing plan

TDD. Tests use a real `Dio` with a capturing adapter; timing tests run under `fakeAsync`.

**`dart_falconnect/test/engine/https/default_http_client_test.dart` (new)**

- No `configure` call: JSON content type, 20 s connect and receive timeouts, and a chain of `ImplyContentTypeInterceptor` plus one `DefaultNetworkExceptionHandlerInterceptor`.
- Swap while a request runs: the adapter holds request A, `configure` runs, request B starts. A carries the old headers and passes the old interceptors; B carries the new ones.
- Reuse: an equal box yields the identical instance; a changed box yields a new one. Turning `log` on keeps the token bucket instance, its spent tokens, and an active 429 pause.
- Failed build: an invalid policy makes `configure` throw, and `currentConfig`, `dio.options`, and the interceptor list stay unchanged.
- Order: the list matches section 9 for a configuration with every box set. A cache hit spends no token and takes no slot. The exception handler is last.
- `validateStatus`: with the default, a 404 reaches the exception handler, and a 429 reaches `RetryInterceptor`.
- Diagnostics: after turning `log` on, a kept limiter prints through the new printer; after turning it off, it prints nothing.
- `addInterceptors` puts the interceptor in the custom slot, it sees errors, and it survives a later `configure`.
- `setupBaseUrl` updates `currentConfig` and `dio.options.baseUrl`.
- `dispose()` disposes the current limiters.

**Model tests**

- `HttpClientConfig` and every box: `==`, `hashCode`, defaults, and `copyWith(log: null)` turning logging off.
- `RateLimitConfig`: an exhaustive `switch` over the three variants.
- `dart_faltool/test/utils/token_bucket_policy_test.dart`: `effectiveBurst` replaces the `burst` expectations; value equality.

**Existing tests**

- Every SP1, SP2, and SP3 interceptor test, `rate_limit_retry_chain_test.dart`, `test/web/engine_web_test.dart`, and `test/web/compile_smoke.dart` move to box constructors and keep passing.

## 15. Implementation logistics

- Work in a git worktree on branch `feature/client-config` from `develop` (`0da59c3`). Implement with the `dart-engineer-pack:dart-engineer` agent.
- Run `melos run build_runner` after adding freezed classes; generated files go to `generated/`.
- Export the new files from the barrels in alphabetical order (`directives_ordering`). `https.dart` gains `config/config.dart`.
- Commit with `git commit -- <paths>`. No `Co-Authored-By` or AI attribution.
- Do not push or tag. The owner tags 2.0.0 after this spec merges. Before the tag, confirm the skill matches the source.

## 16. Risks

| Risk | Mitigation |
|---|---|
| A limit change lets old and new limiters overlap, and drops an active 429 pause. | Rebuild only on a limit change; documented in section 8. |
| An inline lambda makes its box unequal on every `configure`. | Harmless for log and retry; the docs advise top-level functions. |
| Direct `dio.interceptors.add(...)` is lost at the next `configure`. | Documented; `addInterceptors` is the supported path. |
| An absolute Retrofit `baseUrl` silently ignores switches. | Documented rule and example. |
| A custom interceptor breaks the slot-safety rule and leaks concurrency slots. | The rule is stated next to the custom slot; SP3 placement tests cover the built-in chain. |
| Many breaking changes in one release. | One migration note; 2.0.0 is not yet tagged. |

## 17. Success criteria

- `DefaultHttpClient.instance` with no `configure` call behaves as today.
- A `configure` call never disturbs a running request, and applies to every request that starts after it.
- A change to one box rebuilds only that box's interceptor, proven for the token bucket, the pause, and the concurrency limiter.
- A failed `configure` leaves everything unchanged.
- The chain order of section 9 holds for every combination of boxes.
- `HttpClientConfig` and the boxes are importable from `package:dart_falconx/dart_falconx.dart`.
- `melos run analyze`, `melos run test`, `dart compile js`, and the Chrome web test pass.
- Every file in section 13 matches the code.

## 18. Details decided in this spec, for owner review

The brainstorm settled the design; these finer points were chosen here and are open to change at review.

1. `TokenBucketPolicy` keeps a `const` constructor and moves the computed value to `effectiveBurst` (section 6). The alternative, computing `burst` at construction, loses `const`.
2. `PauseConfig` is a nested box shared by both rate-limit variants, and `pauseOnly` keeps its own `maxQueueSize`.
3. `LogConfig.diagnostics` lets an app see HTTP logs without interceptor diagnostics.
4. `HttpLogInterceptor` keeps its constructor; only the six config-reading interceptors change.
5. `applyTo` keeps merging headers for subclasses, while `configure` replaces the whole header map.
6. `RetryConfig` carries `onRetry`, so the client can build `RetryInterceptor` from the box alone.
7. The default exception handler is one shared instance, kept across `configure` calls.
