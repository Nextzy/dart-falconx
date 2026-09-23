# Concurrency limit on `resilience` Bulkhead (SP3)

**Date:** 2026-09-23
**Packages:** `dart_falconnect`
**Version:** no bump. Every package is already 2.0.0.
**Series:** SP3 of 3. It builds on SP1 (`2026-09-23-token-bucket-rate-limit-design.md`) and SP2 (`2026-09-23-token-bucket-429-pause-design.md`). Owner ruling 2026-09-23: SP1, SP2, and SP3 ship together, and 2.0.0 is tagged only after SP3 lands. Breaking changes are allowed until the tag.
**Contract:** the SP1 and SP2 specs describe what exists. Every change this spec makes to them is listed in section 13.

## 1. Context

SP1 limits how fast the client sends; SP2 makes the client obey a server's 429 and 503. Neither limits how many requests are in flight at once. Partner APIs that allow "N concurrent requests per key", and servers that must cap their outbound connections, need that limit. SP3 adds a `ConcurrencyLimitInterceptor` built on the `Bulkhead` of `resilience` 1.1.3, which `dart_faltool` already re-exports.

dio has no hook that fires when a request ends. The interceptor takes a slot in `onRequest` and must give it back in `onResponse` or `onError`. Code reading of dio 5.11.1 on 2026-09-23 found where that can fail:

1. dio runs `onRequest`, `onResponse`, and `onError` in list order for every phase (`dio_mixin.dart:534, 564, 577`). A request interceptor that calls `resolve` without `callFollowingResponseInterceptor` skips every `onResponse`, including those of earlier interceptors (`dio_mixin.dart:466`). A `reject` without `callFollowingErrorInterceptor` skips every `onError`, unless the error has type `cancel` (`dio_mixin.dart:510-523`).
2. `CacheInterceptor` answers a cache hit with `handler.resolve(cachedEntry.response)` (`cache_interceptor.dart:82`). A concurrency interceptor placed before it would lose a slot on every cache hit.
3. `Options.compose` sets `cancelToken.requestOptions` to the request being composed (`options.dart:374`). A `CancelToken` shared by several requests therefore reports every cancel error with the options of the last request that used it. Releasing a slot by `err.requestOptions` would free one slot per shared token and lose the others.
4. `RetryInterceptor.onError` awaits `dio.fetch` of the next attempt before dio calls the next error interceptor. A concurrency interceptor placed after it still holds the first attempt's slot while the next attempt waits for one. With a limit of N, N requests that fail at the same time wait for each other forever.
5. A request that takes its tokens from `TokenBucketRateLimitInterceptor` and then waits for a slot is sent later, in a burst with other waiters. That breaks the SP1 ceiling on the wire and can send a request to a host that was paused while it waited (SP2 section 7, step 8). The slot must be taken before the tokens.
6. `DefaultNetworkExceptionHandlerInterceptor` rejects without `callFollowingErrorInterceptor` (`default_network_exception_handler_interceptor.dart:13`), so later error interceptors never run.
7. `Bulkhead` keeps no timer and has no `dispose`. It cannot remove a waiter. It holds a slot until the action's future completes (`bulkhead.dart:78-104`), so `execute(() => released.future)` holds a slot across dio phases.
8. `RetryAfterPause.wait` (`retry_after_pause.dart:156`) and `RetryInterceptor._wait` (`retry_interceptor.dart:260`) attach a `whenCancel` listener for every wait. A `Future` listener cannot be removed, so a long-lived token collects one dead listener per finished wait. This is SP2 deferred item M7.

## 2. Goals and non-goals

**Goals**

- Limit requests in flight per host and for all hosts together, with per-host overrides, in the style of SP1.
- Queue requests when no slot is free, with SP1's queue caps, and reject with SP2's local 429 when a queue is full.
- Give every slot back on every path: response, error, cancel (including a shared `CancelToken`), and `dispose()`.
- Never deadlock a retry or a re-send, whatever the interceptor order.
- Keep the SP1 ceiling and the SP2 pause true with the new interceptor in the chain.
- Keep per-host state bounded by active requests.
- Close SP2 deferred item M7.

**Non-goals**

