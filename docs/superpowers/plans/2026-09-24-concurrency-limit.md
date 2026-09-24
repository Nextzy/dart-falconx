# Concurrency Limit (SP3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `ConcurrencyLimitInterceptor`, which caps requests in flight per host and in total on `resilience` `Bulkhead`, and close SP2 deferred item M7 with a shared `CancelToken` watch.

**Architecture:** A standalone Dio interceptor takes a slot in `onRequest` through a `ResiliencePipeline` of a host `Bulkhead` and the global `Bulkhead`, holds it with a permit stored in `RequestOptions.extra`, and gives it back in `onResponse`, `onError`, on its own `CancelToken`, or on `dispose()`. Retry attempts and re-sends reuse a held permit, so no order deadlocks. An internal `watchCancel` helper gives each token one listener; `RetryAfterPause.wait` and `RetryInterceptor._wait` move onto it.

**Tech Stack:** Dart 3.13 (the repository's `new(...)` constructor syntax), dio 5.11.1, `resilience` 1.1.3 (re-exported by `dart_faltool`), `package:test`, `fake_async`, melos 8.

**Spec:** `docs/superpowers/specs/2026-09-23-concurrency-limit-design.md`

**Provenance:** every code block below passed `melos run analyze`, `melos run format`, `melos run test` (falconnect 123, falmodel 58, faltool 699, falconx 1), `dart compile js`, and `dart test -p chrome` (7) in a throwaway worktree on 2026-09-24. Mutation checks confirmed that the reuse, cancel-watch, prune, per-instance-key, and chain-order tests each fail when their feature is removed.

## Global Constraints

- Work in worktree `.claude/worktrees/sp3-concurrency-limit` on branch `feature/sp3-concurrency-limit`, created from `develop`.
- No new dependency in any `pubspec.yaml`.
- `dart_falconnect` compiles to the web: no `dart:io`, and no `int` shift or bitwise operator on a value that may exceed 32 bits.
- Lints: `very_good_analysis`, `melos run analyze` runs with `--fatal-infos`; single quotes; 80 columns; exports in barrel files sorted alphabetically.
- Interceptor files import the files they need directly (`package:dart_falconnect/engine/...`, `package:dart_falconnect/src/...`), as the neighbouring interceptors do.
- Files under `lib/src/` are never exported.
- Run `dart format` on every file you touch before committing.
- Commit with explicit paths. No `Co-Authored-By` line and no AI attribution in any commit message.
- Do not push and do not tag.

## Review Focus

1. **Two `ConcurrencyLimitInterceptor`s in one chain** (for example one global, one per host): each must enforce its own limit and give its slots back. A shared `extra` key lets the second reuse the first one's permit and skip its limit. Pinned by Task 3 test `two limiters in one chain both give their slots back`.
2. **An interceptor after the limiter throws in `onRequest`:** dio turns the throw into a rejection that calls the error interceptors; the slot must come back. Pinned by Task 3 test `an interceptor that throws after it gives the slot back`.
3. **A request whose `Options.extra` is a const map:** storing the permit must not throw `UnsupportedError`. Pinned by Task 3 test `a request with a const extra map passes and gives its slot back`.
4. **A cancelled waiter keeps its queue place** (documented limitation): it counts toward `maxQueueSize` until it reaches the head, then passes its slot on at once. Pinned by Task 3 test `a cancelled waiter keeps its queue place until it reaches the head`.
5. **A `CancelToken` cancelled after its request already finished:** nothing happens, no slot is freed twice, no error surfaces. Pinned by Task 3 test `a cancel after the response changes nothing`.

---

### Task 1: `watchCancel` helper

**Files:**
- Create: `dart_falconnect/lib/src/engine/https/cancel_watch.dart`
- Test: `dart_falconnect/test/engine/https/cancel_watch_test.dart`

**Interfaces:**
- Consumes: `CancelToken.whenCancel` (`Future<DioException>`), `CancelToken.cancelError` from dio 5.11.1.
- Produces: `void Function() watchCancel(CancelToken token, void Function(DioException error) onCancel)` and `@visibleForTesting int activeCancelWatches(CancelToken token)`, both in `package:dart_falconnect/src/engine/https/cancel_watch.dart`. Tasks 2 and 3 call `watchCancel`; their tests call `activeCancelWatches`.

- [ ] **Step 1: Write the failing test**

Create `dart_falconnect/test/engine/https/cancel_watch_test.dart`:

```dart
import 'dart:async';

import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('runs every watch once, in registration order, with the error', () {
    final token = CancelToken();
    final calls = <String>[];
    watchCancel(token, (e) => calls.add('first ${e.type.name}'));
    watchCancel(token, (e) => calls.add('second ${e.type.name}'));
    expect(activeCancelWatches(token), 2);

    token.cancel();
    return Future<void>.delayed(Duration.zero, () {
      expect(calls, ['first cancel', 'second cancel']);
      expect(activeCancelWatches(token), 0);
    });
  });

  test('a removed watch never runs', () {
    final token = CancelToken();
    var ran = false;
    final remove = watchCancel(token, (_) => ran = true);
    remove();
    expect(activeCancelWatches(token), 0);

    token.cancel();
    return Future<void>.delayed(Duration.zero, () => expect(ran, isFalse));
  });

  test('a watch on a cancelled token runs in a microtask', () async {
    final token = CancelToken()..cancel();
    await Future<void>.delayed(Duration.zero);
    var ran = false;
    watchCancel(token, (_) => ran = true);
    final removed = watchCancel(token, (_) => fail('removed watch ran'));

    expect(ran, isFalse);
    removed();
    await Future<void>.delayed(Duration.zero);
    expect(ran, isTrue);
  });

  test('finished watches leave nothing behind on a long-lived token', () {
    final token = CancelToken();
    for (var i = 0; i < 1000; i++) {
      watchCancel(token, (_) {})();
    }
    expect(activeCancelWatches(token), 0);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd dart_falconnect && dart test test/engine/https/cancel_watch_test.dart`
Expected: FAIL at load time, because `package:dart_falconnect/src/engine/https/cancel_watch.dart` does not exist.

- [ ] **Step 3: Write the implementation**

Create `dart_falconnect/lib/src/engine/https/cancel_watch.dart`:

```dart
import 'dart:async';

import 'package:dart_faltool/dart_faltool.dart' show visibleForTesting;
import 'package:dio/dio.dart';

final Expando<_CancelHub> _hubs = Expando<_CancelHub>('cancel watch hub');

/// Runs [onCancel] once if [token] cancels before the returned function is
/// called.
///
/// The token gets one `whenCancel` listener, however many watches exist,
/// and a finished watch leaves nothing behind. Listening to `whenCancel`
/// directly adds a listener per wait that can never be removed. A watch on
/// a token that is already cancelled runs in a microtask, unless it is
/// removed first.
void Function() watchCancel(
  CancelToken token,
  void Function(DioException error) onCancel,
) => (_hubs[token] ??= _CancelHub(token)).add(onCancel);

/// Watches on [token] that have neither run nor been removed.
@visibleForTesting
int activeCancelWatches(CancelToken token) =>
    _hubs[token]?._watches.length ?? 0;

class _CancelHub {
  new(this._token) {
    unawaited(_token.whenCancel.then(_fire));
  }

  final CancelToken _token;
  final Map<Object, void Function(DioException error)> _watches = {};
  bool _fired = false;

  void Function() add(void Function(DioException error) onCancel) {
    final key = Object();
    _watches[key] = onCancel;
    if (_fired) {
      scheduleMicrotask(() => _run(key, _token.cancelError!));
    }
    return () => _watches.remove(key);
  }

  void _fire(DioException error) {
    _fired = true;
    for (final key in _watches.keys.toList()) {
      _run(key, error);
    }
  }

  void _run(Object key, DioException error) {
    _watches.remove(key)?.call(error);
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd dart_falconnect && dart test test/engine/https/cancel_watch_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Analyze and format**

Run: `cd dart_falconnect && dart format lib/src/engine/https/cancel_watch.dart test/engine/https/cancel_watch_test.dart && dart analyze lib test`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add dart_falconnect/lib/src/engine/https/cancel_watch.dart dart_falconnect/test/engine/https/cancel_watch_test.dart
git commit -m "feat(dart_falconnect): add a CancelToken watch with one listener per token"
```

---

### Task 2: Move the SP2 waits onto `watchCancel` and forget ended pauses (closes M7)

**Files:**
- Modify: `dart_falconnect/lib/src/engine/https/interceptors/retry_after_pause.dart` (imports, `localRateLimitRejection` doc comment, `wait`, `observe`, new `trackedPauses` getter, `dispose` loop, `_Held`, new `_Waiter`)
- Modify: `dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart` (import, `_wait`)
- Test: `dart_falconnect/test/engine/https/interceptors/retry_after_pause_test.dart` (append 2 tests)
- Test: `dart_falconnect/test/engine/https/interceptors/retry_interceptor_test.dart` (append 1 test)

**Interfaces:**
- Consumes: `watchCancel` and `activeCancelWatches` from Task 1.
- Produces: `RetryAfterPause.trackedPauses` (`@visibleForTesting int get`). The behaviour of `wait`, `observe`, `dispose`, and `RetryInterceptor` is unchanged except that finished waits leave no `CancelToken` listener and `observe` drops ended pauses.

- [ ] **Step 1: Write the failing tests**

In `retry_after_pause_test.dart`, add this import after the `local_rate_limit.dart` import:

```dart
import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
```

Append inside `main()`, after the last test:

```dart
  test('finished holds leave no cancel watch on a long-lived token', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      final token = CancelToken();
      for (var i = 0; i < 3; i++) {
        unawaited(pause.wait('a.test', token));
      }
      expect(activeCancelWatches(token), 3);

      async.elapse(const Duration(seconds: 3));
      expect(activeCancelWatches(token), 0);

      pause.observe(_response(429, retryAfter: '3'));
      final failures = <Object>[];
      unawaited(pause.wait('a.test', token).catchError(failures.add));
      pause.dispose();
      async.flushMicrotasks();
      expect(failures.single, isA<StateError>());
      expect(activeCancelWatches(token), 0);
    });
  });

  test('observe forgets pauses that have ended', () {
    fakeAsync((async) {
      final pause = _pause()
        ..observe(_response(429, retryAfter: '3'))
        ..observe(_response(429, host: 'b.test', retryAfter: '60'));
      expect(pause.trackedPauses, 2);

      async.elapse(const Duration(seconds: 4));
      pause.observe(_response(429, host: 'c.test', retryAfter: '3'));

      expect(pause.trackedPauses, 2);
      expect(
        pause.pausedUntilByHost.keys,
        unorderedEquals(['b.test', 'c.test']),
      );
    });
  });
```

In `retry_interceptor_test.dart`, add the same import after the `retry_interceptor.dart` import, and append inside `main()`, after the last test:

```dart
  test('retry waits leave no cancel watch on a long-lived token', () {
    fakeAsync((async) {
      final token = CancelToken();
      final client = _Client([reply(503), reply(503), reply(200)])
        ..send((d) => d.get('/x', cancelToken: token));
      async.elapse(const Duration(milliseconds: 1));
      expect(client.retries, hasLength(1));
      expect(activeCancelWatches(token), 1);

      async.elapse(const Duration(seconds: 10));

      expect((client.outcome! as Response<dynamic>).statusCode, 200);
      expect(client.sent, 3);
      expect(activeCancelWatches(token), 0);
    });
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/retry_after_pause_test.dart test/engine/https/interceptors/retry_interceptor_test.dart`
Expected: FAIL. `retry_after_pause_test.dart` does not compile (`trackedPauses` is not defined); the retry test fails with `Expected: <1> Actual: <0>` for `activeCancelWatches`.

- [ ] **Step 3: Update `retry_after_pause.dart`**

Replace the imports

```dart
import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falmodel/networks/https/retry_after.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock;
```

with

```dart
import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
import 'package:dart_falmodel/networks/https/retry_after.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock, visibleForTesting;
```

Replace the first paragraph of the `localRateLimitRejection` doc comment

```dart
/// Builds the 429 that `TokenBucketRateLimitInterceptor` and
/// `RetryAfterPauseInterceptor` reject with.
///
/// [error] is the cause (a `RateLimitExceededException` when a queue is
/// full). [retryAfter] is the remaining pause; when given, it becomes a
```

with

```dart
/// Builds the 429 that `TokenBucketRateLimitInterceptor`,
/// `RetryAfterPauseInterceptor`, and `ConcurrencyLimitInterceptor` reject
/// with.
///
/// [error] is the cause: a `RateLimitExceededException` when a token queue
/// is full, a `BulkheadRejectedException` when a concurrency queue is
/// full. [retryAfter] is the remaining pause; when given, it becomes a
```

Replace the whole `wait` method (from `Future<void> wait(String host, CancelToken? cancelToken) {` to its closing brace; keep the doc comment above it) with:

```dart
  Future<void> wait(String host, CancelToken? cancelToken) {
    if (_disposed) {
      return Future.error(StateError('RetryAfterPause disposed'));
    }
    final held = _held.putIfAbsent(host, _Held.new);
    final waiter = _Waiter();
    held.waiters.add(waiter);
    _schedule(host, held);
    if (cancelToken != null) {
      waiter.unwatch = watchCancel(cancelToken, (error) {
        if (held.waiters.remove(waiter)) {
          waiter.completer.completeError(error);
          if (held.waiters.isEmpty) {
            held.timer?.cancel();
            _held.remove(host);
          }
        }
      });
    }
    return waiter.completer.future;
  }
```

Replace the whole `observe` method, doc comment included, with this block, which also adds the `trackedPauses` getter after it:

```dart
  /// Starts or extends a pause from a server response.
  ///
  /// A 429 pauses for its `Retry-After`, else for [defaultPause]; a 503
  /// pauses only for its `Retry-After`. A local 429 starts nothing. Every
  /// pause is clamped to [maxPause] and never shortens an existing one.
  void observe(Response<dynamic> response) {
    if (_disposed || response.isLocalRateLimit) {
      return;
    }
    final length = switch (response.statusCode) {
      429 => response.headers.retryAfter ?? defaultPause,
      503 => response.headers.retryAfter,
      _ => null,
    };
    if (length == null || length <= Duration.zero) {
      return;
    }
    final now = clock.now();
    // Forget ended pauses, so hosts that are never requested again do not
    // stay in the map.
    _until.removeWhere((_, end) => !end.isAfter(now));
    final host = response.requestOptions.uri.host;
    final until = now.add(length > maxPause ? maxPause : length);
    final current = _until[host];
    if (current == null || until.isAfter(current)) {
      _until[host] = until;
    }
  }

  /// Pause end times kept, ended ones included until the next [observe].
  @visibleForTesting
  int get trackedPauses => _until.length;
```

In `dispose`, replace

```dart
        held.waiters.removeFirst().completeError(
          StateError('RetryAfterPause disposed'),
        );
```

with

```dart
        held.waiters.removeFirst().fail(StateError('RetryAfterPause disposed'));
```

`_release` keeps `held.waiters.removeFirst().complete();`; it now calls `_Waiter.complete`.

Replace the `_Held` class at the end of the file with:

```dart
class _Held {
  final Queue<_Waiter> waiters = Queue<_Waiter>();
  Timer? timer;
}

/// A held request and the watch on its `CancelToken`.
class _Waiter {
  final Completer<void> completer = Completer<void>();

  /// Removes the `CancelToken` watch; set when the request has a token.
  void Function()? unwatch;

  void complete() {
    unwatch?.call();
    completer.complete();
  }

  void fail(Object error) {
    unwatch?.call();
    completer.completeError(error);
  }
}
```

- [ ] **Step 4: Update `RetryInterceptor._wait`**

In `retry_interceptor.dart`, add after the `local_rate_limit.dart` import:

```dart
import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
```

Replace the body of `_wait` after the early `isCancelled` return

```dart
    final done = Completer<bool>();
    final timer = Timer(delay, () {
      if (!done.isCompleted) done.complete(true);
    });
    if (cancelToken != null) {
      unawaited(
        cancelToken.whenCancel.then((_) {
          timer.cancel();
          if (!done.isCompleted) done.complete(false);
        }),
      );
    }
    return done.future;
```

with

```dart
    final done = Completer<bool>();
    void Function()? unwatch;
    final timer = Timer(delay, () {
      unwatch?.call();
      if (!done.isCompleted) done.complete(true);
    });
    if (cancelToken != null) {
      unwatch = watchCancel(cancelToken, (_) {
        timer.cancel();
        if (!done.isCompleted) done.complete(false);
      });
    }
    return done.future;
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/retry_after_pause_test.dart test/engine/https/interceptors/retry_interceptor_test.dart`
Expected: PASS, every existing test plus the 3 new ones.

Run: `cd dart_falconnect && dart test`
Expected: PASS. Every other SP2 test passes unchanged.

- [ ] **Step 6: Confirm no direct `whenCancel` listener remains**

Run: `grep -rn 'whenCancel' dart_falconnect/lib`
Expected: matches only in `lib/src/engine/https/cancel_watch.dart`.

- [ ] **Step 7: Analyze, format, commit**

Run: `cd dart_falconnect && dart format lib test && dart analyze lib test`
Expected: `No issues found!`

```bash
git add dart_falconnect/lib/src/engine/https/interceptors/retry_after_pause.dart dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart dart_falconnect/test/engine/https/interceptors/retry_after_pause_test.dart dart_falconnect/test/engine/https/interceptors/retry_interceptor_test.dart
git commit -m "fix(dart_falconnect): stop CancelToken listeners from outliving pause and retry waits"
```

---

### Task 3: `ConcurrencyLimitInterceptor`

**Files:**
- Create: `dart_falconnect/lib/src/engine/https/interceptors/host_key.dart`
- Create: `dart_falconnect/lib/engine/https/interceptors/concurrency_limit_interceptor.dart`
- Modify: `dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart` (use `isHostKey`, delete `_isHostKey`)
- Modify: `dart_falconnect/lib/engine/https/interceptors/interceptors.dart` (export)
- Modify: `dart_falconnect/lib/engine/https/interceptors/local_rate_limit.dart` (doc comment)
- Modify: `dart_falconnect/test/engine/https/interceptors/_scripted_adapter.dart` (add `GatedRequest`, `GatedAdapter`)
- Test: `dart_falconnect/test/engine/https/interceptors/concurrency_limit_interceptor_test.dart`

**Interfaces:**
- Consumes: `watchCancel` (Task 1); `localRateLimitRejection(RequestOptions, {Object? error, Duration? retryAfter})` from `retry_after_pause.dart`; `Bulkhead`, `BulkheadRejectedException`, `ResiliencePipeline`, `immutable` from `package:dart_faltool/dart_faltool.dart`.
- Produces:
  - `bool isHostKey(String key)` in `package:dart_falconnect/src/engine/https/interceptors/host_key.dart`.
  - `ConcurrencyLimitInterceptor({required HttpClientConfig config, int? global, int? perHost, Map<String, int?> hosts = const {}, bool queueRequests = true, int maxQueueSize = 50, int maxGlobalQueueSize = 500})` with `ConcurrencyLimitStatistics getStatistics()` and `void dispose()`.
  - `ConcurrencyLimitStatistics` with `int forwarded`, `int rejected`, `Map<String, int> activeByHost`, `Map<String, int> waitingByHost`, `int globalActive`, `int globalWaiting`.
  - Test helpers `GatedAdapter` (`requests`, `inFlight`) and `GatedRequest` (`options`, `sentAt`, `isDone`, `respond(int status, {Map<String, String> headers})`); Task 4 uses them.

- [ ] **Step 1: Add the gated test adapter**

In `_scripted_adapter.dart`, replace the imports

```dart
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
```

with

```dart
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:dio/dio.dart';
```

and append at the end of the file:

```dart
/// One request held by a [GatedAdapter] until the test answers it.
class GatedRequest {
  new(this.options) : sentAt = clock.now();

  final RequestOptions options;

  /// When the request reached the adapter, read from `clock`, which
  /// `fakeAsync` controls.
  final DateTime sentAt;
  final Completer<ResponseBody> _answer = Completer<ResponseBody>();
  bool _cancelled = false;

  /// Whether the request was answered or cancelled.
  bool get isDone => _answer.isCompleted || _cancelled;

  /// Answers with [status], optional headers, and a JSON body.
  void respond(int status, {Map<String, String> headers = const {}}) =>
      _answer.complete(reply(status, headers: headers)(options));
}

/// A fake transport that holds every request until the test answers it,
/// so a test can see how many requests are in flight at once.
class GatedAdapter implements HttpClientAdapter {
  final List<GatedRequest> requests = [];

  /// Requests neither answered nor cancelled.
  List<GatedRequest> get inFlight =>
      requests.where((request) => !request.isDone).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    final request = GatedRequest(options);
    requests.add(request);
    unawaited(cancelFuture?.then((_) => request._cancelled = true));
    return request._answer.future;
  }

  @override
  void close({bool force = false}) {}
}
```

- [ ] **Step 2: Write the failing test**

Create `dart_falconnect/test/engine/https/interceptors/concurrency_limit_interceptor_test.dart`:

```dart
import 'dart:async';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_faltool/dart_faltool.dart'
    show BulkheadRejectedException, TokenBucketPolicy;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

const _config = HttpClientConfig(
  enableCache: false,
  maxRetryAttempts: 1,
  retryDelay: Duration(seconds: 1),
  maxRetryDelay: Duration(seconds: 1),
);

Dio _dio(HttpClientAdapter adapter, List<Interceptor> Function(Dio) chain) {
  final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll(chain(dio));
  return dio;
}

/// Starts a GET and records its outcome: a response or an error.
void _get(
  Dio dio,
  String url,
  List<Object> outcomes, {
  CancelToken? cancelToken,
  Options? options,
}) {
  unawaited(
    dio
        .get<dynamic>(url, cancelToken: cancelToken, options: options)
        .then(outcomes.add, onError: outcomes.add),
  );
}

/// Runs every timer and microtask due now.
void _settle(FakeAsync async) => async.elapse(Duration.zero);

List<String> _urls(Iterable<GatedRequest> requests) => [
  for (final request in requests) request.options.uri.toString(),
];

/// Records what the interceptor does with a request, standing in for the
/// rest of the Dio chain.
class _RecordingHandler extends RequestInterceptorHandler {
  final forwarded = <RequestOptions>[];

  @override
  void next(RequestOptions requestOptions) => forwarded.add(requestOptions);
}

/// Re-sends the first failed request from `onError`, as an auth refresh
/// interceptor does.
class _ResendOnce extends Interceptor {
  new(this.dio);

  final Dio dio;
  bool _sent = false;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_sent) {
      handler.next(err);
      return;
    }
    _sent = true;
    try {
      handler.resolve(await dio.fetch<dynamic>(err.requestOptions));
    } on DioException catch (error) {
      handler.next(error);
    }
  }
}

void main() {
  test('forwards synchronously and builds nothing without a limit', () {
    final limiter = ConcurrencyLimitInterceptor(config: _config);
    final handler = _RecordingHandler();

    unawaited(
      limiter.onRequest(RequestOptions(path: 'https://a.test/x'), handler),
    );

    expect(handler.forwarded, hasLength(1));
    final stats = limiter.getStatistics();
    expect(stats.forwarded, 1);
    expect(stats.activeByHost, isEmpty);
    expect(stats.globalActive, 0);
  });

  test('perHost holds extra requests and releases them in FIFO order', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 2);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      for (final path in ['/1', '/2', '/3', '/4']) {
        _get(dio, path, outcomes);
      }
      _settle(async);
      expect(_urls(adapter.requests), ['https://a.test/1', 'https://a.test/2']);
      expect(limiter.getStatistics().waitingByHost, {'a.test': 2});

      adapter.requests[1].respond(200);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/1', 'https://a.test/3']);

      adapter.requests[0].respond(200);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/3', 'https://a.test/4']);
      expect(limiter.getStatistics().activeByHost, {'a.test': 2});

      for (final request in adapter.inFlight) {
        request.respond(200);
      }
      _settle(async);
      expect(outcomes, hasLength(4));
      expect(limiter.getStatistics().forwarded, 4);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('hosts overrides perHost, and a null value opts out', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        perHost: 1,
        hosts: {'b.test': 2, 'c.test': null},
      );
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      for (final host in ['a', 'a', 'b', 'b', 'b', 'c', 'c', 'c']) {
        _get(dio, 'https://$host.test/x', outcomes);
      }
      _settle(async);

      int sentTo(String host) =>
          adapter.requests.where((r) => r.options.uri.host == host).length;
      expect(sentTo('a.test'), 1);
      expect(sentTo('b.test'), 2);
      expect(sentTo('c.test'), 3);
      expect(limiter.getStatistics().activeByHost.keys, ['a.test', 'b.test']);
    });
  });

  test('global is shared by every host, opted-out hosts included', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        global: 2,
        hosts: {'c.test': null},
      );
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      for (final host in ['a', 'b', 'c']) {
        _get(dio, 'https://$host.test/x', outcomes);
      }
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/x', 'https://b.test/x']);
      final stats = limiter.getStatistics();
      expect(stats.globalActive, 2);
      expect(stats.globalWaiting, 1);
      // Hosts without a host limit store nothing per host.
      expect(stats.activeByHost, isEmpty);

      adapter.requests[0].respond(200);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://b.test/x', 'https://c.test/x']);
    });
  });

  test('a full queue fails with a local 429 that is not retried', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        perHost: 1,
        maxQueueSize: 1,
      );
      final dio = _dio(
        adapter,
        (dio) => [limiter, RetryInterceptor(config: _config, dio: dio)],
      );
      final outcomes = <Object>[];

      for (final path in ['/1', '/2', '/3']) {
        _get(dio, path, outcomes);
      }
      _settle(async);

      final error = outcomes.single as DioException;
      expect(error.error, isA<BulkheadRejectedException>());
      expect(error.response?.statusCode, 429);
      expect(error.response?.isLocalRateLimit, isTrue);
      expect(error.response?.headers.value('retry-after'), isNull);
      expect(limiter.getStatistics().rejected, 1);

      async.elapse(const Duration(seconds: 5));
      expect(adapter.requests, hasLength(1));
    });
  });

  test('a global rejection gives the host slot back', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        global: 1,
        perHost: 2,
        maxGlobalQueueSize: 0,
      );
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes);
      _settle(async);

      expect(outcomes.single, isA<DioException>());
      expect(limiter.getStatistics().activeByHost, {'a.test': 1});
    });
  });

  test('queueRequests false rejects at once when no slot is free', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        perHost: 1,
        queueRequests: false,
      );
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes);
      _settle(async);

      expect((outcomes.single as DioException).response?.statusCode, 429);
      expect(adapter.requests, hasLength(1));
    });
  });

  test('a server error gives the slot back', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes);
      _settle(async);
      adapter.requests[0].respond(500);
      _settle(async);

      expect(_urls(adapter.inFlight), ['https://a.test/2']);
    });
  });

  test('a local 429 and a cancel from the token bucket give the slot back', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final bucket = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
        queueRequests: false,
      );
      final dio = _dio(adapter, (_) => [limiter, bucket]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _settle(async);
      _get(dio, '/2', outcomes);
      _settle(async);
      expect((outcomes.last as DioException).response?.isLocalRateLimit, true);
      expect(limiter.getStatistics().activeByHost, isEmpty);

      bucket.dispose();
      _get(dio, '/3', outcomes);
      _settle(async);
      expect((outcomes.last as DioException).type, DioExceptionType.cancel);
      expect(limiter.getStatistics().activeByHost, isEmpty);
    });
  });

  test('a request cancelled while it waits lets the next one through', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];
      final token = CancelToken();

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes, cancelToken: token);
      _get(dio, '/3', outcomes);
      _settle(async);
      token.cancel();
      _settle(async);
      expect((outcomes.single as DioException).type, DioExceptionType.cancel);

      adapter.requests[0].respond(200);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/3']);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('one CancelToken shared by requests in flight frees every slot', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 3);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];
      final token = CancelToken();

      for (final path in ['/1', '/2', '/3']) {
        _get(dio, path, outcomes, cancelToken: token);
      }
      _settle(async);
      expect(adapter.inFlight, hasLength(3));

      token.cancel();
      _settle(async);
      expect(outcomes, hasLength(3));
      expect(limiter.getStatistics().activeByHost, isEmpty);

      for (final path in ['/4', '/5', '/6']) {
        _get(dio, path, outcomes);
      }
      _settle(async);
      expect(adapter.inFlight, hasLength(3));
    });
  });

  for (final limiterFirst in [true, false]) {
    test('a retry with a limit of 1 does not deadlock '
        '(limiter ${limiterFirst ? 'before' : 'after'} RetryInterceptor)', () {
      fakeAsync((async) {
        final adapter = ScriptedAdapter([reply(503), reply(200)]);
        final limiter = ConcurrencyLimitInterceptor(
          config: _config,
          perHost: 1,
        );
        final dio = _dio(adapter, (dio) {
          final retry = RetryInterceptor(config: _config, dio: dio);
          return limiterFirst ? [limiter, retry] : [retry, limiter];
        });
        final outcomes = <Object>[];

        _get(dio, '/x', outcomes);
        async.elapse(const Duration(seconds: 2));

        expect((outcomes.single as Response<dynamic>).statusCode, 200);
        expect(adapter.requests, hasLength(2));
        expect(limiter.getStatistics().activeByHost, isEmpty);
      });
    });
  }

  test('a re-send from an interceptor placed before it reuses the slot', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(401), reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (dio) => [_ResendOnce(dio), limiter]);
      final outcomes = <Object>[];

      _get(dio, '/x', outcomes);
      _settle(async);

      expect((outcomes.single as Response<dynamic>).statusCode, 200);
      expect(limiter.getStatistics().activeByHost, isEmpty);
    });
  });

  test('a cache hit, with CacheInterceptor first, takes no slot', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(
        adapter,
        (_) => [CacheInterceptor(config: const HttpClientConfig()), limiter],
      );
      final outcomes = <Object>[];

      _get(dio, '/x', outcomes);
      _settle(async);
      _get(dio, '/x', outcomes);
      _settle(async);

      expect(outcomes, hasLength(2));
      expect(adapter.requests, hasLength(1));
      expect(limiter.getStatistics().forwarded, 1);
      expect(limiter.getStatistics().activeByHost, isEmpty);
    });
  });

  test('dispose cancels waiters and leaves requests in flight alone', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(
        config: _config,
        perHost: 1,
        hosts: {'free.test': null},
      );
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes);
      _settle(async);
      limiter
        ..dispose()
        ..dispose();
      _settle(async);
      final waiter = outcomes.single as DioException;
      expect(waiter.type, DioExceptionType.cancel);
      expect(waiter.error, isA<StateError>());

      adapter.requests[0].respond(200);
      _settle(async);
      expect((outcomes.last as Response<dynamic>).statusCode, 200);

      _get(dio, '/3', outcomes);
      _get(dio, 'https://free.test/x', outcomes);
      _settle(async);
      expect((outcomes[2] as DioException).type, DioExceptionType.cancel);
      expect(_urls(adapter.inFlight), ['https://free.test/x']);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('dispose cancels a retry that would reuse a held slot', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(
        adapter,
        (dio) => [RetryInterceptor(config: _config, dio: dio), limiter],
      );
      final outcomes = <Object>[];

      _get(dio, '/x', outcomes);
      _settle(async);
      adapter.requests.single.respond(503);
      _settle(async);
      limiter.dispose();
      async.elapse(const Duration(seconds: 2));

      expect((outcomes.single as DioException).type, DioExceptionType.cancel);
      expect(adapter.requests, hasLength(1));
    });
  });

  test('a stream response gives the slot back when its headers arrive', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(
        dio,
        '/1',
        outcomes,
        options: Options(responseType: ResponseType.stream),
      );
      _get(dio, '/2', outcomes);
      _settle(async);
      adapter.requests[0].respond(200);
      _settle(async);

      expect(outcomes.single, isA<Response<dynamic>>());
      expect(_urls(adapter.inFlight), ['https://a.test/2']);
    });
  });

  test('an idle host limit is forgotten', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, 'https://a.test/x', outcomes);
      _get(dio, 'https://b.test/x', outcomes);
      _settle(async);
      expect(limiter.getStatistics().activeByHost.keys, ['a.test', 'b.test']);

      adapter.requests[0].respond(200);
      _settle(async);
      expect(limiter.getStatistics().activeByHost, {'b.test': 1});
    });
  });

  test('the permit in extra reads as its state', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/x', outcomes);
      _settle(async);

      final extra = (outcomes.single as Response<dynamic>).requestOptions.extra;
      final permits = [
        for (final entry in extra.entries)
          if (entry.key.startsWith('dart_falconnect.concurrency.permit.'))
            entry.value.toString(),
      ];
      expect(permits, ['ConcurrencyPermit(released)']);
    });
  });

  test('rejects invalid settings', () {
    ConcurrencyLimitInterceptor build({
      int? global,
      int? perHost,
      Map<String, int?> hosts = const {},
      int maxQueueSize = 50,
      int maxGlobalQueueSize = 500,
    }) => ConcurrencyLimitInterceptor(
      config: _config,
      global: global,
      perHost: perHost,
      hosts: hosts,
      maxQueueSize: maxQueueSize,
      maxGlobalQueueSize: maxGlobalQueueSize,
    );

    expect(() => build(global: 0), throwsArgumentError);
    expect(() => build(perHost: 0), throwsArgumentError);
    expect(() => build(hosts: {'a.test': 0}), throwsArgumentError);
    expect(() => build(maxQueueSize: -1), throwsArgumentError);
    expect(() => build(maxGlobalQueueSize: -1), throwsArgumentError);
    for (final key in ['A.test', 'a.test:8080', ' a.test', '[::1]', '']) {
      expect(() => build(hosts: {key: 1}), throwsArgumentError, reason: key);
    }
    expect(build(hosts: {'::1': 1}), isNotNull);
  });

  test('two limiters in one chain both give their slots back', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final global = ConcurrencyLimitInterceptor(config: _config, global: 5);
      final perHost = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [global, perHost]);
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _get(dio, '/2', outcomes);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/1']);
      expect(global.getStatistics().globalActive, 2);
      adapter.requests.single.respond(200);
      _settle(async);

      expect(_urls(adapter.inFlight), ['https://a.test/2']);
      adapter.inFlight.single.respond(200);
      _settle(async);
      expect(global.getStatistics().globalActive, 0);
      expect(perHost.getStatistics().activeByHost, isEmpty);
    });
  });

  test('an interceptor that throws after it gives the slot back', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      var throws = true;
      final dio = _dio(
        adapter,
        (_) => [
          limiter,
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (throws) {
                throw StateError('no token');
              }
              handler.next(options);
            },
          ),
        ],
      );
      final outcomes = <Object>[];

      _get(dio, '/1', outcomes);
      _settle(async);
      expect(outcomes.single, isA<DioException>());

      throws = false;
      _get(dio, '/2', outcomes);
      _settle(async);
      expect(_urls(adapter.inFlight), ['https://a.test/2']);
    });
  });

  test('a request with a const extra map passes and gives its slot back', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];

      _get(dio, '/x', outcomes, options: Options(extra: const {'tag': 1}));
      _settle(async);

      expect((outcomes.single as Response<dynamic>).statusCode, 200);
      expect(limiter.getStatistics().activeByHost, isEmpty);
    });
  });

  test(
    'a cancelled waiter keeps its queue place until it reaches the head',
    () {
      fakeAsync((async) {
        final adapter = GatedAdapter();
        final limiter = ConcurrencyLimitInterceptor(
          config: _config,
          perHost: 1,
          maxQueueSize: 2,
        );
        final dio = _dio(adapter, (_) => [limiter]);
        final outcomes = <Object>[];
        final token = CancelToken();

        _get(dio, '/1', outcomes);
        _get(dio, '/2', outcomes, cancelToken: token);
        _get(dio, '/3', outcomes);
        _settle(async);
        token.cancel();
        _settle(async);
        expect(limiter.getStatistics().waitingByHost, {'a.test': 2});

        _get(dio, '/4', outcomes);
        _settle(async);
        expect((outcomes.last as DioException).response?.statusCode, 429);

        adapter.requests.single.respond(200);
        _settle(async);
        expect(_urls(adapter.inFlight), ['https://a.test/3']);
        expect(limiter.getStatistics().waitingByHost, {'a.test': 0});
      });
    },
  );

  test('a cancel after the response changes nothing', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = ConcurrencyLimitInterceptor(config: _config, perHost: 1);
      final dio = _dio(adapter, (_) => [limiter]);
      final outcomes = <Object>[];
      final token = CancelToken();

      _get(dio, '/1', outcomes, cancelToken: token);
      _settle(async);
      token.cancel();
      _get(dio, '/2', outcomes);
      _settle(async);

      expect(outcomes.whereType<Response<dynamic>>(), hasLength(2));
      expect(limiter.getStatistics().activeByHost, isEmpty);
    });
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/concurrency_limit_interceptor_test.dart`
Expected: FAIL at compile time: `ConcurrencyLimitInterceptor` is not defined.

- [ ] **Step 4: Share the host key rule**

Create `dart_falconnect/lib/src/engine/https/interceptors/host_key.dart`:

```dart
/// Whether [key] is a bare host exactly as `Uri.host` returns it:
/// lowercase, with no port, brackets, or spaces.
///
/// Shared by the interceptors that take per-host settings, so a key they
/// accept always matches `options.uri.host`.
bool isHostKey(String key) {
  if (key.isEmpty) {
    return false;
  }
  try {
    return Uri(scheme: 'http', host: key).host == key;
  } on FormatException {
    return false;
  }
}
```

In `token_bucket_rate_limit_interceptor.dart`, add after the `http_client_config.dart` import:

```dart
import 'package:dart_falconnect/src/engine/https/interceptors/host_key.dart';
```

replace `if (!_isHostKey(host)) {` with `if (!isHostKey(host)) {`, and delete the whole `static bool _isHostKey(String key) { ... }` method.

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart`
Expected: PASS, including the host key validation tests.

- [ ] **Step 5: Write the interceptor**

Create `dart_falconnect/lib/engine/https/interceptors/concurrency_limit_interceptor.dart`:

```dart
import 'dart:async';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/host_key.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart'
    show localRateLimitRejection;
import 'package:dart_faltool/dart_faltool.dart'
    show Bulkhead, BulkheadRejectedException, ResiliencePipeline, immutable;
import 'package:dio/dio.dart';

/// Activity counters of a [ConcurrencyLimitInterceptor].
@immutable
class ConcurrencyLimitStatistics {
  /// Creates a statistics snapshot.
  const new({
    required this.forwarded,
    required this.rejected,
    required this.activeByHost,
    required this.waitingByHost,
    required this.globalActive,
    required this.globalWaiting,
  });

  /// Requests passed to the next handler since construction, retry
  /// attempts included.
  final int forwarded;

  /// Requests rejected with a local 429 because a queue was full.
  final int rejected;

  /// Slots held in each host's own limit, keyed by host. Only hosts with a
  /// request in flight or queued appear.
  final Map<String, int> activeByHost;

  /// Requests queued for each host's own limit, keyed by host.
  final Map<String, int> waitingByHost;

  /// Slots held in the global limit; 0 without one.
  final int globalActive;

  /// Requests queued for the global limit; 0 without one.
  final int globalWaiting;
}

/// Limits how many requests are in flight at once, per host and for all
/// hosts together, with `resilience` `Bulkhead`s.
///
/// A request takes a slot in `onRequest` and gives it back when its
/// response or error passes this interceptor, or when its `CancelToken`
/// cancels. A host's limit comes from `hosts[host]` when that key exists,
/// otherwise from `perHost`; a null value means no host limit. Every
/// request to a limited host also takes a `global` slot when `global` is
/// set. A request to a host with neither limit is forwarded synchronously.
///
/// When no slot is free, a request waits in a FIFO queue of at most
/// `maxQueueSize` per host and `maxGlobalQueueSize` globally, or fails at
/// once when `queueRequests` is false. A full queue fails the request with
/// a local 429 that answers `isLocalRateLimit`, carries a
/// `BulkheadRejectedException` as its error, and has no `Retry-After`.
/// There is no limit on the time spent in a queue; pass a `CancelToken`
/// with a deadline to bound it. A cancelled request keeps its queue place
/// until it reaches the head of the queue, so it still counts toward the
/// queue size until then.
///
/// A retry attempt or a re-send that carries the `RequestOptions.extra` of
/// a request still holding a slot reuses that slot, so a retry never waits
/// for its own earlier attempt.
///
/// Place it after `CacheInterceptor` and any interceptor that answers in
/// `onRequest`: a request answered after this interceptor without calling
/// the response or error interceptors keeps its slot forever. Place it
/// before the rate limiter, so the slot is taken before the tokens, before
/// `RetryInterceptor`, and before the network exception handler, which
/// stops the error chain. A request holds its slot while the rate limiter
/// holds it, so set `perHost` below `global` to keep one slow or paused
/// host from taking every global slot.
///
/// A request that never ends holds its slot: keep dio's connect and
/// receive timeouts set. A `ResponseType.stream` response gives its slot
/// back when its headers arrive, before its body is read. On a server,
/// build one interceptor per process; each process, isolate, or instance
/// counts only its own requests.
class ConcurrencyLimitInterceptor extends Interceptor {
  /// Creates a concurrency limit interceptor.
  ///
  /// Each key of [hosts] must be a bare host exactly as `Uri.host` returns
  /// it: lowercase, with no port, brackets, or spaces. Every limit that is
  /// set must be at least 1; queue sizes must not be negative.
  new({
    required this.config,
    this.global,
    this.perHost,
    Map<String, int?> hosts = const {},
    this.queueRequests = true,
    this.maxQueueSize = 50,
    this.maxGlobalQueueSize = 500,
  }) : _hosts = _validated(
         global: global,
         perHost: perHost,
         hosts: hosts,
         maxQueueSize: maxQueueSize,
         maxGlobalQueueSize: maxGlobalQueueSize,
       ),
       _globalBulkhead = global == null
           ? null
           : Bulkhead(
               maxConcurrent: global,
               maxQueued: queueRequests ? maxGlobalQueueSize : 0,
             );

  /// Configuration; `enableLogging` gates diagnostic prints.
  final HttpClientConfig config;

  /// Most requests in flight to all hosts together; null means no limit.
  final int? global;

  /// Most requests in flight to a host missing from `hosts`; null means no
  /// limit.
  final int? perHost;

  /// Whether a request with no free slot waits (`true`) or is rejected.
  final bool queueRequests;

  /// Queue capacity of each host limit.
  final int maxQueueSize;

  /// Queue capacity of the global limit.
  final int maxGlobalQueueSize;

  /// Gives every instance its own `extra` key, so two instances in one
  /// chain never overwrite each other's permit.
  static int _instances = 0;

  /// Key in `RequestOptions.extra` that holds this instance's permit.
  final String _permitKey =
      'dart_falconnect.concurrency.permit.${_instances++}';

  final Map<String, int?> _hosts;
  final Bulkhead? _globalBulkhead;
  late final ResiliencePipeline? _globalPipeline = _globalBulkhead == null
      ? null
      : ResiliencePipeline([_globalBulkhead]);
  final Map<String, _HostSlots> _hostSlots = {};
  final Set<_Permit> _waiting = {};
  int _forwarded = 0;
  int _rejected = 0;
  bool _disposed = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final host = options.uri.host;
    final hostLimit = _hosts.containsKey(host) ? _hosts[host] : perHost;
    if (hostLimit == null && _globalBulkhead == null) {
      _forwarded++;
      handler.next(options);
      return;
    }
    if (_disposed) {
      handler.reject(
        _cancelled(
          options,
          StateError('ConcurrencyLimitInterceptor disposed'),
          'Concurrency limiter disposed',
        ),
      );
      return;
    }
    if (_permitOf(options)?.isHeld ?? false) {
      // A retry attempt or re-send of a request that still holds its slot.
      _forwarded++;
      handler.next(options);
      return;
    }
    final cancelToken = options.cancelToken;
    if (cancelToken != null && cancelToken.isCancelled) {
      handler.reject(
        _cancelled(options, cancelToken.cancelError, 'Request cancelled'),
      );
      return;
    }
    final permit = _Permit();
    options.extra = {...options.extra, _permitKey: permit};
    if (cancelToken != null) {
      permit.unwatch = watchCancel(cancelToken, permit.release);
    }
    _waiting.add(permit);
    final slots = hostLimit == null
        ? null
        : _hostSlots.putIfAbsent(
            host,
            () => _HostSlots(_hostBulkhead(hostLimit), _globalBulkhead),
          );
    final pipeline = slots?.pipeline ?? _globalPipeline!;
    unawaited(
      pipeline
          .execute(permit.hold)
          .then<void>((_) {}, onError: permit.reject)
          .whenComplete(() => _prune(host, slots)),
    );
    try {
      await permit.granted;
    } on BulkheadRejectedException catch (error) {
      _waiting.remove(permit);
      _rejected++;
      _log('Concurrency queue full for $host');
      handler.reject(localRateLimitRejection(options, error: error), true);
      return;
    } on Object catch (error) {
      // Cancelled, or disposed, while waiting for a slot.
      _waiting.remove(permit);
      handler.reject(_cancelled(options, error, 'Request cancelled'));
      return;
    }
    _waiting.remove(permit);
    _forwarded++;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _permitOf(response.requestOptions)?.release();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _permitOf(err.requestOptions)?.release();
    handler.next(err);
  }

  /// Returns the current activity counters.
  ConcurrencyLimitStatistics getStatistics() => ConcurrencyLimitStatistics(
    forwarded: _forwarded,
    rejected: _rejected,
    activeByHost: Map.unmodifiable({
      for (final entry in _hostSlots.entries)
        entry.key: entry.value.bulkhead.activeCount,
    }),
    waitingByHost: Map.unmodifiable({
      for (final entry in _hostSlots.entries)
        entry.key: entry.value.bulkhead.queueLength,
    }),
    globalActive: _globalBulkhead?.activeCount ?? 0,
    globalWaiting: _globalBulkhead?.queueLength ?? 0,
  );

  /// Cancels every request waiting for a slot.
  ///
  /// Requests in flight keep their slots and give them back when they end.
  /// Afterwards, requests to a limited host are cancelled, retry attempts
  /// included, and requests to an unlimited host pass. Calling it again has
  /// no effect.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final disposed = StateError('ConcurrencyLimitInterceptor disposed');
    for (final permit in _waiting.toList()) {
      permit.release(disposed);
    }
    _waiting.clear();
  }

  static Map<String, int?> _validated({
    required int? global,
    required int? perHost,
    required Map<String, int?> hosts,
    required int maxQueueSize,
    required int maxGlobalQueueSize,
  }) {
    void checkLimit(int? limit, String name) {
      if (limit != null && limit < 1) {
        throw ArgumentError.value(limit, name, 'must be at least 1 or null');
      }
    }

    void checkQueue(int size, String name) {
      if (size < 0) {
        throw ArgumentError.value(size, name, 'must not be negative');
      }
    }

    checkLimit(global, 'global');
    checkLimit(perHost, 'perHost');
    checkQueue(maxQueueSize, 'maxQueueSize');
    checkQueue(maxGlobalQueueSize, 'maxGlobalQueueSize');
    for (final entry in hosts.entries) {
      if (!isHostKey(entry.key)) {
        throw ArgumentError.value(
          entry.key,
          'hosts',
          'keys must be bare lowercase hosts, as Uri.host returns them',
        );
      }
      checkLimit(entry.value, 'hosts');
    }
    return Map.unmodifiable(hosts);
  }

  Bulkhead _hostBulkhead(int limit) => Bulkhead(
    maxConcurrent: limit,
    maxQueued: queueRequests ? maxQueueSize : 0,
  );

  _Permit? _permitOf(RequestOptions options) {
    final permit = options.extra[_permitKey];
    return permit is _Permit ? permit : null;
  }

  /// Forgets an idle host limit; an empty `Bulkhead` is the same as a new
  /// one, so the next request to the host builds a fresh one.
  void _prune(String host, _HostSlots? slots) {
    if (slots != null &&
        slots.bulkhead.activeCount == 0 &&
        slots.bulkhead.queueLength == 0 &&
        identical(_hostSlots[host], slots)) {
      _hostSlots.remove(host);
    }
  }

  DioException _cancelled(
    RequestOptions options,
    Object? error,
    String message,
  ) => DioException(
    requestOptions: options,
    type: DioExceptionType.cancel,
    error: error,
    message: message,
  );

  void _log(String message) {
    if (config.enableLogging) {
      // Intentional logging for concurrency limit diagnostics.
      // ignore: avoid_print
      print('[ConcurrencyLimitInterceptor] $message');
    }
  }
}

