# Client Config Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every `BaseHttpClient`, `DefaultHttpClient.instance` included, one freezed `HttpClientConfig` that it applies with `configure` at any time. Change the six config-reading interceptors so each takes only its own box. Collapse the request methods into one path, and fix the `catchWhenError` and `mapJson` bugs.

**Architecture:** `HttpClientConfig` becomes a freezed class of dio options plus one freezed box per feature. `BaseHttpClient.configure` compares boxes and rebuilds only changed interceptors, then assembles the chain in a fixed order. It writes only the options the config owns, and swaps the interceptor list in one synchronous block, so running requests keep the chain dio bound them to. Interceptors print diagnostics through a `logPrint` function that reads the current log box, so a log toggle never rebuilds a stateful interceptor.

**Tech Stack:** Dart 3.13 (the repository's `new(...)` constructor syntax), dio 5.11.1, freezed 4 with `freezed_annotation` 3.1, retrofit 4.10, `resilience` 1.1.3 (re-exported by `dart_faltool`), `package:test`, `fake_async`, melos 8.

**Spec:** `docs/superpowers/specs/2026-09-24-default-http-client-config-design.md`

**Provenance:** Every code block in Tasks 1 to 6 comes from a throwaway prototype built on `c6f0f28` on 2026-09-24. There, `melos run analyze` and `melos run format` exited 0, `melos run test` passed (dart_falconnect 186 with 1 existing skip, dart_faltool 701, dart_falmodel 58, dart_falconx 1), `dart compile js test/web/compile_smoke.dart` exited 0, and `dart test -p chrome test/web` passed 7. Run against the unchanged `develop` code, 7 of the 10 original response-extension tests fail with the errors of spec section 1, gaps 8 and 9. Removing instance reuse from `configure` makes 3 configure tests fail. The documentation tasks (7 and 8) were not prototyped.

## Global Constraints

- Work in worktree `.claude/worktrees/client-config` on branch `feature/client-config`, created from the `develop` commit that holds this plan.
- No new dependency in any `pubspec.yaml`.
- `dart_falconnect` compiles to the web: no `dart:io`, and no `int` shift or bitwise operator on a value that may exceed 32 bits.
- Lints: `very_good_analysis`; `melos run analyze` runs with `--fatal-infos`; single quotes; 80 columns; exports in barrel files sorted alphabetically. `remove_deprecations_in_breaking_versions` is active: no `@Deprecated` member while the version is 2.0.0; remove instead.
- Every model is freezed (owner rule), in the repository's syntax: `@freezed abstract class X with _$X { const factory({...}) = _X; }`, plus `const new _();` when the class has methods or getters. Generated files go to `generated/`. Run `dart run build_runner build --delete-conflicting-outputs` in the package after changing a model.
- Interceptor and config files import the files they need directly (`package:dart_falconnect/engine/...`, `package:dart_falconnect/src/...`), as the neighbouring interceptors do. `http_client.dart` and the extensions import `package:dart_falconnect/lib.dart`, as today.
- Under `fakeAsync`, dio starts every request chain on a zero-length timer: advance with `async.elapse(Duration.zero)`, never `flushMicrotasks()`.
- Run `dart format` on every file you touch before committing.
- Commit with explicit paths: `git commit -m <msg> -- <paths>`. No `Co-Authored-By` line and no AI attribution in any commit message.
- Do not push and do not tag.

## Review Focus

1. **`configure` called with the config already in use** (a settings screen that saves without changes): every interceptor, and so every limiter's state, must stay. Pinned by Task 6 test `configure with the same config keeps every interceptor`.
2. **A header key that changes only in case** between two configs (`x-a` then `X-A`): the removal of the old key must not delete the new value, because dio's header map ignores case. Pinned by Task 6 test `a header whose key changes only in case keeps its new value`.
3. **A timeout dropped from the config** (`sendTimeout` set, then left null): the old value must be cleared, because the config owns the field. Pinned by Task 6 test `a timeout dropped from the config is cleared`.
4. **A converter that returns null** for a nullable `T`: the response must carry null, not the raw JSON map. Pinned by Task 5 test `a converter that returns null yields null data`.
5. **A `catchError` fallback that throws**: its own exception must surface, not the original error and not a crash in the recovery code. Pinned by Task 5 test `a fallback that throws surfaces its own error`.

---

### Task 1: `TokenBucketPolicy` becomes freezed

**Files:**
- Modify: `dart_faltool/lib/utils/token_bucket_policy.dart` (whole file)
- Create (generated): `dart_faltool/lib/utils/generated/token_bucket_policy.freezed.dart`
- Test: `dart_faltool/test/utils/token_bucket_policy_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `TokenBucketPolicy` with `==` and `hashCode`; `int? burst` (as given); `int get effectiveBurst`; `validate()` and `toRateLimiter({int? maxQueueLength})` unchanged in behaviour. The constructor stays `const`.

- [ ] **Step 1: Write the failing tests**

In `dart_faltool/test/utils/token_bucket_policy_test.dart`, replace the whole `group('TokenBucketPolicy.burst', ...)` with these two groups:

```dart
  group('TokenBucketPolicy.effectiveBurst', () {
    test('defaults to 10% of permits and leaves burst null', () {
      const policy = TokenBucketPolicy(permits: 100, per: Duration(minutes: 1));
      expect(policy.effectiveBurst, 10);
      expect(policy.burst, isNull);
    });

    test('defaults to at least 1', () {
      const policy = TokenBucketPolicy(permits: 5, per: Duration(seconds: 1));
      expect(policy.effectiveBurst, 1);
    });

    test('uses an explicit value', () {
      const policy = TokenBucketPolicy(
        permits: 100,
        per: Duration(minutes: 1),
        burst: 40,
      );
      expect(policy.burst, 40);
      expect(policy.effectiveBurst, 40);
    });
  });

  group('TokenBucketPolicy equality', () {
    TokenBucketPolicy build(int permits) =>
        TokenBucketPolicy(permits: permits, per: const Duration(seconds: 1));

    test('policies with equal fields are equal', () {
      expect(build(5), build(5));
      expect(build(5).hashCode, build(5).hashCode);
      expect(build(5), isNot(build(6)));
    });
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_faltool && dart test test/utils/token_bucket_policy_test.dart`
Expected: FAIL to compile with `The getter 'effectiveBurst' isn't defined for the type 'TokenBucketPolicy'`.

- [ ] **Step 3: Replace the class with the freezed version**

Replace the whole of `dart_faltool/lib/utils/token_bucket_policy.dart` with:

```dart
import 'dart:math' as math;

import 'package:dart_faltool/lib.dart';

part 'generated/token_bucket_policy.freezed.dart';

/// A rate limit stated as "at most [permits] requests in any window of
/// length [per]", enforced with a token bucket.
///
/// [burst] is how many requests may leave back to back after an idle
/// period; null means 10% of [permits], at least 1, which
/// [effectiveBurst] returns. A larger burst lowers the steady rate to
/// `permits - effectiveBurst + 1` per [per]; the ceiling of [permits] per
/// [per] never moves.
@freezed
abstract class TokenBucketPolicy with _$TokenBucketPolicy {
  /// Creates a policy allowing [permits] requests per [per].
  const factory({
    /// Most requests allowed in any window of length [per].
    required int permits,

    /// Window length.
    required Duration per,

    /// Requests allowed back to back after an idle period, as given; null
    /// means the default that [effectiveBurst] computes.
    int? burst,
  }) = _TokenBucketPolicy;

  const new _();

  /// Requests allowed back to back after an idle period.
  int get effectiveBurst => burst ?? math.max(1, permits ~/ 10);

  /// Throws an [ArgumentError] when this policy cannot be enforced.
  void validate() {
    if (permits < 1) {
      throw ArgumentError.value(permits, 'permits', 'must be at least 1');
    }
    if (per <= Duration.zero) {
      throw ArgumentError.value(per, 'per', 'must be positive');
    }
    if (effectiveBurst < 1 || effectiveBurst > permits) {
      throw ArgumentError.value(
        effectiveBurst,
        'burst',
        'must be in 1..$permits',
      );
    }
    if (per.inMicroseconds < permits - effectiveBurst + 1) {
      throw ArgumentError.value(
        per,
        'per',
        'must be at least ${permits - effectiveBurst + 1} microseconds',
      );
    }
  }

  /// Builds the `resilience` [RateLimiter] that enforces this policy.
  ///
  /// The bucket holds [effectiveBurst] tokens and refills
  /// `permits - effectiveBurst + 1` tokens per [per], rounded towards
  /// slower refills, so no window of length [per] ever admits more than
  /// [permits] requests.
  RateLimiter toRateLimiter({int? maxQueueLength}) {
    validate();
    final burst = effectiveBurst;
    final refills = permits - burst + 1;
    return RateLimiter(
      maxPermits: burst,
      per: Duration(
        microseconds: (per.inMicroseconds * burst + refills - 1) ~/ refills,
      ),
      maxQueueLength: maxQueueLength,
    );
  }
}
```

- [ ] **Step 4: Generate code**

Run: `cd dart_faltool && dart run build_runner build --delete-conflicting-outputs`
Expected: `wrote 2 outputs` or similar, and `lib/utils/generated/token_bucket_policy.freezed.dart` exists.

- [ ] **Step 5: Run the tests and the analyzer**

Run: `cd dart_faltool && dart test test/utils/token_bucket_policy_test.dart && dart analyze --fatal-infos`
Expected: all tests pass; `No issues found!`
Run: `cd ../dart_falconnect && dart analyze --fatal-infos lib`
Expected: `No issues found!` (nothing in `dart_falconnect` reads `burst`).

- [ ] **Step 6: Commit**

```bash
git commit -m "refactor(dart_faltool)!: make TokenBucketPolicy freezed and add effectiveBurst" -- dart_faltool/lib/utils/token_bucket_policy.dart dart_faltool/lib/utils/generated/token_bucket_policy.freezed.dart dart_faltool/test/utils/token_bucket_policy_test.dart
```

---

### Task 2: Feature boxes

**Files:**
- Create: `dart_falconnect/lib/engine/https/config/log_config.dart`, `performance_config.dart`, `cache_config.dart`, `concurrency_config.dart`, `retry_config.dart`, `pause_config.dart`, `rate_limit_config.dart`, `config.dart` (all under `dart_falconnect/lib/engine/https/config/`)
- Create (generated): the matching `generated/*.freezed.dart` files
- Modify: `dart_falconnect/lib/engine/https/https.dart` (export the config barrel)
- Modify: `dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart` (move the `RetryCallback` typedef out)
- Test: `dart_falconnect/test/engine/https/config/feature_boxes_test.dart`

**Interfaces:**
- Consumes: `TokenBucketPolicy` with value equality (Task 1).
- Produces: freezed boxes `LogConfig`, `PerformanceConfig`, `CacheConfig`, `ConcurrencyConfig`, `RetryConfig`, `PauseConfig`; the sealed union `RateLimitConfig` with variants `NoRateLimitConfig` (`RateLimitConfig.none()`), `PauseOnlyRateLimitConfig` (`RateLimitConfig.pauseOnly(...)`), and `TokenBucketRateLimitConfig` (`RateLimitConfig.tokenBucket(...)`); the typedef `RetryCallback` now in `retry_config.dart`. Every box is exported from `package:dart_falconnect/dart_falconnect.dart`.

- [ ] **Step 1: Write the failing test**

Create `dart_falconnect/test/engine/https/config/feature_boxes_test.dart`:

```dart
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:test/test.dart';

RetryConfig _retry(int attempts) => RetryConfig(maxAttempts: attempts);

TokenBucketPolicy _policy(int permits) =>
    TokenBucketPolicy(permits: permits, per: const Duration(seconds: 1));

void main() {
  test('defaults match the interceptor defaults', () {
    const retry = RetryConfig();
    expect(retry.maxAttempts, 3);
    expect(retry.delay, const Duration(seconds: 1));
    expect(retry.maxDelay, const Duration(seconds: 30));
    expect(retry.maxDuration, const Duration(seconds: 60));
    expect(retry.onRetry, isNull);

    const cache = CacheConfig();
    expect(cache.duration, const Duration(minutes: 15));
    expect(cache.maxSize, 50 * 1024 * 1024);

    const pause = PauseConfig();
    expect(pause.maxPauseWait, const Duration(seconds: 10));
    expect(pause.maxPause, const Duration(minutes: 10));
    expect(pause.defaultPause, const Duration(seconds: 5));

    const concurrency = ConcurrencyConfig();
    expect(concurrency.global, isNull);
    expect(concurrency.perHost, isNull);
    expect(concurrency.hosts, isEmpty);
    expect(concurrency.queueRequests, isTrue);
    expect(concurrency.maxQueueSize, 50);
    expect(concurrency.maxGlobalQueueSize, 500);

    const performance = PerformanceConfig();
    expect(performance.maxMetricsHistory, 1000);
    expect(performance.collectDetailedTimings, isTrue);

    const log = LogConfig();
    expect(log.responseHeader, isFalse);
    expect(log.logPrint, isNull);
    expect(log.diagnostics, isTrue);
  });

  test('boxes compare by value', () {
    expect(_retry(2), const RetryConfig(maxAttempts: 2));
    expect(_retry(2).hashCode, const RetryConfig(maxAttempts: 2).hashCode);
    expect(_retry(2), isNot(_retry(3)));
    expect(
      RateLimitConfig.tokenBucket(global: [_policy(5)]),
      RateLimitConfig.tokenBucket(global: [_policy(5)]),
    );
    expect(
      RateLimitConfig.tokenBucket(global: [_policy(5)]),
      isNot(RateLimitConfig.tokenBucket(global: [_policy(6)])),
    );
  });

  test('RateLimitConfig has exactly three variants', () {
    String name(RateLimitConfig config) => switch (config) {
      NoRateLimitConfig() => 'none',
      PauseOnlyRateLimitConfig() => 'pause',
      TokenBucketRateLimitConfig() => 'bucket',
    };

    expect(
      [
        name(const RateLimitConfig.none()),
        name(const RateLimitConfig.pauseOnly()),
        name(const RateLimitConfig.tokenBucket()),
      ],
      ['none', 'pause', 'bucket'],
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd dart_falconnect && dart test test/engine/https/config/feature_boxes_test.dart`
Expected: FAIL to compile, because `RetryConfig` and the other boxes are not defined yet.

- [ ] **Step 3: Create the box files**

`dart_falconnect/lib/engine/https/config/log_config.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/log_config.freezed.dart';

/// HTTP logging settings; a non-null box adds `HttpLogInterceptor`.
@freezed
abstract class LogConfig with _$LogConfig {
  /// Creates logging settings. Defaults match `HttpLogInterceptor()`.
  const factory({
    /// Logs the request line and options.
    @Default(true) bool request,

    /// Logs request headers.
    @Default(true) bool requestHeader,

    /// Logs the request body.
    @Default(true) bool requestBody,

    /// Logs response headers.
    @Default(false) bool responseHeader,

    /// Logs the response body.
    @Default(true) bool responseBody,

    /// Logs errors.
    @Default(true) bool error,

    /// Printer for HTTP logs and diagnostics; null prints to the console.
    void Function(Object? object)? logPrint,

    /// Whether interceptors print their diagnostics through [logPrint].
    @Default(true) bool diagnostics,
  }) = _LogConfig;
}
```

`dart_falconnect/lib/engine/https/config/performance_config.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/performance_config.freezed.dart';

/// Performance monitoring settings; a non-null box adds
/// `PerformanceInterceptor`.
@freezed
abstract class PerformanceConfig with _$PerformanceConfig {
  /// Creates performance monitoring settings.
  const factory({
    /// Most request metrics kept in memory.
    @Default(1000) int maxMetricsHistory,

    /// Whether to collect detailed timing information.
    @Default(true) bool collectDetailedTimings,
  }) = _PerformanceConfig;
}
```

`dart_falconnect/lib/engine/https/config/cache_config.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/cache_config.freezed.dart';

/// Response cache settings; a non-null box adds `CacheInterceptor`.
@freezed
abstract class CacheConfig with _$CacheConfig {
  /// Creates cache settings.
  const factory({
    /// How long a response stays valid when its headers set no lifetime.
    @Default(Duration(minutes: 15)) Duration duration,

    /// Largest total cache size in bytes.
    @Default(50 * 1024 * 1024) int maxSize,
  }) = _CacheConfig;
}
```

`dart_falconnect/lib/engine/https/config/concurrency_config.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/concurrency_config.freezed.dart';

/// Concurrency limit settings; a non-null box adds
/// `ConcurrencyLimitInterceptor`.
@freezed
abstract class ConcurrencyConfig with _$ConcurrencyConfig {
  /// Creates concurrency limit settings. Every scope is unlimited until it
  /// gets a number.
  const factory({
    /// Most requests in flight to all hosts together; null means no limit.
    int? global,

    /// Most requests in flight to a host missing from [hosts]; null means
    /// no limit.
    int? perHost,

    /// Per-host limits keyed by bare lowercase host; a null value opts the
    /// host out of [perHost].
    @Default(<String, int?>{}) Map<String, int?> hosts,

    /// Whether a request with no free slot waits (`true`) or is rejected.
    @Default(true) bool queueRequests,

    /// Queue capacity of each host limit.
    @Default(50) int maxQueueSize,

    /// Queue capacity of the global limit.
    @Default(500) int maxGlobalQueueSize,
  }) = _ConcurrencyConfig;
}
```

`dart_falconnect/lib/engine/https/config/retry_config.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/retry_config.freezed.dart';

/// Called before each retry waits.
///
/// [attempt] is 1 for the first retry. The stack trace of the failure is
/// `error.stackTrace`.
typedef RetryCallback = void Function(
  DioException error,
  int attempt,
  Duration delay,
);

/// Retry settings; a non-null box adds `RetryInterceptor`.
@freezed
abstract class RetryConfig with _$RetryConfig {
  /// Creates retry settings.
  const factory({
    /// Most retries of one request.
    @Default(3) int maxAttempts,

    /// Base delay of the exponential backoff.
    @Default(Duration(seconds: 1)) Duration delay,

    /// Longest wait before one retry, and the cap on `Retry-After`.
    @Default(Duration(seconds: 30)) Duration maxDelay,

    /// Most time spent retrying one request, from its first failure.
    @Default(Duration(seconds: 60)) Duration maxDuration,

    /// Called before each retry waits.
    RetryCallback? onRetry,
  }) = _RetryConfig;
}
```

`dart_falconnect/lib/engine/https/config/pause_config.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/pause_config.freezed.dart';

/// Settings of the 429 and 503 `Retry-After` pause.
@freezed
abstract class PauseConfig with _$PauseConfig {
  /// Creates pause settings.
  const factory({
    /// Longest remaining pause a request waits out instead of failing.
    @Default(Duration(seconds: 10)) Duration maxPauseWait,

    /// Longest pause any response can start.
    @Default(Duration(minutes: 10)) Duration maxPause,

    /// Pause for a 429 without a readable `Retry-After`; null means none.
    @Default(Duration(seconds: 5)) Duration? defaultPause,
  }) = _PauseConfig;
}
```

`dart_falconnect/lib/engine/https/config/rate_limit_config.dart`:

```dart
import 'package:dart_falconnect/engine/https/config/pause_config.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/rate_limit_config.freezed.dart';

/// Rate limit settings: none, the `Retry-After` pause alone, or token
/// buckets with the pause built in. The two limiters never share a chain.
@freezed
sealed class RateLimitConfig with _$RateLimitConfig {
  /// No rate limit and no pause.
  const factory none() = NoRateLimitConfig;

  /// The `Retry-After` pause alone; builds `RetryAfterPauseInterceptor`.
  const factory pauseOnly({
    /// Pause settings.
    @Default(PauseConfig()) PauseConfig pause,

    /// Most requests held per paused host.
    @Default(50) int maxQueueSize,
  }) = PauseOnlyRateLimitConfig;

  /// Token buckets with the pause built in; builds
  /// `TokenBucketRateLimitInterceptor`.
  const factory tokenBucket({
    /// Tiers every request passes.
    @Default(<TokenBucketPolicy>[]) List<TokenBucketPolicy> global,

    /// Tiers of a host missing from `hosts`.
    @Default(<TokenBucketPolicy>[]) List<TokenBucketPolicy> perHost,

    /// Tiers keyed by bare lowercase host; an empty list opts the host out
    /// of `perHost`.
    @Default(<String, List<TokenBucketPolicy>>{})
    Map<String, List<TokenBucketPolicy>> hosts,

    /// Whether a request with no token, or to a briefly paused host, waits.
    @Default(true) bool queueRequests,

    /// Wait-queue capacity of each host tier, and of each host's pause.
    @Default(50) int maxQueueSize,

    /// Wait-queue capacity of each global tier.
    @Default(500) int maxGlobalQueueSize,

    /// Pause settings.
    @Default(PauseConfig()) PauseConfig pause,
  }) = TokenBucketRateLimitConfig;
}
```

`dart_falconnect/lib/engine/https/config/config.dart`:

```dart
export 'cache_config.dart';
export 'concurrency_config.dart';
export 'http_client_config.dart';
export 'log_config.dart';
export 'pause_config.dart';
export 'performance_config.dart';
export 'rate_limit_config.dart';
export 'retry_config.dart';
```

- [ ] **Step 4: Export the barrel and move `RetryCallback`**

In `dart_falconnect/lib/engine/https/https.dart`, add as the first line:

```dart
export 'config/config.dart';
```

In `dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart`, delete this block (the typedef now lives in `retry_config.dart`, and two exports of one name would clash):

```dart
/// Called before each retry waits.
///
/// [attempt] is 1 for the first retry. The stack trace of the failure is
/// `error.stackTrace`.
typedef RetryCallback = void Function(
  DioException error,
  int attempt,
  Duration delay,
);
```

and add, next to the existing `http_client_config.dart` import:

```dart
import 'package:dart_falconnect/engine/https/config/retry_config.dart';
```

The barrel now exports `HttpClientConfig`, so delete this line from the four test files that also import `package:dart_falconnect/dart_falconnect.dart` (`unnecessary_import` would fail the analyzer): `test/engine/https/interceptors/concurrency_limit_interceptor_test.dart`, `test/engine/https/interceptors/rate_limit_retry_chain_test.dart`, `test/web/compile_smoke.dart`, and `test/web/engine_web_test.dart`.

```dart
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
```

- [ ] **Step 5: Generate code**

Run: `cd dart_falconnect && dart run build_runner build --delete-conflicting-outputs`
Expected: seven new files under `lib/engine/https/config/generated/`.

- [ ] **Step 6: Run the test and the analyzer**

Run: `cd dart_falconnect && dart test test/engine/https/config/feature_boxes_test.dart && dart analyze --fatal-infos && dart test`
Expected: 3 new tests pass; `No issues found!`; the whole suite passes.

- [ ] **Step 7: Commit**

```bash
git commit -m "feat(dart_falconnect): add freezed feature boxes for the client config" -- dart_falconnect/lib/engine/https/config dart_falconnect/lib/engine/https/https.dart dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart dart_falconnect/test/engine/https/config/feature_boxes_test.dart dart_falconnect/test/engine/https/interceptors dart_falconnect/test/web
```

---

### Task 3: The six interceptors take their own box

**Files:**
- Modify: `dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart`, `performance_interceptor.dart`, `retry_interceptor.dart`, `retry_after_pause_interceptor.dart`, `token_bucket_rate_limit_interceptor.dart`, `concurrency_limit_interceptor.dart`
- Create: `dart_falconnect/test/engine/https/interceptors/interceptor_diagnostics_test.dart`
- Modify (migration): every file under `dart_falconnect/test/engine/https/interceptors/` that builds an interceptor, plus `dart_falconnect/test/web/compile_smoke.dart` and `dart_falconnect/test/web/engine_web_test.dart` (constructor calls only; the presets go in Task 4)

**Interfaces:**
- Consumes: the boxes and `RetryCallback` of Task 2.
- Produces, each `config` defaulting to its box built with no arguments and each `logPrint` of type `void Function(String message)?` defaulting to null:
  - `CacheInterceptor({CacheConfig config, logPrint})`
  - `PerformanceInterceptor({PerformanceConfig config, logPrint})`; `maxMetricsHistory` and `collectDetailedTimings` become getters.
  - `RetryInterceptor({RetryConfig config, required Dio dio, logPrint, Random? random})`; `onRetry` moves into `RetryConfig`.
  - `RetryAfterPauseInterceptor({PauseOnlyRateLimitConfig config, logPrint})`
  - `TokenBucketRateLimitInterceptor({TokenBucketRateLimitConfig config, logPrint})`; `queueRequests`, `maxQueueSize`, and `maxGlobalQueueSize` become getters.
  - `ConcurrencyLimitInterceptor({ConcurrencyConfig config, logPrint})`; `global`, `perHost`, `queueRequests`, `maxQueueSize`, and `maxGlobalQueueSize` become getters.
  - No interceptor reads `enableLogging`, `enableCache`, or `enablePerformanceMonitoring` any more.

- [ ] **Step 1: Write the failing test**

Create `dart_falconnect/test/engine/https/interceptors/interceptor_diagnostics_test.dart`:

```dart
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

Dio _dio(List<Reply> script) =>
    Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = ScriptedAdapter(script);

void main() {
  test('RetryInterceptor prints through logPrint', () {
    fakeAsync((async) {
      final lines = <String>[];
      final dio = _dio([reply(500), reply(200)]);
      dio.interceptors.add(
        RetryInterceptor(
          config: const RetryConfig(delay: Duration(milliseconds: 1)),
          dio: dio,
          logPrint: lines.add,
        ),
      );

      dio.get<dynamic>('/x').ignore();
      async.elapse(const Duration(seconds: 1));

      expect(lines, hasLength(1));
      expect(lines.single, startsWith('[RetryInterceptor] Retrying request 1'));
    });
  });

  test('CacheInterceptor prints a hit through logPrint', () async {
    final lines = <String>[];
    final dio = _dio([reply(200)]);
    dio.interceptors.add(CacheInterceptor(logPrint: lines.add));

    await dio.get<dynamic>('/x');
    await dio.get<dynamic>('/x');

    expect(
      lines.where((line) => line.startsWith('[CacheInterceptor] Cache hit')),
      hasLength(1),
    );
  });

  test('an interceptor without logPrint prints nothing', () {
    fakeAsync((async) {
      final dio = _dio([reply(500), reply(200)]);
      dio.interceptors.add(
        RetryInterceptor(
          config: const RetryConfig(delay: Duration(milliseconds: 1)),
          dio: dio,
        ),
      );

      var done = false;
      dio.get<dynamic>('/x').then((_) => done = true).ignore();
      async.elapse(const Duration(seconds: 1));

      expect(done, isTrue);
    });
  });

  test('every config parameter has a default box', () {
    final dio = Dio();

    expect(CacheInterceptor().config, const CacheConfig());
    expect(PerformanceInterceptor().config, const PerformanceConfig());
    expect(RetryInterceptor(dio: dio).config, const RetryConfig());
    expect(ConcurrencyLimitInterceptor().config, const ConcurrencyConfig());
    expect(
      TokenBucketRateLimitInterceptor().config,
      const TokenBucketRateLimitConfig(),
    );
    expect(
      RetryAfterPauseInterceptor().config,
      const PauseOnlyRateLimitConfig(),
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/interceptor_diagnostics_test.dart`
Expected: FAIL to compile with `No named parameter with the name 'logPrint'`.

- [ ] **Step 3: Change the six interceptors**

Apply each diff below to the file it names. The diffs are against the `develop` commit the worktree starts from, after Task 2.

`dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/cache_interceptor.dart
@@ -1,6 +1,6 @@
 import 'dart:convert';
 
-import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
+import 'package:dart_falconnect/engine/https/config/cache_config.dart';
 import 'package:dart_faltool/dart_faltool.dart' show clock;
 import 'package:dio/dio.dart';
 
@@ -40,10 +40,13 @@
 /// timestamps stamped by that zone.
 class CacheInterceptor extends Interceptor {
   /// Creates a new cache interceptor.
-  new({required this.config});
-
-  /// Configuration driving cache behavior (enable flag, duration, size limit).
-  final HttpClientConfig config;
+  new({this.config = const CacheConfig(), this.logPrint});
+
+  /// Cache lifetime and size limit.
+  final CacheConfig config;
+
+  /// Prints diagnostics; null prints nothing.
+  final void Function(String message)? logPrint;
   final Map<String, CacheEntry> _cache = {};
   int _currentCacheSize = 0;
 
@@ -53,7 +56,7 @@
     RequestInterceptorHandler handler,
   ) async {
     // Only cache GET requests
-    if (!config.enableCache || options.method != 'GET') {
+    if (options.method != 'GET') {
       return handler.next(options);
     }
 
@@ -69,14 +72,7 @@
     // Check if we have a valid cached response
     final cachedEntry = _cache[cacheKey];
     if (cachedEntry != null && !cachedEntry.isExpired) {
-      if (config.enableLogging) {
-        // Intentional logging for cache diagnostics.
-        // ignore: avoid_print
-        print(
-          '[CacheInterceptor] Cache hit for: '
-          '${options.method} ${options.uri}',
-        );
-      }
+      _log('Cache hit for: ${options.method} ${options.uri}');
 
       // Return cached response
       return handler.resolve(cachedEntry.response);
@@ -97,8 +93,7 @@
     ResponseInterceptorHandler handler,
   ) {
     // Only cache successful GET requests
-    if (!config.enableCache ||
-        response.requestOptions.method != 'GET' ||
+    if (response.requestOptions.method != 'GET' ||
         response.statusCode == null ||
         response.statusCode! < 200 ||
         response.statusCode! >= 300) {
@@ -193,7 +188,7 @@
     }
 
     // Use default from config
-    return config.cacheDuration;
+    return config.duration;
   }
 
   /// Adds a response to the cache.
@@ -207,7 +202,7 @@
     final responseSize = _estimateResponseSize(response);
 
     // Check if adding this would exceed cache size
-    if (_currentCacheSize + responseSize > config.maxCacheSize) {
+    if (_currentCacheSize + responseSize > config.maxSize) {
       _evictOldestEntries(responseSize);
     }
 
@@ -219,17 +214,13 @@
     );
     _currentCacheSize += responseSize;
 
-    if (config.enableLogging) {
-      // Intentional logging for cache diagnostics.
-      // ignore: avoid_print
-      print(
-        '[CacheInterceptor] Cached response for: '
-        '${response.requestOptions.method} '
-        '${response.requestOptions.uri} '
-        '(${responseSize ~/ 1024}KB, '
-        'expires in ${maxAge.inSeconds}s)',
-      );
-    }
+    _log(
+      'Cached response for: '
+      '${response.requestOptions.method} '
+      '${response.requestOptions.uri} '
+      '(${responseSize ~/ 1024}KB, '
+      'expires in ${maxAge.inSeconds}s)',
+    );
   }
 
   /// Removes an entry from the cache.
@@ -248,7 +239,7 @@
 
     // Remove entries until we have enough space
     for (final entry in sortedEntries) {
-      if (_currentCacheSize + requiredSize <= config.maxCacheSize) {
+      if (_currentCacheSize + requiredSize <= config.maxSize) {
         break;
       }
       _removeFromCache(entry.key);
@@ -289,6 +280,8 @@
     return size;
   }
 
+  void _log(String message) => logPrint?.call('[CacheInterceptor] $message');
+
   /// Clears the entire cache.
   void clearCache() {
     _cache.clear();
```

`dart_falconnect/lib/engine/https/interceptors/performance_interceptor.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/performance_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/performance_interceptor.dart
@@ -1,6 +1,6 @@
 import 'dart:collection';
 
-import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
+import 'package:dart_falconnect/engine/https/config/performance_config.dart';
 import 'package:dart_faltool/dart_faltool.dart' show clock;
 import 'package:dio/dio.dart';
 
@@ -245,20 +245,19 @@
 /// each request and provides aggregated statistics.
 class PerformanceInterceptor extends Interceptor {
   /// Creates a new performance interceptor.
-  new({
-    required this.config,
-    this.maxMetricsHistory = 1000,
-    this.collectDetailedTimings = true,
-  });
-
-  /// Configuration driving monitoring behavior (enable flag, logging).
-  final HttpClientConfig config;
+  new({this.config = const PerformanceConfig(), this.logPrint});
+
+  /// History size and timing detail.
+  final PerformanceConfig config;
+
+  /// Prints diagnostics; null prints nothing.
+  final void Function(String message)? logPrint;
 
   /// Maximum number of detailed metrics to keep in memory.
-  final int maxMetricsHistory;
+  int get maxMetricsHistory => config.maxMetricsHistory;
 
   /// Whether to collect detailed timing information.
-  final bool collectDetailedTimings;
+  bool get collectDetailedTimings => config.collectDetailedTimings;
 
   /// Recent request metrics.
   final Queue<RequestMetrics> _metricsHistory = Queue<RequestMetrics>();
@@ -271,10 +270,6 @@
 
   @override
   void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
-    if (!config.enablePerformanceMonitoring) {
-      return handler.next(options);
-    }
-
     // Create metrics for this request
     final metrics =
         RequestMetrics(
@@ -296,10 +291,6 @@
     Response<dynamic> response,
     ResponseInterceptorHandler handler,
   ) {
-    if (!config.enablePerformanceMonitoring) {
-      return handler.next(response);
-    }
-
     // Get metrics from request
     final metrics =
         response.requestOptions.extra['performanceMetrics'] as RequestMetrics?;
@@ -317,27 +308,18 @@
     // Add to history and statistics
     _addMetrics(metrics);
 
-    if (config.enableLogging) {
-      // Intentional logging for performance diagnostics.
-      // ignore: avoid_print
-      print(
-        '[PerformanceInterceptor] '
-        '${metrics.method} ${metrics.url} - '
-        '${metrics.totalDuration.inMilliseconds}ms, '
-        'status: ${metrics.statusCode}, '
-        'response: ${metrics.responseSize} bytes',
-      );
-    }
+    _log(
+      '${metrics.method} ${metrics.url} - '
+      '${metrics.totalDuration.inMilliseconds}ms, '
+      'status: ${metrics.statusCode}, '
+      'response: ${metrics.responseSize} bytes',
+    );
 
     handler.next(response);
   }
 
   @override
   void onError(DioException err, ErrorInterceptorHandler handler) {
-    if (!config.enablePerformanceMonitoring) {
-      return handler.next(err);
-    }
-
     // Get metrics from request
     final metrics =
         err.requestOptions.extra['performanceMetrics'] as RequestMetrics?;
@@ -358,20 +340,18 @@
     // Add to history and statistics
     _addMetrics(metrics);
 
-    if (config.enableLogging) {
-      // Intentional logging for performance diagnostics.
-      // ignore: avoid_print
-      print(
-        '[PerformanceInterceptor] '
-        '${metrics.method} ${metrics.url} - '
-        'FAILED: '
-        '${metrics.totalDuration.inMilliseconds}ms, '
-        'error: ${metrics.error}',
-      );
-    }
+    _log(
+      '${metrics.method} ${metrics.url} - '
+      'FAILED: '
+      '${metrics.totalDuration.inMilliseconds}ms, '
+      'error: ${metrics.error}',
+    );
 
     handler.next(err);
   }
+
+  void _log(String message) =>
+      logPrint?.call('[PerformanceInterceptor] $message');
 
   /// Adds metrics to history and updates statistics.
   void _addMetrics(RequestMetrics metrics) {
```

`dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart
@@ -1,7 +1,6 @@
 import 'dart:async';
 import 'dart:math';
 
-import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
 import 'package:dart_falconnect/engine/https/config/retry_config.dart';
 import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
 import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
@@ -21,7 +20,7 @@
   set disableRetry(bool value) => extra = {...extra, _disableKey: value};
 
   /// Most retries for this request; null uses
-  /// `HttpClientConfig.maxRetryAttempts`.
+  /// `RetryConfig.maxAttempts`.
   int? get retryAttempts => extra[_attemptsKey] as int?;
   set retryAttempts(int? value) =>
       extra = {...extra, _attemptsKey: _checkAttempts(value)};
@@ -43,7 +42,7 @@
   set disableRetry(bool value) => extra = {...?extra, _disableKey: value};
 
   /// Most retries for this request; null uses
-  /// `HttpClientConfig.maxRetryAttempts`.
+  /// `RetryConfig.maxAttempts`.
   int? get retryAttempts => extra?[_attemptsKey] as int?;
   set retryAttempts(int? value) =>
       extra = {...?extra, _attemptsKey: _checkAttempts(value)};
@@ -91,18 +90,21 @@
   /// Creates a retry interceptor.
   ///
   /// [random] drives the backoff jitter; tests pass a seeded one.
-  new({required this.config, required this.dio, this.onRetry, Random? random})
-    : _random = random ?? Random();
-
-  /// Configuration: `maxRetryAttempts`, `retryDelay`, `maxRetryDelay`,
-  /// `maxRetryDuration`, and `enableLogging`.
-  final HttpClientConfig config;
+  new({
+    this.config = const RetryConfig(),
+    required this.dio,
+    this.logPrint,
+    Random? random,
+  }) : _random = random ?? Random();
+
+  /// Attempts, delays, deadline, and the `onRetry` callback.
+  final RetryConfig config;
 
   /// The [Dio] instance that sends every retry.
   final Dio dio;
 
-  /// Called before each retry waits.
-  final RetryCallback? onRetry;
+  /// Prints diagnostics; null prints nothing.
+  final void Function(String message)? logPrint;
 
   final Random _random;
 
@@ -142,7 +144,7 @@
         handler.next(current);
         return;
       }
-      onRetry?.call(current, attempt, delay);
+      config.onRetry?.call(current, attempt, delay);
       _log(
         'Retrying request $attempt after ${delay.inMilliseconds}ms: '
         '${original.method} ${original.uri}',
@@ -182,14 +184,14 @@
         : null;
     final Duration delay;
     if (retryAfter != null) {
-      if (retryAfter > config.maxRetryDelay) {
+      if (retryAfter > config.maxDelay) {
         return null;
       }
       delay = retryAfter;
     } else {
       delay = _backoff(attempt);
     }
-    if (elapsed + delay > config.maxRetryDuration) {
+    if (elapsed + delay > config.maxDuration) {
       return null;
     }
     return delay;
@@ -206,7 +208,7 @@
         err.type == DioExceptionType.badCertificate) {
       return false;
     }
-    if (attempt > (options.retryAttempts ?? config.maxRetryAttempts)) {
+    if (attempt > (options.retryAttempts ?? config.maxAttempts)) {
       return false;
     }
     final status = response?.statusCode;
@@ -228,10 +230,10 @@
   Duration _backoff(int attempt) {
     // Doubles never wrap, and 2^30 keeps the result exact on the web.
     final exponential =
-        config.retryDelay.inMilliseconds * pow(2.0, min(attempt - 1, 30));
+        config.delay.inMilliseconds * pow(2.0, min(attempt - 1, 30));
     final cap = max(
       0,
-      min(config.maxRetryDelay.inMilliseconds, exponential).toInt(),
+      min(config.maxDelay.inMilliseconds, exponential).toInt(),
     );
     return Duration(
       milliseconds: _random.nextInt(min(cap + 1, _maxRandomRange)),
@@ -266,11 +268,5 @@
     );
   }
 
-  void _log(String message) {
-    if (config.enableLogging) {
-      // Intentional logging for retry diagnostics.
-      // ignore: avoid_print
-      print('[RetryInterceptor] $message');
-    }
-  }
-}
+  void _log(String message) => logPrint?.call('[RetryInterceptor] $message');
+}
```

`dart_falconnect/lib/engine/https/interceptors/retry_after_pause_interceptor.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/retry_after_pause_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/retry_after_pause_interceptor.dart
@@ -1,4 +1,4 @@
-import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
+import 'package:dart_falconnect/engine/https/config/rate_limit_config.dart';
 import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart';
 import 'package:dio/dio.dart';
 
@@ -22,18 +22,13 @@
 /// which stops the error chain.
 class RetryAfterPauseInterceptor extends Interceptor {
   /// Creates a pause-only interceptor.
-  new({
-    required this.config,
-    Duration maxPauseWait = const Duration(seconds: 10),
-    Duration maxPause = const Duration(minutes: 10),
-    Duration? defaultPause = const Duration(seconds: 5),
-    int maxQueueSize = 50,
-  }) : _pause = _buildPause(
-         maxPauseWait: maxPauseWait,
-         maxPause: maxPause,
-         defaultPause: defaultPause,
-         maxQueueSize: maxQueueSize,
-       );
+  new({this.config = const PauseOnlyRateLimitConfig(), this.logPrint})
+    : _pause = _buildPause(
+        maxPauseWait: config.pause.maxPauseWait,
+        maxPause: config.pause.maxPause,
+        defaultPause: config.pause.defaultPause,
+        maxQueueSize: config.maxQueueSize,
+      );
 
   /// Builds the pause core, reporting a negative queue size under its
   /// public name before the core's own check can.
@@ -59,8 +54,11 @@
     );
   }
 
-  /// Configuration; `enableLogging` gates diagnostic prints.
-  final HttpClientConfig config;
+  /// Pause settings and hold-queue size.
+  final PauseOnlyRateLimitConfig config;
+
+  /// Prints diagnostics; null prints nothing.
+  final void Function(String message)? logPrint;
 
   final RetryAfterPause _pause;
 
@@ -122,11 +120,6 @@
   /// without a pause. Calling it again has no effect.
   void dispose() => _pause.dispose();
 
-  void _log(String message) {
-    if (config.enableLogging) {
-      // Intentional logging for pause diagnostics.
-      // ignore: avoid_print
-      print('[RetryAfterPauseInterceptor] $message');
-    }
-  }
+  void _log(String message) =>
+      logPrint?.call('[RetryAfterPauseInterceptor] $message');
 }
```

`dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart
@@ -1,4 +1,4 @@
-import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
+import 'package:dart_falconnect/engine/https/config/rate_limit_config.dart';
 import 'package:dart_falconnect/src/engine/https/interceptors/host_key.dart';
 import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart';
 import 'package:dart_faltool/dart_faltool.dart'
@@ -89,38 +89,30 @@
 class TokenBucketRateLimitInterceptor extends Interceptor {
   /// Creates a token bucket rate limit interceptor.
   ///
-  /// Each key of [hosts] must be a bare host exactly as `Uri.host` returns
-  /// it: lowercase, with no port, brackets, or spaces.
-  new({
-    required this.config,
-    List<TokenBucketPolicy> global = const [],
-    List<TokenBucketPolicy> perHost = const [],
-    Map<String, List<TokenBucketPolicy>> hosts = const {},
-    this.queueRequests = true,
-    this.maxQueueSize = 50,
-    this.maxGlobalQueueSize = 500,
-    Duration maxPauseWait = const Duration(seconds: 10),
-    Duration maxPause = const Duration(minutes: 10),
-    Duration? defaultPause = const Duration(seconds: 5),
-  }) : _perHost = List.unmodifiable(perHost),
-       _hosts = Map.unmodifiable({
-         for (final entry in hosts.entries)
-           entry.key: List<TokenBucketPolicy>.unmodifiable(entry.value),
-       }),
-       _globalLimiters = [
-         for (final policy in global)
-           policy.toRateLimiter(
-             maxQueueLength: queueRequests ? maxGlobalQueueSize : 0,
-           ),
-       ],
-       _pause = _buildPause(
-         maxPauseWait: maxPauseWait,
-         maxPause: maxPause,
-         defaultPause: defaultPause,
-         maxQueueSize: maxQueueSize,
-         holdRequests: queueRequests,
-       ) {
-    for (final host in hosts.keys) {
+  /// Each key of `config.hosts` must be a bare host exactly as `Uri.host`
+  /// returns it: lowercase, with no port, brackets, or spaces.
+  new({this.config = const TokenBucketRateLimitConfig(), this.logPrint})
+    : _perHost = List.unmodifiable(config.perHost),
+      _hosts = Map.unmodifiable({
+        for (final entry in config.hosts.entries)
+          entry.key: List<TokenBucketPolicy>.unmodifiable(entry.value),
+      }),
+      _globalLimiters = [
+        for (final policy in config.global)
+          policy.toRateLimiter(
+            maxQueueLength: config.queueRequests
+                ? config.maxGlobalQueueSize
+                : 0,
+          ),
+      ],
+      _pause = _buildPause(
+        maxPauseWait: config.pause.maxPauseWait,
+        maxPause: config.pause.maxPause,
+        defaultPause: config.pause.defaultPause,
+        maxQueueSize: config.maxQueueSize,
+        holdRequests: config.queueRequests,
+      ) {
+    for (final host in config.hosts.keys) {
       if (!isHostKey(host)) {
         throw ArgumentError.value(
           host,
@@ -129,23 +121,29 @@
         );
       }
     }
-    for (final policy in [...perHost, ...hosts.values.expand((p) => p)]) {
+    for (final policy in [
+      ...config.perHost,
+      ...config.hosts.values.expand((p) => p),
+    ]) {
       policy.validate();
     }
   }
 
-  /// Configuration; `enableLogging` gates diagnostic prints.
-  final HttpClientConfig config;
+  /// Policies, queue sizes, and pause settings.
+  final TokenBucketRateLimitConfig config;
+
+  /// Prints diagnostics; null prints nothing.
+  final void Function(String message)? logPrint;
 
   /// Whether a request with no token, or to a briefly paused host, waits
   /// (`true`) or is rejected.
-  final bool queueRequests;
+  bool get queueRequests => config.queueRequests;
 
   /// Wait-queue capacity of each host tier, and of each host's pause.
-  final int maxQueueSize;
+  int get maxQueueSize => config.maxQueueSize;
 
   /// Wait-queue capacity of each global tier.
-  final int maxGlobalQueueSize;
+  int get maxGlobalQueueSize => config.maxGlobalQueueSize;
 
   final List<TokenBucketPolicy> _perHost;
   final Map<String, List<TokenBucketPolicy>> _hosts;
@@ -337,11 +335,6 @@
     message: message,
   );
 
-  void _log(String message) {
-    if (config.enableLogging) {
-      // Intentional logging for rate limit diagnostics.
-      // ignore: avoid_print
-      print('[TokenBucketRateLimitInterceptor] $message');
-    }
-  }
+  void _log(String message) =>
+      logPrint?.call('[TokenBucketRateLimitInterceptor] $message');
 }
```

`dart_falconnect/lib/engine/https/interceptors/concurrency_limit_interceptor.dart`:

```diff
--- a/dart_falconnect/lib/engine/https/interceptors/concurrency_limit_interceptor.dart
+++ b/dart_falconnect/lib/engine/https/interceptors/concurrency_limit_interceptor.dart
@@ -1,6 +1,6 @@
 import 'dart:async';
 
-import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
+import 'package:dart_falconnect/engine/https/config/concurrency_config.dart';
 import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
 import 'package:dart_falconnect/src/engine/https/interceptors/host_key.dart';
 import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart'
@@ -89,49 +89,45 @@
 class ConcurrencyLimitInterceptor extends Interceptor {
   /// Creates a concurrency limit interceptor.
   ///
-  /// Each key of [hosts] must be a bare host exactly as `Uri.host` returns
-  /// it: lowercase, with no port, brackets, or spaces. Every limit that is
-  /// set must be at least 1; queue sizes must not be negative.
-  new({
-    required this.config,
-    this.global,
-    this.perHost,
-    Map<String, int?> hosts = const {},
-    this.queueRequests = true,
-    this.maxQueueSize = 50,
-    this.maxGlobalQueueSize = 500,
-  }) : _hosts = _validated(
-         global: global,
-         perHost: perHost,
-         hosts: hosts,
-         maxQueueSize: maxQueueSize,
-         maxGlobalQueueSize: maxGlobalQueueSize,
-       ),
-       _globalBulkhead = global == null
-           ? null
-           : Bulkhead(
-               maxConcurrent: global,
-               maxQueued: queueRequests ? maxGlobalQueueSize : 0,
-             );
-
-  /// Configuration; `enableLogging` gates diagnostic prints.
-  final HttpClientConfig config;
+  /// Each key of `config.hosts` must be a bare host exactly as `Uri.host`
+  /// returns it: lowercase, with no port, brackets, or spaces. Every limit
+  /// that is set must be at least 1; queue sizes must not be negative.
+  new({this.config = const ConcurrencyConfig(), this.logPrint})
+    : _hosts = _validated(
+        global: config.global,
+        perHost: config.perHost,
+        hosts: config.hosts,
+        maxQueueSize: config.maxQueueSize,
+        maxGlobalQueueSize: config.maxGlobalQueueSize,
+      ),
+      _globalBulkhead = config.global == null
+          ? null
+          : Bulkhead(
+              maxConcurrent: config.global!,
+              maxQueued: config.queueRequests ? config.maxGlobalQueueSize : 0,
+            );
+
+  /// Limits and queue sizes.
+  final ConcurrencyConfig config;
+
+  /// Prints diagnostics; null prints nothing.
+  final void Function(String message)? logPrint;
 
   /// Most requests in flight to all hosts together; null means no limit.
-  final int? global;
+  int? get global => config.global;
 
   /// Most requests in flight to a host missing from `hosts`; null means no
   /// limit.
-  final int? perHost;
+  int? get perHost => config.perHost;
 
   /// Whether a request with no free slot waits (`true`) or is rejected.
-  final bool queueRequests;
+  bool get queueRequests => config.queueRequests;
 
   /// Queue capacity of each host limit.
-  final int maxQueueSize;
+  int get maxQueueSize => config.maxQueueSize;
 
   /// Queue capacity of the global limit.
-  final int maxGlobalQueueSize;
+  int get maxGlobalQueueSize => config.maxGlobalQueueSize;
 
   /// Gives every instance its own `extra` key, so two instances in one
   /// chain never overwrite each other's permit.
@@ -367,13 +363,8 @@
     message: message,
   );
 
-  void _log(String message) {
-    if (config.enableLogging) {
-      // Intentional logging for concurrency limit diagnostics.
-      // ignore: avoid_print
-      print('[ConcurrencyLimitInterceptor] $message');
-    }
-  }
+  void _log(String message) =>
+      logPrint?.call('[ConcurrencyLimitInterceptor] $message');
 }
 
 /// A host's own limit, taken before the global one.
```

- [ ] **Step 4: Run the new test**

Run: `cd dart_falconnect && dart format lib && dart test test/engine/https/interceptors/interceptor_diagnostics_test.dart`
Expected: all tests pass.

- [ ] **Step 5: Migrate the existing tests**

`dart analyze test` now lists every call site to change (about 210 errors). Apply these rules until it reports none:

| Old call | New call |
|---|---|
| `TokenBucketRateLimitInterceptor(config: X, global: g, perHost: p, hosts: h, queueRequests: q, maxQueueSize: m, maxGlobalQueueSize: mg, maxPauseWait: w, maxPause: mp, defaultPause: d)` | `TokenBucketRateLimitInterceptor(config: TokenBucketRateLimitConfig(global: g, perHost: p, hosts: h, queueRequests: q, maxQueueSize: m, maxGlobalQueueSize: mg, pause: PauseConfig(maxPauseWait: w, maxPause: mp, defaultPause: d)))`, keeping only the arguments the old call passed |
| `RetryAfterPauseInterceptor(config: X, maxPauseWait: w, maxPause: mp, defaultPause: d, maxQueueSize: m)` | `RetryAfterPauseInterceptor(config: PauseOnlyRateLimitConfig(pause: PauseConfig(maxPauseWait: w, maxPause: mp, defaultPause: d), maxQueueSize: m))` |
| `ConcurrencyLimitInterceptor(config: X, global: g, perHost: p, hosts: h, queueRequests: q, maxQueueSize: m, maxGlobalQueueSize: mg)` | `ConcurrencyLimitInterceptor(config: ConcurrencyConfig(global: g, perHost: p, hosts: h, queueRequests: q, maxQueueSize: m, maxGlobalQueueSize: mg))` |
| `RetryInterceptor(config: X, dio: d, onRetry: cb, random: r)` | `RetryInterceptor(config: RetryConfig(maxAttempts: X.maxRetryAttempts, delay: X.retryDelay, maxDelay: X.maxRetryDelay, maxDuration: X.maxRetryDuration, onRetry: cb), dio: d, random: r)` |
| `CacheInterceptor(config: X)` | `CacheInterceptor()` |
| `PerformanceInterceptor(config: X)` | `PerformanceInterceptor()` |
| a shared `const _config = HttpClientConfig(maxRetryAttempts: a, retryDelay: b, maxRetryDelay: c, maxRetryDuration: e)` | `const _retry = RetryConfig(maxAttempts: a, delay: b, maxDelay: c, maxDuration: e)`, and each helper parameter typed `HttpClientConfig` becomes `RetryConfig` |
| a shared `HttpClientConfig` passed only to the limiters | delete it |
| `import 'package:dart_falconnect/engine/https/config/http_client_config.dart';` in a test that imports interceptor files directly (the retry, pause, and token bucket tests) | the box file it uses: `config/retry_config.dart`, `config/rate_limit_config.dart`, or `config/config.dart` |
| `final cfg = HttpClientConfig.development();` in `test/web/compile_smoke.dart` and `test/web/engine_web_test.dart` | delete it once no interceptor reads it; leave the three preset lines and the preset test for Task 4 |
| `HttpClientConfig.test()` passed to a retry helper | `RetryConfig(maxAttempts: 0)`, the preset's retry setting; rename the test to say so |

Keep `const` wherever every argument is constant; drop it where a `TokenBucketPolicy` or a variable is not. Representative call sites, verified in the prototype:

#### 1. Token bucket (config box absorbs named params; pause moves into PauseConfig)

Before — `token_bucket_rate_limit_interceptor_test.dart`, "rejects invalid pause settings":

```dart
() => TokenBucketRateLimitInterceptor(
  config: _config,
  maxPause: Duration.zero,
),
```

After:

```dart
() => TokenBucketRateLimitInterceptor(
  config: const TokenBucketRateLimitConfig(
    pause: PauseConfig(maxPause: Duration.zero),
  ),
),
```

#### 2. Concurrency limit (all named params fold into ConcurrencyConfig)

Before — `concurrency_limit_interceptor_test.dart`, "hosts overrides perHost":

```dart
final limiter = ConcurrencyLimitInterceptor(
  config: _config,
  perHost: 1,
  hosts: {'b.test': 2, 'c.test': null},
);
```

After:

```dart
final limiter = ConcurrencyLimitInterceptor(
  config: const ConcurrencyConfig(
    perHost: 1,
    hosts: {'b.test': 2, 'c.test': null},
  ),
);
```

#### 3. Retry (HttpClientConfig retry fields become RetryConfig; onRetry moves in; dio/random stay on the interceptor)

Before — `retry_interceptor_test.dart`, `_Client`:

```dart
const _config = HttpClientConfig(
  maxRetryAttempts: 3,
  retryDelay: Duration(seconds: 1),
  maxRetryDelay: Duration(seconds: 30),
  maxRetryDuration: Duration(seconds: 60),
);
// ...
RetryInterceptor(
  config: config,
  dio: dio,
  random: Random(7),
  onRetry: (error, attempt, delay) { ... },
),
```

After:

```dart
const _config = RetryConfig(
  maxAttempts: 3,
  delay: Duration(seconds: 1),
  maxDelay: Duration(seconds: 30),
  maxDuration: Duration(seconds: 60),
);
// ...
RetryInterceptor(
  config: RetryConfig(
    maxAttempts: config.maxAttempts,
    delay: config.delay,
    maxDelay: config.maxDelay,
    maxDuration: config.maxDuration,
    onRetry: (error, attempt, delay) { ... },
  ),
  dio: dio,
  random: Random(7),
),
```

- [ ] **Step 6: Run the package tests**

Run: `cd dart_falconnect && dart format test && dart analyze --fatal-infos && dart test`
Expected: `No issues found!`; all tests pass.

- [ ] **Step 7: Commit**

```bash
git commit -m "refactor(dart_falconnect)!: give each interceptor its own config box and a logPrint" -- dart_falconnect/lib/engine/https/interceptors dart_falconnect/test/engine/https/interceptors dart_falconnect/test/web
```

---

### Task 4: `HttpClientConfig` becomes the freezed client config

**Files:**
- Modify: `dart_falconnect/lib/engine/https/config/http_client_config.dart` (whole file)
- Create (generated): `dart_falconnect/lib/engine/https/config/generated/http_client_config.freezed.dart`
- Modify: `dart_falconnect/test/web/compile_smoke.dart`, `dart_falconnect/test/web/engine_web_test.dart` (remove the presets)
- Test: `dart_falconnect/test/engine/https/config/http_client_config_test.dart`

**Interfaces:**
- Consumes: the boxes (Task 2) and `NetworkExceptionHandlerInterceptor`.
- Produces: freezed `HttpClientConfig` with the fields and defaults of spec section 3; `Map<String, String> get effectiveHeaders`; `void applyTo(Dio dio)`. The presets, `defaultHeaders`, and every flat feature field are gone.

- [ ] **Step 1: Write the failing test**

Create `dart_falconnect/test/engine/https/config/http_client_config_test.dart`:

```dart
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

bool _acceptAll(int? status) => true;

void main() {
  test('defaults reproduce the options of DefaultHttpClient', () {
    const config = HttpClientConfig();

    expect(config.baseUrl, '');
    expect(config.connectTimeout, const Duration(seconds: 20));
    expect(config.receiveTimeout, const Duration(seconds: 20));
    expect(config.sendTimeout, isNull);
    expect(config.contentType, Headers.jsonContentType);
    expect(config.headers, isEmpty);
    expect(config.validateStatus, isNull);
    expect(config.rateLimit, const RateLimitConfig.none());
    expect(config.log, isNull);
    expect(config.performance, isNull);
    expect(config.cache, isNull);
    expect(config.concurrency, isNull);
    expect(config.retry, isNull);
    expect(config.interceptors, isEmpty);
    expect(config.exceptionHandler, isNull);
  });

  test('copyWith turns a box off with null', () {
    const config = HttpClientConfig(log: LogConfig(), retry: RetryConfig());

    final quiet = config.copyWith(log: null);

    expect(quiet.log, isNull);
    expect(quiet.retry, const RetryConfig());
  });

  test('effectiveHeaders adds User-Agent when set', () {
    const config = HttpClientConfig(
      headers: {'X-A': '1'},
      userAgent: 'falcon/2',
    );

    expect(config.effectiveHeaders, {'X-A': '1', 'User-Agent': 'falcon/2'});
    expect(const HttpClientConfig().effectiveHeaders, isEmpty);
  });

  test('applyTo writes the owned fields and leaves the others', () {
    final dio = Dio(
      BaseOptions(headers: {'X-Old': 'kept'}, responseType: ResponseType.plain),
    );
    final validate = dio.options.validateStatus;

    const HttpClientConfig(
      baseUrl: 'https://a.test',
      sendTimeout: Duration(seconds: 3),
      headers: {'X-New': '1'},
      maxRedirects: 2,
    ).applyTo(dio);

    expect(dio.options.baseUrl, 'https://a.test');
    expect(dio.options.sendTimeout, const Duration(seconds: 3));
    expect(dio.options.maxRedirects, 2);
    expect(dio.options.contentType, Headers.jsonContentType);
    expect(dio.options.headers['X-Old'], 'kept');
    expect(dio.options.headers['X-New'], '1');
    expect(dio.options.responseType, ResponseType.plain);
    expect(dio.options.validateStatus, same(validate));
  });

  test('applyTo writes validateStatus when it is set', () {
    final dio = Dio();

    const HttpClientConfig(validateStatus: _acceptAll).applyTo(dio);

    expect(dio.options.validateStatus(404), isTrue);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd dart_falconnect && dart test test/engine/https/config/http_client_config_test.dart`
Expected: FAIL to compile with `No named parameter with the name 'log'`.

- [ ] **Step 3: Replace the class**

Replace the whole of `dart_falconnect/lib/engine/https/config/http_client_config.dart` with:

```dart
import 'package:dart_falconnect/engine/https/config/cache_config.dart';
import 'package:dart_falconnect/engine/https/config/concurrency_config.dart';
import 'package:dart_falconnect/engine/https/config/log_config.dart';
import 'package:dart_falconnect/engine/https/config/performance_config.dart';
import 'package:dart_falconnect/engine/https/config/rate_limit_config.dart';
import 'package:dart_falconnect/engine/https/config/retry_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/network_exception_handler_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/http_client_config.freezed.dart';

/// Configuration of a `BaseHttpClient`: the dio options it owns and one box
/// per feature. A null box turns its feature off.
@freezed
abstract class HttpClientConfig with _$HttpClientConfig {
  /// Creates a configuration. The defaults reproduce the options and chain
  /// of `DefaultHttpClient` before configuration existed.
  const factory({
    /// Base URL of every request.
    @Default('') String baseUrl,

    /// Timeout for opening a connection.
    @Default(Duration(seconds: 20)) Duration connectTimeout,

    /// Timeout between two received chunks.
    @Default(Duration(seconds: 20)) Duration receiveTimeout,

    /// Timeout for sending the body; null means no limit.
    Duration? sendTimeout,

    /// Default `Content-Type`.
    @Default(Headers.jsonContentType) String contentType,

    /// Default headers the configuration owns.
    @Default(<String, String>{}) Map<String, String> headers,

    /// `User-Agent` header; null leaves it unset.
    String? userAgent,

    /// Whether dio follows redirects.
    @Default(true) bool followRedirects,

    /// Most redirects followed.
    @Default(5) int maxRedirects,

    /// Which statuses succeed; null keeps dio's default, 2xx only.
    ValidateStatus? validateStatus,

    /// HTTP logging; null turns it off.
    LogConfig? log,

    /// Performance monitoring; null turns it off.
    PerformanceConfig? performance,

    /// Response cache; null turns it off.
    CacheConfig? cache,

    /// Concurrency limit; null turns it off.
    ConcurrencyConfig? concurrency,

    /// Rate limit and `Retry-After` pause.
    @Default(RateLimitConfig.none()) RateLimitConfig rateLimit,

    /// Retry; null turns it off.
    RetryConfig? retry,

    /// The app's own interceptors, placed first in the chain.
    @Default(<Interceptor>[]) List<Interceptor> interceptors,

    /// Last interceptor of the chain; null means
    /// `DefaultNetworkExceptionHandlerInterceptor`.
    NetworkExceptionHandlerInterceptor? exceptionHandler,
  }) = _HttpClientConfig;

  const new _();

  /// [headers] plus `User-Agent` when [userAgent] is set.
  Map<String, String> get effectiveHeaders => {
    ...headers,
    'User-Agent': ?userAgent,
  };

  /// Writes the options this configuration owns onto `dio.options` and
  /// merges [effectiveHeaders] into its header map. Other fields are left
  /// alone; `validateStatus` is written only when it is not null.
  void applyTo(Dio dio) {
    final options = dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = connectTimeout
      ..receiveTimeout = receiveTimeout
      ..sendTimeout = sendTimeout
      ..contentType = contentType
      ..followRedirects = followRedirects
      ..maxRedirects = maxRedirects;
    if (validateStatus != null) {
      options.validateStatus = validateStatus!;
    }
    options.headers.addAll(effectiveHeaders);
  }
}
```

- [ ] **Step 4: Generate code and remove the presets from the web tests**

Run: `cd dart_falconnect && dart run build_runner build --delete-conflicting-outputs`

In `test/web/compile_smoke.dart`, replace the three preset lines and their comment:

```dart
  // HTTP config factories
  _sink(HttpClientConfig.production());
  _sink(HttpClientConfig.development());
  _sink(HttpClientConfig.test());
```

with:

```dart
  // HTTP config
  _sink(const HttpClientConfig(retry: RetryConfig()));
```

In `test/web/engine_web_test.dart`, replace the test `HttpClientConfig factories build without throwing` with:

```dart
    test('HttpClientConfig builds with every box set', () {
      expect(
        const HttpClientConfig(
          log: LogConfig(),
          performance: PerformanceConfig(),
          cache: CacheConfig(),
          concurrency: ConcurrencyConfig(global: 16, perHost: 4),
          rateLimit: RateLimitConfig.tokenBucket(),
          retry: RetryConfig(),
        ),
        isNotNull,
      );
    });
```

- [ ] **Step 5: Run the tests, the analyzer, and the web compile**

Run: `cd dart_falconnect && dart format lib test && dart analyze --fatal-infos && dart test && dart compile js test/web/compile_smoke.dart -o /tmp/compile_smoke.js`
Expected: `No issues found!`; all tests pass; `dart compile js` exits 0.

- [ ] **Step 6: Commit**

```bash
git commit -m "refactor(dart_falconnect)!: restructure HttpClientConfig into freezed feature boxes" -- dart_falconnect/lib/engine/https/config dart_falconnect/test/engine/https/config/http_client_config_test.dart dart_falconnect/test/web
```

---

### Task 5: Fix response mapping and error recovery

**Files:**
- Modify: `dart_falconnect/lib/engine/https/extensions/response_extensions.dart` (whole file)
- Test: `dart_falconnect/test/engine/https/extensions/response_extensions_test.dart`

**Interfaces:**
- Consumes: `CommonException` and `InputErrorType` (dart_falmodel), `JsonRpcResponse`, retrofit `HttpResponse`.
- Produces: `mapJson` that throws `DioException(error: CommonException(type: InputErrorType.invalidFormat))` for a non-object body or a throwing converter; `catchWhenError` on `Future<Response<T>>`, `Future<JsonRpcResponse<RESULT>>`, and `Future<HttpResponse<T>>` that rethrows on a null fallback and recovers when the error has no response; `transformData` and `copyWith` on a null `Response` throw `StateError`.

- [ ] **Step 1: Write the failing tests**

Create `dart_falconnect/test/engine/https/extensions/response_extensions_test.dart`:

```dart
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:test/test.dart';

final _options = RequestOptions(
  path: '/rpc',
  data: const {'jsonrpc': '2.0', 'method': 'm', 'id': 7},
);

DioException _withResponse() => DioException(
  requestOptions: _options,
  response: Response<dynamic>(requestOptions: _options, statusCode: 500),
  type: DioExceptionType.badResponse,
);

DioException _withoutResponse() => DioException(
  requestOptions: _options,
  type: DioExceptionType.connectionError,
);

class _Result extends JsonRpcResult {
  const new(this.value);

  final String value;
}

void main() {
  group('catchWhenError on Future<Response<T>>', () {
    test('rethrows when no fallback is given', () {
      final future = Future<Response<String>>.error(_withResponse());

      expect(future.catchWhenError(null), throwsA(isA<DioException>()));
    });

    test('rethrows when the fallback returns null', () {
      final future = Future<Response<String>>.error(_withResponse());

      expect(
        future.catchWhenError((e, st) => null),
        throwsA(isA<DioException>()),
      );
    });

    test('rethrows an error that is not a DioException', () {
      final future = Future<Response<String>>.error(StateError('x'));

      expect(
        future.catchWhenError((e, st) => 'fallback'),
        throwsA(isA<StateError>()),
      );
    });

    test('resolves with the error response carrying the fallback', () async {
      final future = Future<Response<String>>.error(_withResponse());

      final response = await future.catchWhenError((e, st) => 'fallback');

      expect(response.data, 'fallback');
      expect(response.statusCode, 500);
    });

    test('resolves without a response, as after a lost connection', () async {
      final future = Future<Response<String>>.error(_withoutResponse());

      final response = await future.catchWhenError((e, st) => 'offline');

      expect(response.data, 'offline');
      expect(response.requestOptions, same(_options));
    });
  });

  group('catchWhenError on Future<JsonRpcResponse<RESULT>>', () {
    test('resolves with a JsonRpcResponse carrying the request id', () async {
      final future = Future<JsonRpcResponse<_Result>>.error(_withoutResponse());

      final response = await future.catchWhenError(
        (e, st) => const _Result('fallback'),
      );

      expect(response.result.value, 'fallback');
      expect(response.id, 7);
    });

    test('rethrows when the fallback returns null', () {
      final future = Future<JsonRpcResponse<_Result>>.error(_withResponse());

      expect(
        future.catchWhenError((e, st) => null),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('catchWhenError on Future<HttpResponse<T>>', () {
    test('resolves with an HttpResponse carrying the fallback', () async {
      final future = Future<HttpResponse<String>>.error(_withoutResponse());

      final response = await future.catchWhenError((e, st) => 'offline');

      expect(response.data, 'offline');
      expect(response.response.data, 'offline');
    });
  });

  group('mapJson', () {
    Future<Response<dynamic>> body(Object? data) =>
        Future.value(Response<dynamic>(requestOptions: _options, data: data));

    Matcher invalidFormat() => throwsA(
      isA<DioException>().having(
        (e) => e.error,
        'error',
        isA<CommonException>().having(
          (c) => c.type,
          'type',
          InputErrorType.invalidFormat,
        ),
      ),
    );

    test('passes a JSON object to the converter', () async {
      final response = await body({'a': 1}).mapJson((json) => json['a']);

      expect(response.data, 1);
    });

    test('wraps a String body under result', () async {
      final response = await body('plain').mapJson((json) => json['result']);

      expect(response.data, 'plain');
    });

    test('fails with invalidFormat on a JSON array', () {
      expect(body([1, 2]).mapJson((json) => json), invalidFormat());
    });

    test('fails with invalidFormat on an empty body', () {
      expect(body(null).mapJson((json) => json), invalidFormat());
    });

    test('fails with invalidFormat when the converter throws', () {
      expect(
        body({'a': 1})
            .mapJson<int>((json) => throw const FormatException('bad')),
        invalidFormat(),
      );
    });

    test('a converter that returns null yields null data', () async {
      final response = await body({'a': 1}).mapJson<int?>((json) => null);

      expect(response.data, isNull);
    });
  });

  test('a fallback that throws surfaces its own error', () {
    final future = Future<Response<String>>.error(_withResponse());

    expect(
      future.catchWhenError((e, st) => throw StateError('fallback failed')),
      throwsA(isA<StateError>()),
    );
  });

  group('null Response', () {
    test('transformData throws a StateError', () {
      const Response<dynamic>? response = null;

      expect(() => response.transformData<String>(data: 'x'), throwsStateError);
    });

    test('copyWith throws a StateError', () {
      const Response<dynamic>? response = null;

      expect(() => response.copyWith<String>(data: 'x'), throwsStateError);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_falconnect && dart test test/engine/https/extensions/response_extensions_test.dart`
Expected: failures, among them `rethrows when the fallback returns null` (`Expected: throws <Instance of 'DioException'>`) and `resolves without a response, as after a lost connection` (`Null check operator used on a null value`). These reproduce the bugs of spec section 1, gaps 8 to 10.

- [ ] **Step 3: Replace the extensions**

Replace the whole of `dart_falconnect/lib/engine/https/extensions/response_extensions.dart` with:

```dart
import 'package:dart_falconnect/lib.dart';

/// Extensions on `Future<Response<dynamic>>` for JSON mapping.
extension DartFalconnectHttpFutureDynamicExtensions
    on Future<Response<dynamic>> {
  /// Maps the response body through [f], which receives the decoded JSON
  /// object and returns an instance of [T].
  ///
  /// A plain [String] body is wrapped under a `result` key. Any other body
  /// that is not a JSON object, and any exception from [f], fails with a
  /// [DioException] whose `error` is a [CommonException] of
  /// [InputErrorType.invalidFormat].
  Future<Response<T>> mapJson<T>(
    FutureOr<T> Function(Map<String, Object?> response) f,
  ) {
    return then((response) async {
      final body = response.data;
      final Map<String, Object?> json;
      if (body is Map<String, Object?>) {
        json = body;
      } else if (body is String) {
        json = {'result': body};
      } else {
        throw _invalidFormat(
          response,
          'Expected a JSON object, got ${body.runtimeType}.',
        );
      }
      final T data;
      try {
        data = await f(json);
      } on Object catch (error, stackTrace) {
        throw _invalidFormat(
          response,
          'The converter failed: $error',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return response.transformData<T>(data: data);
    });
  }
}

DioException _invalidFormat(
  Response<dynamic> response,
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) => DioException(
  requestOptions: response.requestOptions,
  response: response,
  message: message,
  stackTrace: stackTrace,
  error: CommonException(
    type: InputErrorType.invalidFormat,
    developerMessage: message,
    originalException: error,
    stackTrace: stackTrace,
  ),
);

/// Runs [fallback] for a [DioException]; rethrows every other error, and
/// the original error when [fallback] is null or returns null.
FutureOr<R> _recover<T, R>(
  Object error,
  StackTrace stackTrace,
  T? Function(DioException exception, StackTrace? stackTrace)? fallback,
  R Function(DioException exception, T value) wrap,
) {
  if (fallback == null || error is! DioException) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  final value = fallback(error, error.stackTrace);
  if (value == null) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  return wrap(error, value);
}

/// The response a recovered request resolves with: the error's response
/// carrying [value], or a new one when the error has no response.
Response<T> _fallbackResponse<T>(DioException error, T value) {
  final response = error.response;
  return response == null
      ? Response<T>(requestOptions: error.requestOptions, data: value)
      : response.transformData<T>(data: value);
}

/// Extensions on `Future<Response<T>>` for unwrapping and error recovery.
extension DartFalconnectFutureResponseExtensions<T> on Future<Response<T>> {
  /// Unwraps the response and returns only the data payload.
  Future<T> unwrapResponse() => then((response) => response.data as T);

  /// Recovers from a [DioException] with the value [f] returns.
  ///
  /// A null [f], a null result, or an error that is not a [DioException]
  /// rethrows the original error.
  Future<Response<T>> catchWhenError(
    T? Function(DioException exception, StackTrace? stackTrace)? f,
  ) {
    return then(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) =>
          _recover<T, Response<T>>(error, stackTrace, f, _fallbackResponse),
    );
  }
}

/// Extensions on `Future<JsonRpcResponse<RESULT>>` for unwrapping and error
/// recovery.
extension DartFalconnectHttpFutureRpcResponseExtensions<
  RESULT extends JsonRpcResult
>
    on Future<JsonRpcResponse<RESULT>> {
  /// Unwraps the JSON-RPC response and returns only the result payload.
  Future<RESULT> unwrapResponse() => then((response) => response.result);

  /// Recovers from a [DioException] with the result [f] returns.
  ///
  /// The recovered response carries the request's id, or 0 when the
  /// request body holds none. A null [f], a null result, or an error that
  /// is not a [DioException] rethrows the original error.
  Future<JsonRpcResponse<RESULT>> catchWhenError(
    RESULT? Function(DioException exception, StackTrace? stackTrace)? f,
  ) {
    return then(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) =>
          _recover<RESULT, JsonRpcResponse<RESULT>>(
            error,
            stackTrace,
            f,
            (exception, result) => JsonRpcResponse<RESULT>(
              jsonrpc: '2.0',
              id: _requestId(exception.requestOptions),
              result: result,
            ),
          ),
    );
  }
}

int _requestId(RequestOptions options) {
  final body = options.data;
  if (body is Map && body['id'] is int) return body['id'] as int;
  return 0;
}

/// Extensions on `Future<HttpResponse<T>>` for unwrapping and error recovery.
extension DartFalconnectHttpFutureResponseExtensions<T>
    on Future<HttpResponse<T>> {
  /// Unwraps the HTTP response and returns only the data payload.
  Future<T> unwrapResponse() => then((response) => response.data);

  /// Recovers from a [DioException] with the value [f] returns.
  ///
  /// A null [f], a null result, or an error that is not a [DioException]
  /// rethrows the original error.
  Future<HttpResponse<T>> catchWhenError(
    T? Function(DioException exception, StackTrace? stackTrace)? f,
  ) {
    return then(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) =>
          _recover<T, HttpResponse<T>>(
            error,
            stackTrace,
            f,
            (exception, value) =>
                HttpResponse<T>(value, _fallbackResponse(exception, value)),
          ),
    );
  }
}

/// Extensions on a nullable [Response] for creating modified copies.
extension DartFalconnectResponseExtensions on Response<dynamic>? {
  /// Creates a copy of this response with the given fields replaced.
  ///
  /// All parameters are optional; unspecified fields are carried over from the
  /// original response. Returns a new `Response<T>` with [data] typed to [T].
  Response<T> copyWith<T>({
    T? data,
    Headers? headers,
    RequestOptions? requestOptions,
    bool? isRedirect,
    int? statusCode,
    String? statusMessage,
    List<RedirectRecord>? redirects,
    Map<String, dynamic>? extra,
  }) {
    final options = requestOptions ?? this?.requestOptions;
    if (options == null) {
      throw StateError('copyWith on a null Response needs requestOptions.');
    }
    return Response<T>(
      data: (data ?? this?.data) as T?,
      headers: headers ?? this?.headers,
      requestOptions: options,
      isRedirect: isRedirect ?? this?.isRedirect ?? false,
      statusCode: statusCode ?? this?.statusCode,
      statusMessage: statusMessage ?? this?.statusMessage,
      redirects: redirects ?? this?.redirects ?? [],
      extra: extra ?? this?.extra ?? {},
    );
  }

  /// Creates a copy of this response replacing [data] with [data] typed as
  /// [T].
  ///
  /// Unlike [copyWith], the [data] parameter is required and the return type is
  /// always `Response<T>`. If this response is `null`, the data is applied in
  /// place before the cast.
  Response<T> transformData<T>({
    required T? data,
    Headers? headers,
    RequestOptions? requestOptions,
    bool? isRedirect,
    int? statusCode,
    String? statusMessage,
    List<RedirectRecord>? redirects,
    Map<String, dynamic>? extra,
  }) {
    final options = requestOptions ?? this?.requestOptions;
    if (options == null) {
      throw StateError(
        'transformData on a null Response needs requestOptions.',
      );
    }
    return Response<T>(
      data: data,
      headers: headers ?? this?.headers,
      requestOptions: options,
      isRedirect: isRedirect ?? this?.isRedirect ?? false,
      statusCode: statusCode ?? this?.statusCode,
      statusMessage: statusMessage ?? this?.statusMessage,
      redirects: redirects ?? this?.redirects ?? [],
      extra: extra ?? this?.extra ?? {},
    );
  }
}
```

- [ ] **Step 4: Run the tests and the analyzer**

Run: `cd dart_falconnect && dart format lib test && dart test test/engine/https/extensions/response_extensions_test.dart && dart analyze --fatal-infos`
Expected: all tests pass; `No issues found!`

- [ ] **Step 5: Commit**

```bash
git commit -m "fix(dart_falconnect)!: rethrow on a null fallback, recover without a response, and wrap parse failures" -- dart_falconnect/lib/engine/https/extensions/response_extensions.dart dart_falconnect/test/engine/https/extensions/response_extensions_test.dart
```

---

### Task 6: `BaseHttpClient.configure` and one request path

**Files:**
- Create: `dart_falconnect/lib/engine/https/extensions/use_token_extensions.dart`
- Modify: `dart_falconnect/lib/engine/https/extensions/extensions.dart`
- Modify: `dart_falconnect/lib/engine/https/request_api_service.dart` (whole file)
- Modify: `dart_falconnect/lib/engine/https/http_client.dart` (whole file)
- Modify: `dart_falconnect/lib/engine/https/default_http_client.dart` (whole file)
- Test: `dart_falconnect/test/engine/https/base_http_client_configure_test.dart`, `dart_falconnect/test/engine/https/http_client_test.dart`

**Interfaces:**
- Consumes: every box and interceptor constructor (Tasks 2 to 4), `mapJson` and `catchWhenError` (Task 5).
- Produces:
  - `BaseHttpClient({required Dio dio, HttpClientConfig config = const HttpClientConfig()})`; `HttpClientConfig get currentConfig`; `void configure(HttpClientConfig config)`; `void setupBaseUrl(String baseUrl)`; `void addInterceptors(Iterable<Interceptor> interceptors)`; `void dispose()`; `BaseOptions get options`. Removed: `setupOptions`, `setupInterceptors`, and the `config` getter.
  - `DefaultHttpClient` keeps only `DefaultHttpClient.instance`.
  - Typedefs `JsonResponseConverter<T>` and `RequestErrorCallback<T>` in `request_api_service.dart`.
  - `RequestOptions.useToken` and `Options.useToken` (extensions `FalconAuthRequestOptionsExtensions`, `FalconAuthOptionsExtensions`), backed by `extra['dart_falconnect.auth.useToken']`, true when unset.

- [ ] **Step 1: Write the failing tests**

Create `dart_falconnect/test/engine/https/base_http_client_configure_test.dart`:

```dart
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import 'interceptors/_scripted_adapter.dart';

class _Client extends BaseHttpClient {
  new(HttpClientAdapter adapter)
    : super(dio: Dio()..httpClientAdapter = adapter);
}

/// Records every error it sees and passes it on.
class _ErrorSpy extends Interceptor {
  final List<int?> statuses = [];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    statuses.add(err.response?.statusCode);
    handler.next(err);
  }
}

class _RefreshLike extends Interceptor {
  new(this.dio);

  final Dio dio;
}

class _SelfConfiguringClient extends BaseHttpClient {
  new() : super(dio: Dio()) {
    configure(HttpClientConfig(interceptors: [_RefreshLike(dio)]));
  }
}

const _policy = TokenBucketPolicy(permits: 2, per: Duration(seconds: 10));

void main() {
  group('default configuration', () {
    test('keeps the options and chain DefaultHttpClient always had', () {
      final client = _Client(ScriptedAdapter([reply(200)]));

      expect(client.options.contentType, Headers.jsonContentType);
      expect(client.options.connectTimeout, const Duration(seconds: 20));
      expect(client.options.receiveTimeout, const Duration(seconds: 20));
      expect(client.options.sendTimeout, isNull);
      expect(client.interceptors.map((i) => '${i.runtimeType}'), [
        'ImplyContentTypeInterceptor',
        'DefaultNetworkExceptionHandlerInterceptor',
      ]);
      expect(client.currentConfig, const HttpClientConfig());
    });

    test('DefaultHttpClient.instance starts on the default config', () {
      expect(
        DefaultHttpClient.instance.currentConfig,
        const HttpClientConfig(),
      );
    });
  });

  group('configure', () {
    test('assembles every box in the fixed order', () {
      final custom = _ErrorSpy();
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(
          HttpClientConfig(
            interceptors: [custom],
            log: const LogConfig(),
            performance: const PerformanceConfig(),
            cache: const CacheConfig(),
            concurrency: const ConcurrencyConfig(global: 4),
            rateLimit: const RateLimitConfig.pauseOnly(),
            retry: const RetryConfig(),
          ),
        );
      addTearDown(client.dispose);

      expect(client.interceptors.map((i) => '${i.runtimeType}'), [
        'ImplyContentTypeInterceptor',
        '_ErrorSpy',
        'HttpLogInterceptor',
        'PerformanceInterceptor',
        'CacheInterceptor',
        'ConcurrencyLimitInterceptor',
        'RetryAfterPauseInterceptor',
        'RetryInterceptor',
        'DefaultNetworkExceptionHandlerInterceptor',
      ]);
    });

    test('keeps an unchanged box and rebuilds a changed one', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(
          const HttpClientConfig(
            rateLimit: RateLimitConfig.tokenBucket(global: [_policy]),
            retry: RetryConfig(),
          ),
        );
      addTearDown(client.dispose);
      final limiter = client.interceptors
          .whereType<TokenBucketRateLimitInterceptor>()
          .single;
      final retry = client.interceptors.whereType<RetryInterceptor>().single;

      client.configure(
        client.currentConfig.copyWith(
          log: const LogConfig(),
          retry: const RetryConfig(maxAttempts: 1),
        ),
      );

      expect(
        client.interceptors.whereType<TokenBucketRateLimitInterceptor>().single,
        same(limiter),
      );
      expect(
        client.interceptors.whereType<RetryInterceptor>().single,
        isNot(same(retry)),
      );
    });

    test('a kept limiter keeps its spent tokens', () {
      fakeAsync((async) {
        final adapter = ScriptedAdapter([reply(200)]);
        final client = _Client(adapter)
          ..configure(
            const HttpClientConfig(
              baseUrl: 'https://a.test',
              rateLimit: RateLimitConfig.tokenBucket(
                global: [
                  TokenBucketPolicy(
                    permits: 1,
                    per: Duration(seconds: 10),
                    burst: 1,
                  ),
                ],
              ),
            ),
          );
        client.dio.get<dynamic>('/1').ignore();
        async.elapse(Duration.zero);
        client.configure(client.currentConfig.copyWith(log: const LogConfig()));
        client.dio.get<dynamic>('/2').ignore();
        async.elapse(Duration.zero);

        expect(adapter.requests, hasLength(1));

        async.elapse(const Duration(seconds: 10));
        expect(adapter.requests, hasLength(2));
        client.dispose();
      });
    });

    test('a request that started before configure finishes on the old '
        'options and chain', () {
      fakeAsync((async) {
        final adapter = GatedAdapter();
        final oldSpy = _ErrorSpy();
        final client = _Client(adapter)
          ..configure(
            HttpClientConfig(
              baseUrl: 'https://a.test',
              headers: const {'X-Env': 'dev'},
              interceptors: [oldSpy],
            ),
          );
        client.dio.get<dynamic>('/a').ignore();
        async.elapse(Duration.zero);

        client.configure(
          const HttpClientConfig(
            baseUrl: 'https://a.test',
            headers: {'X-Env': 'prod'},
          ),
        );
        client.dio.get<dynamic>('/b').ignore();
        async.elapse(Duration.zero);
        adapter.requests[0].respond(500);
        adapter.requests[1].respond(500);
        async.elapse(Duration.zero);

        expect(adapter.requests[0].options.headers['X-Env'], 'dev');
        expect(adapter.requests[1].options.headers['X-Env'], 'prod');
        expect(oldSpy.statuses, [500]);
      });
    });

    test('a config that cannot be built throws and changes nothing', () {
      final client = _Client(ScriptedAdapter([reply(200)]));
      final before = client.interceptors.toList();

      expect(
        () => client.configure(
          const HttpClientConfig(
            baseUrl: 'https://b.test',
            concurrency: ConcurrencyConfig(global: 0),
          ),
        ),
        throwsArgumentError,
      );
      expect(client.currentConfig, const HttpClientConfig());
      expect(client.baseUrl, '');
      expect(client.interceptors.toList(), before);
    });

    test('keeps a header set on dio.options and drops one the config '
        'stopped setting', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(const HttpClientConfig(headers: {'X-A': '1'}));
      client.options.headers['X-Manual'] = 'kept';

      client.configure(const HttpClientConfig(headers: {'X-B': '2'}));

      expect(client.options.headers['X-Manual'], 'kept');
      expect(client.options.headers['X-B'], '2');
      expect(client.options.headers.containsKey('X-A'), isFalse);
    });

    test('configure with the same config keeps every interceptor', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(
          const HttpClientConfig(
            cache: CacheConfig(),
            concurrency: ConcurrencyConfig(global: 2),
            rateLimit: RateLimitConfig.pauseOnly(),
            retry: RetryConfig(),
          ),
        );
      addTearDown(client.dispose);
      final before = client.interceptors.toList();

      client.configure(client.currentConfig);

      expect(client.interceptors.toList(), before);
    });

    test('a header whose key changes only in case keeps its new value', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(const HttpClientConfig(headers: {'x-a': '1'}))
        ..configure(const HttpClientConfig(headers: {'X-A': '2'}));

      expect(client.options.headers['X-A'], '2');
    });

    test('a timeout dropped from the config is cleared', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..configure(const HttpClientConfig(sendTimeout: Duration(seconds: 3)))
        ..configure(const HttpClientConfig());

      expect(client.options.sendTimeout, isNull);
    });

    test('keeps a field the config does not own', () {
      final client = _Client(ScriptedAdapter([reply(200)]));
      client.options.responseType = ResponseType.plain;

      client.configure(const HttpClientConfig(baseUrl: 'https://a.test'));

      expect(client.options.responseType, ResponseType.plain);
    });
  });

  group('validateStatus', () {
    test('a 4xx reaches the error interceptors by default', () async {
      final spy = _ErrorSpy();
      final client = _Client(ScriptedAdapter([reply(404)]))
        ..configure(
          HttpClientConfig(baseUrl: 'https://a.test', interceptors: [spy]),
        );

      await expectLater(
        client.dio.get<dynamic>('/x'),
        throwsA(isA<DioException>()),
      );
      expect(spy.statuses, [404]);
    });

    test('a 429 reaches RetryInterceptor', () {
      fakeAsync((async) {
        final adapter = ScriptedAdapter([reply(429), reply(200)]);
        final client = _Client(adapter)
          ..configure(
            const HttpClientConfig(
              baseUrl: 'https://a.test',
              retry: RetryConfig(delay: Duration(milliseconds: 1)),
            ),
          );
        client.dio.get<dynamic>('/x').ignore();
        async.elapse(const Duration(seconds: 1));

        expect(adapter.requests, hasLength(2));
      });
    });
  });

  group('diagnostics', () {
    test('a kept interceptor follows the current log box', () {
      fakeAsync((async) {
        final lines = <Object?>[];
        final adapter = ScriptedAdapter([reply(500)]);
        final client = _Client(adapter)
          ..configure(
            const HttpClientConfig(
              baseUrl: 'https://a.test',
              retry: RetryConfig(
                maxAttempts: 1,
                delay: Duration(milliseconds: 1),
              ),
            ),
          );
        client.dio.get<dynamic>('/quiet').ignore();
        async.elapse(const Duration(seconds: 1));
        expect(lines, isEmpty);

        client.configure(
          client.currentConfig.copyWith(
            log: LogConfig(
              request: false,
              requestHeader: false,
              requestBody: false,
              responseBody: false,
              error: false,
              logPrint: lines.add,
            ),
          ),
        );
        client.dio.get<dynamic>('/loud').ignore();
        async.elapse(const Duration(seconds: 1));

        expect(
          lines.whereType<String>().where(
            (line) => line.startsWith('[RetryInterceptor]'),
          ),
          hasLength(1),
        );
      });
    });
  });

  group('addInterceptors and setupBaseUrl', () {
    test('addInterceptors puts the interceptor in the custom slot, where it '
        'sees errors and survives configure', () async {
      final spy = _ErrorSpy();
      final client = _Client(ScriptedAdapter([reply(500)]))
        ..setupBaseUrl('https://a.test')
        ..addInterceptors([spy]);
      client.configure(
        client.currentConfig.copyWith(log: LogConfig(logPrint: (_) {})),
      );

      await expectLater(
        client.dio.get<dynamic>('/x'),
        throwsA(isA<DioException>()),
      );
      expect(client.currentConfig.interceptors, [spy]);
      expect(spy.statuses, [500]);
    });

    test('setupBaseUrl updates the config and the options', () {
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..setupBaseUrl('https://b.test');

      expect(client.currentConfig.baseUrl, 'https://b.test');
      expect(client.baseUrl, 'https://b.test');
    });
  });

  test('a subclass can hand its own dio to an interceptor', () {
    final client = _SelfConfiguringClient();

    expect(
      client.interceptors.whereType<_RefreshLike>().single.dio,
      same(client.dio),
    );
  });

  test('dispose disposes the current limiters', () {
    final client = _Client(ScriptedAdapter([reply(200)]))
      ..configure(
        const HttpClientConfig(
          baseUrl: 'https://a.test',
          rateLimit: RateLimitConfig.tokenBucket(global: [_policy]),
        ),
      )
      ..dispose();

    expect(
      client.dio.get<dynamic>('/x'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
  });
}
```

Create `dart_falconnect/test/engine/https/http_client_test.dart`:

```dart
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:test/test.dart';

import 'interceptors/_scripted_adapter.dart';

class _Client extends BaseHttpClient {
  new(HttpClientAdapter adapter)
    : super(
        dio: Dio()..httpClientAdapter = adapter,
        config: const HttpClientConfig(baseUrl: 'https://a.test'),
      );
}

class _Body extends BaseRequestBody {
  const new();

  @override
  List<Object?> get props => [];

  @override
  Map<String, Object?> toJson() => {'name': 'falcon'};
}

/// Records whether each request asked for a token.
class _TokenSpy extends Interceptor {
  final List<bool> useToken = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    useToken.add(options.useToken);
    handler.next(options);
  }
}

Reply _body(String json) =>
    (_) => ResponseBody.fromString(
      json,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _echo(Map<String, dynamic> json) => json;

Matcher _invalidFormat() => throwsA(
  isA<DioException>().having(
    (e) => e.error,
    'error',
    isA<CommonException>().having(
      (c) => c.type,
      'type',
      InputErrorType.invalidFormat,
    ),
  ),
);

void main() {
  group('request methods', () {
    test('each method sends its verb, path, query, and body', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(adapter);

      await client.get('/g', queryParameters: {'q': 1}, converter: _echo);
      await client.post('/p', data: const _Body(), converter: _echo);
      await client.postFormData(
        '/pf',
        data: FormData.fromMap({'a': 'b'}),
        converter: _echo,
      );
      await client.patch('/pa', data: const _Body(), converter: _echo);
      await client.put('/pu', data: const _Body(), converter: _echo);
      await client.putFormData(
        '/puf',
        data: FormData.fromMap({'a': 'b'}),
        converter: _echo,
      );
      await client.delete('/d', data: const _Body(), converter: _echo);

      expect(adapter.requests.map((r) => '${r.method} ${r.uri.path}'), [
        'GET /g',
        'POST /p',
        'POST /pf',
        'PATCH /pa',
        'PUT /pu',
        'PUT /puf',
        'DELETE /d',
      ]);
      expect(adapter.requests[0].uri.queryParameters, {'q': '1'});
      expect(adapter.requests[1].data, {'name': 'falcon'});
      expect(adapter.requests[2].data, isA<FormData>());
      expect(adapter.requests[6].data, {'name': 'falcon'});
    });

    test('every method accepts an async converter', () async {
      final client = _Client(ScriptedAdapter([reply(200)]));

      final response = await client.post<int>(
        '/p',
        converter: (json) async => json['status']! as int,
      );

      expect(response.data, 200);
    });

    test('a null query value is accepted', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(adapter);

      await client.get(
        '/g',
        queryParameters: {'a': 1, 'b': null},
        converter: _echo,
      );

      expect(adapter.requests.single.uri.path, '/g');
    });

    test('isUseToken reaches interceptors as useToken', () async {
      final spy = _TokenSpy();
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..addInterceptors([spy]);

      await client.get('/a', converter: _echo);
      await client.get('/b', isUseToken: false, converter: _echo);
      await client.dio.get<dynamic>('/raw');

      expect(spy.useToken, [true, false, true]);
    });

    test('the caller options are not changed', () async {
      final client = _Client(ScriptedAdapter([reply(200)]));
      final options = Options(headers: {'X-A': '1'});

      await client.get(
        '/a',
        options: options,
        isUseToken: false,
        converter: _echo,
      );

      expect(options.method, isNull);
      expect(options.extra, isNull);
    });
  });

  group('mapJson', () {
    test('a JSON array body fails with invalidFormat', () {
      final client = _Client(ScriptedAdapter([_body('[1, 2]')]));

      expect(client.get('/a', converter: _echo), _invalidFormat());
    });

    test('an empty JSON body fails with invalidFormat', () {
      final client = _Client(ScriptedAdapter([_body('')]));

      expect(client.get('/a', converter: _echo), _invalidFormat());
    });

    test('a throwing converter fails with invalidFormat and keeps the '
        'original exception', () async {
      final client = _Client(ScriptedAdapter([reply(200)]));

      await expectLater(
        client.get<int>(
          '/a',
          converter: (json) => throw const FormatException('bad'),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => (e.error! as CommonException).originalException,
            'originalException',
            isA<FormatException>(),
          ),
        ),
      );
    });

    test('catchError sees a parse failure', () async {
      final client = _Client(ScriptedAdapter([_body('[1]')]));

      final response = await client.get<String>(
        '/a',
        converter: (json) => 'parsed',
        catchError: (e, st) => 'fallback',
      );

      expect(response.data, 'fallback');
    });

    test('a String body still arrives under result', () async {
      final client = _Client(
        ScriptedAdapter([(_) => ResponseBody.fromString('plain', 200)]),
      );

      final response = await client.get('/a', converter: _echo);

      expect(response.data, {'result': 'plain'});
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_falconnect && dart test test/engine/https/base_http_client_configure_test.dart test/engine/https/http_client_test.dart`
Expected: FAIL to compile with `No named parameter with the name 'config'` and `The getter 'useToken' isn't defined`.

- [ ] **Step 3: Add the `useToken` extensions**

Create `dart_falconnect/lib/engine/https/extensions/use_token_extensions.dart`:

```dart
import 'package:dio/dio.dart';

const String _useTokenKey = 'dart_falconnect.auth.useToken';

/// Whether a request carries the auth token, on [RequestOptions].
extension FalconAuthRequestOptionsExtensions on RequestOptions {
  /// Whether an auth interceptor should attach the token; true unless a
  /// request method was called with `isUseToken: false`.
  bool get useToken => extra[_useTokenKey] != false;
  set useToken(bool value) => extra = {...extra, _useTokenKey: value};
}

/// Whether a request carries the auth token, on [Options].
extension FalconAuthOptionsExtensions on Options {
  /// Whether an auth interceptor should attach the token; true when unset.
  bool get useToken => extra?[_useTokenKey] != false;
  set useToken(bool value) => extra = {...?extra, _useTokenKey: value};
}
```

Replace `dart_falconnect/lib/engine/https/extensions/extensions.dart` with:

```dart
export 'dio_extensions.dart';
export 'response_extensions.dart';
export 'use_token_extensions.dart';
```

- [ ] **Step 4: Replace the request interface**

Replace the whole of `dart_falconnect/lib/engine/https/request_api_service.dart` with:

```dart
import 'package:dart_falconnect/lib.dart';

/// Converts a decoded JSON object into `T`.
typedef JsonResponseConverter<T> = FutureOr<T> Function(
  Map<String, dynamic> json,
);

/// Returns a fallback value for a failed request, or null to rethrow.
typedef RequestErrorCallback<T> = T? Function(
  DioException exception,
  StackTrace? stackTrace,
);

/// Abstract interface for type-safe HTTP operations.
///
/// Every method requires a `converter` that turns the decoded JSON object
/// into `T`. A body that is not a JSON object, or a converter that throws,
/// fails with a [DioException] holding a `CommonException` of
/// `InputErrorType.invalidFormat`. An optional `catchError` returns a
/// fallback value; returning null rethrows the error.
abstract class RequestApiService {
  /// Sends a `GET` request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `POST` request with a JSON body.
  Future<Response<T>> post<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `POST` request with a multipart body.
  Future<Response<T>> postFormData<T>(
    String path, {
    FormData? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `PATCH` request with a JSON body.
  Future<Response<T>> patch<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `PUT` request with a JSON body.
  Future<Response<T>> put<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `PUT` request with a multipart body.
  Future<Response<T>> putFormData<T>(
    String path, {
    FormData? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `DELETE` request with an optional JSON body.
  Future<Response<T>> delete<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });
}
```

- [ ] **Step 5: Replace `BaseHttpClient`**

Replace the whole of `dart_falconnect/lib/engine/https/http_client.dart` with:

```dart
import 'package:dart_falconnect/lib.dart';

/// Base class of every HTTP client in FalconX: one [Dio] configured by one
/// [HttpClientConfig].
///
/// The client orders the interceptor chain itself: the config's own
/// `interceptors`, then log, performance, cache, concurrency limit, rate
/// limit, retry, and the exception handler last. [configure] applies a new
/// configuration to requests that start after it returns; requests already
/// running finish on the configuration they started with. Interceptors
/// whose box is unchanged are kept, with their state.
///
/// A subclass passes its configuration to the super constructor. An
/// interceptor that needs [dio] is built in the subclass constructor body,
/// which then calls [configure].
abstract class BaseHttpClient implements RequestApiService {
  /// Creates a client on [dio] and applies [config].
  new({required Dio dio, HttpClientConfig config = const HttpClientConfig()})
    : _dio = dio,
      _defaultValidateStatus = BaseOptions().validateStatus {
    configure(config);
  }

  final Dio _dio;
  final ValidateStatus _defaultValidateStatus;
  final NetworkExceptionHandlerInterceptor _defaultExceptionHandler =
      DefaultNetworkExceptionHandlerInterceptor();

  HttpClientConfig? _config;
  HttpLogInterceptor? _log;
  PerformanceInterceptor? _performance;
  CacheInterceptor? _cache;
  ConcurrencyLimitInterceptor? _concurrency;
  Interceptor? _rateLimit;
  RetryInterceptor? _retry;

  /// The underlying Dio instance, for Retrofit and advanced use.
  Dio get dio => _dio;

  /// The base URL new requests use.
  String get baseUrl => _dio.options.baseUrl;

  /// The Dio base options.
  BaseOptions get options => _dio.options;

  /// The current interceptor chain. Add interceptors through
  /// [addInterceptors] or the config: [configure] rebuilds this list.
  Interceptors get interceptors => _dio.interceptors;

  /// The configuration new requests use.
  HttpClientConfig get currentConfig => _config!;

  /// Applies [config] to requests that start after this call returns.
  ///
  /// Throws, and keeps the current configuration, when an interceptor
  /// cannot be built from [config].
  void configure(HttpClientConfig config) {
    final previous = _config;
    final log = _keepOrBuild(previous?.log, config.log, _log, _buildLog);
    final performance = _keepOrBuild(
      previous?.performance,
      config.performance,
      _performance,
      (box) => PerformanceInterceptor(config: box, logPrint: _diagnostic),
    );
    final cache = _keepOrBuild(
      previous?.cache,
      config.cache,
      _cache,
      (box) => CacheInterceptor(config: box, logPrint: _diagnostic),
    );
    final concurrency = _keepOrBuild(
      previous?.concurrency,
      config.concurrency,
      _concurrency,
      (box) => ConcurrencyLimitInterceptor(config: box, logPrint: _diagnostic),
    );
    final rateLimit = previous != null && previous.rateLimit == config.rateLimit
        ? _rateLimit
        : _buildRateLimit(config.rateLimit);
    final retry = _keepOrBuild(
      previous?.retry,
      config.retry,
      _retry,
      (box) => RetryInterceptor(config: box, dio: _dio, logPrint: _diagnostic),
    );

    _applyOptions(previous, config);
    _dio.interceptors
      ..clear()
      ..addAll([
        ...config.interceptors,
        ?log,
        ?performance,
        ?cache,
        ?concurrency,
        ?rateLimit,
        ?retry,
        config.exceptionHandler ?? _defaultExceptionHandler,
      ]);
    _config = config;
    _log = log;
    _performance = performance;
    _cache = cache;
    _concurrency = concurrency;
    _rateLimit = rateLimit;
    _retry = retry;
  }

  /// Sets the base URL of the current configuration.
  void setupBaseUrl(String baseUrl) {
    configure(currentConfig.copyWith(baseUrl: baseUrl));
  }

  /// Adds [interceptors] to the custom slot of the current configuration,
  /// so they run first and survive later [configure] calls.
  void addInterceptors(Iterable<Interceptor> interceptors) {
    configure(
      currentConfig.copyWith(
        interceptors: [...currentConfig.interceptors, ...interceptors],
      ),
    );
  }

  /// Disposes the stateful interceptors of the current configuration.
  ///
  /// Needed at the end of a test or a CLI; a Flutter app never calls it.
  void dispose() {
    final rateLimit = _rateLimit;
    if (rateLimit is TokenBucketRateLimitInterceptor) {
      rateLimit.dispose();
    } else if (rateLimit is RetryAfterPauseInterceptor) {
      rateLimit.dispose();
    }
    _concurrency?.dispose();
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'GET',
    path,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> post<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'POST',
    path,
    data: data?.toJson(),
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> postFormData<T>(
    String path, {
    FormData? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'POST',
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> patch<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'PATCH',
    path,
    data: data?.toJson(),
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> put<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'PUT',
    path,
    data: data?.toJson(),
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> putFormData<T>(
    String path, {
    FormData? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'PUT',
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> delete<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'DELETE',
    path,
    data: data?.toJson(),
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  /// The one request path behind every public method.
  Future<Response<T>> _request<T>(
    String method,
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    required bool isUseToken,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) {
    final requestOptions = (options ?? Options()).copyWith(method: method)
      ..useToken = isUseToken;
    return _dio
        .request<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: requestOptions,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        )
        .mapJson(converter)
        .catchWhenError(catchError);
  }

  /// Keeps [current] when its box did not change, else builds a new one.
  static I? _keepOrBuild<B extends Object, I extends Object>(
    B? before,
    B? after,
    I? current,
    I Function(B box) build,
  ) {
    if (after == null) return null;
    if (current != null && before == after) return current;
    return build(after);
  }

  HttpLogInterceptor _buildLog(LogConfig box) {
    final log = HttpLogInterceptor(
      request: box.request,
      requestHeader: box.requestHeader,
      requestBody: box.requestBody,
      responseHeader: box.responseHeader,
      responseBody: box.responseBody,
      error: box.error,
    );
    final printer = box.logPrint;
    if (printer != null) log.logPrint = printer;
    return log;
  }

  Interceptor? _buildRateLimit(RateLimitConfig box) => switch (box) {
    NoRateLimitConfig() => null,
    PauseOnlyRateLimitConfig() => RetryAfterPauseInterceptor(
      config: box,
      logPrint: _diagnostic,
    ),
    TokenBucketRateLimitConfig() => TokenBucketRateLimitInterceptor(
      config: box,
      logPrint: _diagnostic,
    ),
  };

  /// Writes the options [next] owns and removes the header keys that
  /// [previous] set and [next] drops. Other fields and keys stay.
  void _applyOptions(HttpClientConfig? previous, HttpClientConfig next) {
    if (previous != null) {
      final kept = next.effectiveHeaders;
      for (final key in previous.effectiveHeaders.keys) {
        if (!kept.containsKey(key)) _dio.options.headers.remove(key);
      }
    }
    next.applyTo(_dio);
    _dio.options.validateStatus = next.validateStatus ?? _defaultValidateStatus;
  }

  /// Prints an interceptor diagnostic through the current log box.
  void _diagnostic(String message) {
    final log = _config?.log;
    if (log == null || !log.diagnostics) return;
    final printer = log.logPrint;
    if (printer != null) {
      printer(message);
    } else {
      // Diagnostics go to the console when the config sets no printer.
      // ignore: avoid_print
      print(message);
    }
  }
}
```

- [ ] **Step 6: Replace `DefaultHttpClient`**

Replace the whole of `dart_falconnect/lib/engine/https/default_http_client.dart` with:

```dart
import 'package:dart_falconnect/lib.dart';

/// The shared [BaseHttpClient]. Its default configuration gives JSON
/// content type, 20-second connect and receive timeouts, and
/// [DefaultNetworkExceptionHandlerInterceptor]; call [configure] to change
/// it at any time.
class DefaultHttpClient extends BaseHttpClient {
  new _singleton({required super.dio});

  /// The shared instance.
  static final DefaultHttpClient instance = DefaultHttpClient._singleton(
    dio: Dio(),
  );
}
```

- [ ] **Step 7: Run the tests and the analyzer**

Run: `cd dart_falconnect && dart format lib test && dart analyze --fatal-infos && dart test`
Expected: `No issues found!`; every test passes, the two new files included. `test/web/_stub_http_client.dart` needs no change: `new({required super.dio})` still matches.

- [ ] **Step 8: Commit**

```bash
git commit -m "feat(dart_falconnect)!: configure any BaseHttpClient at run time through one request path" -- dart_falconnect/lib/engine/https dart_falconnect/test/engine/https/base_http_client_configure_test.dart dart_falconnect/test/engine/https/http_client_test.dart
```

---

### Task 7: Documentation in this repository

**Files:**
- Modify: `skills/dart-falconx-package/references/http.md`, `skills/dart-falconx-package/SKILL.md`, `skills/dart-falconx-package/references/json-rpc.md`, `skills/dart-falconx-package/references/models.md`, `dart_falconnect/CLAUDE.md`, `CLAUDE.md`, `_bmad-output/project-context.md`

**Interfaces:**
- Consumes: the public API of Tasks 1 to 6.
- Produces: docs that match the source (the skill maintenance rule in `CLAUDE.md`).

- [ ] **Step 1: Rewrite the client sections of `http.md`**

Replace the section `## \`DefaultHttpClient\`` (and its paragraph) with:

````markdown
## Configure a client

Every `BaseHttpClient`, `DefaultHttpClient.instance` included, runs on one `HttpClientConfig`: the dio options it owns, plus one box per feature. A null box turns its feature off. With no `configure` call, a client has JSON content type, 20 s connect and receive timeouts, no send timeout, and `DefaultNetworkExceptionHandlerInterceptor`.

```dart
final dev = HttpClientConfig(
  baseUrl: 'https://dev.api.example.com',
  log: const LogConfig(),
  retry: const RetryConfig(maxAttempts: 1),
  rateLimit: const RateLimitConfig.pauseOnly(),
);

final prod = HttpClientConfig(
  baseUrl: 'https://api.example.com',
  cache: const CacheConfig(),
  concurrency: const ConcurrencyConfig(global: 16, perHost: 4),
  rateLimit: RateLimitConfig.tokenBucket(
    perHost: [TokenBucketPolicy(permits: 100, per: const Duration(minutes: 1))],
  ),
  retry: const RetryConfig(),
  interceptors: [AuthInterceptor(tokenStore)],
);

void main() {
  DefaultHttpClient.instance.configure(kReleaseMode ? prod : dev);
  runApp(const App());
}
```

`configure` applies to requests that start after it returns. Requests already running finish on the configuration they started with. Only the interceptors whose box changed are rebuilt, so token buckets, 429 pauses, concurrency slots, the cache, and performance statistics survive an unrelated change:

```dart
final client = DefaultHttpClient.instance;
client.configure(client.currentConfig.copyWith(log: const LogConfig())); // limiter kept
client.configure(client.currentConfig.copyWith(log: null));              // log off
client.setupBaseUrl('https://staging.api.example.com');
```

| Box | Adds | Defaults |
|---|---|---|
| `LogConfig` | `HttpLogInterceptor`; `diagnostics` also prints interceptor diagnostics | request, headers, and bodies on; response headers off |
| `PerformanceConfig` | `PerformanceInterceptor` | `maxMetricsHistory` 1000 |
| `CacheConfig` | `CacheInterceptor` | 15 min, 50 MB |
| `ConcurrencyConfig` | `ConcurrencyLimitInterceptor` | every scope unlimited |
| `RateLimitConfig.none()`, `.pauseOnly(...)`, `.tokenBucket(...)` | nothing, `RetryAfterPauseInterceptor`, or `TokenBucketRateLimitInterceptor`; never both limiters | `none()` |
| `RetryConfig` | `RetryInterceptor` | 3 attempts, 1 s base delay, 30 s cap, 60 s deadline |

- The client orders the chain: your `interceptors`, log, performance, cache, concurrency limit, rate limit, retry, then `exceptionHandler` (null means `DefaultNetworkExceptionHandlerInterceptor`).
- `configure` owns `baseUrl`, the three timeouts, `contentType`, redirects, `validateStatus` (null means dio's default, 2xx only), and the header keys of `headers` and `userAgent`. Other `dio.options` fields, and headers you set by hand, survive it.
- Add interceptors with `addInterceptors` or the config, never with `dio.interceptors.add(...)`: `configure` rebuilds the list.
- When the client switches base URLs, give Retrofit APIs no absolute `baseUrl`, neither as the factory argument nor in `@RestApi(baseUrl:)`. An absolute one wins over `dio.options.baseUrl`.
- A box holding an inline lambda (`logPrint`, `onRetry`, `validateStatus`) is unequal on every `configure`, so its interceptor is rebuilt. Pass top-level functions.
- The next attempt of a request that was retrying across a `configure` passes the new chain, with its old retry settings.
- Call `dispose()` at the end of a test or a CLI. A Flutter app never needs it.
````

Replace the section `## Custom client: subclass \`BaseHttpClient\`` (up to the `Members:` line inclusive) with:

````markdown
## Custom client: subclass `BaseHttpClient`

Write one client class per external system, and pass its configuration to the super constructor:

```dart
class PaymentHttpClient extends BaseHttpClient {
  PaymentHttpClient()
    : super(
        dio: Dio(),
        config: HttpClientConfig(
          baseUrl: 'https://pay.example.com',
          retry: const RetryConfig(),
          interceptors: [PaymentAuthInterceptor()],
        ),
      );
}
```

An interceptor that needs the client's `dio`, such as a token refresh that re-sends, is built in the constructor body, where `dio` is ready:

```dart
class PaymentHttpClient extends BaseHttpClient {
  PaymentHttpClient(TokenStore store) : super(dio: Dio()) {
    configure(HttpClientConfig(
      baseUrl: 'https://pay.example.com',
      interceptors: [TokenRefreshInterceptor(dio, store)],
    ));
  }
}
```

Your interceptors run before `ConcurrencyLimitInterceptor`, so they follow its slot-safety rule (see "Interceptor order"): end `onResponse` and `onError` with `handler.next(...)` or `handler.reject(err, true)`.

Members: `dio`, `baseUrl`, `options` (the dio `BaseOptions`), `interceptors`, `currentConfig`, `configure(config)`, `setupBaseUrl(url)`, `addInterceptors(interceptors)`, `dispose()`.
````

In `## Converter-based calls`, change the table row for `get<T>` so it no longer says the converter may be async only there, and replace the paragraph that starts with `` `catchError: `` with:

> Every method accepts a converter that may be async. `catchError: (DioException e, StackTrace? st) => T?` returns a fallback value, and returning `null` rethrows the original error; a failure with no response, such as a timeout or a lost connection, recovers too. A body that is not a JSON object, or a converter that throws, fails with a `DioException` whose `error` is `CommonException(type: InputErrorType.invalidFormat)`, and `catchError` sees it. `isUseToken: false` sets `requestOptions.useToken` to false for your auth interceptor; `useToken` reads true when unset, Retrofit requests included.

- [ ] **Step 2: Update the interceptor catalog and every code sample**

In `## Interceptor catalog`, set the constructor column to:

| Class | Constructor |
|---|---|
| `RetryInterceptor` | `(config: RetryConfig(maxAttempts: 3, delay: 1 s, maxDelay: 30 s, maxDuration: 60 s, onRetry:), dio:, logPrint:, random:)` |
| `CacheInterceptor` | `(config: CacheConfig(duration: 15 min, maxSize: 50 MB), logPrint:)` |
| `ConcurrencyLimitInterceptor` | `(config: ConcurrencyConfig(global:, perHost:, hosts:, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500), logPrint:)` |
| `TokenBucketRateLimitInterceptor` | `(config: TokenBucketRateLimitConfig(global: [], perHost: [], hosts: {}, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500, pause: PauseConfig()), logPrint:)` |
| `RetryAfterPauseInterceptor` | `(config: PauseOnlyRateLimitConfig(pause: PauseConfig(maxPauseWait: 10 s, maxPause: 10 min, defaultPause: 5 s), maxQueueSize: 50), logPrint:)` |
| `PerformanceInterceptor` | `(config: PerformanceConfig(maxMetricsHistory: 1000, collectDetailedTimings: true), logPrint:)` |

Keep the other columns and rows. Below the table, add: "Every `config` defaults to its box built with no arguments. `logPrint` receives diagnostics; null prints nothing. Inside a `BaseHttpClient`, the client passes a printer that follows `LogConfig.diagnostics`."

Replace the paragraph that starts with `` `HttpClientConfig`: `` with:

> `HttpClientConfig` is freezed: `==`, `copyWith` (which can set a box to `null`), `effectiveHeaders`, and `applyTo(dio)`, which writes the owned options onto a bare `Dio`, merges `headers`, and sets `validateStatus` only when given. It has no presets.

Rewrite every remaining sample that passes `config: config` to an interceptor by the Task 3 migration table. In `## Rate limiting`, change the sentence about `burst` to: "`burst` (null means 10% of `permits`, at least 1; `effectiveBurst` returns the computed value)". Put a sentence under `## Interceptor order` saying that `BaseHttpClient` assembles this order itself, with your `interceptors`, `HttpLogInterceptor`, and `PerformanceInterceptor` in front, and that a hand-built chain on a bare `Dio` must follow it.

- [ ] **Step 3: Add the migration note to `http.md`**

Append:

````markdown
## Migrating to the 2.0.0 client config

An app that only uses `DefaultHttpClient.instance` needs no change, except where it relied on the old `catchError` behaviour below. A `BaseHttpClient` subclass drops its hooks:

```dart
// 1.x
class PaymentHttpClient extends BaseHttpClient {
  PaymentHttpClient() : super(dio: Dio());
  static final _config = HttpClientConfig.production();

  @override
  void setupOptions(Dio dio, BaseOptions options) {
    _config.applyTo(dio);
    options.baseUrl = 'https://pay.example.com';
  }

  @override
  void setupInterceptors(Dio dio, Interceptors interceptors) {
    interceptors.addAll([
      PaymentAuthInterceptor(),
      RetryInterceptor(config: _config, dio: dio),
      DefaultNetworkExceptionHandlerInterceptor(),
    ]);
  }
}

// 2.0.0
class PaymentHttpClient extends BaseHttpClient {
  PaymentHttpClient()
    : super(
        dio: Dio(),
        config: HttpClientConfig(
          baseUrl: 'https://pay.example.com',
          retry: const RetryConfig(),
          interceptors: [PaymentAuthInterceptor()],
        ),
      );
}
```

- `setupOptions` and `setupInterceptors` are gone. Pass `config:` to the super constructor, or call `configure` in the constructor body.
- Each interceptor takes its own box: `RetryInterceptor(config: const RetryConfig(), dio: dio)`, `CacheInterceptor()`, and so on (see the catalog).
- `HttpClientConfig` fields moved into boxes: `maxRetryAttempts` is `retry?.maxAttempts`, `retryDelay` is `retry?.delay`, `maxRetryDelay` is `retry?.maxDelay`, `maxRetryDuration` is `retry?.maxDuration`, `cacheDuration` is `cache?.duration`, `maxCacheSize` is `cache?.maxSize`, and `defaultHeaders` is `headers`. `enableCache` and `enablePerformanceMonitoring` become a null or non-null box; `enableLogging` becomes `LogConfig.diagnostics` inside a client, or `logPrint:` on a bare interceptor.
- `production()`, `development()`, and `test()` are removed; build your own values.
- Default timeouts are 20 s; they were 30 s in `HttpClientConfig`.
- `applyTo` no longer sets `validateStatus` to `status < 500`, so a 4xx fails in `onError` and reaches `RetryInterceptor`. Set `validateStatus` to keep the old behaviour.
- `maxConnectionsPerHost`, `idleConnectionTimeout`, `validateCertificates`, and `logBodies` are removed.
- `TokenBucketPolicy.burst` is the value you passed, possibly null; `effectiveBurst` returns the computed one.
- `addInterceptors` adds to the front of the chain, where interceptors see errors; it used to append after the exception handler.
- `configure` overwrites the options it owns; put `baseUrl`, timeouts, and headers in the config.
- A `catchError` fallback that returns `null` now rethrows; it used to resolve with null data.
- A non-object body or a throwing converter now fails with a `DioException` holding `InputErrorType.invalidFormat`, which `catchError` sees.
- `BaseHttpClient.config` is removed; read `options`.
- `RequestApiService` names its first parameter `path` and declares the same parameters as `BaseHttpClient`; only implementers update.
````

- [ ] **Step 4: Update the other files**

| File | Change |
|---|---|
| `skills/dart-falconx-package/SKILL.md` | Add a capability row `Client configuration` → `HttpClientConfig` boxes, `configure`, `currentConfig`, `setupBaseUrl` → dart_falconnect → `references/http.md`. In the `Interceptors` row, mention that each takes its own box. Replace the interceptor order line with: "Interceptor order (`BaseHttpClient` assembles it): your `interceptors`, `HttpLogInterceptor`, `PerformanceInterceptor`, `CacheInterceptor`, `ConcurrencyLimitInterceptor`, the rate limiter, `RetryInterceptor`, then the exception handler." |
| `skills/dart-falconx-package/references/json-rpc.md` | Replace the `catchWhenError` bullet with: "Transport failures surface as `DioException`; `.catchWhenError((e, st) => fallback)` resolves with a `JsonRpcResponse` carrying the request id, and returning `null` rethrows." |
| `skills/dart-falconx-package/references/models.md` | Next to `TokenBucketPolicy`, add `effectiveBurst` and value equality. |
| `dart_falconnect/CLAUDE.md` | Line 38: `BaseHttpClient` takes an `HttpClientConfig` and applies it with `configure`; no hooks. Line 40: `HttpClientConfig` is freezed, holds one box per feature, and has no presets. Update the interceptor chain section with the order of spec section 9. |
| `CLAUDE.md` (root) | Line 107: `BaseHttpClient` configures itself from `HttpClientConfig`. Line 149: prefix the order with `your interceptors → log → performance →`. |
| `_bmad-output/project-context.md` | Line 100: the converter may be async on every method, and a non-object body fails with `InputErrorType.invalidFormat`. |

- [ ] **Step 5: Check the docs against the source**

Run: `grep -rn "setupOptions\|setupInterceptors\|HttpClientConfig.production\|config: config\|enableLogging\|maxRetryAttempts" skills CLAUDE.md dart_falconnect/CLAUDE.md _bmad-output/project-context.md`
Expected: no match outside the migration note of `http.md`, which quotes the old API on purpose.

- [ ] **Step 6: Commit**

```bash
git commit -m "docs: document the client config, configure, and the 2.0.0 migration" -- skills/dart-falconx-package CLAUDE.md dart_falconnect/CLAUDE.md _bmad-output/project-context.md
```

---

### Task 8: The consumer skill in the plugin source (NTD OS repository)

**Files:**
- Modify: `/Users/nonthawit/Data/NTD OS/projects/indevelopment-plugins/nonthawit-pack/dart-engineer-pack/skills/expert-dart-api-integration/references/client.md`
- Modify: `/Users/nonthawit/Data/NTD OS/projects/indevelopment-plugins/nonthawit-pack/dart-engineer-pack/skills/expert-dart-api-integration/references/interceptor.md`

**Interfaces:**
- Consumes: the `BaseHttpClient` API of Task 6.
- Produces: a skill that teaches the config pattern instead of the removed hooks.

- [ ] **Step 1: Read the plugin rules**

Read `/Users/nonthawit/Data/NTD OS/projects/indevelopment-plugins/CLAUDE.md` and follow its rules for editing a pack, including any version bump in `.claude-plugin/plugin.json`.

- [ ] **Step 2: Rewrite the `dart_falconnect` section of `client.md`**

Replace the section `## If the Project Depends on \`dart_falconnect\`` (up to, not including, `## If the Project Does Not Depend on \`dart_falconnect\``) with:

````markdown
## If the Project Depends on `dart_falconnect`

Extend `BaseHttpClient` and pass one `HttpClientConfig` to its constructor. The config holds the per-server options (base URL, timeouts, content type, headers, `validateStatus`) and one box per cross-cutting feature (`log`, `performance`, `cache`, `concurrency`, `rateLimit`, `retry`), plus your own `interceptors`. `BaseHttpClient` assembles the chain in a fixed order: your interceptors, log, performance, cache, concurrency limit, rate limit, retry, then the exception handler, which is `DefaultNetworkExceptionHandlerInterceptor` unless `exceptionHandler` names a `NetworkExceptionHandlerInterceptor` subclass. It exposes `dio`, `baseUrl`, `options`, `currentConfig`, `configure`, `setupBaseUrl`, `addInterceptors`, `dispose`, and typed `get`/`post`/`put`/`patch`/`delete`/`postFormData`/`putFormData` helpers with automatic JSON conversion.

```dart
/// A ready-to-use singleton client with auth, retry, and error mapping.
class FooHttpClient extends BaseHttpClient {
  FooHttpClient._singleton()
    : super(
        dio: Dio(),
        config: HttpClientConfig(
          baseUrl: Env.fooBaseUrl,
          retry: const RetryConfig(),
          interceptors: [FooAuthInterceptor(), FooErrorMappingInterceptor()],
        ),
      );

  static final FooHttpClient instance = FooHttpClient._singleton();
}
```

An interceptor that needs the client's `dio`, such as a token refresh that re-sends with `dio.fetch`, is built in the constructor body, where `dio` is ready, and applied with `configure`:

```dart
class FooHttpClient extends BaseHttpClient {
  FooHttpClient(TokenStore store) : super(dio: Dio()) {
    configure(HttpClientConfig(
      baseUrl: Env.fooBaseUrl,
      interceptors: [FooTokenRefreshInterceptor(dio, store)],
    ));
  }
}
```

`configure` can run at any time: requests that start after it use the new config, running requests finish on the old one, and interceptors whose box is unchanged keep their state. Construct the Retrofit api from the client's `dio`, and give it no absolute `baseUrl` when the client switches base URLs:

```dart
final fooApi = FooApi(FooHttpClient.instance.dio);
```
````

- [ ] **Step 3: Correct `interceptor.md`**

In `## Chain Mechanics`, replace the first bullet with:

> - Order matters: dio runs `onRequest`, `onResponse`, and `onError` all in registration order (dio 5.11.1, `DioMixin.fetch`). Register auth before logging so logging sees the final headers. An interceptor that ends the error phase with `handler.reject(err)` skips every later interceptor, so the error-mapping or exception-handler interceptor goes last. With `dart_falconnect`, `BaseHttpClient` assembles the chain from `HttpClientConfig` in a fixed order; see `client.md`.

- [ ] **Step 4: Commit in the NTD OS repository**

```bash
cd "/Users/nonthawit/Data/NTD OS"
git commit -m "docs(dart-engineer-pack): teach the dart_falconnect config pattern and fix the chain-order claim" -- projects/indevelopment-plugins/nonthawit-pack/dart-engineer-pack
```

Tell the owner to run `/reload-plugins` afterwards.

---

### Task 9: Final gates (controller)

- [ ] **Step 1: Run every gate from the worktree root**

```bash
melos run analyze
melos run format
melos run test
cd dart_falconnect && dart compile js test/web/compile_smoke.dart -o /tmp/compile_smoke.js && dart test -p chrome test/web && cd ..
```

Expected: every command exits 0.

- [ ] **Step 2: Check the spec's success criteria**

Walk spec section 19 line by line and point each at a passing test or a command above. Walk spec section 15 and confirm each file changed.

- [ ] **Step 3: Request the whole-branch review**

Use superpowers:requesting-code-review on `feature/client-config` against `develop`. Fix findings through a new commit per fix.

- [ ] **Step 4: Hand over**

Report the branch, the commit list, and the gate results. The owner merges, pushes, and tags 2.0.0.