- A maximum time in the queue. On a server, a `CancelToken` with a deadline bounds every wait at once (section 14).
- Building the concurrency limit into `TokenBucketRateLimitInterceptor`.
- Wrapping `HttpClientAdapter`. It would take the slot after the tokens (section 1, item 5), and adapter options belong to the `dart-falconx-client-config` phase.
- Limits shared between processes, isolates, or container instances.
- Limits keyed by API key or tenant. The key is the host, as in SP1 and SP2.
- Pruning SP1's per-host token buckets (section 8).
- Assembling the chain of `DefaultHttpClient`. The client-config phase owns it; this spec states the order it must follow (section 12).

## 3. Dependency changes

None. `Bulkhead` and `BulkheadRejectedException` come from `resilience`, re-exported by `dart_faltool`.

## 4. `ConcurrencyLimitInterceptor`

**File:** `dart_falconnect/lib/engine/https/interceptors/concurrency_limit_interceptor.dart`, exported from `interceptors.dart` in alphabetical order, after `cache_interceptor.dart`.

### 4.1 Constructor

```dart
ConcurrencyLimitInterceptor({
  required HttpClientConfig config,
  int? global,
  int? perHost,
  Map<String, int?> hosts = const {},
  bool queueRequests = true,
  int maxQueueSize = 50,
  int maxGlobalQueueSize = 500,
})
```

| Parameter | Meaning |
|---|---|
| `config` | `enableLogging` gates diagnostic prints, as in SP1. |
| `global` | Most requests in flight to all hosts together. `null` means no global limit. |
| `perHost` | Most requests in flight to a host missing from `hosts`. Each host gets its own `Bulkhead`. `null` means no host limit. |
| `hosts` | Limit for a named host. Replaces `perHost` for that host. A `null` value opts the host out of `perHost`; the host still counts toward `global`. |
| `queueRequests` | `false` gives every `Bulkhead` `maxQueued: 0`: a request with no free slot is rejected at once. |
| `maxQueueSize` | `maxQueued` of each host `Bulkhead`. |
| `maxGlobalQueueSize` | `maxQueued` of the global `Bulkhead`. |

Example: `global: 16, perHost: 4, hosts: {'pay.partner.com': 2, 'cdn.example.com': null}` lets `pay.partner.com` run 2 requests at once, gives `cdn.example.com` no host limit, and gives every other host 4. All of them share the 16 global slots.

**Validation.** The constructor throws `ArgumentError` when `global`, `perHost`, or a `hosts` value is set and below 1 (`Bulkhead` requires at least 1), when `maxQueueSize` or `maxGlobalQueueSize` is negative, or when a `hosts` key fails the host key rule of section 11. Host `Bulkhead`s are built lazily, so without these checks an invalid host limit would only surface on that host's first request. `hosts` is stored as an unmodifiable copy.

### 4.2 Statistics

`getStatistics()` returns a snapshot. Its cost grows with the number of hosts that have a request in flight or queued (section 8), never with the number of requests. Every map is unmodifiable. Declared in the interceptor's file.

```dart
@immutable
class ConcurrencyLimitStatistics {
  const ConcurrencyLimitStatistics({
    required this.forwarded,
    required this.rejected,
    required this.activeByHost,
    required this.waitingByHost,
    required this.globalActive,
    required this.globalWaiting,
  });

  final int forwarded;                 // passed to handler.next, retry attempts included
  final int rejected;                  // local 429 because a queue was full
  final Map<String, int> activeByHost; // Bulkhead.activeCount of each host Bulkhead
  final Map<String, int> waitingByHost;// Bulkhead.queueLength of each host Bulkhead
  final int globalActive;              // 0 when global is null
  final int globalWaiting;             // 0 when global is null
}
```

A host with no host `Bulkhead` does not appear in the host maps.

## 5. Permit

A permit is a private `_Permit` object, one per logical request. Each interceptor stores its permits in `RequestOptions.extra` under its own key, `dart_falconnect.concurrency.permit.<n>`, where `<n>` counts instances. With one shared key, a second `ConcurrencyLimitInterceptor` in the same chain would see the first one's held permit and skip its own limit (found while prototyping).