/// A host's own limit and the pipeline that also takes a global slot.
class _HostSlots {
  new(this.bulkhead, Bulkhead? global)
    : pipeline = ResiliencePipeline([bulkhead, ?global]);

  final Bulkhead bulkhead;
  final ResiliencePipeline pipeline;
}

enum _PermitState { waiting, held, abandoned, released }

/// One logical request's claim on a slot, kept in `RequestOptions.extra`.
class _Permit {
  final Completer<void> _granted = Completer<void>();
  final Completer<void> _released = Completer<void>();
  _PermitState _state = _PermitState.waiting;

  /// Removes the `CancelToken` watch; set when the request has a token.
  void Function()? unwatch;

  bool get isHeld => _state == _PermitState.held;

  /// Completes when every slot is taken; fails when the queue is full, or
  /// when the request is cancelled or disposed while it waits.
  Future<void> get granted => _granted.future;

  /// The pipeline action: holds every slot until [release].
  Future<void> hold() {
    if (_state == _PermitState.abandoned) {
      // Cancelled while waiting: pass the slot straight on.
      _state = _PermitState.released;
      return Future<void>.value();
    }
    _state = _PermitState.held;
    _granted.complete();
    return _released.future;
  }

  /// Fails a permit the pipeline rejected before granting it.
  void reject(Object error, StackTrace stackTrace) {
    if (_state == _PermitState.waiting) {
      _state = _PermitState.released;
      unwatch?.call();
      _granted.completeError(error, stackTrace);
    }
  }

