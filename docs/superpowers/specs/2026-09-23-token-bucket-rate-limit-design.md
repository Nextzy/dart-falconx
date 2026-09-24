# Token bucket rate limiting on `resilience` (SP1)

**Date:** 2026-09-23
**Packages:** `dart_faltool`, `dart_falconnect`
**Version bump:** 1.0.11 → 2.0.0 (breaking: `RateLimitInterceptor` is removed)
**Series:** SP1 of 3. SP2 (adaptive pause on 429 / `Retry-After`) and SP3 (`ConcurrencyLimitInterceptor` on `Bulkhead`) get their own specs and depend on this one.

## 1. Context

`dart_falconnect` ships a hand-written `RateLimitInterceptor` (`lib/engine/https/interceptors/rate_limit_interceptor.dart`, 361 lines). Probes and benchmarks run on 2026-09-23 found four defects:

1. `_globalBucket.tryConsume() && hostBucket.tryConsume()` spends a global token and drops it when the host bucket is empty.
2. Every queued request starts its own `_processQueue` loop on the same queue. With 1,000 queued requests at 100 req/s, the last request left at 11.90 s instead of 10.0 s, using 1.79 s of CPU and 49.5 MB peak memory.
3. `_recordRequest` runs `removeWhere` over the whole request history on every request. The per-request cost grew from 61 µs at 10,000 requests to 384 µs at 50,000 requests inside one window.
4. The API takes whole requests per second only, so a limit such as "100 per minute" cannot be expressed.

The owner chose to rebuild the interceptor on the pub.dev package `resilience` (1.1.3, MIT, no dependencies). Its `RateLimiter` is a token bucket with a FIFO wait queue. In the same queue benchmark it released the last request at 10.01 s, using 0.10 s of CPU and 22.9 MB.

## 2. Goals and non-goals

**Goals**

- `dart_faltool` owns the `resilience` dependency and re-exports it (except the names that clash with `package:test`, section 3.2), so other projects can use its policies.
- A `TokenBucketPolicy` states a limit in any time unit, with ceiling semantics: never more than `permits` requests in any window of length `per`.
- A renamed `TokenBucketRateLimitInterceptor` applies policies globally, per host by default, and per host by override, with any number of tiers per scope.
- No policy means no limit. Limiting only happens where the consumer sets a policy.

**Non-goals**

- Adaptive pause on 429 / `Retry-After` (SP2).
- Concurrency limits (SP3).
- Other algorithms (fixed window, sliding window log, leaky bucket). A token bucket with the ceiling mapping covers the documented client-side cases.
- Wildcard or pattern host matching.
- A deprecated alias for `RateLimitInterceptor`. The constructor shape changes completely, so an alias could not keep old call sites compiling.

## 3. Dependency changes

### 3.1 `dart_faltool/pubspec.yaml`

- Add `resilience: ^1.1.3` under `dependencies`.
- Add `fake_async: ^1.3.3` under `dev_dependencies` (policy tests).

### 3.2 `dart_faltool/lib/dart_faltool.dart`

Add `export 'package:resilience/resilience.dart' hide Retry, RetryEvent, Timeout;` between `package:numeral/numeral.dart` and `package:retry/retry.dart` (alphabetical, enforced by `directives_ordering`).

`package:test` and `flutter_test` export their own `Retry` and `Timeout`. With a full re-export, a consumer test that imports the umbrella package and writes `timeout: Timeout(...)` or `@Retry(n)` fails with `ambiguous_import` (reproduced with `flutter analyze` on 2026-09-23). Hiding the two names follows the existing precedent (`fpdart hide State, Task`, `data hide Field`, `rrule hide DateTimeRrule`) and also avoids a fourth retry API in scope. `RetryEvent` is hidden with `Retry` because it only serves `Retry`. Consumers who want them import `package:resilience/resilience.dart` with a prefix.

A scan of the 116 packages in `pubspec.lock` plus the four workspace packages found one other clashing name: the dead `RateLimiter` class in `dart_falconnect/lib/utils/rate_limiter.dart`, which this change deletes (section 6).

## 4. `TokenBucketPolicy` (`dart_faltool`)

**File:** `dart_faltool/lib/utils/token_bucket_policy.dart`, exported from `lib/utils/utils.dart`.