- The interceptor writes `options.extra = {...options.extra, key: permit}`. `extra` may be a const map, so it is never mutated in place (the lesson of SP2 section 9).
- `extra` survives `copyWith` and `dio.fetch(err.requestOptions)`, so a retry attempt and a re-send carry the permit of the request they repeat. An `Expando` keyed by the `RequestOptions` object would not survive `copyWith`. `PerformanceInterceptor` already keeps an object in `extra` (`performance_interceptor.dart:289`).
- An interceptor only reads its own key, so it only uses, releases, or counts its own permits.
- `HttpLogInterceptor` prints `extra` (`log_interceptor.dart:85`), so `toString()` returns a short form such as `ConcurrencyPermit(held)`.

**States**

```
waiting ──slot granted──▶ held ──release──▶ released
   │
   └──cancel or dispose──▶ abandoned ──slot granted──▶ released at once
```

`release()` is idempotent:

| State | Effect |
|---|---|
| `waiting` | Becomes `abandoned`; the waiting `onRequest` stops with a cancel. |
| `held` | Becomes `released`; the cancel watch is removed; the future returned to `Bulkhead` completes, and `Bulkhead` hands the slot to its oldest waiter. |
| `abandoned`, `released` | Nothing. |

An abandoned permit that later receives its slot releases it at once, so the next waiter proceeds.

## 6. Request flow

`onRequest`:

1. Resolve the host limit: `hosts[host]` when `hosts` contains the key, otherwise `perHost`. When the host limit and `global` are both null, count the request in `forwarded` and call `handler.next(options)` synchronously. No permit, no `Bulkhead`.
2. When disposed, reject with `DioExceptionType.cancel` and `StateError('ConcurrencyLimitInterceptor disposed')` as `error`.
3. When this interceptor's key in `extra` holds a permit in state `held`, reuse it: count the request in `forwarded` and call `handler.next(options)` without taking a slot. This is how a retry attempt or a re-send avoids waiting for the slot its own earlier attempt still holds (section 1, item 4).
4. When `options.cancelToken` is already cancelled, reject with `DioExceptionType.cancel` and the token's cancel error.
5. Create a permit in state `waiting`, store it in `extra`, and register it with `watchCancel` (section 10) when the request has a `CancelToken`.
6. Take the host slot, then the global slot, host first as in SP1: the host `Bulkhead` runs an action that, while the permit is still waiting, calls the global `Bulkhead`. A permit abandoned while it waited for the host slot gives that slot back before it would join the global queue (found in task review). Hosts without a host limit call the global `Bulkhead` directly and store nothing per host. The innermost action tells the permit it holds the slot and returns a future that completes when the permit is released.
7. Slot granted: the permit becomes `held`; count the request in `forwarded`; call `handler.next(options)`.
8. A `Bulkhead` queue is full (`BulkheadRejectedException`): remove the cancel watch, count the request in `rejected`, and call `handler.reject(localRateLimitRejection(options, error: e), true)`. No `Retry-After` is set; the wait is unknown. When the global `Bulkhead` rejects after the host slot was taken, the host `Bulkhead`'s `finally` returns the host slot. Unlike SP1's tokens, no slot stays spent.

**Cancel while waiting.** dio fails the chain at once (`listenCancelForAsyncTask`, `dio_mixin.dart:774-782`) and ignores the interceptor's later `handler` call. The cancel watch abandons the permit; when `Bulkhead` grants it the slot, the slot is released at once. `Bulkhead` cannot remove a waiter, so the cancelled request counts toward its queue cap until it reaches the head of the queue. During that time a full queue can reject new requests. This matches SP1's known limitation for tokens.

## 7. Releasing a slot

Four signals call `release()`:

| Signal | Permit found in |
|---|---|
| `onResponse` | `response.requestOptions.extra` |
| `onError` | `err.requestOptions.extra` |
| The request's own `CancelToken` cancels | The `watchCancel` callback registered in section 6, step 5 |
| `dispose()` | The set of permits in state `waiting` |

`onResponse` and `onError` then call `next`.

A cancel error whose `err.requestOptions` names another request on the same token (section 1, item 3) releases that request's permit. That is correct: that request was cancelled by the same token, and its own watch releases it too. Idempotence makes the double call harmless.

**Stream responses.** For `ResponseType.stream`, dio calls `onResponse` when the headers arrive, while the body is still streaming. The slot is released then. For other response types, dio reads the whole body before `onResponse`.

**Paths that still lose a slot.** Both are placement errors; section 12 forbids them.