  /// Gives the slot back, or abandons the wait; later calls do nothing.
  void release([Object? reason]) {
    switch (_state) {
      case _PermitState.waiting:
        _state = _PermitState.abandoned;
        unwatch?.call();
        _granted.completeError(reason ?? StateError('Request cancelled'));
      case _PermitState.held:
        _state = _PermitState.released;
        unwatch?.call();
        _released.complete();
      case _PermitState.abandoned:
      case _PermitState.released:
        return;
    }
  }

  @override
  String toString() => 'ConcurrencyPermit(${_state.name})';
}
```

In `interceptors.dart`, add after `export 'cache_interceptor.dart';`:

```dart
export 'concurrency_limit_interceptor.dart';
```

In `local_rate_limit.dart`, replace

```dart
  /// Whether this response is a 429 built by a rate-limit interceptor, with
  /// no request sent to the server.
```

with

```dart
  /// Whether this response is a 429 built by a rate-limit or concurrency
  /// limit interceptor, with no request sent to the server.
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/concurrency_limit_interceptor_test.dart`
Expected: PASS, 26 tests.

Run: `cd dart_falconnect && dart test`
Expected: PASS.

- [ ] **Step 7: Analyze, format, commit**

Run: `cd dart_falconnect && dart format lib test && dart analyze lib test`
Expected: `No issues found!`

```bash
git add dart_falconnect/lib/src/engine/https/interceptors/host_key.dart dart_falconnect/lib/engine/https/interceptors/concurrency_limit_interceptor.dart dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart dart_falconnect/lib/engine/https/interceptors/interceptors.dart dart_falconnect/lib/engine/https/interceptors/local_rate_limit.dart dart_falconnect/test/engine/https/interceptors/_scripted_adapter.dart dart_falconnect/test/engine/https/interceptors/concurrency_limit_interceptor_test.dart
git commit -m "feat(dart_falconnect): add ConcurrencyLimitInterceptor on resilience Bulkhead"
```

---

### Task 4: Chain order tests and web gates

**Files:**
- Modify: `dart_falconnect/test/engine/https/interceptors/rate_limit_retry_chain_test.dart` (helper `_limitedChain` and 3 tests)
- Modify: `dart_falconnect/test/web/compile_smoke.dart`
- Modify: `dart_falconnect/test/web/engine_web_test.dart`

**Interfaces:**
- Consumes: `ConcurrencyLimitInterceptor` (Task 3, exported through `package:dart_falconnect/dart_falconnect.dart`), `GatedAdapter` and `GatedRequest.sentAt` (Task 3), `TokenBucketRateLimitInterceptor`, `TokenBucketPolicy`, `RetryInterceptor`, `DefaultNetworkExceptionHandlerInterceptor`.
- Produces: tests only.

These tests pin the chain order of spec section 12. In the prototype, swapping `concurrency` and `limiter` in `_limitedChain` made the ceiling test and the pause test fail, and the documented order made them pass.

- [ ] **Step 1: Add the chain helper and tests**

In `rate_limit_retry_chain_test.dart`, insert before `void main() {`:

```dart
/// The full order of the SP3 spec, section 12, without a cache.
Dio _limitedChain(
  HttpClientAdapter adapter,
  ConcurrencyLimitInterceptor concurrency,
  TokenBucketRateLimitInterceptor limiter, {
  bool retry = true,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll([
    concurrency,
    limiter,
    if (retry) RetryInterceptor(config: _config, dio: dio),
    DefaultNetworkExceptionHandlerInterceptor(),
  ]);
  return dio;
}
```

Append inside `main()`, after the last test:

```dart
  test('the token ceiling holds on the wire behind a concurrency limit', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final concurrency = ConcurrencyLimitInterceptor(
        config: _config,
        perHost: 4,
      );
      final limiter = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 2, per: Duration(seconds: 1), burst: 2),
        ],
      );
      final dio = _limitedChain(adapter, concurrency, limiter);
      for (var i = 0; i < 12; i++) {
        unawaited(dio.get<dynamic>('/$i').then((_) {}, onError: (_) {}));
      }

      // The server answers every request in flight at once, every 6 s, so
      // four slots free up together. Requests that took tokens before
      // their slot would all leave at that moment.
      for (var second = 6; second <= 30; second += 6) {
        async.elapse(const Duration(seconds: 6));
        for (final request in adapter.inFlight) {
          request.respond(200);
        }
      }

      final sentAt = [for (final r in adapter.requests) r.sentAt];
      expect(sentAt, hasLength(12));
      for (final start in sentAt) {
        final end = start.add(const Duration(seconds: 1));
        final window = sentAt.where(
          (t) => !t.isBefore(start) && t.isBefore(end),
        );
        expect(window.length, lessThanOrEqualTo(2), reason: 'from $start');
      }
      concurrency.dispose();
      limiter.dispose();
    });
  });

  test('a request waiting for a slot is not sent to a host paused '
      'meanwhile', () {
    fakeAsync((async) {
      final adapter = GatedAdapter();
      final concurrency = ConcurrencyLimitInterceptor(
        config: _config,
        perHost: 1,
      );
      final limiter = TokenBucketRateLimitInterceptor(config: _config);
      final dio = _limitedChain(adapter, concurrency, limiter, retry: false);
      final outcomes = <Object>[];

      for (final path in ['/1', '/2']) {
        unawaited(
          dio.get<dynamic>(path).then(outcomes.add, onError: outcomes.add),
        );
      }
      async.elapse(Duration.zero);
      adapter.requests.single.respond(429, headers: {'retry-after': '3'});
      async.elapse(const Duration(milliseconds: 2900));
      expect(adapter.requests, hasLength(1), reason: 'held by the pause');

      async.elapse(const Duration(milliseconds: 200));
      expect(adapter.requests, hasLength(2));
      concurrency.dispose();
      limiter.dispose();
    });
  });

  test('a 429 pauses the host, and the retry passes the pause with a '
      'concurrency limit of 1', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        reply(429, headers: {'retry-after': '2'}),
        reply(200),
      ]);
      final concurrency = ConcurrencyLimitInterceptor(
        config: _config,
        perHost: 1,
      );
      final limiter = TokenBucketRateLimitInterceptor(config: _config);
      final dio = _limitedChain(adapter, concurrency, limiter);
      Object? outcome;

      unawaited(
        dio
            .get<dynamic>('/x')
            .then((r) => outcome = r, onError: (Object e) => outcome = e),
      );
      async.elapse(const Duration(seconds: 3));

      expect((outcome! as Response<dynamic>).statusCode, 200);
      expect(adapter.requests, hasLength(2));
      expect(concurrency.getStatistics().activeByHost, isEmpty);
      concurrency.dispose();
      limiter.dispose();
    });
  });
