# 429 Pause and Retry Rewrite (SP2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pause requests to a host after it answers 429, or 503 with `Retry-After`, inside `TokenBucketRateLimitInterceptor` and a new `RetryAfterPauseInterceptor`; rewrite `RetryInterceptor`; share one `Retry-After` parser; fold in the SP1 deferred minors.

**Architecture:** `dart_falmodel` gains `parseRetryAfter` and a `Headers.retryAfter` getter (delay-seconds and HTTP-date through `http_parser`). `dart_falconnect` gains one internal pause core under `lib/src/`, used by both rate-limit interceptors; the token bucket checks the pause before and after taking tokens, so the SP1 ceiling holds across a pause. Local 429s become `badResponse` errors sent through every error interceptor. `RetryInterceptor` becomes a loop that resends with `dio.fetch<dynamic>`, gates non-idempotent methods, caps `Retry-After`, and stops at `maxRetryDuration`.

**Tech Stack:** Dart 3.13, Melos 8 workspace, `dio` 5.11.1, `resilience` 1.1.3, `http_parser` 4.1.2, `fake_async` 1.3.3, `package:test`, `very_good_analysis` 11.

**Spec:** `docs/superpowers/specs/2026-09-23-token-bucket-429-pause-design.md`

Every code block in this plan ran green in a throwaway prototype on 2026-09-23: `melos run analyze`, `melos run test` (faltool 699, falmodel 54, falconnect 79, falconx 1), `dart compile js`, and `dart test -p chrome` (5 tests).

## Global Constraints

- Work in a git worktree on branch `feature/sp2-429-pause-retry` created from `develop` (use superpowers:using-git-worktrees). Another session edits `dart_falconnect/lib/engine/https/config/http_client_config.dart` in the main checkout without committing; never touch the main checkout, and expect a merge conflict in that file.
- Run `dart pub get` at the worktree root once before Task 1 (Dart workspace resolution).
- `melos run analyze` runs `dart analyze` with `--fatal-infos`: every info-level lint fails the build.
- Constructors use the declaring form `new(...)` / `const new(...)`; `ClassName(...)` constructors trip `unnecessary_type_name_in_constructor`.
- Lines stay within 80 characters; run `dart format` on every file you touch.
- Every timing test runs under `fakeAsync`. Wrap fire-and-forget futures in `unawaited(...)` (`discarded_futures`).
- Internal code lives under `dart_falconnect/lib/src/`. `@internal` is rejected outside `lib/src/` (`invalid_internal_annotation`, verified).
- Resend retries with `dio.fetch<dynamic>` only; any other type argument makes dio overwrite `responseType` (`dio_mixin.dart:419`).
- Pause defaults: `maxPauseWait` 10 s, `maxPause` 10 min, `defaultPause` 5 s, hold capacity `maxQueueSize` (50).
- `maxRetryDuration` defaults: 60 s constructor, 2 min `production()`, 10 s `development()`, 5 s `test()`.
- Idempotent methods: `GET`, `HEAD`, `OPTIONS`, `PUT`, `DELETE`, `TRACE`.
- No version bump: every package is already 2.0.0 (`781ab1a`). Do not push or tag.
- Commits use Conventional Commits and carry no `Co-Authored-By` or AI attribution (repository `CLAUDE.md`).

## Review Focus

- A retry that itself gets a 429 must extend the pause for every other request to that host, because the nested attempt passes the rate limiter's `onError`. Test in Task 6.
- A client whose `validateStatus` accepts 429 (as `HttpClientConfig.applyTo` does) receives the 429 as a normal response, yet the host must still pause. Test in Task 6.
- `HttpClientConfig.test()` sets `maxRetryAttempts: 0`; the rewrite must never retry with it. Test in Task 5.
- A `hosts` key that `Uri.host` could never return (a port, a space, brackets) must throw, while an IPv6 host such as `::1` must be accepted. Test in Task 4.
- A request that gets its tokens during a pause must not reach the server, and the ceiling must hold after the pause. Test in Task 4 (a mutation that removes the post-token check fails it).

---

### Task 1: `Retry-After` parser in `dart_falmodel`

**Files:**
- Modify: `dart_falmodel/pubspec.yaml` (dependencies, after `freezed_annotation: ^3.1.0`)
- Create: `dart_falmodel/lib/networks/https/retry_after.dart`
- Modify: `dart_falmodel/lib/networks/https/https.dart`
- Modify: `dart_falmodel/lib/networks/exceptions/base_http_exception.dart:55-67`
- Modify: `dart_falmodel/lib/networks/exceptions/code5XX/server_error_exception.dart:69-75`
- Test: `dart_falmodel/test/networks/https/retry_after_test.dart` (new directory)

**Interfaces:**
- Consumes: `clock` from `dart_faltool`; `Headers` from `dio`; `parseHttpDate` from `http_parser`.
- Produces: `Duration? parseRetryAfter(String? value, {DateTime? serverDate})` and `extension FalconRetryAfterHeadersExtensions on Headers { Duration? get retryAfter; }`, both reachable through `package:dart_falmodel/dart_falmodel.dart` and `package:dart_falmodel/networks/https/retry_after.dart`.

- [ ] **Step 1: Write the failing test**

Create `dart_falmodel/test/networks/https/retry_after_test.dart`:

```dart
import 'package:dart_falmodel/lib.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 9, 23, 12);

Headers _headers(Map<String, String> values) => Headers.fromMap({
  for (final entry in values.entries) entry.key: [entry.value],
});

Response<dynamic> _response(int status, Map<String, String> headers) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: 'https://a.test/x'),
      statusCode: status,
      headers: _headers(headers),
    );

void main() {
  group('parseRetryAfter', () {
    test('reads delay-seconds', () {
      expect(parseRetryAfter('120'), const Duration(seconds: 120));
      expect(parseRetryAfter(' 0 '), Duration.zero);
    });

    test('clamps a huge delay-seconds value instead of overflowing', () {
      const clamp = Duration(seconds: 1 << 31);
      expect(parseRetryAfter('9000000000000000000'), clamp);
      expect(parseRetryAfter('99999999999999999999999'), clamp);
    });

    test('reads every HTTP-date format against serverDate', () {
      final server = DateTime.utc(1994, 11, 6, 8, 49, 7);
      for (final value in [
        'Sun, 06 Nov 1994 08:49:37 GMT',
        'Sunday, 06-Nov-94 08:49:37 GMT',
        'Sun Nov  6 08:49:37 1994',
      ]) {
        expect(
          parseRetryAfter(value, serverDate: server),
          const Duration(seconds: 30),
          reason: value,
        );
      }
    });

    test('measures a date from clock.now() without serverDate', () {
      withClock(Clock.fixed(_now), () {
        expect(
          parseRetryAfter('Wed, 23 Sep 2026 12:00:45 GMT'),
          const Duration(seconds: 45),
        );
      });
    });

    test('gives zero for a date in the past', () {
      withClock(Clock.fixed(_now), () {
        expect(parseRetryAfter('Wed, 23 Sep 2026 11:00:00 GMT'), Duration.zero);
      });
    });

    test('gives null for missing and unreadable values', () {
      for (final value in [null, '', '  ', '-5', '1.5', 'soon', '12s']) {
        expect(parseRetryAfter(value), isNull, reason: '$value');
      }
    });
  });

  group('Headers.retryAfter', () {
    test('uses the Date header as the reference time', () {
      // The client clock is an hour ahead of the server.
      withClock(Clock.fixed(_now.add(const Duration(hours: 1))), () {
        final headers = _headers({
          'retry-after': 'Wed, 23 Sep 2026 12:00:10 GMT',
          'date': 'Wed, 23 Sep 2026 12:00:00 GMT',
        });
        expect(headers.retryAfter, const Duration(seconds: 10));
      });
    });

    test('ignores an unreadable Date header', () {
      withClock(Clock.fixed(_now), () {
        final headers = _headers({
          'retry-after': 'Wed, 23 Sep 2026 12:00:10 GMT',
          'date': 'yesterday',
        });
        expect(headers.retryAfter, const Duration(seconds: 10));
      });
    });

    test('is null without a Retry-After header', () {
      expect(_headers({}).retryAfter, isNull);
    });
  });

  group('recommendedRetryDelay', () {
    test('429 reads an HTTP-date Retry-After', () {
      withClock(Clock.fixed(_now), () {
        final exception = NetworkLimitExceededException(
          response: _response(429, {
            'retry-after': 'Wed, 23 Sep 2026 12:00:20 GMT',
          }),
        );
        expect(exception.recommendedRetryDelay, const Duration(seconds: 20));
      });
    });

    test('429 without Retry-After falls back to one minute', () {
      final exception = NetworkLimitExceededException(
        response: _response(429, {}),
      );
      expect(exception.recommendedRetryDelay, const Duration(minutes: 1));
    });

    test('503 reads Retry-After and falls back to 30 seconds', () {
      final withHeader = NetworkServerException(
        statusCode: 503,
        response: _response(503, {'retry-after': '7'}),
      );
      final without = NetworkServerException(
        statusCode: 503,
        response: _response(503, {}),
      );
      expect(withHeader.recommendedRetryDelay, const Duration(seconds: 7));
      expect(without.recommendedRetryDelay, const Duration(seconds: 30));
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd dart_falmodel && dart test test/networks/https/retry_after_test.dart`
Expected: compile error, `parseRetryAfter` and `retryAfter` are not defined.

- [ ] **Step 3: Add the dependency**

In `dart_falmodel/pubspec.yaml`, under `dependencies:`, insert after `  freezed_annotation: ^3.1.0`:

```yaml
  http_parser: ^4.1.2
```

Run `dart pub get` at the worktree root.

- [ ] **Step 4: Write the parser**

Create `dart_falmodel/lib/networks/https/retry_after.dart`:

```dart
import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:dio/dio.dart' show Headers;
import 'package:http_parser/http_parser.dart' show parseHttpDate;

/// The longest delay [parseRetryAfter] returns, about 68 years. Clamping
/// to it keeps a huge delay-seconds value from overflowing [Duration].
const Duration _maxRetryAfter = Duration(seconds: 1 << 31);

final RegExp _delaySeconds = RegExp(r'^\d+$');

/// Converts a `Retry-After` header value into a delay.
///
/// Accepts delay-seconds (`120`) and the three HTTP-date formats RFC 9110
/// requires a recipient to accept. A date is measured from [serverDate],
/// the response's `Date` header, when given, otherwise from `clock.now()`;
/// a date in the past gives [Duration.zero]. Delay-seconds above 2^31
/// (about 68 years) are clamped to 2^31 seconds.
///
/// Returns null for a missing, empty, negative, decimal, or unreadable
/// value.
Duration? parseRetryAfter(String? value, {DateTime? serverDate}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  if (_delaySeconds.hasMatch(text)) {
    final seconds = int.tryParse(text);
    if (seconds == null || seconds > _maxRetryAfter.inSeconds) {
      return _maxRetryAfter;
    }
    return Duration(seconds: seconds);
  }
  final DateTime date;
  try {
    date = parseHttpDate(text);
  } on FormatException {
    return null;
  }
  final delay = date.difference(serverDate ?? clock.now());
  return delay.isNegative ? Duration.zero : delay;
}

/// Reads `Retry-After` from response headers.
extension FalconRetryAfterHeadersExtensions on Headers {
  /// The `Retry-After` delay of this response, or null when the header is
  /// missing or unreadable.
  ///
  /// An HTTP-date is measured from the response's `Date` header when it is
  /// readable, so a wrong client clock does not change the delay.
  Duration? get retryAfter {
    DateTime? serverDate;
    final date = value('date');
    if (date != null) {
      try {
        serverDate = parseHttpDate(date);
      } on FormatException {
        serverDate = null;
      }
    }
    return parseRetryAfter(value('retry-after'), serverDate: serverDate);
  }
}
```

In `dart_falmodel/lib/networks/https/https.dart`, add after `export 'responses/responses.dart';`:

```dart
export 'retry_after.dart';
```

- [ ] **Step 5: Use it in the exceptions**

In `dart_falmodel/lib/networks/exceptions/base_http_exception.dart`, replace:

```dart
    // Check for Retry-After header (429 errors)
    if (statusCode == 429 && response?.headers != null) {
      final retryAfter = response!.headers.value('retry-after');
      if (retryAfter != null) {
        final seconds = int.tryParse(retryAfter);
        if (seconds != null) return Duration(seconds: seconds);
      }
    }

    // Default retry delays
    if (statusCode == 429) return const Duration(minutes: 1);
```

with:

```dart
    // Retry-After (delay-seconds or HTTP-date), else one minute
    if (statusCode == 429) {
      return response?.headers.retryAfter ?? const Duration(minutes: 1);
    }

    // Default retry delays
```

In `dart_falmodel/lib/networks/exceptions/code5XX/server_error_exception.dart`, replace:

```dart
      case 503: // Service Unavailable might have Retry-After header
        final retryAfter = response?.headers.value('retry-after');
        if (retryAfter != null) {
          final seconds = int.tryParse(retryAfter);
          if (seconds != null) return Duration(seconds: seconds);
        }
        return const Duration(seconds: 30);
```

with:

```dart
      case 503: // Service Unavailable might have Retry-After header
        return response?.headers.retryAfter ?? const Duration(seconds: 30);
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `cd dart_falmodel && dart test && dart analyze --fatal-infos`
Expected: all tests pass (54), no issues.

- [ ] **Step 7: Commit**

```bash
git add dart_falmodel/pubspec.yaml dart_falmodel/lib/networks/https/retry_after.dart dart_falmodel/lib/networks/https/https.dart dart_falmodel/lib/networks/exceptions/base_http_exception.dart dart_falmodel/lib/networks/exceptions/code5XX/server_error_exception.dart dart_falmodel/test/networks/https/retry_after_test.dart
git commit -m "feat(dart_falmodel): parse Retry-After as seconds or HTTP-date"
```

---

### Task 2: Pause core and the local 429 marker in `dart_falconnect`

**Files:**
- Create: `dart_falconnect/lib/src/engine/https/interceptors/retry_after_pause.dart`
- Create: `dart_falconnect/lib/engine/https/interceptors/local_rate_limit.dart`
- Modify: `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/retry_after_pause_test.dart`

**Interfaces:**
- Consumes: `FalconRetryAfterHeadersExtensions.retryAfter` (Task 1); `clock` from `dart_faltool`.
- Produces (internal, `lib/src/`): `const String localRateLimitKey`; `DioException localRateLimitRejection(RequestOptions options, {Object? error, Duration? retryAfter})`; `sealed class PauseAdmission` with `PausePass()`, `PauseHold()`, `PauseReject(Duration remaining)`; `class RetryAfterPause({required Duration maxPauseWait, required Duration maxPause, required Duration? defaultPause, required int maxHeld, required bool holdRequests})` with `PauseAdmission admit(String host)`, `bool isPaused(String host)`, `Future<void> wait(String host, CancelToken? cancelToken)`, `void observe(Response<dynamic> response)`, `Map<String, int> get heldByHost`, `Map<String, DateTime> get pausedUntilByHost`, `void dispose()`.
- Produces (public): `extension FalconLocalRateLimitResponseExtensions on Response<dynamic> { bool get isLocalRateLimit; }`.

- [ ] **Step 1: Write the failing test**

Create `dart_falconnect/test/engine/https/interceptors/retry_after_pause_test.dart`:

```dart
import 'dart:async';

import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

RetryAfterPause _pause({
  Duration maxPauseWait = const Duration(seconds: 10),
  Duration maxPause = const Duration(minutes: 10),
  Duration? defaultPause = const Duration(seconds: 5),
  int maxHeld = 50,
  bool holdRequests = true,
}) => RetryAfterPause(
  maxPauseWait: maxPauseWait,
  maxPause: maxPause,
  defaultPause: defaultPause,
  maxHeld: maxHeld,
  holdRequests: holdRequests,
);

Response<dynamic> _response(
  int status, {
  String host = 'a.test',
  String? retryAfter,
}) => Response<dynamic>(
  requestOptions: RequestOptions(path: 'https://$host/x'),
  statusCode: status,
  headers: Headers.fromMap({
    if (retryAfter != null) 'retry-after': [retryAfter],
  }),
);

Duration _remaining(PauseAdmission admission) =>
    (admission as PauseReject).remaining;