1. An interceptor after this one answers in `onRequest` with `resolve`, or with a `reject` whose type is not `cancel`, without the call-following flag. Every `onResponse` or `onError` is skipped. Place caches and mocks before this interceptor.
2. An error interceptor before this one ends the error phase with `resolve`, or with `reject` without the call-following flag. Place exception handlers after this interceptor.

**Requests that never end.** A request that stalls holds its slot until a dio timeout fires. With `connectTimeout` or `receiveTimeout` set to null, a stalled request holds its slot forever. The doc comment requires timeouts.

## 8. Pruning idle state

**Host `Bulkhead`s.** When a slot request completes, and the host `Bulkhead` then has `activeCount == 0` and `queueLength == 0`, the interceptor removes that host's `Bulkhead`, provided the map still holds that same entry. The next request to the host builds a new one. An empty `Bulkhead` has no timer and no memory of past calls, so a new one behaves the same. The check is race-free: `onRequest` calls the host `Bulkhead` synchronously, and `Bulkhead.execute` takes a free slot before its first `await` (`bulkhead.dart:79-80`), so no request can hold a reference to a `Bulkhead` that is about to be removed without already counting as active. The global `Bulkhead` is never removed.

Without pruning, every distinct host would keep a `Bulkhead` forever: tenant subdomains, content hosts, or a server that forwards to many hosts would grow memory without bound.

**SP2 pauses.** `RetryAfterPause.observe` removes every `_until` entry that has ended before it records a new pause. `observe` only does work for a 429 or 503, so the sweep is rare. Before, a host paused once and never requested again kept its entry forever. A `@visibleForTesting int get trackedPauses` exposes the entry count to the test.

**SP1 token buckets: known limitation.** `TokenBucketRateLimitInterceptor` also keeps one `RateLimiter` and pipeline per host forever. They cannot be pruned safely: `RateLimiter` does not expose its remaining tokens (`_tokens` is private, `rate_limiter.dart:96`), and replacing a bucket that is not full with a new, full one breaks the ceiling. The documentation advises `hosts` with named keys instead of `perHost` when the set of hosts is open-ended. An upstream request for an available-permits getter would remove the limitation.

## 9. `dispose()`

- Every permit in state `waiting` is abandoned, and its request is rejected with `DioExceptionType.cancel` and `StateError('ConcurrencyLimitInterceptor disposed')`.
- Permits in state `held` are untouched. Their requests finish and release their slots as usual; abandoned waiters then drain from each `Bulkhead`.
- Afterwards, requests to a limited host are rejected with `DioExceptionType.cancel`, retry attempts included (section 6, step 2 runs before step 3). Requests to a host with no limit pass. This matches SP1.
- Idempotent. There is no timer to cancel.

Where to call it follows SP1 section 5.4. `Bulkhead` has no timer, so a missing `dispose()` never delays a CLI exit or fails `testWidgets`; it only lets queued requests of a discarded scope run.

## 10. Cancel watch (closes M7)

**File:** `dart_falconnect/lib/src/engine/https/cancel_watch.dart`, not exported.

```dart
/// Runs [onCancel] once if [token] cancels before the returned function is
/// called. The token gets one listener, however many watches exist.
void Function() watchCancel(
  CancelToken token,
  void Function(DioException error) onCancel,
);

@visibleForTesting
int activeCancelWatches(CancelToken token);
```

- An `Expando<_CancelHub>` attaches one hub to each token. The hub listens to `token.whenCancel` once and keeps the active callbacks in registration order.
- The returned function removes the callback. After it runs, `onCancel` is never called.
- On cancel, the hub calls each active callback once, in registration order, and clears the list.
- A watch registered on a token that is already cancelled runs `onCancel` in a microtask, unless it is removed first.
- A hub lives as long as its token. Memory per token is one listener plus the active watches.

**Users**

| Site | Registers | Removes |
|---|---|---|
| `ConcurrencyLimitInterceptor` | When a permit is created | When the permit is released |
| `RetryAfterPause.wait` | When a request is held | When the held request completes: released, disposed, or cancelled |
| `RetryInterceptor._wait` | When a retry delay starts | When the delay timer fires |

SP2 behaviour does not change. Only the listener lifetime does.

## 11. Shared internals