```

- [ ] **Step 2: Run the chain tests**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/rate_limit_retry_chain_test.dart`
Expected: PASS, 8 tests.

- [ ] **Step 3: Confirm the order tests discriminate**

Temporarily swap the first two entries of `_limitedChain`'s `addAll` list (`limiter` before `concurrency`) and run the same command.
Expected: FAIL in `the token ceiling holds on the wire behind a concurrency limit` (`Actual: <4>`) and in `a request waiting for a slot is not sent to a host paused meanwhile`.
Restore the original order and run again. Expected: PASS, 8 tests. Run `git diff dart_falconnect/test/engine/https/interceptors/rate_limit_retry_chain_test.dart` and confirm the list reads `concurrency, limiter, ...`.

- [ ] **Step 4: Extend the web gates**

In `test/web/compile_smoke.dart`, add after `_sink(CacheInterceptor(config: cfg));`:

```dart
  _sink(ConcurrencyLimitInterceptor(config: cfg, global: 16, perHost: 4));
```

In `test/web/engine_web_test.dart`, add after `expect(CacheInterceptor(config: cfg), isNotNull);`:

```dart
      expect(ConcurrencyLimitInterceptor(config: cfg), isNotNull);
```

and append inside the `group`, after the `RetryInterceptor backs off and retries on web` test:

```dart
    test(
      'ConcurrencyLimitInterceptor runs requests one at a time on web',
      () async {
        final adapter = ScriptedAdapter([reply(200)]);
        final limiter = ConcurrencyLimitInterceptor(
          config: HttpClientConfig.development(),
          perHost: 1,
        );
        final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
          ..httpClientAdapter = adapter;
        dio.interceptors.add(limiter);

        final responses = await Future.wait([
          dio.get<dynamic>('/1'),
          dio.get<dynamic>('/2'),
        ]);

        expect(responses.map((r) => r.statusCode), [200, 200]);
        expect(limiter.getStatistics().forwarded, 2);
        expect(limiter.getStatistics().activeByHost, isEmpty);
      },
    );
```

- [ ] **Step 5: Run the web gates**

Run: `cd dart_falconnect && dart compile js test/web/compile_smoke.dart -o /tmp/sp3_compile_smoke.js`
Expected: exit code 0, `Compiled ... to ... characters JavaScript`.

Run: `cd dart_falconnect && dart test -p chrome test/web/engine_web_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 6: Format and commit**

Run: `cd dart_falconnect && dart format test && dart analyze test`
Expected: `No issues found!`

```bash
git add dart_falconnect/test/engine/https/interceptors/rate_limit_retry_chain_test.dart dart_falconnect/test/web/compile_smoke.dart dart_falconnect/test/web/engine_web_test.dart
git commit -m "test(dart_falconnect): pin the concurrency limit chain order and cover it on the web"
```

---

### Task 5: Documentation

**Files:**
- Modify: `skills/dart-falconx-package/SKILL.md` (interceptor row, order line)
- Modify: `skills/dart-falconx-package/references/http.md` (catalog, order section, two new sections)
- Modify: `skills/dart-falconx-package/references/third-party.md` (`resilience` row)
- Modify: `CLAUDE.md` (root; interceptor summary and order line)
- Modify: `dart_falconnect/CLAUDE.md` (interceptor list, order line, gotcha)
- Modify: `_bmad-output/project-context.md` (order line)

**Interfaces:**
- Consumes: the public API of Task 3 and the order of spec section 12.
- Produces: documentation only.

- [ ] **Step 1: `SKILL.md`**

In the `Interceptors` row of the capability table, replace `` `RetryInterceptor`, `CacheInterceptor`, `TokenBucketRateLimitInterceptor`, `` with `` `RetryInterceptor`, `CacheInterceptor`, `ConcurrencyLimitInterceptor`, `TokenBucketRateLimitInterceptor`, ``.

Replace the line

```markdown
- Interceptor order: auth, then `RetryInterceptor`, `CacheInterceptor`, `HttpLogInterceptor` last so it sees every change. Dio's own `LogInterceptor` is a different class.
```

with

```markdown
- Interceptor order: `CacheInterceptor`, `ConcurrencyLimitInterceptor`, the rate limiter, `RetryInterceptor`, then `DefaultNetworkExceptionHandlerInterceptor` last. An auth refresh goes after `ConcurrencyLimitInterceptor`; error loggers go before `RetryInterceptor`. See `references/http.md`. Dio's own `LogInterceptor` is a different class.
```

- [ ] **Step 2: `references/http.md`, interceptor catalog**

Insert this row after the `CacheInterceptor` row:

```markdown
| `ConcurrencyLimitInterceptor`                 | `(config:, global:, perHost:, hosts: {}, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500)`                                                                | most requests in flight per host and in total, on `resilience` `Bulkhead`; a null limit means none; full queue → local 429 with `BulkheadRejectedException` and no `Retry-After`; a retry or re-send reuses its request's slot; `getStatistics()`, `dispose()` |
```

In the `HttpLogInterceptor` row, replace `ANSI-coloured chunked printing; add last` with `ANSI-coloured chunked printing; logs requests and responses from anywhere in the chain, errors only when placed before `RetryInterceptor` and the exception handler`.

- [ ] **Step 3: `references/http.md`, interceptor order**

Replace the code block under `## Interceptor order` with:

```dart
interceptors.addAll([
  CacheInterceptor(config: config),
  ConcurrencyLimitInterceptor(config: config, global: 16, perHost: 4),
  TokenBucketRateLimitInterceptor(config: config), // or RetryAfterPauseInterceptor, never both
  RetryInterceptor(config: config, dio: dio),
  DefaultNetworkExceptionHandlerInterceptor(),
]);
```

Insert these bullets before the existing bullet that starts `- The rate limiter comes before `RetryInterceptor``:

```markdown
- `CacheInterceptor` comes first: a cache hit answers in `onRequest` without calling the response interceptors, so it takes no concurrency slot and spends no token. Any interceptor that answers in `onRequest`, such as a cache or a mock, goes before `ConcurrencyLimitInterceptor`; placed after it, every answer it gives keeps a slot forever.
- `ConcurrencyLimitInterceptor` comes before the rate limiter: the slot is taken before the tokens, so the token ceiling holds on the wire and the pause gate sees every request. A request holds its slot while the rate limiter holds it, so set `perHost` below `global`, for example 4 and 16, so one slow or paused host cannot take every global slot.
```

Insert these bullets after the existing bullet that starts `- The rate limiter comes before `RetryInterceptor``:

```markdown
- An interceptor that re-sends from `onError`, such as an auth refresh, goes after `ConcurrencyLimitInterceptor`. Placed before it, the re-send reuses its request's slot, which also works.
```