```dart
@immutable
class TokenBucketPolicy {
  const TokenBucketPolicy({required this.permits, required this.per, int? burst})
      : _burst = burst;

  /// Most requests allowed in any window of length [per].
  final int permits;

  /// Window length.
  final Duration per;

  final int? _burst;

  /// Requests allowed back to back after an idle period.
  /// Defaults to 10% of [permits], at least 1.
  int get burst => _burst ?? math.max(1, permits ~/ 10);

  /// Throws an [ArgumentError] when this policy cannot be enforced.
  void validate();

  /// Builds the `resilience` limiter that enforces this policy.
  /// Calls [validate] first.
  RateLimiter toRateLimiter({int? maxQueueLength});
}
```

**Validation** (`validate()` throws `ArgumentError`; `toRateLimiter` calls it): `permits > 0`, `per > Duration.zero`, `1 <= burst <= permits`, and `per.inMicroseconds >= permits - burst + 1` (the floor `resilience` needs to schedule a refill). The const constructor has no asserts, so an invalid policy reports the same `ArgumentError` in debug and release builds.

**Ceiling mapping.** A token bucket with capacity `C` that adds one token every `Δ` admits at most `C + ceil(T / Δ) - 1` requests in a half-open window of length `T`. `toRateLimiter` sets capacity to `burst` and refills `permits - burst + 1` tokens per `per`:

```dart
final refills = permits - burst + 1;
RateLimiter(
  maxPermits: burst,
  // ceil(per * burst / refills), in whole microseconds
  per: Duration(
    microseconds: (per.inMicroseconds * burst + refills - 1) ~/ refills,
  ),
  maxQueueLength: maxQueueLength,
)
```

Rounding the refill period up makes refills slightly slower, never faster, so the ceiling still holds. Probe results under saturating demand for five minutes (`fakeAsync`):

| Policy | Max in any 60 s | Per calendar minute |
|---|---|---|
| 100 / min, burst 10 | 100 | 100, 91, 91, 91, 91 |
| 100 / min, burst 1 | 100 | 100, 100, 100, 100, 100 |
| 100 / min, burst 100 | 100 | 100, 1, 1, 1, 1 |
| 60 / min, burst 1 | 60 | 60, 60, 60, 60, 60 |

Steady throughput is `permits - burst + 1` per `per`. A larger burst lets more requests leave at once after idle time and lowers the steady rate. The ceiling never moves.

## 5. `TokenBucketRateLimitInterceptor` (`dart_falconnect`)

**File:** `dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart`, exported from `interceptors.dart` in alphabetical order.

### 5.1 Constructor

```dart
TokenBucketRateLimitInterceptor({
  required HttpClientConfig config,
  List<TokenBucketPolicy> global = const [],
  List<TokenBucketPolicy> perHost = const [],
  Map<String, List<TokenBucketPolicy>> hosts = const {},
  bool queueRequests = true,
  int maxQueueSize = 50,
  int maxGlobalQueueSize = 500,
})
```

| Parameter | Meaning |
|---|---|
| `config` | `enableLogging` gates the diagnostic prints, as before. |
| `global` | Tiers shared by every request to every host. Empty means no global limit. |
| `perHost` | Default tiers for a host missing from `hosts`. Each host gets its own limiters. Empty means no limit. |
| `hosts` | Tiers for a named host. Replaces `perHost` for that host. An empty list opts the host out of `perHost`. Keys match `options.uri.host` exactly; `Uri` lowercases hosts, so keys must be lowercase. |
| `queueRequests` | `false` sets every tier's `maxQueueLength` to 0: a request with no token is rejected at once. |
| `maxQueueSize` | `maxQueueLength` of each host tier. |
| `maxGlobalQueueSize` | `maxQueueLength` of each global tier. |

The constructor fails fast with `ArgumentError` when a `hosts` key is not lowercase (it could never match) or when any `global`, `perHost`, or `hosts` policy is invalid. Host limiters are built lazily, so without this check an invalid host policy would only surface on that host's first request.

### 5.2 Request flow

1. Resolve the host tiers: `hosts[host]` if the key exists, otherwise `perHost`.
2. On first sight of a host, build its chain once and cache it: the host's own `RateLimiter`s followed by the shared global `RateLimiter`s, wrapped in one `ResiliencePipeline`. A host whose combined list is empty caches "unlimited".
3. Unlimited host: call `handler.next(options)` synchronously. No limiter, no timer.
4. Limited host: `await pipeline.execute(() async {})`, then `handler.next(options)`.