**Host key rule.** `_isHostKey` moves from `TokenBucketRateLimitInterceptor` (`token_bucket_rate_limit_interceptor.dart:316-325`) to `isHostKey` in `dart_falconnect/lib/src/engine/https/interceptors/host_key.dart`, not exported. Both interceptors use it. The rule is unchanged: not empty, and `Uri(scheme: 'http', host: key).host == key`. One copy keeps the two interceptors from drifting; SP2 already tightened the rule once.

**Local 429.** `ConcurrencyLimitInterceptor` imports `localRateLimitRejection` from `retry_after_pause.dart`, as the SP2 interceptors do. The doc comments of `localRateLimitRejection` and `isLocalRateLimit` name the concurrency queue as a third source.

Effects of reusing the local 429, as in SP2 section 8:

- `NetworkExceptionHandlerInterceptor` maps it to `NetworkLimitExceededException`.
- `RetryInterceptor` does not retry it.
- The pause core ignores it.
- Until the exception handler replaces the error with `NetworkLimitExceededException`, `err.error is BulkheadRejectedException` tells it apart from a token or pause rejection.
- It carries no `Retry-After`, so `recommendedRetryDelay` falls back to 1 minute.

## 12. Interceptor order

Replaces SP2 section 12. The documentation states this order and why:

```dart
interceptors.addAll([
  CacheInterceptor(...),
  ConcurrencyLimitInterceptor(...),
  TokenBucketRateLimitInterceptor(...), // or RetryAfterPauseInterceptor, never both
  RetryInterceptor(...),
  DefaultNetworkExceptionHandlerInterceptor(),
]);
```

| Rule | Reason |
|---|---|
| `CacheInterceptor` before `ConcurrencyLimitInterceptor` | A cache hit resolves without calling the response interceptors (section 1, item 2). A cache hit needs no slot; placed first, it also spends no token. |
| `ConcurrencyLimitInterceptor` before the rate limiter | The slot comes before the tokens, so the SP1 ceiling holds on the wire and the SP2 pause gate sees every request (section 1, item 5). |
| `ConcurrencyLimitInterceptor` before `RetryInterceptor` | The slot is released before the retry waits. Placed after it, permit reuse still prevents a deadlock, but the slot stays busy during the backoff. |
| An interceptor that re-sends in `onError` (auth refresh) after `ConcurrencyLimitInterceptor` | Its first attempt has released the slot. Placed before, the re-send reuses the permit. The client-config auth spec fixes its exact place. |
| `DefaultNetworkExceptionHandlerInterceptor` last | It rejects without calling later error interceptors (section 1, item 6). |
| Interceptors that only read, such as logging and performance | Anywhere, except that error loggers go before `RetryInterceptor` (SP2 section 16). |

**Head-of-line blocking.** A request holds its slot while the rate limiter holds it for a pause or for tokens. With a `global` limit, requests to a slow or paused host can fill the global slots and make other hosts wait. Set `perHost` below `global`, for example 4 and 16, so one host cannot take every global slot.

The client-config phase owns how `DefaultHttpClient` assembles its chain; it must follow this order.

## 13. Changes to the SP1 and SP2 contracts

| Where | Before | After |
|---|---|---|
| SP2 section 12 | Rate limiter, `RetryInterceptor`, exception handler | `CacheInterceptor`, `ConcurrencyLimitInterceptor`, rate limiter, `RetryInterceptor`, exception handler |
| SP2 section 5, `RetryAfterPause.wait` | One `whenCancel` listener per wait | `watchCancel`; same behaviour |
| SP2 section 5, `RetryAfterPause.observe` | Ended pauses stay until their host is requested | Ended pauses are removed on each `observe` |
| SP2 section 9, `RetryInterceptor._wait` | One `whenCancel` listener per wait | `watchCancel`; same behaviour |
| SP1 section 5.1 and SP2 section 10, host keys | Private `_isHostKey` | Shared `isHostKey`; same rule |
| SP2 section 8, local 429 doc comments | Token bucket or pause | Also a full concurrency queue |

## 14. Client and server deployment

These notes go into `http.md` (section 16). None needs code.

**Client (Flutter)**