Replace the bullet `- `DefaultNetworkExceptionHandlerInterceptor` comes last: it rejects without calling later error interceptors.` with:

```markdown
- `DefaultNetworkExceptionHandlerInterceptor` comes last: it rejects without calling later error interceptors, so a `ConcurrencyLimitInterceptor` placed after it would never get its slots back.
```

- [ ] **Step 4: `references/http.md`, new sections**

Insert before `## Retry`:

````markdown
## Concurrency limit

`ConcurrencyLimitInterceptor` limits how many requests are in flight at once. Every scope is unlimited until you set it.

```dart
final concurrency = ConcurrencyLimitInterceptor(
  config: config,
  global: 16,
  perHost: 4,
  hosts: const {'pay.partner.com': 2, 'cdn.example.com': null},
);
```

`pay.partner.com` runs 2 requests at once; `cdn.example.com` has no host limit but still counts toward the 16 global slots; every other host gets 4. `hosts` keys follow the token bucket rule: bare lowercase hosts as `Uri.host` returns them.

A request takes a slot in `onRequest` and gives it back when its response or error passes the interceptor, or when its `CancelToken` cancels. Without a free slot it waits in a FIFO queue (`maxQueueSize` per host, `maxGlobalQueueSize` for the global limit), or fails at once with `queueRequests: false`. A full queue fails the request with a local 429: `isLocalRateLimit` is true, `err.error` is a `BulkheadRejectedException` until the exception handler maps it to `NetworkLimitExceededException`, and there is no `Retry-After`, so `recommendedRetryDelay` falls back to 1 minute. A retry attempt, or a re-send of `err.requestOptions`, reuses the slot its request still holds, so a limit of 1 never deadlocks.

