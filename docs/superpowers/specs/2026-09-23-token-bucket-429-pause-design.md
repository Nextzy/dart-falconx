# 429 pause and retry rewrite (SP2)

**Date:** 2026-09-23
**Packages:** `dart_falmodel`, `dart_falconnect`
**Version:** no bump. Commit `781ab1a` already set every package to 2.0.0.
**Series:** SP2 of 3. It builds on SP1 (`2026-09-23-token-bucket-rate-limit-design.md`). Owner ruling 2026-09-23: SP1, SP2, and SP3 ship together, and 2.0.0 is tagged only after SP3 lands. Breaking changes are allowed until the tag.
**Contract:** the SP1 spec describes what exists. Every change this spec makes to SP1 behaviour is listed in section 11.

## 1. Context

SP1 limits how fast the client sends. It ignores what the server says back. Code reading on 2026-09-23 found these gaps:

1. A server 429 or 503 with `Retry-After` does not slow other requests to the same host. Only the failed request may wait, inside `RetryInterceptor`.
2. The local 429 from `TokenBucketRateLimitInterceptor` uses `handler.reject(err)` without `callFollowingErrorInterceptor`, so every `onError` is skipped (dio 5.11.1, `dio_mixin.dart:516-523`). Callers receive a raw `DioException` for a local 429 and a `NetworkLimitExceededException` for a server 429.
3. `RetryInterceptor` retries at most once. The nested retry sets `isRetry: true` (`retry_interceptor.dart:28-31, 79`), and the outer call does not loop.
4. `RetryInterceptor` returns the `Retry-After` delay before applying `maxRetryDelay` (`retry_interceptor.dart:149-151` against `163-165`), so `Retry-After: 3600` holds a request for an hour.
5. `RetryInterceptor` retries every HTTP method, including a `POST` after a receive timeout, which can submit a payment twice.
6. `RetryInterceptor` rebuilds `Options` by hand and drops `sendTimeout`, `receiveTimeout`, a per-request `baseUrl`, and other fields.
7. `Retry-After` is parsed with `int.tryParse` in three places (`retry_interceptor.dart:149`, `base_http_exception.dart:61`, `server_error_exception.dart:72`). None accepts the HTTP-date form, which RFC 9110 section 10.2.3 allows.
8. `HttpClientConfig.applyTo` sets `validateStatus` to `status < 500` (`http_client_config.dart:168`). With it, a server 429 arrives as a normal response in `onResponse`, not in `onError`.
9. dio runs `onRequest`, `onResponse`, and `onError` in list order for every phase (`dio_mixin.dart:533, 564, 577`). An interceptor must come before `RetryInterceptor` to see a server 429 before the retry is sent.