- **Web: `Retry-After` and `Date` are hidden cross-origin.** A browser lets script read only the CORS-safelisted response headers (`Cache-Control`, `Content-Language`, `Content-Length`, `Content-Type`, `Expires`, `Last-Modified`, `Pragma`) unless the server lists more in `Access-Control-Expose-Headers`. dio's web adapter reads headers with `getAllResponseHeaders()` (`dio_web_adapter` 2.2.2, `adapter_impl.dart:385`). Without `Access-Control-Expose-Headers: Retry-After, Date`, a 429 pauses for `defaultPause`, a 503 does not pause, `RetryInterceptor` uses backoff, and the pause is measured with the client clock. Mobile builds are not affected. Tests cannot catch this, because the Chrome tests use a fake adapter.
- **Timeouts.** A request that stalls, for example while the app is in the background, holds its slot until a dio timeout fires. `DefaultHttpClient` sets 20 seconds. Never set `receiveTimeout` to null with this interceptor.
- **Web: the browser has its own cap.** Chrome allows 6 connections per host on HTTP/1.1, so a `perHost` above 6 has no further effect on the web, and time queued inside the browser does not appear in the statistics.

**Server (dart_frog)**

- **Limits are per process.** Each process, isolate, or container instance has its own limiters. For a partner limit of 10 requests per second across 4 instances, each instance needs 2.5. With autoscaling the count changes, so the client cannot guarantee a partner limit; the SP2 pause is the last line.
- **Limits are per host.** When a partner limits per API key and the server uses one key per tenant, a shared client limits every tenant together, and a 429 for one tenant pauses all of them. Build one client per credential.
- **Queued requests outlive the incoming request.** A load balancer may end the incoming request while the outbound request still waits, which later sends it to the partner and wastes quota. Pass a `CancelToken` that cancels at the incoming request's deadline. One token bounds every wait: the concurrency queue, tokens, pause holds, retry backoff, and the request in flight.
- **One client per process** (`http.md`, "build the client once per process"). A client built per request limits nothing.
- **Open-ended hosts.** Prefer `hosts` with named keys over `perHost` for the token bucket (section 8).

**Both**

- Until the client-config phase changes `applyTo` (`validateStatus: status < 500`), a server 429 arrives in `onResponse`, and `RetryInterceptor` does not retry it (SP2 section 16). The pause still works.

## 15. Testing plan

TDD. Every timing test runs under `fakeAsync` with a real `Dio`, and ends with no pending timer.

**Test helper.** `GatedAdapter` in `test/engine/https/interceptors/_scripted_adapter.dart` holds each request until the test releases it, honours dio's `cancelFuture`, and records each request's `sentAt` from `clock`. The existing `ScriptedAdapter` answers at once, so it cannot show requests in flight together.

**`concurrency_limit_interceptor_test.dart`**

- No limit: forwarded synchronously; statistics empty; no `Bulkhead`.
- `perHost: 2`: the third request waits until one finishes; waiters leave in FIFO order.
- `hosts` override; a `null` value opts out of `perHost` and still counts toward `global`; `global` is shared across hosts; hosts without a host limit store nothing per host.
- Queue full: local 429 with `BulkheadRejectedException` as `error` and `isLocalRateLimit`; not retried; a global rejection returns the host slot; `queueRequests: false` rejects at once.
- Release on success, on a server error, on a local 429 from the token bucket placed after it, and on the token bucket's cancel rejection.
- Cancel while waiting: the next waiter gets the slot.
- Cancel in flight with one `CancelToken` shared by 3 requests: all 3 slots come back (section 1, item 3).
- Limit 1 with `RetryInterceptor`: no deadlock in the documented order, and none when `ConcurrencyLimitInterceptor` is placed after `RetryInterceptor`.
- Limit 1 with an interceptor placed before it that re-sends with `dio.fetch(err.requestOptions)`: no deadlock.
- A cache hit, with `CacheInterceptor` first, takes no slot.
- An idle host `Bulkhead` is removed; statistics list only hosts with requests in flight or queued.
- `dispose()`: waiting requests cancelled; requests in flight untouched and released later; new limited requests and retry attempts cancelled; unlimited requests pass; idempotent.
- Validation: each limit below 1, each negative queue size, each invalid host key.
- `ResponseType.stream` releases in `onResponse`.
- Statistics counts; `toString()` of a permit.
- Two `ConcurrencyLimitInterceptor`s in one chain both enforce their limits and give their slots back.
- An interceptor after it that throws in `onRequest`; a request whose `extra` is a const map; a cancel after the response.
- A cancelled waiter still counts toward the queue cap until it reaches the head.

**`cancel_watch_test.dart`**