Limitations:

- Nothing limits the time a request spends in the queue. Pass a `CancelToken` with a deadline to bound it.
- A request cancelled while it waits keeps its queue place until it reaches the head, so it counts toward `maxQueueSize` until then.
- A request that never ends holds its slot. Keep `connectTimeout` and `receiveTimeout` set.
- A `ResponseType.stream` response gives its slot back when its headers arrive, before its body is read.
- Two concurrent fetches of one `RequestOptions` object share one slot.

`getStatistics()` returns `ConcurrencyLimitStatistics`: `forwarded`, `rejected`, `activeByHost` and `waitingByHost` (only hosts with a request in flight or queued; idle hosts are forgotten), `globalActive`, `globalWaiting`. `dispose()` cancels queued requests and lets requests in flight finish; afterwards, requests to a limited host are cancelled and requests to an unlimited host pass. `Bulkhead` keeps no timer, so a missing `dispose()` never delays a CLI exit or fails `testWidgets`.

## Client and server deployment

**Web**

- A browser hides every cross-origin response header outside the CORS safelist, including `Retry-After` and `Date`. Have the server send `Access-Control-Expose-Headers: Retry-After, Date`. Without it, a 429 pauses for `defaultPause`, a 503 does not pause, `RetryInterceptor` uses backoff instead of `Retry-After`, and the pause runs on the client clock. Tests with a fake adapter cannot catch this.
- Chrome opens at most 6 connections per host over HTTP/1.1, so a `perHost` above 6 changes nothing on the web.

**Apps**

- A request that stalls, for example while the app is in the background, holds its concurrency slot until a dio timeout fires.

**Servers**

- Limits count per process, isolate, or container instance. Divide a partner's limit by the instance count; with autoscaling, rely on the 429 pause as the last line.
- Limits are keyed by host. When a partner limits per API key and you use one key per tenant, build one client per key; otherwise one tenant's 429 pauses every tenant.
- Queued requests outlive the incoming request that started them. Give each incoming request a `CancelToken` that cancels at its deadline; it bounds the concurrency queue, the token wait, the pause hold, retry backoff, and the request in flight together.
- Build the client once per process (see the `dispose()` table above).
- For an open-ended set of hosts, prefer named `hosts` keys over `perHost` in `TokenBucketRateLimitInterceptor`: its per-host buckets are never freed. `ConcurrencyLimitInterceptor` forgets idle hosts itself.

````

- [ ] **Step 5: `references/third-party.md`**

In the `resilience` row, replace `` `RateLimiter`, `Bulkhead`, `CircuitBreaker`, `Hedge`, `ResiliencePipeline`, `withFallback` `` with `` `RateLimiter` (behind `TokenBucketRateLimitInterceptor`), `Bulkhead` (behind `ConcurrencyLimitInterceptor`), `CircuitBreaker`, `Hedge`, `ResiliencePipeline`, `withFallback` ``.

- [ ] **Step 6: Root `CLAUDE.md`**

Replace `  - Interceptors: cache, retry, rate limiting, logging, error handling` with `  - Interceptors: cache, concurrency limiting, rate limiting, retry, logging, error handling`.

Replace `   - Order matters: auth → retry → cache → logging` with `   - Order matters: cache → concurrency limit → rate limiter → retry → exception handler (see `skills/dart-falconx-package/references/http.md`)`.

- [ ] **Step 7: `dart_falconnect/CLAUDE.md`**

Replace `Eight interceptors available (barrel: `interceptors/interceptors.dart`):` with `Nine interceptors available (barrel: `interceptors/interceptors.dart`):`, and add after the item `8. `LogInterceptor` — Request/response logging with ANSI colors`:

```markdown
9. `ConcurrencyLimitInterceptor` — Most requests in flight per host and in total on `resilience` `Bulkhead`; takes a slot in `onRequest` and gives it back on response, error, `CancelToken` cancel, or `dispose()`; a retry or re-send reuses its request's slot; idle hosts are forgotten
```

Replace the line that starts `Order: rate limiter → `RetryInterceptor` → exception handler.` with:

```markdown
Order: `CacheInterceptor` → `ConcurrencyLimitInterceptor` → rate limiter → `RetryInterceptor` → exception handler. The pause core lives in `lib/src/engine/https/interceptors/retry_after_pause.dart`, the host key rule in `lib/src/engine/https/interceptors/host_key.dart`, and `watchCancel` in `lib/src/engine/https/cancel_watch.dart` (none exported).
```

Append to `## Gotchas`:

```markdown
- Wait on a `CancelToken` through `watchCancel` (`lib/src/engine/https/cancel_watch.dart`), never `cancelToken.whenCancel.then(...)`: a `Future` listener cannot be removed, so a long-lived token would collect one per finished wait
```

- [ ] **Step 8: `_bmad-output/project-context.md`**

Replace `- Interceptor order matters: auth → retry → cache → logging` with `- Interceptor order matters: cache → concurrency limit → rate limiter → retry → exception handler`.

- [ ] **Step 9: Check and commit**

Run: `grep -rn 'auth → retry → cache → logging\|HttpLogInterceptor` last\|add last' CLAUDE.md dart_falconnect/CLAUDE.md skills/dart-falconx-package _bmad-output/project-context.md`
Expected: no output.

```bash
git add skills/dart-falconx-package/SKILL.md skills/dart-falconx-package/references/http.md skills/dart-falconx-package/references/third-party.md CLAUDE.md dart_falconnect/CLAUDE.md _bmad-output/project-context.md
git commit -m "docs: document ConcurrencyLimitInterceptor, the new chain order, and deployment notes"
```

---

### Task 6: Final gates (controller)

**Files:** none changed.

- [ ] **Step 1: Run every gate from the worktree root**

```bash
dart pub get
melos run analyze
melos run format
melos run test
cd dart_falconnect && dart compile js test/web/compile_smoke.dart -o /tmp/sp3_compile_smoke.js && dart test -p chrome test/web/engine_web_test.dart
```

Expected: analyze `SUCCESS` with `--fatal-infos`; format `SUCCESS`; tests pass (falconnect 123 with 1 skipped, falmodel 58, faltool 699, falconx 1); dart2js exit code 0; Chrome 7 passed.

- [ ] **Step 2: Confirm the skill matches the source**

Run: `grep -n 'ConcurrencyLimitInterceptor' skills/dart-falconx-package/SKILL.md skills/dart-falconx-package/references/http.md dart_falconnect/lib/engine/https/interceptors/interceptors.dart`
Expected: at least one match in each file.