Global limiters are built once in the constructor and shared by every host chain, so the global ceiling covers all hosts together. Host tiers run before global tiers, so a request holds its host tokens while it waits for a global token; no token is dropped on that path.

### 5.3 Errors

| Case | Result | Effect on other interceptors |
|---|---|---|
| A tier's queue is full (`RateLimitExceededException`) | `handler.reject(DioException(type: DioExceptionType.unknown, error: e, response: 429 Too Many Requests))`, same shape as the old class | `reject()` without `callFollowingErrorInterceptor` skips every `onError` (dio 5.11.1, `dio_mixin.dart:516-523`), so `RetryInterceptor` never retries a local 429. |
| Limiter disposed (`StateError`), for waiting and new requests to a limited host | `handler.reject(DioException(type: DioExceptionType.cancel, error: e))` | `onError` runs for cancels; `RetryInterceptor` skips cancels (`retry_interceptor.dart:113`). |

After `dispose()`, requests to an unlimited host still pass through; requests to a limited host are cancelled, because the limit can no longer be enforced. No limiter is built after disposal.

**Known limitation.** `resilience` consumes a token on acquire and has no refund or peek. When a later tier rejects, tokens already taken by earlier tiers are not returned. This only happens on the reject path while a scope is saturated. Document it; do not work around it.

### 5.4 `dispose()`

Disposes every `RateLimiter` the interceptor built. Idempotent. Refill timers otherwise run until each bucket is full again, which delays process exit and fails `testWidgets`.

Where to call it (for the doc comment and the skill):

| Context | Call |
|---|---|
| Flutter app, client lives as long as the app | Not needed. |
| Scoped client (DI scope, logout, environment switch) | When the scope ends: get_it `dispose:`, injectable `@disposeMethod`, Riverpod `ref.onDispose`. |
| `testWidgets` using a real client | At the end of the test body, or from the widget tree's `dispose`. `addTearDown` runs after Flutter's pending-timer check and is too late (verified). |
| Unit test under `fakeAsync` | End of the `fakeAsync` body. |
| CLI | In a `finally` before `main` returns. Without it, exit waits until every bucket is full again, `burst × per / (permits - burst + 1)` at most (a prototype measured 10.04 s after 100 requests). |
| Server (dart_frog) | Not needed. `SIGTERM` ends the process immediately (measured 0.02 s). |

### 5.5 Statistics

`getStatistics()` returns a typed snapshot in O(1), replacing the old `Map<String, dynamic>` and the per-request history scan.

```dart
@immutable
class TokenBucketRateLimitStatistics {
  const TokenBucketRateLimitStatistics({
    required this.forwarded,
    required this.rejected,
    required this.waitingByHost,
    required this.globalWaiting,
  });

  final int forwarded;               // passed to handler.next since construction
  final int rejected;                // rejected with 429 since construction
  final Map<String, int> waitingByHost;  // sum of queueLength across each host's own tiers
  final int globalWaiting;           // sum of queueLength across the global tiers
}
```

Declared in the interceptor's file.

### 5.6 Removed members

`windowSize`, `globalRateLimit`, `perHostRateLimit`, `clearQueues()`, `_TokenBucket`, `_QueuedRequest`, `_RequestInfo`, `_queueRequest`, `_processQueue`, `_recordRequest`. `clearQueues()` goes because rebuilding limiters refills every bucket and can break the ceiling inside the current window; `dispose()` covers cancellation.

### 5.7 Doc comment

Replace the clock-zone paragraph added in `fb8918f`. Refills are driven by `Timer`, not by reading the clock, so `fakeAsync`'s `elapse` advances them and `withClock(Clock.fixed(...))` has no effect on them. The class reads no time for limiting.

## 6. Deletions

- `dart_falconnect/lib/engine/https/interceptors/rate_limit_interceptor.dart` and its export.
- `dart_falconnect/lib/utils/rate_limiter.dart` (all code commented out, never imported or exported).
- `dart_falconnect/test/engine/https/interceptors/rate_limit_interceptor_test.dart` (replaced; its drain-the-queue scenario moves to the new test with adjusted numbers).