- Callbacks run once, in registration order; removed callbacks never run.
- A watch on a cancelled token runs in a microtask unless removed first.
- After 1,000 finished watches on one token, `activeCancelWatches` is 0.

**SP2 regression**

- After `RetryAfterPause.wait` and `RetryInterceptor._wait` finish, `activeCancelWatches` is 0.
- `observe` removes ended pauses.
- Every existing SP2 test passes unchanged, and the token bucket's host key tests pass against the shared rule.

**Chain (`rate_limit_retry_chain_test.dart`, extended, order of section 12)**

- The SP1 ceiling holds in every window with the concurrency limit in the chain.
- A request waiting for a slot is not sent to a host paused while it waited.
- A 429 starts a pause; the retry passes the pause gate and completes.

**Web gates.** `test/web/compile_smoke.dart` adds `ConcurrencyLimitInterceptor`; `test/web/engine_web_test.dart` sends one request through a chain with a limit of 1 in Chrome. Run `dart compile js` and `dart test -p chrome`.

**Gates.** `melos run analyze` (`--fatal-infos`) and `melos run test`.

## 16. Documentation

Per the skill maintenance rule, in the same change:

| File | Change |
|---|---|
| `skills/dart-falconx-package/SKILL.md` | Line 38: interceptor list gains `ConcurrencyLimitInterceptor`. Line 67: replace the order line with the order of section 12. |
| `skills/dart-falconx-package/references/http.md` | The new interceptor, parameters, and example; the order of section 12 with its reasons; the two placement errors of section 7; stream responses; required timeouts; `perHost` below `global`; `dispose()`; no `Retry-After` on its local 429; a new "Client and server deployment" section with section 14. |
| `skills/dart-falconx-package/references/third-party.md` | `resilience` row: `Bulkhead` backs `ConcurrencyLimitInterceptor`. |
| `CLAUDE.md` (root) | Replace "Order matters: auth → retry → cache → logging" with the order of section 12. |
| `dart_falconnect/CLAUDE.md` | Nine interceptors; the order line; a gotcha: wait on a `CancelToken` through `watchCancel`, never `whenCancel.then`. |
| `_bmad-output/project-context.md` | Line 102: replace the order line with the order of section 12. |

## 17. Implementation logistics

- Work in a git worktree on branch `feature/sp3-concurrency-limit` from `develop` (`fd480b6`). Implement with the `dart-engineer-pack:dart-engineer` agent.
- The client-config session works in parallel with uncommitted edits. SP3 does not touch `HttpClientConfig`; expect conflicts only in `http.md`, `SKILL.md`, and the `CLAUDE.md` files.
- Commit with `git commit -- <paths>` so another session's staged files are not swept in.
- No `Co-Authored-By` or AI attribution in commits.
- Do not push or tag. The owner tags 2.0.0 after SP3 merges. Before the tag, confirm the skill matches the source.

## 18. Risks

| Risk | Mitigation |
|---|---|
| A misplaced interceptor loses slots (section 7). | Section 12 order in the docs; chain tests in that order. Placement cannot be checked at run time. |
| Cancelled waiters keep their queue places. | Documented, as SP1 does for tokens. |
| Head-of-line blocking across hosts with a `global` limit. | Documented advice: `perHost` below `global`. |
| Two concurrent fetches of one `RequestOptions` object share a permit and exceed the limit. | Rare (for example, hedging); documented. |
| Stream responses release the slot before the body ends. | Documented. |
| `Retry-After` and `Date` are hidden on the web. | Section 14; a server checklist item. |
| Limits are per process. | Section 14. |
| SP1 per-host token buckets grow with distinct hosts. | Known limitation; `hosts` advice; upstream getter request. |
| `resilience` is young, with one maintainer. | As in SP1: MIT, and `Bulkhead` is 106 lines, easy to vendor. |

## 19. Success criteria

- No slot is lost on response, error, cancel (a shared `CancelToken` included), or `dispose()`.
- A limit of 1 with `RetryInterceptor` does not deadlock in either order.
- The SP1 ceiling and the SP2 pause hold with `ConcurrencyLimitInterceptor` in the chain.
- `activeCancelWatches` is 0 after every finished wait (M7 closed).
- Idle host `Bulkhead`s and ended pauses are removed.
- `melos run analyze`, `melos run test`, and both web gates pass.
- Every file in section 16 matches the code.