A review of `dio_smart_retry` 7.0.1 (MIT) and its issue tracker supplied ideas and warnings. Borrowed ideas: resend with `dio.fetch`, check the `CancelToken` after the delay, clone `FormData`, a per-request `disableRetry`, and a public attempt counter. Warnings: `fetch<void>` overwrites `responseType` (`dio_mixin.dart:419`; upstream issue #49, still open), open PR #47 parses dates with `dart:io` `HttpDate` and breaks web builds, and every method is retried (discussed in upstream issue #19). This spec rewrites our own interceptor. It does not vendor the package.

## 2. Goals and non-goals

**Goals**

- Part A: when a host answers 429, or 503 with `Retry-After`, hold or reject further requests to that host until the pause ends. Never forward a request to a paused host, and keep the SP1 ceiling true across the pause.
- Part A: offer the pause alone through a new `RetryAfterPauseInterceptor`, and built into `TokenBucketRateLimitInterceptor`.
- Part A: give callers the same exception type for a local 429 and a server 429.
- Part B: rewrite `RetryInterceptor` so it retries up to `maxRetryAttempts`, protects non-idempotent requests, honours and caps `Retry-After`, and stops at a total time limit.
- One `Retry-After` parser, shared by both parts and by the `dart_falmodel` exceptions.
- Fold in every SP1 deferred minor (section 10).

**Non-goals**

- A pause shared by all hosts. The pause is per host.
- `ConcurrencyLimitInterceptor` (SP3).
- Assembling the interceptor chain of `DefaultHttpClient`, and changing `applyTo`. Both belong to the `dart-falconx-client-config` phase. This spec only states the order the chain must follow (section 12).
- Retrying from `onResponse`. With `applyTo`, `RetryInterceptor` never sees a 4xx; fixing `validateStatus` belongs to the client-config phase.
- Retrying `DioExceptionType.unknown` socket errors such as "connection reset by peer" (upstream issue #45).
- Removing waiters from a `resilience` queue. The package has no such API.
- Decimal `Retry-After` values such as `1.5`. RFC 9110 allows digits only.

## 3. Dependency changes

- `dart_falmodel/pubspec.yaml`: add `http_parser: ^4.1.2` under `dependencies`. It is already in `pubspec.lock` as a dependency of `dio`, is published by `dart.dev`, and supports web and wasm. Its `parseHttpDate` accepts all three HTTP-date formats that RFC 9110 requires a recipient to accept.
- No other package changes.

## 4. `Retry-After` parser (`dart_falmodel`)

**File:** `dart_falmodel/lib/networks/https/retry_after.dart`, exported from `networks/https/https.dart`.

```dart
/// Converts a `Retry-After` value into a delay, or returns null when the
/// value cannot be read.
Duration? parseRetryAfter(String? value, {DateTime? serverDate});

extension RetryAfterHeaders on Headers {
  /// The `Retry-After` delay of this response, measured from the server's
  /// `Date` header when it is present and readable.
  Duration? get retryAfter;
}
```

**Rules**

| Input (after trimming) | Result |
|---|---|
| `null` or empty | `null` |
| Digits only, for example `120` | `Duration(seconds: 120)`; `null` when `int.tryParse` overflows |
| Anything `parseHttpDate` accepts | The date minus `serverDate`, or minus `clock.now()` when `serverDate` is null; `Duration.zero` when the date is in the past |
| Anything else, including `-5`, `1.5`, and garbage | `null` |

`retryAfter` reads `value('retry-after')` and passes the parsed `Date` header as `serverDate`; an unreadable `Date` header is ignored. Measuring from the server's own `Date` keeps a wrong client clock from stretching or shrinking the delay.

**Callers**

- `BaseHttpException.recommendedRetryDelay` uses `response?.headers.retryAfter` for 429. The fallback stays 1 minute.
- `NetworkServerException.recommendedRetryDelay` uses it for 503. The fallback stays 30 seconds.
- Part A and Part B use it through the same getter.

The only behaviour change for the exceptions: an HTTP-date `Retry-After` is now understood instead of falling back.

## 5. Pause core (`dart_falconnect`, internal)

**File:** `dart_falconnect/lib/engine/https/interceptors/retry_after_pause.dart`. Annotated `@internal` and not exported from `interceptors.dart`. Both interceptors in sections 6 and 7 use it, so the pause logic exists once.

```dart
@internal
class RetryAfterPause {
  RetryAfterPause({
    required Duration maxPauseWait,
    required Duration maxPause,
    required Duration? defaultPause,
    required int maxHeld,
    required bool holdRequests,
  });

  /// Decides what happens to a request for [host] right now.
  PauseAdmission admit(String host);

  /// Completes when the pause of [host] ends; fails when [cancelToken]
  /// cancels or [dispose] runs.
  Future<void> wait(String host, CancelToken? cancelToken);

  /// Whether [host] is paused at this moment.
  bool isPaused(String host);

  /// Starts or extends a pause from a server response.
  void observe(Response<dynamic> response);

  Map<String, int> get heldByHost;
  Map<String, DateTime> get pausedUntilByHost;

  void dispose();
}

@internal
sealed class PauseAdmission {}
// PausePass, PauseHold, PauseReject(Duration remaining)
```

**Starting a pause (`observe`)**

| Response | Pause length |
|---|---|
| 429 with a readable `Retry-After` | That delay |
| 429 without one | `defaultPause`; none when `defaultPause` is null |
| 503 with a readable `Retry-After` | That delay |
| 503 without one, or any other status | None |
| A local 429 (`isLocalRateLimit`, section 8) | None |

- A length of zero or less starts no pause.
- Every length is clamped to `maxPause`.
- The pause ends at `clock.now() + length`. A later pause for the same host replaces the end time only when it ends later; a pause is never shortened.
- The host key is `response.requestOptions.uri.host`, as in SP1.

**Admitting a request (`admit`)**

| State of the host | Result |
|---|---|
| Not paused | `PausePass` |
| Paused, remaining time at most `maxPauseWait`, `holdRequests` true, fewer than `maxHeld` requests held for this host | `PauseHold` |
| Paused, any other case | `PauseReject(remaining)` |

**Holding (`wait`)**

- Held requests wait in FIFO order per host.
- A `Timer` exists only while a host has held requests. It fires at the end time; if the pause was extended meanwhile, it is rescheduled. A pause with nobody held creates no timer, so a 10-minute pause does not keep a CLI alive or fail `testWidgets`.
- When the timer fires, every held request of the host is released in order. Each released request runs `admit` again, so a new 429 received during the hold is honoured.
- A `CancelToken` that cancels removes its request from the queue at once and fails the wait.
- `dispose()` cancels the timers, fails every held request with `StateError('RetryAfterPause disposed')`, and forgets every pause. Afterwards `admit` always passes and `observe` does nothing.

**Time source.** End times use `clock.now()` from `dart_faltool`'s `clock` re-export. `fakeAsync` wraps its callback in `withClock` (`fake_async.dart:182`), so `elapse` moves both the end times and the hold timers.

## 6. `RetryAfterPauseInterceptor` (`dart_falconnect`, new)

**File:** `dart_falconnect/lib/engine/https/interceptors/retry_after_pause_interceptor.dart`, exported from `interceptors.dart` in alphabetical order.

```dart
RetryAfterPauseInterceptor({
  required HttpClientConfig config,
  Duration maxPauseWait = const Duration(seconds: 10),
  Duration maxPause = const Duration(minutes: 10),
  Duration? defaultPause = const Duration(seconds: 5),
  int maxQueueSize = 50,
})
```

- Throws `ArgumentError` when `maxPauseWait` is negative, `maxPause` is not positive, `defaultPause` is not null and not positive, or `maxQueueSize` is negative.
- The pause core gets `holdRequests: true` and `maxHeld: maxQueueSize`.
- `onRequest`: `admit`; pass forwards, hold waits then admits again, reject sends the local 429 of section 8. A cancelled wait rejects with `DioExceptionType.cancel`.
- `onResponse` and `onError` (when `err.response` is not null): `observe`, then `next`.
- `dispose()`: disposes the pause core. Afterwards, requests pass without a pause.
- `config.enableLogging` gates diagnostic prints, as in SP1.

**Doc comment requirement.** State that `TokenBucketRateLimitInterceptor` already contains this pause, so a chain that uses it must not add `RetryAfterPauseInterceptor`. Two pause interceptors do not break requests, but they hold twice and apply two sets of limits.

## 7. `TokenBucketRateLimitInterceptor` changes

**Constructor.** Adds `maxPauseWait`, `maxPause`, and `defaultPause` with the defaults and validation of section 6. The pause core gets `holdRequests: queueRequests` and `maxHeld: maxQueueSize`. `hosts` key validation and immutability change per section 10.

**Request flow** (replaces SP1 section 5.2):

1. `admit(host)`.
2. Reject: count it in `rejected` and send the local 429 of section 8 with `Retry-After`.
3. Hold: `wait(host, cancelToken)`, then go back to step 1. A cancelled wait rejects with `DioExceptionType.cancel`.
4. Pass, host with no policy (its tiers and the global tiers are empty): count it in `forwarded` and call `handler.next` without awaiting, so the SP1 synchronous path is kept when no pause is active.
5. Pass, disposed: reject with `DioExceptionType.cancel`, as in SP1.
6. Pass, limited host: `await pipeline.execute(...)`. Queue-full and dispose errors behave as in SP1, except for the local 429 shape of section 8.
7. After the tokens: when `options.cancelToken` is cancelled, reject with `DioExceptionType.cancel` and do not count the request as forwarded.
8. After the tokens: when `isPaused(host)`, go back to step 1. The tokens are spent. When the pause ends, the request takes new tokens, so every forward still follows a token taken at that moment and the SP1 ceiling holds. Without this check, requests already queued for tokens would reach the server during the pause.
9. Count it in `forwarded` and call `handler.next`.

**`onResponse` and `onError`.** Call `observe`, then `next`. These hooks are new; SP1 only had `onRequest`.

**`dispose()`.** Also disposes the pause core, which fails held requests.

**Statistics** (replaces SP1 section 5.5):

```dart
@immutable
class TokenBucketRateLimitStatistics {
  final int forwarded;                         // excludes requests cancelled before forwarding
  final int rejected;                          // queue full and pause rejections
  final Map<String, int> waitingByHost;        // unchanged meaning, now unmodifiable
  final int globalWaiting;                     // unchanged
  final Map<String, int> heldByHost;           // requests held by a pause, per host
  final Map<String, DateTime> pausedUntilByHost; // end time of each active pause
}
```

The constructor gains the two new fields as required parameters. Every map in the snapshot is unmodifiable.

## 8. Local 429

Both interceptors build a local 429 the same way:

```dart
DioException(
  requestOptions: options,
  type: DioExceptionType.badResponse,
  error: cause, // RateLimitExceededException when a queue is full; null for a pause
  message: 'Rate limited locally for ${options.uri.host}',
  response: Response<dynamic>(
    requestOptions: options,
    statusCode: 429,
    statusMessage: 'Too Many Requests',
    headers: headers, // pause only: retry-after = remaining time, rounded up to whole seconds, at least 1
    extra: {_localRateLimitKey: true},
  ),
)
```

It is sent with `handler.reject(error, true)`, so every error interceptor runs, from the first in the list.

**Public marker.** `dart_falconnect/lib/engine/https/interceptors/local_rate_limit.dart`, exported from `interceptors.dart`:

```dart
extension LocalRateLimitResponse on Response<dynamic> {
  /// Whether this 429 was produced on the client, with no request sent.
  bool get isLocalRateLimit;
}
```

**Effects**

- `NetworkExceptionHandlerInterceptor` maps the local 429 to `NetworkLimitExceededException`, as it does a server 429. Its `recommendedRetryDelay` reads the `Retry-After` of a pause rejection.
- `RetryInterceptor` does not retry it (section 9).
- The pause core ignores it (section 5).
- Logging and crash-reporting interceptors now see it. They can filter with `isLocalRateLimit`.

## 9. `RetryInterceptor` rewrite

**Constructor**

```dart
RetryInterceptor({
  required HttpClientConfig config,
  required Dio dio,
  void Function(DioException error, int attempt, Duration delay)? onRetry,
  Random? random, // tests pass a seeded Random
})
```

`onRetry` runs before each wait. The stack trace is `error.stackTrace`. Diagnostic prints stay gated by `config.enableLogging`.

**`HttpClientConfig`.** Adds `maxRetryDuration`, the most time spent on retries of one request, measured from the first failure. Defaults: 60 seconds in the constructor, 2 minutes in `production()`, 10 seconds in `development()`, 5 seconds in `test()`. `copyWith` gains the parameter. SP2 owns the retry fields of `HttpClientConfig` (`maxRetryAttempts`, `retryDelay`, `maxRetryDelay`, `maxRetryDuration`); the client-config phase owns the rest.

**Per-request settings.** `dart_falconnect/lib/engine/https/interceptors/retry_request_options.dart`, exported from `interceptors.dart`. Extensions on `RequestOptions` and `Options`:

| Member | Type | Meaning |
|---|---|---|
| `disableRetry` | `bool` get/set | Never retry this request |
| `retryAttempts` | `int?` get/set | Overrides `config.maxRetryAttempts`; must not be negative |
| `retryNonIdempotent` | `bool` get/set | Allows the idempotent-only cases of the table below for `POST` and `PATCH` |
| `retryAttempt` | `int` get, `RequestOptions` only | 0 for the original request, 1 for the first retry, and so on |

Keys live in `extra` under a `dart_falconnect.retry.` prefix. Setters copy `extra` before writing, because it may be null or a const map (lessons of upstream PRs #18 and #36). The old `retryCount` and `isRetry` keys are removed.

**Loop.** `onError` of the original request owns every attempt:

1. When `err.requestOptions.retryAttempt > 0`, call `handler.next(err)`. The error belongs to a nested attempt; the loop that sent it handles it.
2. Decide (table below). Stop: `handler.next` with the most recent error.
3. Call `onRetry` and print the log line.
4. Wait for the delay. A cancel during the wait stops the loop at once and cancels the timer.
5. Build the attempt from the original `RequestOptions` with `copyWith`: set `retryAttempt`, and replace `FormData` with `FormData.clone()`. When cloning throws, stop.
6. `await dio.fetch<dynamic>(attempt)`. The type argument must be `dynamic`; any other type makes dio overwrite `responseType` (`dio_mixin.dart:419`, upstream issue #49). Success: `handler.resolve(response)`. A `DioException`: it becomes the most recent error; go to step 2.

Each attempt passes the whole chain again, so the pause gate, authentication, and logging apply to every attempt.

**Decision, first match wins**

| # | Condition | Result |
|---|---|---|
| 1 | `disableRetry`; type `cancel` or a cancelled `CancelToken`; `isLocalRateLimit`; body is a `Stream`; type `badCertificate` | Stop |
| 2 | The number of retries already sent reaches `retryAttempts ?? config.maxRetryAttempts` | Stop |
| 3 | Status 429, or type `connectionTimeout` | Retry for every method; the server did not process the request |
| 4 | Type `sendTimeout`, `receiveTimeout`, `connectionError`; status 408, 409, or 500 to 599 | Retry when the method is `GET`, `HEAD`, `OPTIONS`, `PUT`, `DELETE`, or `TRACE` (RFC 9110 section 9.2.2), or when `retryNonIdempotent` is set |
| 5 | Anything else | Stop |

**Delay**

- Status 429 or 503 with a readable `Retry-After`: that delay. When it exceeds `config.maxRetryDelay`, stop instead of waiting.
- Otherwise, full jitter: a random whole number of milliseconds from 0 to `min(maxRetryDelay, retryDelay × 2^(attempt - 1))`, inclusive.
- When the time since the first failure plus the delay exceeds `config.maxRetryDuration`, stop.

**Breaking changes** (listed in the `http.md` migration note):

- `POST` and `PATCH` are no longer retried after a 5xx, a timeout other than `connectionTimeout`, or a connection error, unless `retryNonIdempotent` is set.
- A `Retry-After` longer than `maxRetryDelay` ends retrying instead of waiting.
- Retries reach `maxRetryAttempts`; before, at most one retry ran.
- `extra['retryCount']` and `extra['isRetry']` are gone; read `retryAttempt`.
- Jitter is now full jitter instead of up to one extra second.

## 10. SP1 deferred minors

| Item | Change |
|---|---|
| `CancelToken` guard | Section 7 steps 3 and 7. A cancelled request is not forwarded and not counted. It still holds its place in a `resilience` token queue and still spends a token there; `resilience` cannot remove a waiter. |
| `hosts` keys | A key is valid when it is not empty and `Uri(scheme: 'http', host: key).host == key`. This rejects `API.a.com`, `api.a.com:8080`, ` api.a.com`, and `[::1]`, and accepts `::1` (probed on 2026-09-23). |
| Immutability | `perHost` and `hosts` are stored as unmodifiable copies, including each policy list. Statistics maps are unmodifiable. |
| Missing tests | An invalid `global` policy throws `ArgumentError`; host tiers and global tiers applied together. |
| `SKILL.md:53` | "without `Retry`, `Timeout`" becomes "without `Retry`, `RetryEvent`, `Timeout`". |
| `_bmad-output/project-context.md` | Delete line 214 (`utils/RateLimiter` no longer exists); rewrite line 216 (`dart_falconnect` has real tests). |

## 11. Changes to the SP1 contract

| SP1 section | SP1 says | SP2 says |
|---|---|---|
| 2 Goals | No policy means no limit | No policy means no token limit; a 429, or a 503 with `Retry-After`, still pauses the host |
| 5.1 Constructor | Keys must be lowercase | Stricter key rule, unmodifiable copies, three pause parameters |
| 5.2 Request flow | Tokens, then forward | Pause check before and after tokens, cancel guard (section 7) |
| 5.3 Errors | Local 429 has type `unknown` and skips every `onError` | Type `badResponse`, sent through every error interceptor, marked with `isLocalRateLimit`; new pause rejection |
| 5.4 `dispose()` | Disposes the limiters | Also fails held requests and forgets pauses |
| 5.5 Statistics | `forwarded` counts cancelled waiters | Excludes them; `rejected` includes pause rejections; `heldByHost` and `pausedUntilByHost` added; maps unmodifiable |
| 10 Risks | Synthetic 429 bypasses `NetworkExceptionHandlerInterceptor` | Resolved |
| Doc comment, known limitation | A cancelled waiter is counted as forwarded | It is no longer counted or forwarded; it still spends a token |

## 12. Interceptor order

The documentation states this order and why:

```dart
interceptors.addAll([
  TokenBucketRateLimitInterceptor(...), // or RetryAfterPauseInterceptor, never both
  RetryInterceptor(...),
  DefaultNetworkExceptionHandlerInterceptor(),
]);
```

- The rate limiter comes before `RetryInterceptor`, so it sees a server 429 and starts the pause before a retry is sent. A retry then passes the pause gate, and the total wait is the longer of the retry delay and the remaining pause, never their sum.
- `DefaultNetworkExceptionHandlerInterceptor` comes last, because it rejects without calling later error interceptors.
- Interceptors that only read requests, such as logging, may go anywhere.

The client-config phase owns how `DefaultHttpClient` assembles its chain; it must follow this order.

## 13. Testing plan

TDD. Every timing test runs under `fakeAsync`.

**`dart_falmodel/test/networks/https/retry_after_test.dart` (new directory)**

- Seconds; each HTTP-date format; the `Date` header offset; a past date gives zero; negative, decimal, empty, overflowing, and garbage values give null.
- `recommendedRetryDelay` of 429 and 503 with an HTTP-date. Time is fixed with `withClock`.

**`dart_falconnect/test/engine/https/interceptors/retry_after_pause_test.dart`**

- Extend but never shorten; clamp to `maxPause`; zero starts nothing; FIFO release; reject above `maxPauseWait` with the remaining time; hold queue full; cancel removes a waiter; `dispose`; a new 429 during a hold is honoured; no pending timer when nobody is held.

**`retry_after_pause_interceptor_test.dart`**

- Pass, hold, reject; observes from `onResponse` and from `onError`; a local 429 starts no pause.

**`token_bucket_rate_limit_interceptor_test.dart` (extended)**

- A 429 seen in `onResponse` and in `onError` pauses the host; a host with no policy is paused; no request is forwarded during a pause, including requests already queued for tokens; the ceiling holds in every window after the pause; `queueRequests: false` rejects instead of holding; the cancel guard; statistics; key validation cases; unmodifiable collections; an invalid `global` policy; host and global tiers together; the SP1 synchronous no-policy test still passes.

**`retry_interceptor_test.dart` (new; real `Dio` with a scripted fake `HttpClientAdapter`)**

- Retries up to `maxRetryAttempts`; `POST` not retried after 500 and retried after 429; `retryNonIdempotent`; a short `Retry-After` is used and a long one stops; jitter bounds with a seeded `Random`; `maxRetryDuration`; a cancel during the wait stops at once with no pending timer; a `Stream` body is not retried; `FormData` is cloned; `responseType: ResponseType.plain` survives a retry (upstream issue #49); `disableRetry`; `retryAttempts`; `onRetry` arguments; a local 429 is not retried.

**Integration (real chain of section 12, fake adapter)**

- A server `429` with `Retry-After: 3` makes the retry wait 3 seconds in total, not 6.
- A local 429 reaches the caller as `NetworkLimitExceededException`.

**Web gates.** `test/web/compile_smoke.dart` and `test/web/engine_web_test.dart` add `RetryAfterPauseInterceptor` and a `parseRetryAfter` call with an HTTP-date. Run `dart compile js` and `dart test -p chrome`.

**Gates.** `melos run analyze` (`--fatal-infos`) and `melos run test`.

## 14. Documentation

Per the skill maintenance rule, in the same change:

| File | Change |
|---|---|
| `skills/dart-falconx-package/SKILL.md` | Interceptor list gains `RetryAfterPauseInterceptor`; line 53 per section 10 |
| `skills/dart-falconx-package/references/http.md` | Both pause interceptors; the order of section 12 with its reasons; "a chain with `TokenBucketRateLimitInterceptor` does not add `RetryAfterPauseInterceptor`"; per-request retry settings; `isLocalRateLimit`; the retry migration note of section 9; `maxRetryDuration` |
| `skills/dart-falconx-package/references/errors.md` | Line 53: `recommendedRetryDelay` accepts an HTTP-date `Retry-After` |
| `skills/dart-falconx-package/references/models.md` | `parseRetryAfter` and `Headers.retryAfter` |
| `CLAUDE.md` (root) | Third-party table gains `http_parser` |
| `dart_falconnect/CLAUDE.md` | Interceptor list gains `RetryAfterPauseInterceptor` and the new `RetryInterceptor` behaviour; an interceptor order gotcha |
| `_bmad-output/project-context.md` | Section 10 |

## 15. Implementation logistics

- Work in a git worktree on a branch from `develop`. The client-config session works in parallel; expect conflicts in `http_client_config.dart` (SP2 edits only the retry fields), `http.md`, `SKILL.md`, and the `CLAUDE.md` files.
- Commit with `git commit -- <paths>` so another session's staged files are not swept in.
- No `Co-Authored-By` or AI attribution in commits.
- Do not push or tag. The owner tags 2.0.0 after SP3.

## 16. Risks

| Risk | Mitigation |
|---|---|
| With `applyTo`, `RetryInterceptor` never sees a 429, so a server 429 is not retried. | The pause still works through `onResponse`. The client-config phase owns the `validateStatus` fix; `http.md` states the gap. |
| Tokens taken by requests that meet a pause after their tokens are wasted. | Accepted. Nothing is forwarded with them, so the ceiling is unaffected. |
| Error interceptors see the error of every retry attempt, not only the last. | Inherent to re-entering the chain; `dio_smart_retry` behaves the same. Documented; `retryAttempt` lets a logger skip intermediate attempts. |
| Retrying a `POST` after 429 assumes the server did not act on it. | `disableRetry` per request. |
| Full jitter can retry almost at once. | Accepted pattern; a `Retry-After` still wins, and the pause gate still holds the host. |
| Local 429s now reach crash reporting. | `isLocalRateLimit` lets a reporter filter them. |
| Two sessions edit the same documentation files. | Worktree plus a rebase before merge. |

## 17. Success criteria

- After a server 429, no request to that host is sent before the pause ends, except requests already sent.
- The SP1 ceiling holds in every window, including after a pause.
- A retry never waits for the pause and its own delay added together.
- Callers receive `NetworkLimitExceededException` for a local 429 and a server 429 alike.
- `RetryInterceptor` retries up to `maxRetryAttempts` and never retries a `POST` after a 5xx without `retryNonIdempotent`.
- `melos run analyze`, `melos run test`, and both web gates pass.
- Every file in section 14 matches the code.