## 7. Testing plan

TDD. Every timing test runs under `fakeAsync`.

**`dart_faltool/test/utils/token_bucket_policy_test.dart`**

- Validation: `permits`, `per`, `burst` bounds, and the microsecond floor.
- Default burst: 10% of `permits`, at least 1.
- Ceiling: under saturating demand, the count in any window of length `per` never exceeds `permits`, for burst 1, the default, and `permits`.

**`dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart`**

- No policy: every request forwarded synchronously; `pendingTimers` stays empty.
- Within burst: forwarded without waiting.
- Queue drain: requests past burst wait and leave at the refill rate (moved scenario).
- `hosts` override replaces `perHost`; `hosts[host] = []` opts out.
- Multi-tier: the tighter tier governs; both ceilings hold.
- Global is shared across hosts.
- Queue full: 429 rejection with `RateLimitExceededException` as `error`.
- `queueRequests: false`: immediate 429 when no token.
- `dispose()`: waiting requests cancelled, new limited requests cancelled, unlimited requests pass, no pending timers.
- Statistics counts.

**Web gates:** update `test/web/compile_smoke.dart` and `test/web/engine_web_test.dart` to the new class; run `dart compile js` and `dart test -p chrome`. `resilience` compiled to JavaScript in a probe.

**Gates:** `melos run analyze` (`--fatal-infos`) and `melos run test`.

## 8. Documentation

Per the repository's skill maintenance rule, in the same change:

| File | Change |
|---|---|
| `skills/dart-falconx-package/SKILL.md` | Interceptor list (line 38); third-party list gains `resilience` (line 53). |
| `skills/dart-falconx-package/references/http.md` | New interceptor and parameters; the `dispose()` table from 5.4; a dart_frog warning: build the client once, never inside a per-request `provider` (a per-request client gave the partner 151 calls in one second with a 10 req/s limit). |
| `skills/dart-falconx-package/references/utils.md` | `TokenBucketPolicy`, ceiling semantics, burst trade-off. |
| `skills/dart-falconx-package/references/third-party.md` | `resilience` row with hidden `Retry`, `RetryEvent`, `Timeout` and why; which retry to use (`retry()`, `retryWithBackoff`, `RetryInterceptor`); pass `now: clock.now` to `CircuitBreaker` in `fakeAsync` tests, because its default `Stopwatch` is not faked. |
| `CLAUDE.md` (root) | Third-party table gains `resilience`. |
| `dart_falconnect/CLAUDE.md` | Interceptor list; drop the `utils/RateLimiter` gotcha; add the `dispose()` gotcha. |

## 9. Implementation logistics

- Another session commits to `develop` in parallel. Work in a git worktree on a branch from `develop`; expect conflicts only in `pubspec.lock` and the replaced test file.
- Commit the spec with `git commit -- <path>` so another session's staged files are not swept in.
- No `Co-Authored-By` or AI attribution in commits (repository `CLAUDE.md`).
- Bump every package from 1.0.11 to 2.0.0 and tag `2.0.0` after merge.

## 10. Risks

| Risk | Mitigation |
|---|---|
| `resilience` is young: one maintainer, 0 likes, 147 downloads in 30 days, created 2026-07-17. | MIT, no dependencies, about 230 lines for `RateLimiter`; can be vendored if abandoned. |
| Refill timers outlive the last request. | `dispose()` plus the call-site table; unlimited hosts create no timer. |
| Consumers build the client per request on a server. | Warning in `http.md` with the measured failure. |
| The synthetic 429 bypasses `NetworkExceptionHandlerInterceptor`. | Same behaviour as the old class; SP2 revisits error routing. |
| `resilience`'s `Retry` and `Timeout` clash with `package:test` in consumer tests. | Hidden in the re-export (section 3.2); a policy test uses `Timeout` to pin it. |

## 11. Success criteria

- `melos run analyze` and `melos run test` pass; both web gates pass.
- The ceiling test proves `permits` is never exceeded in any `per` window.
- No request is forwarded without passing every tier of its host and of global.
- No file under `dart_falconnect` or `dart_faltool` references `RateLimitInterceptor`, `_TokenBucket`, or `utils/rate_limiter.dart`.
- The skill and both `CLAUDE.md` files describe the new API.