void main() {
  test('passes an unpaused host', () {
    expect(_pause().admit('a.test'), isA<PausePass>());
  });

  test('429 with Retry-After pauses only that host', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));

      expect(pause.admit('a.test'), isA<PauseHold>());
      expect(pause.admit('b.test'), isA<PausePass>());
      async.elapse(const Duration(seconds: 3));
      expect(pause.admit('a.test'), isA<PausePass>());
    });
  });

  test('429 without Retry-After pauses for defaultPause', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429));

      async.elapse(const Duration(milliseconds: 4999));
      expect(pause.isPaused('a.test'), isTrue);
      async.elapse(const Duration(milliseconds: 1));
      expect(pause.isPaused('a.test'), isFalse);
    });
  });

  test('a null defaultPause ignores a 429 without Retry-After', () {
    final pause = _pause(defaultPause: null)..observe(_response(429));
    expect(pause.isPaused('a.test'), isFalse);
  });

  test('503 pauses only with Retry-After; other statuses never', () {
    final pause = _pause()
      ..observe(_response(503))
      ..observe(_response(500, retryAfter: '9'))
      ..observe(_response(200, retryAfter: '9'));
    expect(pause.isPaused('a.test'), isFalse);

    pause.observe(_response(503, retryAfter: '9'));
    expect(pause.isPaused('a.test'), isTrue);
  });

  test('a local 429 starts no pause', () {
    final options = RequestOptions(path: 'https://a.test/x');
    final local = localRateLimitRejection(
      options,
      retryAfter: const Duration(seconds: 30),
    ).response!;
    expect(local.isLocalRateLimit, isTrue);

    final pause = _pause()..observe(local);
    expect(pause.isPaused('a.test'), isFalse);
  });

  test('Retry-After: 0 starts no pause', () {
    final pause = _pause()..observe(_response(429, retryAfter: '0'));
    expect(pause.isPaused('a.test'), isFalse);
  });

  test('clamps a pause to maxPause', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '86400'));

      expect(_remaining(pause.admit('a.test')), const Duration(minutes: 10));
      async.elapse(const Duration(minutes: 10));
      expect(pause.isPaused('a.test'), isFalse);
    });
  });

  test('extends a pause but never shortens it', () {
    fakeAsync((async) {
      final pause = _pause(maxPauseWait: Duration.zero)
        ..observe(_response(429, retryAfter: '20'))
        ..observe(_response(429, retryAfter: '5'));
      expect(_remaining(pause.admit('a.test')), const Duration(seconds: 20));

      pause.observe(_response(429, retryAfter: '40'));
      expect(_remaining(pause.admit('a.test')), const Duration(seconds: 40));
    });
  });

  test('rejects when the remaining pause exceeds maxPauseWait', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '11'));

      expect(_remaining(pause.admit('a.test')), const Duration(seconds: 11));
      async.elapse(const Duration(seconds: 1));
      expect(pause.admit('a.test'), isA<PauseHold>());
    });
  });

  test('rejects instead of holding when holdRequests is false', () {
    final pause = _pause(holdRequests: false)
      ..observe(_response(429, retryAfter: '1'));
    expect(pause.admit('a.test'), isA<PauseReject>());
  });

  test('releases held requests in order when the pause ends', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      final released = <int>[];
      for (var i = 0; i < 3; i++) {
        unawaited(pause.wait('a.test', null).then((_) => released.add(i)));
      }
      expect(pause.heldByHost, {'a.test': 3});

      async.elapse(const Duration(milliseconds: 2999));
      expect(released, isEmpty);
      async.elapse(const Duration(milliseconds: 1));
      expect(released, [0, 1, 2]);
      expect(pause.heldByHost, isEmpty);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('keeps holding when a new 429 extends the pause', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      var released = false;
      unawaited(pause.wait('a.test', null).then((_) => released = true));

      async.elapse(const Duration(seconds: 2));
      pause.observe(_response(429, retryAfter: '4'));
      async.elapse(const Duration(seconds: 1));
      expect(released, isFalse);
      async.elapse(const Duration(seconds: 3));
      expect(released, isTrue);
    });
  });

  test('rejects once the hold queue is full', () {
    fakeAsync((async) {
      final pause = _pause(maxHeld: 2)
        ..observe(_response(429, retryAfter: '3'));
      unawaited(pause.wait('a.test', null));
      unawaited(pause.wait('a.test', null));

      expect(pause.admit('a.test'), isA<PauseReject>());
      async.elapse(const Duration(seconds: 3));
    });
  });

  test('a cancelled request leaves the hold queue at once', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      final token = CancelToken();
      Object? failure;
      unawaited(
        pause.wait('a.test', token).catchError((Object e) => failure = e),
      );

      token.cancel('user left');
      async.flushMicrotasks();

      expect(failure, isA<DioException>());
      expect(pause.heldByHost, isEmpty);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('a pause with nobody held creates no timer', () {
    fakeAsync((async) {
      _pause().observe(_response(429, retryAfter: '600'));
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('reports the end time of active pauses only', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      expect(pause.pausedUntilByHost.keys, ['a.test']);

      async.elapse(const Duration(seconds: 3));
      expect(pause.pausedUntilByHost, isEmpty);
    });
  });

  test('dispose fails held requests and forgets pauses', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      Object? failure;
      unawaited(
        pause.wait('a.test', null).catchError((Object e) => failure = e),
      );

      pause
        ..dispose()
        ..dispose();
      async.flushMicrotasks();

      expect(failure, isA<StateError>());
      expect(pause.admit('a.test'), isA<PausePass>());
      pause.observe(_response(429, retryAfter: '3'));
      expect(pause.isPaused('a.test'), isFalse);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('rejects invalid settings', () {
    expect(
      () => _pause(maxPauseWait: const Duration(seconds: -1)),
      throwsArgumentError,
    );
    expect(() => _pause(maxPause: Duration.zero), throwsArgumentError);
    expect(() => _pause(defaultPause: Duration.zero), throwsArgumentError);
    expect(() => _pause(maxHeld: -1), throwsArgumentError);
  });

  test('local 429 carries Retry-After rounded up to whole seconds', () {
    final options = RequestOptions(path: 'https://a.test/x');
    final paused = localRateLimitRejection(
      options,
      retryAfter: const Duration(milliseconds: 2100),
    );
    final brief = localRateLimitRejection(
      options,
      retryAfter: const Duration(milliseconds: 10),
    );
    final full = localRateLimitRejection(options);

    expect(paused.type, DioExceptionType.badResponse);
    expect(paused.response?.statusCode, 429);
    expect(paused.response?.headers.value('retry-after'), '3');
    expect(brief.response?.headers.value('retry-after'), '1');
    expect(full.response?.headers.value('retry-after'), isNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/retry_after_pause_test.dart`
Expected: compile error, the imported files do not exist.

- [ ] **Step 3: Write the public marker**

Create `dart_falconnect/lib/engine/https/interceptors/local_rate_limit.dart`:

```dart
import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart'
    show localRateLimitKey;
import 'package:dio/dio.dart';

/// Tells a 429 produced on the client apart from one the server sent.
extension FalconLocalRateLimitResponseExtensions on Response<dynamic> {
  /// Whether this response is a 429 built by a rate-limit interceptor, with
  /// no request sent to the server.
  bool get isLocalRateLimit => extra[localRateLimitKey] == true;
}
```

In `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`, add after `export 'default_network_exception_handler_interceptor.dart';`:

```dart
export 'local_rate_limit.dart';
```

- [ ] **Step 4: Write the pause core**

Create `dart_falconnect/lib/src/engine/https/interceptors/retry_after_pause.dart`:

```dart
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falmodel/networks/https/retry_after.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:dio/dio.dart';

/// Key in `Response.extra` that marks a 429 built on the client.
const String localRateLimitKey = 'dart_falconnect.localRateLimit';

/// Builds the 429 that `TokenBucketRateLimitInterceptor` and
/// `RetryAfterPauseInterceptor` reject with.
///
/// [error] is the cause (a `RateLimitExceededException` when a queue is
/// full). [retryAfter] is the remaining pause; when given, it becomes a
/// `Retry-After` header in whole seconds, rounded up, at least 1.
DioException localRateLimitRejection(
  RequestOptions options, {
  Object? error,
  Duration? retryAfter,
}) {
  final headers = <String, List<String>>{};
  if (retryAfter != null) {
    const second = Duration.microsecondsPerSecond;
    final seconds = (retryAfter.inMicroseconds + second - 1) ~/ second;
    headers['retry-after'] = ['${math.max(1, seconds)}'];
  }
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    error: error,
    message: 'Rate limited locally for ${options.uri.host}',
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: 429,
      statusMessage: 'Too Many Requests',
      headers: Headers.fromMap(headers),
      extra: {localRateLimitKey: true},
    ),
  );
}

/// What a paused host does with a request.
sealed class PauseAdmission {
  const new();
}

/// The host is not paused: the request may go on.
final class PausePass extends PauseAdmission {
  const new();
}

/// The host is paused briefly: the request waits for the pause to end.
final class PauseHold extends PauseAdmission {
  const new();
}

/// The host is paused too long, or its hold queue is full.
final class PauseReject extends PauseAdmission {
  const new(this.remaining);

  /// Time left until the pause ends.
  final Duration remaining;
}

/// Per-host pauses started by 429 and 503 responses.
///
/// A pause is stored as an end time read from `clock.now()`. A `Timer`
/// exists only while a host has held requests, so a long pause with nobody
/// waiting keeps no timer alive.
class RetryAfterPause {
  /// Creates the pause state shared by the rate-limit interceptors.
  new({
    required this.maxPauseWait,
    required this.maxPause,
    required this.defaultPause,
    required this.maxHeld,
    required this.holdRequests,
  }) {
    if (maxPauseWait.isNegative) {
      throw ArgumentError.value(
        maxPauseWait,
        'maxPauseWait',
        'must not be negative',
      );
    }
    if (maxPause <= Duration.zero) {
      throw ArgumentError.value(maxPause, 'maxPause', 'must be positive');
    }
    final fallback = defaultPause;
    if (fallback != null && fallback <= Duration.zero) {
      throw ArgumentError.value(
        fallback,
        'defaultPause',
        'must be positive or null',
      );
    }
    if (maxHeld < 0) {
      throw ArgumentError.value(maxHeld, 'maxHeld', 'must not be negative');
    }
  }

  /// Longest remaining pause a request waits out instead of failing.
  final Duration maxPauseWait;

  /// Longest pause any response can start.
  final Duration maxPause;

  /// Pause for a 429 without a readable `Retry-After`; null means none.
  final Duration? defaultPause;

  /// Most requests held per host.
  final int maxHeld;

  /// Whether a briefly paused host holds requests (`true`) or rejects them.
  final bool holdRequests;

  final Map<String, DateTime> _until = {};
  final Map<String, _Held> _held = {};
  bool _disposed = false;

  /// Decides what happens to a request for [host] right now.
  PauseAdmission admit(String host) {
    final remaining = _remaining(host);
    if (remaining == null) {
      return const PausePass();
    }
    final held = _held[host]?.waiters.length ?? 0;
    if (holdRequests && remaining <= maxPauseWait && held < maxHeld) {
      return const PauseHold();
    }
    return PauseReject(remaining);
  }

  /// Whether [host] is paused at this moment.
  bool isPaused(String host) => _remaining(host) != null;

  /// Completes when the pause of [host] ends.
  ///
  /// Fails with the cancel error when [cancelToken] cancels, and with a
  /// [StateError] when [dispose] runs.
  Future<void> wait(String host, CancelToken? cancelToken) {
    if (_disposed) {
      return Future.error(StateError('RetryAfterPause disposed'));
    }
    final held = _held.putIfAbsent(host, _Held.new);
    final waiter = Completer<void>();
    held.waiters.add(waiter);
    _schedule(host, held);
    if (cancelToken != null) {
      unawaited(
        cancelToken.whenCancel.then((error) {
          if (held.waiters.remove(waiter)) {
            waiter.completeError(error);
            if (held.waiters.isEmpty) {
              held.timer?.cancel();
              _held.remove(host);
            }
          }
        }),
      );
    }
    return waiter.future;
  }

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
    final host = response.requestOptions.uri.host;
    final until = clock.now().add(length > maxPause ? maxPause : length);
    final current = _until[host];
    if (current == null || until.isAfter(current)) {
      _until[host] = until;
    }
  }

  /// Requests held per host.
  Map<String, int> get heldByHost => Map.unmodifiable({
    for (final entry in _held.entries) entry.key: entry.value.waiters.length,
  });

  /// End time of every active pause, per host.
  Map<String, DateTime> get pausedUntilByHost {
    final now = clock.now();
    return Map.unmodifiable({
      for (final entry in _until.entries)
        if (entry.value.isAfter(now)) entry.key: entry.value,
    });
  }

  /// Fails every held request, cancels the timers, and forgets every
  /// pause. Afterwards [admit] always passes and [observe] does nothing.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _until.clear();
    for (final held in _held.values) {
      held.timer?.cancel();
      while (held.waiters.isNotEmpty) {
        held.waiters.removeFirst().completeError(
          StateError('RetryAfterPause disposed'),
        );
      }
    }
    _held.clear();
  }

  Duration? _remaining(String host) {
    final until = _until[host];
    if (until == null) {
      return null;
    }
    final remaining = until.difference(clock.now());
    if (remaining > Duration.zero) {
      return remaining;
    }
    _until.remove(host);
    return null;
  }

  void _schedule(String host, _Held held) {
    held.timer?.cancel();
    final remaining = _remaining(host) ?? Duration.zero;
    held.timer = Timer(remaining, () => _release(host));
  }

  void _release(String host) {
    final held = _held[host];
    if (held == null) {
      return;
    }
    held.timer = null;
    if (isPaused(host)) {
      // A later response extended the pause while requests were held.
      _schedule(host, held);
      return;
    }
    _held.remove(host);
    while (held.waiters.isNotEmpty) {
      held.waiters.removeFirst().complete();
    }
  }
}

class _Held {
  final Queue<Completer<void>> waiters = Queue<Completer<void>>();
  Timer? timer;
}
```

The two files import each other (the marker needs `localRateLimitKey`; the core needs `isLocalRateLimit`). Dart allows the cycle.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/retry_after_pause_test.dart && dart analyze --fatal-infos`
Expected: 20 tests pass, no issues.

- [ ] **Step 6: Commit**

```bash
git add dart_falconnect/lib/src dart_falconnect/lib/engine/https/interceptors/local_rate_limit.dart dart_falconnect/lib/engine/https/interceptors/interceptors.dart dart_falconnect/test/engine/https/interceptors/retry_after_pause_test.dart
git commit -m "feat(dart_falconnect): add the Retry-After pause core and local 429 marker"
```

---

### Task 3: `RetryAfterPauseInterceptor`

**Files:**
- Create: `dart_falconnect/lib/engine/https/interceptors/retry_after_pause_interceptor.dart`
- Modify: `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/retry_after_pause_interceptor_test.dart`

**Interfaces:**
- Consumes: `RetryAfterPause`, `PauseAdmission` subtypes, `localRateLimitRejection` (Task 2); `HttpClientConfig`.
- Produces: `RetryAfterPauseInterceptor({required HttpClientConfig config, Duration maxPauseWait = const Duration(seconds: 10), Duration maxPause = const Duration(minutes: 10), Duration? defaultPause = const Duration(seconds: 5), int maxQueueSize = 50})` with `onRequest`, `onResponse`, `onError`, `dispose()`.

- [ ] **Step 1: Write the failing test**

Create `dart_falconnect/test/engine/https/interceptors/retry_after_pause_interceptor_test.dart`:

```dart
import 'dart:async';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falconnect/engine/https/interceptors/retry_after_pause_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

class _Handler extends RequestInterceptorHandler {
  new(this.forwarded, this.rejected);

  final List<RequestOptions> forwarded;
  final List<DioException> rejected;

  @override
  void next(RequestOptions requestOptions) => forwarded.add(requestOptions);

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) => rejected.add(error);
}

class _SilentResponseHandler extends ResponseInterceptorHandler {
  @override
  void next(Response<dynamic> response) {}
}

class _SilentErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException error) {}
}

Response<dynamic> _response(int status, {String? retryAfter}) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: 'https://a.test/items'),
      statusCode: status,
      headers: Headers.fromMap({
        if (retryAfter != null) 'retry-after': [retryAfter],
      }),
    );

void main() {
  const config = HttpClientConfig();
  late List<RequestOptions> forwarded;
  late List<DioException> rejected;

  void send(RetryAfterPauseInterceptor interceptor, {String host = 'a.test'}) {
    unawaited(
      interceptor.onRequest(
        RequestOptions(path: 'https://$host/items'),
        _Handler(forwarded, rejected),
      ),
    );
  }

  setUp(() {
    forwarded = [];
    rejected = [];
  });

  test('forwards synchronously while no host is paused', () {
    fakeAsync((async) {
      final interceptor = RetryAfterPauseInterceptor(config: config);

      send(interceptor);

      expect(forwarded, hasLength(1));
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('holds a request until a short pause ends', () {
    fakeAsync((async) {
      final interceptor = RetryAfterPauseInterceptor(config: config)
        ..onResponse(_response(429, retryAfter: '2'), _SilentResponseHandler());

      send(interceptor);
      send(interceptor, host: 'b.test');
      async.flushMicrotasks();
      expect(forwarded.map((o) => o.uri.host), ['b.test']);

      async.elapse(const Duration(seconds: 2));
      expect(forwarded, hasLength(2));
    });
  });

  test('rejects with a local 429 when the pause is long', () {
    fakeAsync((async) {
      final interceptor = RetryAfterPauseInterceptor(config: config)
        ..onError(
          DioException.badResponse(
            statusCode: 503,
            requestOptions: RequestOptions(path: 'https://a.test/items'),
            response: _response(503, retryAfter: '30'),
          ),
          _SilentErrorHandler(),
        );

      send(interceptor);
      async.flushMicrotasks();

      expect(rejected.single.response?.isLocalRateLimit, isTrue);
      expect(rejected.single.response?.headers.value('retry-after'), '30');
    });
  });

  test('dispose cancels held requests and lifts every pause', () {
    fakeAsync((async) {
      final interceptor = RetryAfterPauseInterceptor(config: config)
        ..onResponse(_response(429, retryAfter: '2'), _SilentResponseHandler());
      send(interceptor);
      async.flushMicrotasks();

      interceptor.dispose();
      async.flushMicrotasks();
      send(interceptor);

      expect(rejected.single.type, DioExceptionType.cancel);
      expect(forwarded, hasLength(1));
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('rejects invalid settings', () {
    expect(
      () => RetryAfterPauseInterceptor(config: config, maxQueueSize: -1),
      throwsArgumentError,
    );
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/retry_after_pause_interceptor_test.dart`
Expected: compile error, `retry_after_pause_interceptor.dart` does not exist.

- [ ] **Step 3: Write the interceptor**

Create `dart_falconnect/lib/engine/https/interceptors/retry_after_pause_interceptor.dart`:

```dart
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart';
import 'package:dio/dio.dart';

/// Pauses requests to a host after it answers 429, or 503 with
/// `Retry-After`, without limiting the request rate.
///
/// `TokenBucketRateLimitInterceptor` already contains this pause. A chain
/// that uses it must not add `RetryAfterPauseInterceptor`: the two would
/// hold requests twice under two sets of limits.
///
/// A 429 pauses its host for its `Retry-After`, else for `defaultPause`;
/// a 503 pauses only for its `Retry-After`. Every pause is clamped to
/// `maxPause`. While a host is paused, a request waits when the remaining
/// pause is at most `maxPauseWait` and fewer than `maxQueueSize` requests
/// already wait; otherwise it fails with a local 429 that carries
/// `Retry-After` and goes through every error interceptor, so callers get
/// the same `NetworkLimitExceededException` as for a server 429.
///
/// Place it before `RetryInterceptor`, so a server 429 starts the pause
/// before the retry is sent, and before the network exception handler,
/// which stops the error chain.
class RetryAfterPauseInterceptor extends Interceptor {
  /// Creates a pause-only interceptor.
  new({
    required this.config,
    Duration maxPauseWait = const Duration(seconds: 10),
    Duration maxPause = const Duration(minutes: 10),
    Duration? defaultPause = const Duration(seconds: 5),
    int maxQueueSize = 50,
  }) : _pause = RetryAfterPause(
         maxPauseWait: maxPauseWait,
         maxPause: maxPause,
         defaultPause: defaultPause,
         maxHeld: maxQueueSize,
         holdRequests: true,
       );

  /// Configuration; `enableLogging` gates diagnostic prints.
  final HttpClientConfig config;

  final RetryAfterPause _pause;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final host = options.uri.host;
    while (true) {
      final admission = _pause.admit(host);
      if (admission is PauseReject) {
        _log('Paused host $host rejected a request');
        handler.reject(
          localRateLimitRejection(options, retryAfter: admission.remaining),
          true,
        );
        return;
      }
      if (admission is PausePass) {
        handler.next(options);
        return;
      }
      try {
        await _pause.wait(host, options.cancelToken);
      } on Object catch (error) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: error,
            message: 'Request cancelled while its host was paused',
          ),
        );
        return;
      }
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _pause.observe(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      _pause.observe(response);
    }
    handler.next(err);
  }

  /// Fails held requests and forgets every pause. Afterwards requests pass
  /// without a pause. Calling it again has no effect.
  void dispose() => _pause.dispose();

  void _log(String message) {
    if (config.enableLogging) {
      // Intentional logging for pause diagnostics.
      // ignore: avoid_print
      print('[RetryAfterPauseInterceptor] $message');
    }
  }
}
```

In `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`, add before `export 'retry_interceptor.dart';`:

```dart
export 'retry_after_pause_interceptor.dart';
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/retry_after_pause_interceptor_test.dart && dart analyze --fatal-infos`
Expected: 5 tests pass, no issues.

- [ ] **Step 5: Commit**

```bash
git add dart_falconnect/lib/engine/https/interceptors/retry_after_pause_interceptor.dart dart_falconnect/lib/engine/https/interceptors/interceptors.dart dart_falconnect/test/engine/https/interceptors/retry_after_pause_interceptor_test.dart
git commit -m "feat(dart_falconnect): add RetryAfterPauseInterceptor"
```

---

### Task 4: Pause, local 429 routing, and SP1 minors in `TokenBucketRateLimitInterceptor`

**Files:**
- Modify (replace whole file): `dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart`
- Modify: `dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart`

**Interfaces:**
- Consumes: Task 2 core and marker.
- Produces: constructor gains `Duration maxPauseWait = const Duration(seconds: 10)`, `Duration maxPause = const Duration(minutes: 10)`, `Duration? defaultPause = const Duration(seconds: 5)`; new overrides `onResponse`, `onError`; `TokenBucketRateLimitStatistics` gains required `Map<String, int> heldByHost` and `Map<String, DateTime> pausedUntilByHost`; a local 429 is `DioExceptionType.badResponse`, rejected with `callFollowingErrorInterceptor: true`.

- [ ] **Step 1: Update the test harness**

In `dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart`:

(a) Replace the two imports

```dart
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart';
```

with

```dart
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falconnect/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart';
```

(b) Replace everything from the doc comment `/// Records what the interceptor does with each request, ...` down to, but not including, `const _config = HttpClientConfig();` with:

```dart
/// Records what the interceptor does with each request, standing in for the
/// rest of the Dio chain.
class _RecordingHandler extends RequestInterceptorHandler {
  new(this.log);

  final _Log log;

  @override
  void next(RequestOptions requestOptions) => log.forwarded.add(requestOptions);

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) {
    log.rejected.add(error);
    log.rejectCallsFollowing.add(callFollowingErrorInterceptor);
  }
}

/// Records the fake time at which each request is forwarded.
class _TimedHandler extends _RecordingHandler {
  new(super.log, this.async, this.sentAt);

  final FakeAsync async;
  final List<Duration> sentAt;

  @override
  void next(RequestOptions requestOptions) {
    super.next(requestOptions);
    sentAt.add(async.elapsed);
  }
}

class _Log {
  final forwarded = <RequestOptions>[];
  final rejected = <DioException>[];
  final rejectCallsFollowing = <bool>[];
}

/// Swallows `next` so an unobserved handler future never reports an error.
class _SilentResponseHandler extends ResponseInterceptorHandler {
  @override
  void next(Response<dynamic> response) {}
}

/// Swallows `next` so an unobserved handler future never reports an error.
class _SilentErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException error) {}
}

Response<dynamic> _serverResponse(
  int status, {
  String host = 'a.test',
  String? retryAfter,
}) => Response<dynamic>(
  requestOptions: RequestOptions(path: 'https://$host/items'),
  statusCode: status,
  headers: Headers.fromMap({
    if (retryAfter != null) 'retry-after': [retryAfter],
  }),
);

/// Feeds a server response through `onResponse`, as a client whose
/// `validateStatus` accepts 429 would.
void _respond(
  TokenBucketRateLimitInterceptor interceptor,
  Response<dynamic> response,
) => interceptor.onResponse(response, _SilentResponseHandler());

/// Feeds a server error through `onError`.
void _fail(
  TokenBucketRateLimitInterceptor interceptor,
  Response<dynamic> response,
) => interceptor.onError(
  DioException.badResponse(
    statusCode: response.statusCode!,
    requestOptions: response.requestOptions,
    response: response,
  ),
  _SilentErrorHandler(),
);
```

(c) In the test `rejects with 429 when a queue is full`, replace

```dart
      final error = log.rejected.single;
      expect(error.type, DioExceptionType.unknown);
      expect(error.response?.statusCode, 429);
      expect(error.error, isA<RateLimitExceededException>());
```

with

```dart
      final error = log.rejected.single;
      expect(error.type, DioExceptionType.badResponse);
      expect(error.response?.statusCode, 429);
      expect(error.response?.isLocalRateLimit, isTrue);
      expect(error.error, isA<RateLimitExceededException>());
      expect(log.rejectCallsFollowing.single, isTrue);
```

(d) Insert before the closing `}` of `main`:

```dart
  group('pause', () {
    test('a 429 seen in onResponse pauses only its host', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(config: _config);
        final log = _Log();
        _respond(interceptor, _serverResponse(429, retryAfter: '3'));

        _send(interceptor, log);
        _send(interceptor, log, url: 'https://b.test/items');
        async.flushMicrotasks();
        expect(log.forwarded.map((o) => o.uri.host), ['b.test']);

        async.elapse(const Duration(seconds: 3));
        expect(log.forwarded, hasLength(2));
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('a 429 seen in onError pauses its host', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(config: _config);
        final log = _Log();
        _fail(interceptor, _serverResponse(429, retryAfter: '3'));

        _send(interceptor, log);
        async.flushMicrotasks();
        expect(log.forwarded, isEmpty);
        expect(interceptor.getStatistics().heldByHost, {'a.test': 1});
        expect(interceptor.getStatistics().pausedUntilByHost.keys, ['a.test']);

        async.elapse(const Duration(seconds: 3));
        expect(log.forwarded, hasLength(1));
      });
    });

    test('rejects with a local 429 when the pause exceeds maxPauseWait', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(config: _config);
        final log = _Log();
        _respond(interceptor, _serverResponse(429, retryAfter: '60'));

        _send(interceptor, log);
        async.flushMicrotasks();

        final error = log.rejected.single;
        expect(error.type, DioExceptionType.badResponse);
        expect(error.response?.isLocalRateLimit, isTrue);
        expect(error.response?.headers.value('retry-after'), '60');
        expect(log.rejectCallsFollowing.single, isTrue);
        expect(interceptor.getStatistics().rejected, 1);
      });
    });

    test('queueRequests false rejects instead of holding', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(
          config: _config,
          queueRequests: false,
        );
        final log = _Log();
        _respond(interceptor, _serverResponse(429, retryAfter: '1'));

        _send(interceptor, log);
        async.flushMicrotasks();

        expect(log.rejected.single.response?.statusCode, 429);
      });
    });

    test('a local 429 fed back through onError starts no pause', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(
          config: _config,
          perHost: const [
            TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
          ],
          queueRequests: false,
        );
        final log = _Log();
        _send(interceptor, log, times: 2);
        async.flushMicrotasks();

        interceptor.onError(log.rejected.single, _SilentErrorHandler());
        expect(interceptor.getStatistics().pausedUntilByHost, isEmpty);
        interceptor.dispose();
      });
    });

    test('forwards nothing during a pause, then keeps the ceiling', () {
      fakeAsync((async) {
        // One token per second, burst 1.
        final interceptor = TokenBucketRateLimitInterceptor(
          config: _config,
          perHost: const [
            TokenBucketPolicy(permits: 1, per: Duration(seconds: 1)),
          ],
        );
        final sentAt = <Duration>[];
        final log = _Log();
        for (var i = 0; i < 5; i++) {
          unawaited(
            interceptor.onRequest(
              RequestOptions(path: 'https://a.test/items'),
              _TimedHandler(log, async, sentAt),
            ),
          );
        }
        async.flushMicrotasks();
        expect(sentAt, [Duration.zero]);

        // The server answers the first request with a 3 s pause. Requests
        // that get tokens at 1 s and 2 s must not be forwarded.
        _respond(interceptor, _serverResponse(429, retryAfter: '3'));
        async.elapse(const Duration(milliseconds: 2999));
        expect(sentAt, [Duration.zero]);

        async.elapse(const Duration(seconds: 5));
        expect(sentAt, hasLength(5));
        for (var i = 1; i < sentAt.length; i++) {
          expect(
            sentAt[i] - sentAt[i - 1],
            greaterThanOrEqualTo(const Duration(seconds: 1)),
            reason: 'two forwards inside one 1 s window: $sentAt',
          );
        }
        expect(sentAt[1], greaterThanOrEqualTo(const Duration(seconds: 3)));
        interceptor.dispose();
      });
    });

    test('a request cancelled while it waits for tokens is not counted', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(
          config: _config,
          perHost: const [
            TokenBucketPolicy(permits: 1, per: Duration(seconds: 1)),
          ],
        );
        final log = _Log();
        final token = CancelToken();
        _send(interceptor, log);
        unawaited(
          interceptor.onRequest(
            RequestOptions(path: 'https://a.test/items', cancelToken: token),
            _RecordingHandler(log),
          ),
        );
        async.flushMicrotasks();

        token.cancel('user left');
        async.elapse(const Duration(seconds: 1));

        expect(log.forwarded, hasLength(1));
        expect(log.rejected.single.type, DioExceptionType.cancel);
        expect(interceptor.getStatistics().forwarded, 1);
        interceptor.dispose();
      });
    });

    test('dispose cancels held requests', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(config: _config);
        final log = _Log();
        _respond(interceptor, _serverResponse(429, retryAfter: '3'));
        _send(interceptor, log);
        async.flushMicrotasks();

        interceptor.dispose();
        async.flushMicrotasks();

        expect(log.rejected.single.type, DioExceptionType.cancel);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('rejects invalid pause settings', () {
      expect(
        () => TokenBucketRateLimitInterceptor(
          config: _config,
          maxPause: Duration.zero,
        ),
        throwsArgumentError,
      );
    });
  });

  group('construction', () {
    test('rejects hosts keys Uri.host could never return', () {
      for (final key in ['api.a.test:8080', ' a.test', '[::1]', '']) {
        expect(
          () => TokenBucketRateLimitInterceptor(
            config: _config,
            hosts: {
              key: const [
                TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
              ],
            },
          ),
          throwsArgumentError,
          reason: '"$key"',
        );
      }
      expect(
        TokenBucketRateLimitInterceptor(
          config: _config,
          hosts: const {'::1': []},
        ),
        isNotNull,
      );
    });

    test('an invalid global policy throws', () {
      expect(
        () => TokenBucketRateLimitInterceptor(
          config: _config,
          global: const [
            TokenBucketPolicy(permits: 0, per: Duration(seconds: 1)),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('later changes to the caller maps do not reach the interceptor', () {
      fakeAsync((async) {
        final hosts = <String, List<TokenBucketPolicy>>{};
        final interceptor = TokenBucketRateLimitInterceptor(
          config: _config,
          hosts: hosts,
        );
        hosts['a.test'] = const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ];
        final log = _Log();

        _send(interceptor, log, times: 3);

        expect(log.forwarded, hasLength(3));
        expect(
          () => interceptor.getStatistics().waitingByHost['x'] = 1,
          throwsUnsupportedError,
        );
      });
    });
  });

  test('host tiers and global tiers apply together', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 2, per: Duration(minutes: 1), burst: 2),
        ],
        global: const [
          TokenBucketPolicy(permits: 3, per: Duration(minutes: 1), burst: 3),
        ],
      );
      final log = _Log();

      _send(interceptor, log, times: 3);
      _send(interceptor, log, url: 'https://b.test/items', times: 2);
      async.flushMicrotasks();

      expect(log.forwarded.where((o) => o.uri.host == 'a.test'), hasLength(2));
      expect(log.forwarded.where((o) => o.uri.host == 'b.test'), hasLength(1));
      final stats = interceptor.getStatistics();
      expect(stats.waitingByHost, {'a.test': 1, 'b.test': 0});
      expect(stats.globalWaiting, 1);
      interceptor.dispose();
    });
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart`
Expected: compile errors, `maxPause`, `heldByHost`, and `pausedUntilByHost` are not defined.

- [ ] **Step 3: Replace the interceptor**

Replace the whole content of `dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart` with:

```dart
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart';
import 'package:dart_faltool/dart_faltool.dart'
    show
        RateLimitExceededException,
        RateLimiter,
        ResiliencePipeline,
        TokenBucketPolicy,
        immutable;
import 'package:dio/dio.dart';

/// Activity counters of a [TokenBucketRateLimitInterceptor].
@immutable
class TokenBucketRateLimitStatistics {
  /// Creates a statistics snapshot.
  const new({
    required this.forwarded,
    required this.rejected,
    required this.waitingByHost,
    required this.globalWaiting,
    required this.heldByHost,
    required this.pausedUntilByHost,
  });

  /// Requests passed to the next handler since construction. A request
  /// cancelled before it was forwarded is not counted.
  final int forwarded;

  /// Requests rejected with a local 429 since construction, for a full
  /// queue or a paused host.
  final int rejected;

  /// Requests waiting in each host's own tiers, keyed by host.
  final Map<String, int> waitingByHost;

  /// Requests waiting in the global tiers.
  final int globalWaiting;

  /// Requests held by a pause, keyed by host.
  final Map<String, int> heldByHost;

  /// End time of each active pause, keyed by host.
  final Map<String, DateTime> pausedUntilByHost;
}

/// Limits outgoing requests with token buckets built on `resilience`, and
/// pauses a host after it answers 429, or 503 with `Retry-After`.
///
/// Every request passes all tiers of its host, then all `global` tiers.
/// A host's tiers come from `hosts[host]` when that key exists, otherwise
/// from `perHost`. A scope with no policy has no token limit: a request to
/// a host whose tiers and the global tiers are all empty is forwarded
/// synchronously and creates no limiter, unless the host is paused.
///
/// Each [TokenBucketPolicy] guarantees at most `permits` requests in any
/// window of `per`. Refills are driven by `Timer`, not by reading the
/// clock: `fakeAsync`'s `elapse` advances them, and
/// `withClock(Clock.fixed(...))` has no effect on them.
///
/// A 429 pauses its host for its `Retry-After`, else for `defaultPause`;
/// a 503 pauses only for its `Retry-After`. Every pause is clamped to
/// `maxPause`, and applies to hosts without a policy too. While a host is
/// paused, a request waits when the remaining pause is at most
/// `maxPauseWait`, `queueRequests` is true, and fewer than `maxQueueSize`
/// requests already wait; otherwise it fails with a local 429. A request
/// that gets its tokens while its host is paused spends them and waits
/// again, so the ceiling also holds after a pause. This class contains
/// everything `RetryAfterPauseInterceptor` does; do not add both.
///
/// A local 429, for a full queue or a paused host, has type
/// `DioExceptionType.badResponse`, answers `isLocalRateLimit`, and goes
/// through every error interceptor, so callers get the same
/// `NetworkLimitExceededException` as for a server 429. Place this
/// interceptor before `RetryInterceptor` and before the network exception
/// handler.
///
/// Tokens are never returned. When a later tier rejects a request, tokens
/// already taken by earlier tiers stay spent. A request cancelled through
/// its `CancelToken` while it waits for tokens keeps its queue place and
/// still spends a token, but it is neither forwarded nor counted.
///
/// Refill timers keep running until every bucket is full again. Call
/// [dispose] at the end of a `testWidgets` body (`addTearDown` runs after
/// Flutter's pending-timer check), before a CLI's `main` returns, or when a
/// scoped client is discarded. A long-lived app or server client needs no
/// call. On a server, build one interceptor per process: a new instance per
/// request starts with full buckets and limits nothing.
class TokenBucketRateLimitInterceptor extends Interceptor {
  /// Creates a token bucket rate limit interceptor.
  ///
  /// Each key of [hosts] must be a bare host exactly as `Uri.host` returns
  /// it: lowercase, with no port, brackets, or spaces.
  new({
    required this.config,
    List<TokenBucketPolicy> global = const [],
    List<TokenBucketPolicy> perHost = const [],
    Map<String, List<TokenBucketPolicy>> hosts = const {},
    this.queueRequests = true,
    this.maxQueueSize = 50,
    this.maxGlobalQueueSize = 500,
    Duration maxPauseWait = const Duration(seconds: 10),
    Duration maxPause = const Duration(minutes: 10),
    Duration? defaultPause = const Duration(seconds: 5),
  }) : _perHost = List.unmodifiable(perHost),
       _hosts = Map.unmodifiable({
         for (final entry in hosts.entries)
           entry.key: List<TokenBucketPolicy>.unmodifiable(entry.value),
       }),
       _globalLimiters = [
         for (final policy in global)
           policy.toRateLimiter(
             maxQueueLength: queueRequests ? maxGlobalQueueSize : 0,
           ),
       ],
       _pause = RetryAfterPause(
         maxPauseWait: maxPauseWait,
         maxPause: maxPause,
         defaultPause: defaultPause,
         maxHeld: maxQueueSize,
         holdRequests: queueRequests,
       ) {
    for (final host in hosts.keys) {
      if (!_isHostKey(host)) {
        throw ArgumentError.value(
          host,
          'hosts',
          'keys must be bare lowercase hosts, as Uri.host returns them',
        );
      }
    }
    for (final policy in [...perHost, ...hosts.values.expand((p) => p)]) {
      policy.validate();
    }
  }

  /// Configuration; `enableLogging` gates diagnostic prints.
  final HttpClientConfig config;

  /// Whether a request with no token, or to a briefly paused host, waits
  /// (`true`) or is rejected.
  final bool queueRequests;

  /// Wait-queue capacity of each host tier, and of each host's pause.
  final int maxQueueSize;

  /// Wait-queue capacity of each global tier.
  final int maxGlobalQueueSize;

  final List<TokenBucketPolicy> _perHost;
  final Map<String, List<TokenBucketPolicy>> _hosts;
  final List<RateLimiter> _globalLimiters;
  final RetryAfterPause _pause;
  final Map<String, List<RateLimiter>> _hostLimiters = {};
  final Map<String, ResiliencePipeline> _pipelines = {};
  int _forwarded = 0;
  int _rejected = 0;
  bool _disposed = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final host = options.uri.host;
    final hostPolicies = _hosts[host] ?? _perHost;
    final unlimited = hostPolicies.isEmpty && _globalLimiters.isEmpty;
    while (true) {
      final admission = _pause.admit(host);
      if (admission is PauseReject) {
        _rejected++;
        _log('Paused host $host rejected a request');
        handler.reject(
          localRateLimitRejection(options, retryAfter: admission.remaining),
          true,
        );
        return;
      }
      if (admission is PauseHold) {
        try {
          await _pause.wait(host, options.cancelToken);
        } on Object catch (error) {
          handler.reject(_cancelled(options, error, 'Request cancelled'));
          return;
        }
        continue;
      }
      if (unlimited) {
        _forwarded++;
        handler.next(options);
        return;
      }
      if (_disposed) {
        handler.reject(
          _cancelled(
            options,
            StateError('RateLimiter disposed'),
            'Rate limiter disposed',
          ),
        );
        return;
      }
      final pipeline = _pipelines.putIfAbsent(
        host,
        () => _buildPipeline(host, hostPolicies),
      );
      try {
        await pipeline.execute(() async {});
      } on RateLimitExceededException catch (error) {
        _rejected++;
        _log('Rate limit queue full for $host');
        handler.reject(localRateLimitRejection(options, error: error), true);
        return;
      } on Object catch (error) {
        // resilience fails waiting calls with a StateError once disposed.
        if (!_disposed) rethrow;
        handler.reject(_cancelled(options, error, 'Rate limiter disposed'));
        return;
      }
      final cancelToken = options.cancelToken;
      if (cancelToken != null && cancelToken.isCancelled) {
        handler.reject(
          _cancelled(options, cancelToken.cancelError, 'Request cancelled'),
        );
        return;
      }
      if (_pause.isPaused(host)) {
        // A 429 arrived while this request waited for tokens. The tokens
        // are spent; the request takes new ones after the pause.
        continue;
      }
      _forwarded++;
      handler.next(options);
      return;
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _pause.observe(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      _pause.observe(response);
    }
    handler.next(err);
  }

  /// Returns the current activity counters.
  TokenBucketRateLimitStatistics getStatistics() {
    int waiting(Iterable<RateLimiter> limiters) =>
        limiters.fold(0, (sum, limiter) => sum + limiter.queueLength);
    return TokenBucketRateLimitStatistics(
      forwarded: _forwarded,
      rejected: _rejected,
      waitingByHost: Map.unmodifiable({
        for (final entry in _hostLimiters.entries)
          entry.key: waiting(entry.value),
      }),
      globalWaiting: waiting(_globalLimiters),
      heldByHost: _pause.heldByHost,
      pausedUntilByHost: _pause.pausedUntilByHost,
    );
  }

  /// Stops every refill timer, cancels waiting and held requests, and
  /// forgets every pause.
  ///
  /// Afterwards, requests to a limited host are cancelled and requests to
  /// an unlimited host pass. Calling it again has no effect.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _pause.dispose();
    for (final limiter in [
      ..._globalLimiters,
      ..._hostLimiters.values.expand((limiters) => limiters),
    ]) {
      limiter.dispose();
    }
  }

  static bool _isHostKey(String key) {
    if (key.isEmpty) {
      return false;
    }
    try {
      return Uri(scheme: 'http', host: key).host == key;
    } on FormatException {
      return false;
    }
  }

  ResiliencePipeline _buildPipeline(
    String host,
    List<TokenBucketPolicy> policies,
  ) {
    final hostLimiters = [
      for (final policy in policies)
        policy.toRateLimiter(maxQueueLength: queueRequests ? maxQueueSize : 0),
    ];
    _hostLimiters[host] = hostLimiters;
    return ResiliencePipeline([...hostLimiters, ..._globalLimiters]);
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
      // Intentional logging for rate limit diagnostics.
      // ignore: avoid_print
      print('[TokenBucketRateLimitInterceptor] $message');
    }
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart && dart analyze --fatal-infos`
Expected: 27 tests pass, no issues.

- [ ] **Step 5: Prove the post-token check matters**

Temporarily change `if (_pause.isPaused(host)) {` to `if (false && _pause.isPaused(host)) {` and run
`dart test test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart -n "forwards nothing during a pause"`.
Expected: FAIL (forwards at 1 s and 2 s). Revert the change and rerun: PASS.

- [ ] **Step 6: Commit**

```bash
git add dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart
git commit -m "feat(dart_falconnect)!: pause TokenBucketRateLimitInterceptor on 429 and route local 429s through onError"
```

---

### Task 5: `RetryInterceptor` rewrite and `maxRetryDuration`

**Files:**
- Modify: `dart_falconnect/lib/engine/https/config/http_client_config.dart`
- Modify (replace whole file): `dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart`
- Create: `dart_falconnect/test/engine/https/interceptors/_scripted_adapter.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/retry_interceptor_test.dart`

**Interfaces:**
- Consumes: `retryAfter` (Task 1); `isLocalRateLimit` (Task 2).
- Produces: `HttpClientConfig.maxRetryDuration` (constructor, presets, `copyWith`); `typedef RetryCallback = void Function(DioException error, int attempt, Duration delay)`; `RetryInterceptor({required HttpClientConfig config, required Dio dio, RetryCallback? onRetry, Random? random})`; extensions `FalconRetryRequestOptionsExtensions` on `RequestOptions` (`disableRetry`, `retryAttempts`, `retryNonIdempotent`, read-only `retryAttempt`) and `FalconRetryOptionsExtensions` on `Options` (`disableRetry`, `retryAttempts`, `retryNonIdempotent`), declared in `retry_interceptor.dart` so the `extra` keys stay private. Test helpers `ScriptedAdapter`, `Reply`, `reply(status, {headers})`, `failWith(type)` for Task 6.

- [ ] **Step 1: Add the scripted adapter**

Create `dart_falconnect/test/engine/https/interceptors/_scripted_adapter.dart`:

```dart
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// One scripted server answer: a response body, or a thrown DioException.
typedef Reply = ResponseBody Function(RequestOptions options);

/// Answers with [status], optional headers, and a JSON body.
Reply reply(int status, {Map<String, String> headers = const {}}) =>
    (_) => ResponseBody.fromString(
      '{"status":$status}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final entry in headers.entries) entry.key: [entry.value],
      },
    );

/// Fails the request with a DioException of [type], as a network error.
Reply failWith(DioExceptionType type) =>
    (options) => throw DioException(requestOptions: options, type: type);

/// A fake transport that replays [script] in order and repeats its last
/// entry, recording every request it receives.
class ScriptedAdapter implements HttpClientAdapter {
  new(this.script);

  final List<Reply> script;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    requests.add(options);
    return script[min(requests.length, script.length) - 1](options);
  }

  @override
  void close({bool force = false}) {}
}
```

- [ ] **Step 2: Write the failing test**

Create `dart_falconnect/test/engine/https/interceptors/retry_interceptor_test.dart`:

```dart
import 'dart:async';
import 'dart:math';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

const _config = HttpClientConfig(
  maxRetryAttempts: 3,
  retryDelay: Duration(seconds: 1),
  maxRetryDelay: Duration(seconds: 30),
  maxRetryDuration: Duration(seconds: 60),
);

class _Client {
  new(List<Reply> script, {HttpClientConfig config = _config})
    : adapter = ScriptedAdapter(script) {
    dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      RetryInterceptor(
        config: config,
        dio: dio,
        random: Random(7),
        onRetry: (error, attempt, delay) => retries.add((attempt, delay)),
      ),
    );
  }

  final ScriptedAdapter adapter;
  late final Dio dio;
  final List<(int, Duration)> retries = [];
  Object? outcome;

  void send(Future<Response<dynamic>> Function(Dio dio) call) {
    unawaited(
      call(dio).then(
        (response) => outcome = response,
        onError: (Object error) => outcome = error,
      ),
    );
  }

  int get sent => adapter.requests.length;
}

void main() {
  test('retries a GET up to maxRetryAttempts, then fails', () {
    fakeAsync((async) {
      final client = _Client([reply(500)])..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 4);
      expect(client.retries.map((r) => r.$1), [1, 2, 3]);
      final error = client.outcome! as DioException;
      expect(error.response?.statusCode, 500);
      expect(error.requestOptions.retryAttempt, 3);
    });
  });

  test('returns the first successful retry', () {
    fakeAsync((async) {
      final client = _Client([reply(503), reply(200)])
        ..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 5));

      expect(client.sent, 2);
      expect((client.outcome! as Response<dynamic>).statusCode, 200);
    });
  });

  test('backoff uses full jitter under the exponential cap', () {
    fakeAsync((async) {
      final client = _Client(
        [reply(500)],
        config: _config.copyWith(maxRetryDelay: const Duration(seconds: 3)),
      )..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 30));

      final delays = client.retries.map((r) => r.$2).toList();
      expect(delays[0], lessThanOrEqualTo(const Duration(seconds: 1)));
      expect(delays[1], lessThanOrEqualTo(const Duration(seconds: 2)));
      expect(delays[2], lessThanOrEqualTo(const Duration(seconds: 3)));
    });
  });

  test('does not retry a POST after a 500', () {
    fakeAsync((async) {
      final client = _Client([reply(500), reply(200)])
        ..send((d) => d.post('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 1);
      expect(client.outcome, isA<DioException>());
    });
  });

  test('retries a POST after a 429 or a connection timeout', () {
    fakeAsync((async) {
      final client = _Client([
        reply(429, headers: {'retry-after': '1'}),
        failWith(DioExceptionType.connectionTimeout),
        reply(201),
      ])..send((d) => d.post('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 3);
      expect((client.outcome! as Response<dynamic>).statusCode, 201);
    });
  });

  test('retryNonIdempotent lets a POST retry after a 500', () {
    fakeAsync((async) {
      final client = _Client([reply(500), reply(200)])
        ..send(
          (d) => d.post('/x', options: Options()..retryNonIdempotent = true),
        );

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 2);
    });
  });

  test('waits exactly Retry-After when it fits maxRetryDelay', () {
    fakeAsync((async) {
      final client = _Client([
        reply(429, headers: {'retry-after': '3'}),
        reply(200),
      ])..send((d) => d.get('/x'));

      async.elapse(const Duration(milliseconds: 2999));
      expect(client.sent, 1);
      async.elapse(const Duration(milliseconds: 1));
      expect(client.sent, 2);
    });
  });

  test('does not retry when Retry-After exceeds maxRetryDelay', () {
    fakeAsync((async) {
      final client = _Client([
        reply(503, headers: {'retry-after': '31'}),
        reply(200),
      ])..send((d) => d.get('/x'));

      async.elapse(const Duration(minutes: 1));

      expect(client.sent, 1);
      expect(client.retries, isEmpty);
    });
  });

  test('stops before a retry would end past maxRetryDuration', () {
    fakeAsync((async) {
      final client = _Client(
        [
          reply(429, headers: {'retry-after': '1'}),
        ],
        config: _config.copyWith(maxRetryDuration: const Duration(seconds: 2)),
      )..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 3);
    });
  });

  test('a cancel during the wait stops at once', () {
    fakeAsync((async) {
      final token = CancelToken();
      final client = _Client([
        reply(429, headers: {'retry-after': '5'}),
        reply(200),
      ])..send((d) => d.get('/x', cancelToken: token));
      async.elapse(const Duration(milliseconds: 10));
      expect(client.retries, hasLength(1));

      token.cancel('user left');
      async.elapse(const Duration(milliseconds: 1));

      expect((client.outcome! as DioException).type, DioExceptionType.cancel);
      expect(async.pendingTimers, isEmpty);
      expect(client.sent, 1);
    });
  });

  test('never retries a Stream body or a bad certificate', () {
    fakeAsync((async) {
      final stream = _Client([reply(500), reply(200)])
        ..send(
          (d) => d.put(
            '/x',
            data: Stream.value([1, 2, 3]),
            options: Options(headers: {Headers.contentLengthHeader: 3}),
          ),
        );
      final certificate = _Client([
        failWith(DioExceptionType.badCertificate),
        reply(200),
      ])..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(stream.sent, 1);
      expect(certificate.sent, 1);
    });
  });

  test('clones FormData for every retry', () {
    fakeAsync((async) {
      final client = _Client([reply(500), reply(200)])
        ..send(
          (d) => d.put(
            '/x',
            data: FormData.fromMap({'file': MultipartFile.fromString('abc')}),
          ),
        );

      async.elapse(const Duration(seconds: 30));

      expect((client.outcome! as Response<dynamic>).statusCode, 200);
      final first = client.adapter.requests[0].data;
      final second = client.adapter.requests[1].data;
      expect(second, isA<FormData>());
      expect(identical(first, second), isFalse);
    });
  });

  test('keeps responseType plain across a retry (upstream issue #49)', () {
    fakeAsync((async) {
      final client = _Client([reply(500), reply(200)])
        ..send((d) => d.get<String>('/x'));

      async.elapse(const Duration(seconds: 30));

      final response = client.outcome! as Response<dynamic>;
      expect(response.data, '{"status":200}');
      expect(client.adapter.requests[1].responseType, ResponseType.plain);
    });
  });

  test('per-request disableRetry and retryAttempts', () {
    fakeAsync((async) {
      final disabled = _Client([reply(500)])
        ..send((d) => d.get('/x', options: Options()..disableRetry = true));
      final once = _Client([reply(500)])
        ..send((d) => d.get('/x', options: Options()..retryAttempts = 1));

      async.elapse(const Duration(seconds: 30));

      expect(disabled.sent, 1);
      expect(once.sent, 2);
    });
  });

  test('per-request setters copy a const extra map', () {
    final options = Options(extra: const {'k': 1})
      ..disableRetry = true
      ..retryAttempts = 2;
    expect(options.extra?['k'], 1);
    expect(options.disableRetry, isTrue);
    expect(options.retryAttempts, 2);
    expect(() => options.retryAttempts = -1, throwsArgumentError);
  });

  test('HttpClientConfig.test() never retries', () {
    fakeAsync((async) {
      final client = _Client([reply(503)], config: HttpClientConfig.test())
        ..send((d) => d.get('/x'));

      async.elapse(const Duration(seconds: 30));

      expect(client.sent, 1);
    });
  });
}
```

- [ ] **Step 3: Run it to verify it fails**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/retry_interceptor_test.dart`
Expected: compile errors (`maxRetryDuration`, `retryAttempt`, `onRetry`, `random` are not defined).

- [ ] **Step 4: Add `maxRetryDuration` to `HttpClientConfig`**

In `dart_falconnect/lib/engine/https/config/http_client_config.dart`:

- Constructor: after `this.maxRetryDelay = const Duration(seconds: 30),` add `this.maxRetryDuration = const Duration(seconds: 60),`.
- `production()`: after `maxRetryDelay: Duration(minutes: 1),` add `maxRetryDuration: Duration(minutes: 2),`.
- `development()`: after `maxRetryDelay: Duration(seconds: 5),` add `maxRetryDuration: Duration(seconds: 10),`.
- `test()`: after `maxRetryDelay: Duration(seconds: 1),` add `maxRetryDuration: Duration(seconds: 5),`.
- After the `maxRetryDelay` field add:

```dart

  /// Most time spent retrying one request, measured from its first
  /// failure. A retry whose delay would end past it is not sent.
  final Duration maxRetryDuration;
```

- `copyWith`: add the parameter `Duration? maxRetryDuration,` after `Duration? maxRetryDelay,`, and the argument `maxRetryDuration: maxRetryDuration ?? this.maxRetryDuration,` after `maxRetryDelay: maxRetryDelay ?? this.maxRetryDelay,`.

- [ ] **Step 5: Replace the interceptor**

Replace the whole content of `dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart` with:

```dart
import 'dart:async';
import 'dart:math';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falmodel/networks/https/retry_after.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:dio/dio.dart';

const String _disableKey = 'dart_falconnect.retry.disable';
const String _attemptsKey = 'dart_falconnect.retry.attempts';
const String _nonIdempotentKey = 'dart_falconnect.retry.nonIdempotent';
const String _attemptKey = 'dart_falconnect.retry.attempt';

/// Called before each retry waits.
///
/// [attempt] is 1 for the first retry. The stack trace of the failure is
/// `error.stackTrace`.
typedef RetryCallback = void Function(
  DioException error,
  int attempt,
  Duration delay,
);

/// Per-request retry settings on [RequestOptions].
extension FalconRetryRequestOptionsExtensions on RequestOptions {
  /// Whether [RetryInterceptor] leaves this request alone.
  bool get disableRetry => extra[_disableKey] == true;
  set disableRetry(bool value) => extra = {...extra, _disableKey: value};

  /// Most retries for this request; null uses
  /// `HttpClientConfig.maxRetryAttempts`.
  int? get retryAttempts => extra[_attemptsKey] as int?;
  set retryAttempts(int? value) =>
      extra = {...extra, _attemptsKey: _checkAttempts(value)};

  /// Whether a `POST` or `PATCH` may be retried in the cases limited to
  /// idempotent methods.
  bool get retryNonIdempotent => extra[_nonIdempotentKey] == true;
  set retryNonIdempotent(bool value) =>
      extra = {...extra, _nonIdempotentKey: value};

  /// 0 for the original request, 1 for the first retry, and so on.
  int get retryAttempt => (extra[_attemptKey] as int?) ?? 0;
}

/// Per-request retry settings on [Options].
extension FalconRetryOptionsExtensions on Options {
  /// Whether [RetryInterceptor] leaves this request alone.
  bool get disableRetry => extra?[_disableKey] == true;
  set disableRetry(bool value) => extra = {...?extra, _disableKey: value};

  /// Most retries for this request; null uses
  /// `HttpClientConfig.maxRetryAttempts`.
  int? get retryAttempts => extra?[_attemptsKey] as int?;
  set retryAttempts(int? value) =>
      extra = {...?extra, _attemptsKey: _checkAttempts(value)};

  /// Whether a `POST` or `PATCH` may be retried in the cases limited to
  /// idempotent methods.
  bool get retryNonIdempotent => extra?[_nonIdempotentKey] == true;
  set retryNonIdempotent(bool value) =>
      extra = {...?extra, _nonIdempotentKey: value};
}

int? _checkAttempts(int? value) {
  if (value != null && value < 0) {
    throw ArgumentError.value(value, 'retryAttempts', 'must not be negative');
  }
  return value;
}

/// Retries failed requests with backoff, honouring `Retry-After`.
///
/// Every attempt is sent with `dio.fetch`, so it passes the whole
/// interceptor chain again: a rate limiter placed before this interceptor
/// holds retries to a paused host, and the total wait is the longer of the
/// retry delay and the pause, never their sum.
///
/// A 429 or a `connectionTimeout` is retried for every method, because the
/// server did not act on the request. Timeouts, connection errors, 408,
/// 409, and 5xx are retried only for `GET`, `HEAD`, `OPTIONS`, `PUT`,
/// `DELETE`, and `TRACE`, unless the request sets `retryNonIdempotent`. A
/// cancelled request, a local 429, a `Stream` body, and a bad certificate
/// are never retried.
///
/// A 429 or 503 with `Retry-After` waits that long, and is not retried when
/// it exceeds `maxRetryDelay`. Other failures wait a random time between
/// zero and `min(maxRetryDelay, retryDelay * 2^(attempt - 1))`. No retry is
/// sent when its delay would end past `maxRetryDuration`.
///
/// Error interceptors after this one see the error of every attempt; read
/// `requestOptions.retryAttempt` to tell them apart.
class RetryInterceptor extends Interceptor {
  /// Creates a retry interceptor.
  ///
  /// [random] drives the backoff jitter; tests pass a seeded one.
  new({required this.config, required this.dio, this.onRetry, Random? random})
    : _random = random ?? Random();

  /// Configuration: `maxRetryAttempts`, `retryDelay`, `maxRetryDelay`,
  /// `maxRetryDuration`, and `enableLogging`.
  final HttpClientConfig config;

  /// The [Dio] instance that sends every retry.
  final Dio dio;

  /// Called before each retry waits.
  final RetryCallback? onRetry;

  final Random _random;

  static const Set<String> _idempotentMethods = {
    'GET',
    'HEAD',
    'OPTIONS',
    'PUT',
    'DELETE',
    'TRACE',
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final original = err.requestOptions;
    if (original.retryAttempt > 0) {
      // A nested attempt: the loop that sent it decides what comes next.
      handler.next(err);
      return;
    }
    final started = clock.now();
    var current = err;
    for (var attempt = 1; ; attempt++) {
      final delay = _delayFor(
        current,
        attempt,
        clock.now().difference(started),
      );
      if (delay == null) {
        handler.next(current);
        return;
      }
      onRetry?.call(current, attempt, delay);
      _log(
        'Retrying request $attempt after ${delay.inMilliseconds}ms: '
        '${original.method} ${original.uri}',
      );
      if (!await _wait(delay, original.cancelToken)) {
        handler.next(current);
        return;
      }
      final RequestOptions options;
      try {
        options = _attemptOptions(original, attempt);
      } on Object {
        // A FormData whose files cannot be read again.
        handler.next(current);
        return;
      }
      try {
        // dynamic keeps the caller's responseType; any other type argument
        // makes dio overwrite it.
        final response = await dio.fetch<dynamic>(options);
        handler.resolve(response);
        return;
      } on DioException catch (error) {
        current = error;
      }
    }
  }

  /// Returns the wait before retry number [attempt], or null to stop.
  Duration? _delayFor(DioException err, int attempt, Duration elapsed) {
    if (!_isRetryable(err, attempt)) {
      return null;
    }
    final status = err.response?.statusCode;
    final retryAfter = status == 429 || status == 503
        ? err.response?.headers.retryAfter
        : null;
    final Duration delay;
    if (retryAfter != null) {
      if (retryAfter > config.maxRetryDelay) {
        return null;
      }
      delay = retryAfter;
    } else {
      delay = _backoff(attempt);
    }
    if (elapsed + delay > config.maxRetryDuration) {
      return null;
    }
    return delay;
  }

  bool _isRetryable(DioException err, int attempt) {
    final options = err.requestOptions;
    final response = err.response;
    if (options.disableRetry ||
        err.type == DioExceptionType.cancel ||
        (options.cancelToken?.isCancelled ?? false) ||
        (response?.isLocalRateLimit ?? false) ||
        options.data is Stream ||
        err.type == DioExceptionType.badCertificate) {
      return false;
    }
    if (attempt > (options.retryAttempts ?? config.maxRetryAttempts)) {
      return false;
    }
    final status = response?.statusCode;
    if (status == 429 || err.type == DioExceptionType.connectionTimeout) {
      return true;
    }
    final transient =
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        status == 408 ||
        status == 409 ||
        (status != null && status >= 500 && status < 600);
    return transient &&
        (_idempotentMethods.contains(options.method.toUpperCase()) ||
            options.retryNonIdempotent);
  }

  Duration _backoff(int attempt) {
    final exponential = config.retryDelay.inMilliseconds * pow(2, attempt - 1);
    final cap = min(config.maxRetryDelay.inMilliseconds, exponential).toInt();
    return Duration(milliseconds: _random.nextInt(cap + 1));
  }

  /// Waits [delay]; returns false at once when [cancelToken] cancels.
  Future<bool> _wait(Duration delay, CancelToken? cancelToken) {
    if (cancelToken?.isCancelled ?? false) {
      return Future.value(false);
    }
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
  }

  RequestOptions _attemptOptions(RequestOptions original, int attempt) {
    final data = original.data;
    return original.copyWith(
      data: data is FormData ? data.clone() : data,
      extra: {...original.extra, _attemptKey: attempt},
    );
  }

  void _log(String message) {
    if (config.enableLogging) {
      // Intentional logging for retry diagnostics.
      // ignore: avoid_print
      print('[RetryInterceptor] $message');
    }
  }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/retry_interceptor_test.dart && dart analyze --fatal-infos`
Expected: 16 tests pass, no issues.

- [ ] **Step 7: Prove the type argument matters**

Temporarily change `dio.fetch<dynamic>(options)` to `dio.fetch<void>(options)` and run
`dart test test/engine/https/interceptors/retry_interceptor_test.dart -n "responseType plain"`.
Expected: FAIL. Revert and rerun: PASS.

- [ ] **Step 8: Commit**

```bash
git add dart_falconnect/lib/engine/https/config/http_client_config.dart dart_falconnect/lib/engine/https/interceptors/retry_interceptor.dart dart_falconnect/test/engine/https/interceptors/_scripted_adapter.dart dart_falconnect/test/engine/https/interceptors/retry_interceptor_test.dart
git commit -m "feat(dart_falconnect)!: rewrite RetryInterceptor with idempotency, capped Retry-After, and a total deadline"
```

---

### Task 6: Chain integration test and web gates

**Files:**
- Test: `dart_falconnect/test/engine/https/interceptors/rate_limit_retry_chain_test.dart`
- Modify: `dart_falconnect/test/web/compile_smoke.dart`
- Modify: `dart_falconnect/test/web/engine_web_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1 to 5; `ScriptedAdapter`, `reply` (Task 5).
- Produces: nothing new.

- [ ] **Step 1: Write the chain test**

Create `dart_falconnect/test/engine/https/interceptors/rate_limit_retry_chain_test.dart`:

```dart
import 'dart:async';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

const _config = HttpClientConfig(
  maxRetryAttempts: 3,
  retryDelay: Duration(seconds: 1),
  maxRetryDelay: Duration(seconds: 30),
  maxRetryDuration: Duration(seconds: 60),
);

/// The order the documentation prescribes: rate limiter, retry, exception
/// handler.
Dio _chain(ScriptedAdapter adapter, TokenBucketRateLimitInterceptor limiter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll([
    limiter,
    RetryInterceptor(config: _config, dio: dio),
    DefaultNetworkExceptionHandlerInterceptor(),
  ]);
  return dio;
}

void main() {
  test('a retry waits for Retry-After once, not twice', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        reply(429, headers: {'retry-after': '3'}),
        reply(200),
      ]);
      final limiter = TokenBucketRateLimitInterceptor(config: _config);
      final dio = _chain(adapter, limiter);
      final sentAt = <Duration>[];
      Object? outcome;

      unawaited(
        dio
            .get<dynamic>('/x')
            .then((r) => outcome = r, onError: (Object e) => outcome = e),
      );
      // Record when each request reaches the adapter.
      var seen = 0;
      for (var ms = 0; ms <= 7000; ms += 100) {
        async.elapse(const Duration(milliseconds: 100));
        while (seen < adapter.requests.length) {
          seen++;
          sentAt.add(async.elapsed);
        }
      }

      expect((outcome! as Response<dynamic>).statusCode, 200);
      expect(adapter.requests, hasLength(2));
      expect(sentAt[1], lessThanOrEqualTo(const Duration(milliseconds: 3100)));
      limiter.dispose();
    });
  });

  test('a request sent during the pause is held, then sent', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        reply(429, headers: {'retry-after': '3'}),
        reply(200),
      ]);
      final limiter = TokenBucketRateLimitInterceptor(config: _config);
      final dio = _chain(adapter, limiter);

      unawaited(dio.get<dynamic>('/x').then((_) {}, onError: (_) {}));
      async.elapse(const Duration(seconds: 1));
      Object? second;
      unawaited(
        dio
            .get<dynamic>('/y')
            .then((r) => second = r, onError: (Object e) => second = e),
      );
      async.elapse(const Duration(milliseconds: 1900));
      expect(adapter.requests, hasLength(1));

      async.elapse(const Duration(seconds: 2));
      expect((second! as Response<dynamic>).statusCode, 200);
      limiter.dispose();
    });
  });

  test('a local 429 reaches the caller as NetworkLimitExceededException', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([reply(200)]);
      final limiter = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
        queueRequests: false,
      );
      final dio = _chain(adapter, limiter);
      final outcomes = <Object>[];

      for (var i = 0; i < 2; i++) {
        unawaited(
          dio.get<dynamic>('/x').then(outcomes.add, onError: outcomes.add),
        );
      }
      async.elapse(const Duration(seconds: 1));

      expect(adapter.requests, hasLength(1));
      final error = outcomes.whereType<DioException>().single;
      expect(error.error, isA<NetworkLimitExceededException>());
      expect(error.response?.isLocalRateLimit, isTrue);
      limiter.dispose();
    });
  });

  test('a 429 on a retry extends the pause for other requests', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        reply(429, headers: {'retry-after': '2'}),
        reply(429, headers: {'retry-after': '2'}),
        reply(200),
      ]);
      final limiter = TokenBucketRateLimitInterceptor(config: _config);
      final dio = _chain(adapter, limiter);

      unawaited(dio.get<dynamic>('/x').then((_) {}, onError: (_) {}));
      async.elapse(const Duration(milliseconds: 2500));
      unawaited(dio.get<dynamic>('/y').then((_) {}, onError: (_) {}));

      async.elapse(const Duration(milliseconds: 1400));
      expect(adapter.requests, hasLength(2), reason: 'held until 4 s');
      async.elapse(const Duration(milliseconds: 200));
      expect(adapter.requests, hasLength(4));
      limiter.dispose();
    });
  });

  test('with validateStatus below 500 a 429 reaches the caller as a '
      'response and still pauses the host', () {
    fakeAsync((async) {
      final adapter = ScriptedAdapter([
        reply(429, headers: {'retry-after': '2'}),
        reply(200),
      ]);
      final limiter = TokenBucketRateLimitInterceptor(config: _config);
      final dio = _chain(adapter, limiter)
        ..options.validateStatus = (status) => status != null && status < 500;
      final outcomes = <Object>[];

      unawaited(dio.get<dynamic>('/x').then(outcomes.add));
      async.elapse(const Duration(milliseconds: 10));
      unawaited(dio.get<dynamic>('/y').then(outcomes.add));
      async.elapse(const Duration(seconds: 1));

      expect((outcomes.single as Response<dynamic>).statusCode, 429);
      expect(adapter.requests, hasLength(1));
      async.elapse(const Duration(seconds: 1));
      expect(adapter.requests, hasLength(2));
      limiter.dispose();
    });
  });
}
```

- [ ] **Step 2: Run it**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/rate_limit_retry_chain_test.dart`
Expected: 5 tests pass. A failure here means an earlier task diverged from this plan; fix the task, not the test.

- [ ] **Step 3: Extend the web gates**

In `dart_falconnect/test/web/compile_smoke.dart`, add after `  _sink(TokenBucketRateLimitInterceptor(config: cfg));`:

```dart
  _sink(RetryAfterPauseInterceptor(config: cfg));
```

In `dart_falconnect/test/web/engine_web_test.dart`, add after the `http_client_config.dart` import:

```dart
import 'package:dart_falmodel/dart_falmodel.dart' show parseRetryAfter;
```

add after `      expect(TokenBucketRateLimitInterceptor(config: cfg), isNotNull);`:

```dart
      expect(RetryAfterPauseInterceptor(config: cfg), isNotNull);
```

and add before `    test('DefaultJsonRpcService builds on web', () {`:

```dart
    test('parseRetryAfter reads an HTTP-date on web', () {
      expect(
        parseRetryAfter(
          'Wed, 21 Oct 2026 07:28:30 GMT',
          serverDate: DateTime.utc(2026, 10, 21, 7, 28),
        ),
        const Duration(seconds: 30),
      );
    });

```

- [ ] **Step 4: Run the web gates**

Run from `dart_falconnect`:

```bash
dart analyze --fatal-infos test/web
dart compile js -o /tmp/sp2_smoke.js test/web/compile_smoke.dart
dart test -p chrome test/web/engine_web_test.dart
```

Expected: no issues; compile exits 0; 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add dart_falconnect/test/engine/https/interceptors/rate_limit_retry_chain_test.dart dart_falconnect/test/web/compile_smoke.dart dart_falconnect/test/web/engine_web_test.dart
git commit -m "test(dart_falconnect): cover the rate limit and retry chain and the SP2 web gates"
```

---

### Task 7: Documentation and the consumer skill

**Files:**
- Modify: `skills/dart-falconx-package/SKILL.md` (capability map rows "Interceptors" and "Third-party libs")
- Modify: `skills/dart-falconx-package/references/http.md` (interceptor catalog, `HttpClientConfig` paragraph, "Rate limiting", "Helpers")
- Modify: `skills/dart-falconx-package/references/errors.md:53`
- Modify: `skills/dart-falconx-package/references/models.md` ("Responses")
- Modify: `CLAUDE.md` (third-party "Networking" table)
- Modify: `dart_falconnect/CLAUDE.md` ("HTTP Interceptor Chain", "Gotchas")
- Modify: `_bmad-output/project-context.md:214-216`

**Interfaces:**
- Consumes: the public API from Tasks 1 to 5.
- Produces: documentation only.

The repository keeps Markdown tables aligned: after editing a row, re-pad every row of that table so each column has one width.

- [ ] **Step 1: `SKILL.md`**

In the capability map, row `Interceptors`: insert `` `RetryAfterPauseInterceptor`, `` after `` `TokenBucketRateLimitInterceptor`, ``.
Row `Third-party libs, free with the umbrella import`: replace `` `resilience` (without `Retry`, `Timeout`) `` with `` `resilience` (without `Retry`, `RetryEvent`, `Timeout`) ``.

- [ ] **Step 2: `references/http.md`, interceptor catalog**

Replace the `RetryInterceptor` row's Constructor and Behaviour cells with:

- Constructor: `` `(config:, dio:, onRetry:, random:)` ``
- Behaviour: `` loops up to `retryAttempts ?? config.maxRetryAttempts`; 429 and `connectionTimeout` for every method; timeouts, connection errors, 408/409/5xx only for idempotent methods unless `retryNonIdempotent`; `Retry-After` on 429/503 (not retried above `maxRetryDelay`), else full jitter; stops at `config.maxRetryDuration`; never retries cancels, local 429s, `Stream` bodies, bad certificates ``

Replace the `TokenBucketRateLimitInterceptor` row with:

- Constructor: `` `(config:, global: [], perHost: [], hosts: {}, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500, maxPauseWait: 10 s, maxPause: 10 min, defaultPause: 5 s)` ``
- Behaviour: `` token buckets from `TokenBucketPolicy` lists; no policy means no token limit; pauses a host on 429, or 503 with `Retry-After`; full queue or long pause → local 429 through the error chain; `getStatistics()`, `dispose()`; do not add `RetryAfterPauseInterceptor` next to it ``

Add a row after it:

- Class: `` `RetryAfterPauseInterceptor` ``
- Constructor: `` `(config:, maxPauseWait: 10 s, maxPause: 10 min, defaultPause: 5 s, maxQueueSize: 50)` ``
- Behaviour: `` the pause of `TokenBucketRateLimitInterceptor` without token limits; `dispose()` ``

- [ ] **Step 3: `references/http.md`, `HttpClientConfig` paragraph and interceptor order**

At the end of the `HttpClientConfig` paragraph, append: `` Retry fields: `maxRetryAttempts`, `retryDelay`, `maxRetryDelay`, `maxRetryDuration`. Because `applyTo` accepts every status below 500, a 429 reaches the caller as a normal response and `RetryInterceptor` never sees it; the rate limiter still pauses the host. ``

Insert a new section after that paragraph:

````markdown
## Interceptor order

```dart
interceptors.addAll([
  TokenBucketRateLimitInterceptor(config: config), // or RetryAfterPauseInterceptor, never both
  RetryInterceptor(config: config, dio: dio),
  DefaultNetworkExceptionHandlerInterceptor(),
]);
```

- The rate limiter comes before `RetryInterceptor`: dio runs `onError` in list order, so the limiter sees a server 429 and starts the pause before the retry is sent. The retry then passes the pause gate, and the total wait is the longer of the retry delay and the pause, never their sum.
- `DefaultNetworkExceptionHandlerInterceptor` comes last: it rejects without calling later error interceptors.
- Every retry passes the whole chain again, so logging and error interceptors see each attempt; `requestOptions.retryAttempt` tells them apart.
````

- [ ] **Step 4: `references/http.md`, rate limiting**

Replace the sentence `` `hosts` keys must be lowercase. `` with `` `hosts` keys must be bare hosts exactly as `Uri.host` returns them: lowercase, with no port, brackets, or spaces (`::1` is valid). ``

Replace the paragraph that starts `Tokens are never returned.` with:

```markdown
Tokens are never returned. When a later tier's full queue rejects a request, tokens already taken by earlier tiers stay spent. A request cancelled with a `CancelToken` while it waits for tokens keeps its queue place and still spends a token when it reaches the front; it is neither forwarded nor counted in `getStatistics().forwarded`. For screens that cancel queued requests often, keep `maxQueueSize` small or set `queueRequests: false`.

### Pause on 429 and 503

A 429 pauses its host for its `Retry-After` (seconds or HTTP-date), else for `defaultPause`; a 503 pauses only when it carries `Retry-After`. Every pause is clamped to `maxPause`, never shortens an earlier one, and applies to hosts without a policy too. While a host is paused, a request waits when the remaining pause is at most `maxPauseWait` and fewer than `maxQueueSize` requests already wait; otherwise it fails at once with a local 429 carrying `Retry-After`. A request that gets its tokens during a pause spends them and waits again, so the ceiling also holds after the pause.

A local 429 (full queue or long pause) has type `DioExceptionType.badResponse` and goes through every error interceptor, so callers get `NetworkLimitExceededException` for local and server 429s alike. `response.isLocalRateLimit` tells them apart, for example to keep them out of crash reports.

Use `RetryAfterPauseInterceptor` for the pause alone. `TokenBucketRateLimitInterceptor` already contains it; a chain with the token bucket must not add `RetryAfterPauseInterceptor`.
```

- [ ] **Step 5: `references/http.md`, retry section and migration**

Insert before `## Helpers`:

````markdown
## Retry

```dart
await dio.post<dynamic>(
  '/payments',
  options: Options()
    ..retryNonIdempotent = true // allow retries of this POST after 5xx and timeouts
    ..retryAttempts = 5,        // overrides config.maxRetryAttempts
);
await dio.get<dynamic>('/live', options: Options()..disableRetry = true);
```

`onRetry: (error, attempt, delay) {...}` runs before each wait; `error.stackTrace` holds the failure's stack trace.

### Migrating `RetryInterceptor` from 1.x

- `POST` and `PATCH` are no longer retried after a 5xx, a timeout other than `connectionTimeout`, or a connection error, unless `retryNonIdempotent` is set.
- A `Retry-After` longer than `maxRetryDelay` ends retrying instead of waiting.
- Retries reach `maxRetryAttempts`; 1.x ran at most one retry.
- `extra['retryCount']` and `extra['isRetry']` are gone; read `requestOptions.retryAttempt`.
- The delay is full jitter, a random time up to the exponential cap, instead of the cap plus up to one second.
````

In `## Helpers`, add a bullet:

```markdown
- `headers.retryAfter` and `parseRetryAfter(value, serverDate:)` (from `dart_falmodel`) read `Retry-After` as seconds or HTTP-date; `response.isLocalRateLimit` marks a client-side 429.
```

- [ ] **Step 6: `errors.md`, `models.md`, root `CLAUDE.md`**

`references/errors.md` line 53: replace `` `recommendedRetryDelay` (honours `Retry-After`) `` with `` `recommendedRetryDelay` (honours `Retry-After` as seconds or HTTP-date) ``.

`references/models.md`, section `## Responses`, add a bullet:

```markdown
- `parseRetryAfter(String? value, {DateTime? serverDate})` returns the `Retry-After` delay (delay-seconds or any HTTP-date; past dates give zero; unreadable values give null); `Headers.retryAfter` measures an HTTP-date from the response's `Date` header.
```

Root `CLAUDE.md`, table under `### Networking`, add after the `json_annotation` row:

```markdown
| `http_parser`                           | `parseHttpDate` for HTTP-date `Retry-After` values (`dart_falmodel`) |
```

- [ ] **Step 7: `dart_falconnect/CLAUDE.md` and `_bmad-output/project-context.md`**

In `dart_falconnect/CLAUDE.md`, section `### HTTP Interceptor Chain`: change `Seven interceptors` to `Eight interceptors`; replace item 2 with `` 2. `RetryInterceptor` — Loop up to `maxRetryAttempts`; idempotent-only for 5xx/408/409/timeouts (429 and `connectionTimeout` for every method); `Retry-After` capped by `maxRetryDelay`; total `maxRetryDuration`; per-request `disableRetry`, `retryAttempts`, `retryNonIdempotent` ``; replace item 6 with `` 6. `TokenBucketRateLimitInterceptor` — Token buckets from `TokenBucketPolicy` lists plus a per-host pause on 429/503 `Retry-After`; unlimited when no policy is set ``; insert before the `LogInterceptor` item `` 7. `RetryAfterPauseInterceptor` — The pause alone; never add it next to `TokenBucketRateLimitInterceptor` `` and renumber `LogInterceptor` to 8. After the list add: `` Order: rate limiter → `RetryInterceptor` → exception handler. The pause core lives in `lib/src/engine/https/interceptors/retry_after_pause.dart` (not exported). ``

In `## Gotchas`, replace `` `test/unit_test.dart` is a stub with an empty test; the real tests are the web verification gates under `test/web/` `` with `` Interceptor tests live in `test/engine/https/interceptors/` (run under `fakeAsync`); `test/unit_test.dart` is an empty stub; the web gates are under `test/web/` ``.

In `_bmad-output/project-context.md`, delete line 214 (`` `RateLimiter` in dart_falconnect `utils/` is a placeholder ... ``) and replace line 216 with `` - `dart_falconnect` has real interceptor tests under `test/engine/https/interceptors/`; `test/unit_test.dart` is an empty stub ``.

- [ ] **Step 8: Check and commit**

Run: `grep -n "RetryEvent" skills/dart-falconx-package/SKILL.md && grep -c "RetryAfterPauseInterceptor" skills/dart-falconx-package/references/http.md`
Expected: one `SKILL.md` match; at least 4 matches in `http.md`.

```bash
git add skills/dart-falconx-package CLAUDE.md dart_falconnect/CLAUDE.md _bmad-output/project-context.md
git commit -m "docs: document the 429 pause, the retry rewrite, and the interceptor order"
```

---

### Task 8: Final verification

**Files:** none changed unless a gate fails.

- [ ] **Step 1: Run every gate from the worktree root**

```bash
dart format --set-exit-if-changed dart_falconnect dart_falmodel
melos run analyze --no-select
melos run test --no-select
cd dart_falconnect && dart compile js -o /tmp/sp2_smoke.js test/web/compile_smoke.dart && dart test -p chrome test/web/engine_web_test.dart
```

Expected: format exit 0; analyze SUCCESS; tests pass (faltool 699, falmodel 54, falconnect 79, falconx 1); compile exit 0; Chrome 5 tests pass.

- [ ] **Step 2: Check the spec's success criteria against the tests**

| Criterion (spec section 17) | Test |
|---|---|
| No request to a paused host before the pause ends | `forwards nothing during a pause, then keeps the ceiling`; chain `a request sent during the pause is held, then sent` |
| Ceiling holds after a pause | `forwards nothing during a pause, then keeps the ceiling` |
| No double waiting | chain `a retry waits for Retry-After once, not twice` |
| Same exception for local and server 429 | chain `a local 429 reaches the caller as NetworkLimitExceededException` |
| Retries reach `maxRetryAttempts`; no `POST` retry after 5xx | `retries a GET up to maxRetryAttempts, then fails`; `does not retry a POST after a 500` |

- [ ] **Step 3: Confirm no stale references**

Run: `grep -rn "isRetry\|retryCount" dart_falconnect/lib skills/dart-falconx-package`
Expected: no matches.
