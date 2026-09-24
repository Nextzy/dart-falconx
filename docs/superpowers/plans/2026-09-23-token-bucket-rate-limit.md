# Token Bucket Rate Limiting (SP1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `RateLimitInterceptor` with `TokenBucketRateLimitInterceptor`, built on the `resilience` package re-exported from `dart_faltool`, with `TokenBucketPolicy` limits that are unlimited by default.

**Architecture:** `dart_faltool` adds `resilience`, re-exports it without `Retry`, `RetryEvent`, `Timeout`, and adds `TokenBucketPolicy`, which maps "at most N per window" onto a `resilience` `RateLimiter`. `dart_falconnect` adds the new interceptor: each request passes its host's tiers, then the global tiers, through one `ResiliencePipeline` per host. The old interceptor, its test, and the dead `utils/rate_limiter.dart` are deleted, docs follow, and every package moves to 2.0.0.

**Tech Stack:** Dart `>=3.13.0`, Melos 8 workspace, `resilience ^1.1.3`, `dio` 5, `fake_async ^1.3.3`, `package:test`, `very_good_analysis` 11.

**Spec:** `docs/superpowers/specs/2026-09-23-token-bucket-rate-limit-design.md`

## Global Constraints

- Work in a git worktree on branch `feature/token-bucket-rate-limit` created from `develop` (use superpowers:using-git-worktrees). Another session commits to `develop`; do not work in the main checkout.
- Run `dart pub get` at the worktree root once before Task 1 (Dart workspace resolution).
- `melos run analyze` runs `dart analyze` with `--fatal-infos`: every info-level lint fails the build.
- Constructors use the declaring form `new(...)` / `const new(...)`; `ClassName(...)` constructors trip `unnecessary_type_name_in_constructor`.
- Lines stay within 80 characters; run `dart format` on every file you touch.
- Every timing test runs under `fakeAsync`. Wrap fire-and-forget futures in `unawaited(...)` (`discarded_futures`).
- `resilience: ^1.1.3` is a dependency of `dart_faltool` only, re-exported as `export 'package:resilience/resilience.dart' hide Retry, RetryEvent, Timeout;`.
- Policy semantics are a ceiling: never more than `permits` requests in any window of length `per`; `burst` defaults to `max(1, permits ~/ 10)`.
- No policy means unlimited: `global`, `perHost`, `hosts` default to empty.
- Commits use Conventional Commits and carry no `Co-Authored-By` or AI attribution (repository `CLAUDE.md`).
- Final version: `2.0.0` in every `pubspec.yaml` that reads `1.0.11`.

## Review Focus

- A `hosts` key with uppercase letters: it could never match because `Uri` lowercases hosts, so construction must throw `ArgumentError`; a mixed-case request URL must still hit its lowercase key. Tests in Task 2.
- An invalid policy in `perHost` or `hosts`: host limiters are built lazily, so the constructor must throw `ArgumentError` up front instead of failing on the host's first request. Test in Task 2.
- The same host on two ports: `Uri.host` drops the port, so both share one limit. Test in Task 2.
- A request to a never-seen limited host after `dispose()`: it must be cancelled without building a limiter or timer, while an unlimited host still passes. Test in Task 2.
- A consumer test file that imports `package:test` and the umbrella package and uses `Timeout`: it must compile, which the `hide` in the re-export guarantees. Pinned in Task 1 by a `Timeout` on a test group.

---

### Task 1: `TokenBucketPolicy` and the `resilience` dependency in `dart_faltool`

**Files:**
- Modify: `dart_faltool/pubspec.yaml` (dependencies after `numeral: ^4.1.0`; dev_dependencies after `build_runner`)
- Modify: `dart_faltool/lib/dart_faltool.dart` (export after `package:numeral/numeral.dart`)
- Create: `dart_faltool/lib/utils/token_bucket_policy.dart`
- Modify: `dart_faltool/lib/utils/utils.dart`
- Test: `dart_faltool/test/utils/token_bucket_policy_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `TokenBucketPolicy({required int permits, required Duration per, int? burst})` (const), `int get burst`, `void validate()` (throws `ArgumentError`), `RateLimiter toRateLimiter({int? maxQueueLength})`. `RateLimiter`, `RateLimitExceededException`, `ResiliencePipeline` are in scope through `package:dart_faltool/dart_faltool.dart`.

- [ ] **Step 1: Add the dependencies**

In `dart_faltool/pubspec.yaml`, under `dependencies:` insert after `  numeral: ^4.1.0`:

```yaml
  resilience: ^1.1.3
```

Under `dev_dependencies:` insert after `  build_runner: ^2.16.1`:

```yaml
  fake_async: ^1.3.3
```

Run from the worktree root: `dart pub get`
Expected: `Got dependencies!` (or `Changed N dependencies!`), no errors.

- [ ] **Step 2: Write the failing test**

Create `dart_faltool/test/utils/token_bucket_policy_test.dart`:

```dart
import 'package:dart_faltool/lib.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

/// Drives [policy] with saturating demand for [windows] windows and returns
/// the admission times.
List<Duration> _admissions(TokenBucketPolicy policy, {int windows = 5}) {
  final admitted = <Duration>[];
  fakeAsync((async) {
    final limiter = policy.toRateLimiter();
    for (var i = 0; i < policy.permits * (windows + 1); i++) {
      unawaited(limiter.execute(() async => admitted.add(async.elapsed)));
    }
    async.elapse(policy.per * windows);
    limiter.dispose();
  });
  return admitted;
}

/// Largest number of admissions inside any half-open window of [per].
int _maxInAnyWindow(List<Duration> admitted, Duration per) {
  var highest = 0;
  for (var start = 0; start < admitted.length; start++) {
    final end = admitted[start] + per;
    var count = 0;
    for (var i = start; i < admitted.length && admitted[i] < end; i++) {
      count++;
    }
    if (count > highest) highest = count;
  }
  return highest;
}

void main() {
  group('TokenBucketPolicy.burst', () {
    test('defaults to 10% of permits', () {
      const policy = TokenBucketPolicy(permits: 100, per: Duration(minutes: 1));
      expect(policy.burst, 10);
    });

    test('defaults to at least 1', () {
      const policy = TokenBucketPolicy(permits: 5, per: Duration(seconds: 1));
      expect(policy.burst, 1);
    });

    test('uses an explicit value', () {
      const policy = TokenBucketPolicy(
        permits: 100,
        per: Duration(minutes: 1),
        burst: 40,
      );
      expect(policy.burst, 40);
    });
  });

  group('TokenBucketPolicy.validate', () {
    void expectInvalid(TokenBucketPolicy policy) {
      expect(policy.validate, throwsArgumentError);
      expect(policy.toRateLimiter, throwsArgumentError);
    }

    test('rejects permits below 1', () {
      expectInvalid(
        const TokenBucketPolicy(permits: 0, per: Duration(seconds: 1)),
      );
    });

    test('rejects a non-positive per', () {
      expectInvalid(const TokenBucketPolicy(permits: 10, per: Duration.zero));
    });

    test('rejects burst below 1', () {
      expectInvalid(
        const TokenBucketPolicy(
          permits: 10,
          per: Duration(seconds: 1),
          burst: 0,
        ),
      );
    });

    test('rejects burst above permits', () {
      expectInvalid(
        const TokenBucketPolicy(
          permits: 10,
          per: Duration(seconds: 1),
          burst: 11,
        ),
      );
    });

    test('rejects a per shorter than one microsecond per refill', () {
      expectInvalid(
        const TokenBucketPolicy(
          permits: 1000,
          per: Duration(microseconds: 999),
          burst: 1,
        ),
      );
    });

    test('accepts a valid policy', () {
      const policy = TokenBucketPolicy(permits: 10, per: Duration(seconds: 1));
      expect(policy.validate, returnsNormally);
    });
  });

  // `Timeout` here comes from package:test. It compiles only while
  // dart_faltool re-exports resilience with `hide Retry, RetryEvent, Timeout`.
  group(
    'TokenBucketPolicy ceiling',
    () {
      for (final burst in [1, null, 100]) {
        test(
          'never exceeds permits per window with burst ${burst ?? 'default'}',
          () {
            final policy = TokenBucketPolicy(
              permits: 100,
              per: const Duration(minutes: 1),
              burst: burst,
            );
            final admitted = _admissions(policy);
            expect(_maxInAnyWindow(admitted, policy.per), 100);
          },
        );
      }

      test('holds for one request per second', () {
        const policy = TokenBucketPolicy(
          permits: 1,
          per: Duration(seconds: 1),
          burst: 1,
        );
        final admitted = _admissions(policy, windows: 10);
        expect(_maxInAnyWindow(admitted, policy.per), 1);
        final inTenSeconds = admitted.where((t) => t < policy.per * 10);
        expect(inTenSeconds.length, 10);
      });

      test('burst 1 sustains the full quota', () {
        const policy = TokenBucketPolicy(
          permits: 60,
          per: Duration(minutes: 1),
          burst: 1,
        );
        final admitted = _admissions(policy);
        final inFiveMinutes = admitted.where((t) => t < policy.per * 5);
        expect(inFiveMinutes.length, 300);
      });
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd dart_faltool && dart test test/utils/token_bucket_policy_test.dart`
Expected: compile failure, `Undefined name 'TokenBucketPolicy'` / `The method 'TokenBucketPolicy' isn't defined`.

- [ ] **Step 4: Re-export `resilience`**

In `dart_faltool/lib/dart_faltool.dart`, insert between `export 'package:numeral/numeral.dart';` and `export 'package:retry/retry.dart';`:

```dart
export 'package:resilience/resilience.dart' hide Retry, RetryEvent, Timeout;
```

- [ ] **Step 5: Implement `TokenBucketPolicy`**

Create `dart_faltool/lib/utils/token_bucket_policy.dart`:

```dart
import 'dart:math' as math;

import 'package:dart_faltool/lib.dart';

/// A rate limit stated as "at most [permits] requests in any window of
/// length [per]", enforced with a token bucket.
///
/// [burst] is how many requests may leave back to back after an idle
/// period. It defaults to 10% of [permits], at least 1. A larger burst
/// lowers the steady rate to `permits - burst + 1` per [per]; the ceiling
/// of [permits] per [per] never moves.
@immutable
class TokenBucketPolicy {
  /// Creates a policy allowing [permits] requests per [per].
  const new({required this.permits, required this.per, int? burst})
    : _burst = burst;

  /// Most requests allowed in any window of length [per].
  final int permits;

  /// Window length.
  final Duration per;

  final int? _burst;

  /// Requests allowed back to back after an idle period.
  int get burst => _burst ?? math.max(1, permits ~/ 10);

  /// Throws an [ArgumentError] when this policy cannot be enforced.
  void validate() {
    if (permits < 1) {
      throw ArgumentError.value(permits, 'permits', 'must be at least 1');
    }
    if (per <= Duration.zero) {
      throw ArgumentError.value(per, 'per', 'must be positive');
    }
    if (burst < 1 || burst > permits) {
      throw ArgumentError.value(burst, 'burst', 'must be in 1..$permits');
    }
    if (per.inMicroseconds < permits - burst + 1) {
      throw ArgumentError.value(
        per,
        'per',
        'must be at least ${permits - burst + 1} microseconds',
      );
    }
  }

  /// Builds the `resilience` [RateLimiter] that enforces this policy.
  ///
  /// The bucket holds [burst] tokens and refills `permits - burst + 1`
  /// tokens per [per], rounded towards slower refills, so no window of
  /// length [per] ever admits more than [permits] requests.
  RateLimiter toRateLimiter({int? maxQueueLength}) {
    validate();
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

In `dart_faltool/lib/utils/utils.dart`, insert after `export 'json_serialize.dart';`:

```dart
export 'token_bucket_policy.dart';
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `cd dart_faltool && dart test test/utils/token_bucket_policy_test.dart`
Expected: `+14: All tests passed!`

- [ ] **Step 7: Run the package suite and the workspace analyzer**

Run: `cd dart_faltool && dart test`
Expected: `All tests passed!` (existing tests still compile with `resilience` in scope).

Run from the worktree root: `dart format dart_faltool && melos run analyze`
Expected: every package reports `No issues found!`. If `dart format` changed a file, re-run the test from Step 6.

- [ ] **Step 8: Commit**

```bash
git add dart_faltool/pubspec.yaml pubspec.lock dart_faltool/lib/dart_faltool.dart \
  dart_faltool/lib/utils/token_bucket_policy.dart dart_faltool/lib/utils/utils.dart \
  dart_faltool/test/utils/token_bucket_policy_test.dart
git commit -m "feat(dart_faltool): add TokenBucketPolicy and re-export resilience"
```

---

### Task 2: `TokenBucketRateLimitInterceptor` in `dart_falconnect`

**Files:**
- Create: `dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart`
- Modify: `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`
- Test: `dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart`

**Interfaces:**
- Consumes: `TokenBucketPolicy` (`validate()`, `toRateLimiter({int? maxQueueLength})`), `RateLimiter` (`execute`, `dispose`, `queueLength`), `RateLimitExceededException`, `ResiliencePipeline(List<Policy>)` from `package:dart_faltool/dart_faltool.dart`; `HttpClientConfig` (`enableLogging`).
- Produces: `TokenBucketRateLimitInterceptor({required HttpClientConfig config, List<TokenBucketPolicy> global = const [], List<TokenBucketPolicy> perHost = const [], Map<String, List<TokenBucketPolicy>> hosts = const {}, bool queueRequests = true, int maxQueueSize = 50, int maxGlobalQueueSize = 500})`, `Future<void> onRequest(RequestOptions, RequestInterceptorHandler)`, `TokenBucketRateLimitStatistics getStatistics()`, `void dispose()`; `TokenBucketRateLimitStatistics` with `int forwarded`, `int rejected`, `Map<String, int> waitingByHost`, `int globalWaiting`.

- [ ] **Step 1: Write the failing test**

Create `dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart`:

```dart
import 'dart:async';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart';
import 'package:dart_faltool/dart_faltool.dart'
    show RateLimitExceededException, TokenBucketPolicy;
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

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
  ]) => log.rejected.add(error);
}

class _Log {
  final forwarded = <RequestOptions>[];
  final rejected = <DioException>[];
}

const _config = HttpClientConfig();

void _send(
  TokenBucketRateLimitInterceptor interceptor,
  _Log log, {
  String url = 'https://a.test/items',
  int times = 1,
}) {
  for (var i = 0; i < times; i++) {
    unawaited(
      interceptor.onRequest(RequestOptions(path: url), _RecordingHandler(log)),
    );
  }
}

void main() {
  test('forwards synchronously and creates no timer when no policy is set', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(config: _config);
      final log = _Log();

      _send(interceptor, log, times: 20);

      expect(log.forwarded, hasLength(20));
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('forwards requests within burst without waiting', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 10, per: Duration(seconds: 1), burst: 5),
        ],
      );
      final log = _Log();

      _send(interceptor, log, times: 5);
      async.flushMicrotasks();

      expect(log.forwarded, hasLength(5));
      interceptor.dispose();
    });
  });

  test('drains queued requests at the refill rate', () {
    fakeAsync((async) {
      // Burst 10, then (13 - 10 + 1) = 4 refills per 10 s: one every 2.5 s.
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 13, per: Duration(seconds: 10), burst: 10),
        ],
      );
      final log = _Log();

      _send(interceptor, log, times: 13);
      async.flushMicrotasks();
      expect(log.forwarded, hasLength(10));

      async.elapse(const Duration(milliseconds: 2400));
      expect(log.forwarded, hasLength(10));

      async.elapse(const Duration(milliseconds: 5100));
      expect(log.forwarded, hasLength(13));
      expect(log.rejected, isEmpty);
      interceptor.dispose();
    });
  });

  test('a hosts entry replaces perHost for that host', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 2, per: Duration(seconds: 1), burst: 2),
        ],
        hosts: const {
          'b.test': [
            TokenBucketPolicy(permits: 5, per: Duration(seconds: 1), burst: 5),
          ],
        },
      );
      final logA = _Log();
      final logB = _Log();

      _send(interceptor, logA, times: 5);
      _send(interceptor, logB, url: 'https://b.test/items', times: 5);
      async.flushMicrotasks();

      expect(logA.forwarded, hasLength(2));
      expect(logB.forwarded, hasLength(5));
      interceptor.dispose();
    });
  });

  test('an empty hosts entry opts the host out of perHost', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
        hosts: const {'free.test': []},
      );
      final log = _Log();

      _send(interceptor, log, url: 'https://free.test/items', times: 20);

      expect(log.forwarded, hasLength(20));
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('matches hosts case-insensitively through Uri', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        hosts: const {
          'api.partner.test': [
            TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
          ],
        },
      );
      final log = _Log();

      _send(interceptor, log, url: 'https://API.Partner.test/x', times: 3);
      async.flushMicrotasks();

      expect(log.forwarded, hasLength(1));
      interceptor.dispose();
    });
  });

  test('rejects a hosts key that is not lowercase', () {
    expect(
      () => TokenBucketRateLimitInterceptor(
        config: _config,
        hosts: const {
          'API.partner.test': [
            TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
          ],
        },
      ),
      throwsArgumentError,
    );
  });

  test('rejects an invalid perHost or hosts policy at construction', () {
    const invalid = TokenBucketPolicy(permits: 0, per: Duration(seconds: 1));
    expect(
      () => TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [invalid],
      ),
      throwsArgumentError,
    );
    expect(
      () => TokenBucketRateLimitInterceptor(
        config: _config,
        hosts: const {
          'a.test': [invalid],
        },
      ),
      throwsArgumentError,
    );
  });

  test('limits the same host across ports', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
      );
      final log = _Log();

      _send(interceptor, log, url: 'https://a.test:8443/x');
      _send(interceptor, log, url: 'https://a.test:9443/x');
      async.flushMicrotasks();

      expect(log.forwarded, hasLength(1));
      interceptor.dispose();
    });
  });

  test('every tier holds its own ceiling', () {
    fakeAsync((async) {
      // Tier 1: 5 per second, burst 5. Tier 2: 8 per minute, burst 8.
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 5, per: Duration(seconds: 1), burst: 5),
          TokenBucketPolicy(permits: 8, per: Duration(minutes: 1), burst: 8),
        ],
      );
      final log = _Log();

      _send(interceptor, log, times: 20);
      async.flushMicrotasks();
      expect(log.forwarded, hasLength(5), reason: 'tier 1 burst');

      async.elapse(const Duration(seconds: 10));
      expect(log.forwarded, hasLength(8), reason: 'tier 2 ceiling');

      async.elapse(const Duration(seconds: 50));
      expect(log.forwarded, hasLength(9), reason: 'tier 2 refill at 60 s');
      interceptor.dispose();
    });
  });

  test('global tiers are shared by every host', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        global: const [
          TokenBucketPolicy(permits: 3, per: Duration(minutes: 1), burst: 3),
        ],
      );
      final log = _Log();

      _send(interceptor, log, times: 2);
      _send(interceptor, log, url: 'https://b.test/items', times: 2);
      async.flushMicrotasks();

      expect(log.forwarded, hasLength(3));
      expect(interceptor.getStatistics().globalWaiting, 1);
      interceptor.dispose();
    });
  });

  test('rejects with 429 when a queue is full', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
        maxQueueSize: 2,
      );
      final log = _Log();

      _send(interceptor, log, times: 4);
      async.flushMicrotasks();

      expect(log.forwarded, hasLength(1));
      expect(log.rejected, hasLength(1));
      final error = log.rejected.single;
      expect(error.type, DioExceptionType.unknown);
      expect(error.response?.statusCode, 429);
      expect(error.error, isA<RateLimitExceededException>());

      final stats = interceptor.getStatistics();
      expect(stats.forwarded, 1);
      expect(stats.rejected, 1);
      expect(stats.waitingByHost, {'a.test': 2});
      expect(stats.globalWaiting, 0);
      interceptor.dispose();
    });
  });

  test('rejects at once when queueRequests is false', () {
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

      expect(log.forwarded, hasLength(1));
      expect(log.rejected.single.response?.statusCode, 429);
      interceptor.dispose();
    });
  });

  test('dispose cancels waiting and new limited requests only', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
        hosts: const {'free.test': []},
      );
      final log = _Log();

      _send(interceptor, log, times: 3);
      async.flushMicrotasks();
      expect(log.forwarded, hasLength(1));

      interceptor
        ..dispose()
        ..dispose();
      async.flushMicrotasks();
      expect(log.rejected, hasLength(2));
      expect(
        log.rejected.map((e) => e.type),
        everyElement(DioExceptionType.cancel),
      );

      _send(interceptor, log, url: 'https://new.test/x');
      _send(interceptor, log, url: 'https://free.test/x');
      async.flushMicrotasks();
      expect(log.rejected, hasLength(3));
      expect(log.rejected.last.type, DioExceptionType.cancel);
      expect(log.forwarded, hasLength(2));
      expect(async.pendingTimers, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart`
Expected: compile failure, `Target of URI doesn't exist: 'package:dart_falconnect/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart'`.

- [ ] **Step 3: Implement the interceptor**

Create `dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart`:

```dart
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
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
  });

  /// Requests passed to the next handler since construction.
  final int forwarded;

  /// Requests rejected with 429 since construction.
  final int rejected;

  /// Requests waiting in each host's own tiers, keyed by host.
  final Map<String, int> waitingByHost;

  /// Requests waiting in the global tiers.
  final int globalWaiting;
}

/// Limits outgoing requests with token buckets built on `resilience`.
///
/// Every request passes all tiers of its host, then all `global` tiers.
/// A host's tiers come from `hosts[host]` when that key exists, otherwise
/// from `perHost`. A scope with no policy is unlimited: a request to a host
/// whose tiers and the global tiers are all empty is forwarded
/// synchronously and creates no limiter.
///
/// Each [TokenBucketPolicy] guarantees at most `permits` requests in any
/// window of `per`. Refills are driven by `Timer`, not by reading the
/// clock: `fakeAsync`'s `elapse` advances them, and
/// `withClock(Clock.fixed(...))` has no effect on them.
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
  /// Keys of [hosts] must be lowercase, because `Uri` lowercases hosts.
  new({
    required this.config,
    List<TokenBucketPolicy> global = const [],
    List<TokenBucketPolicy> perHost = const [],
    Map<String, List<TokenBucketPolicy>> hosts = const {},
    this.queueRequests = true,
    this.maxQueueSize = 50,
    this.maxGlobalQueueSize = 500,
  }) : _perHost = perHost,
       _hosts = hosts,
       _globalLimiters = [
         for (final policy in global)
           policy.toRateLimiter(
             maxQueueLength: queueRequests ? maxGlobalQueueSize : 0,
           ),
       ] {
    for (final host in hosts.keys) {
      if (host != host.toLowerCase()) {
        throw ArgumentError.value(host, 'hosts', 'keys must be lowercase');
      }
    }
    for (final policy in [...perHost, ...hosts.values.expand((p) => p)]) {
      policy.validate();
    }
  }

  /// Configuration; `enableLogging` gates diagnostic prints.
  final HttpClientConfig config;

  /// Whether a request with no token waits (`true`) or is rejected.
  final bool queueRequests;

  /// Wait-queue capacity of each host tier.
  final int maxQueueSize;

  /// Wait-queue capacity of each global tier.
  final int maxGlobalQueueSize;

  final List<TokenBucketPolicy> _perHost;
  final Map<String, List<TokenBucketPolicy>> _hosts;
  final List<RateLimiter> _globalLimiters;
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
    if (hostPolicies.isEmpty && _globalLimiters.isEmpty) {
      _forwarded++;
      handler.next(options);
      return;
    }
    if (_disposed) {
      handler.reject(_cancelled(options, StateError('RateLimiter disposed')));
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
      handler.reject(_tooManyRequests(options, error));
      return;
    } on Object catch (error) {
      // resilience fails waiting calls with a StateError once disposed.
      if (!_disposed) rethrow;
      handler.reject(_cancelled(options, error));
      return;
    }
    _forwarded++;
    handler.next(options);
  }

  /// Returns the current activity counters.
  TokenBucketRateLimitStatistics getStatistics() {
    int waiting(Iterable<RateLimiter> limiters) =>
        limiters.fold(0, (sum, limiter) => sum + limiter.queueLength);
    return TokenBucketRateLimitStatistics(
      forwarded: _forwarded,
      rejected: _rejected,
      waitingByHost: {
        for (final entry in _hostLimiters.entries)
          entry.key: waiting(entry.value),
      },
      globalWaiting: waiting(_globalLimiters),
    );
  }

  /// Stops every refill timer and cancels waiting requests.
  ///
  /// Afterwards, requests to a limited host are cancelled and requests to
  /// an unlimited host still pass. Calling it again has no effect.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final limiter in [
      ..._globalLimiters,
      ..._hostLimiters.values.expand((limiters) => limiters),
    ]) {
      limiter.dispose();
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

  DioException _tooManyRequests(
    RequestOptions options,
    RateLimitExceededException error,
  ) => DioException(
    requestOptions: options,
    error: error,
    message: 'Rate limit queue full for ${options.uri.host}',
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: 429,
      statusMessage: 'Too Many Requests',
    ),
  );

  DioException _cancelled(RequestOptions options, Object error) => DioException(
    requestOptions: options,
    type: DioExceptionType.cancel,
    error: error,
    message: 'Rate limiter disposed',
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

In `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`, append after `export 'retry_interceptor.dart';`:

```dart
export 'token_bucket_rate_limit_interceptor.dart';
```

(`rate_limit_interceptor.dart` stays exported until Task 3.)

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd dart_falconnect && dart test test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart`
Expected: `+14: All tests passed!`

- [ ] **Step 5: Format and analyze**

Run from the worktree root: `dart format dart_falconnect && melos run analyze`
Expected: `No issues found!` in every package. If `dart format` changed a file, re-run Step 4.

- [ ] **Step 6: Commit**

```bash
git add dart_falconnect/lib/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart \
  dart_falconnect/lib/engine/https/interceptors/interceptors.dart \
  dart_falconnect/test/engine/https/interceptors/token_bucket_rate_limit_interceptor_test.dart
git commit -m "feat(dart_falconnect): add TokenBucketRateLimitInterceptor"
```

---

### Task 3: Remove the old interceptor and move the web gates

**Files:**
- Delete: `dart_falconnect/lib/engine/https/interceptors/rate_limit_interceptor.dart`
- Delete: `dart_falconnect/lib/utils/rate_limiter.dart`
- Delete: `dart_falconnect/test/engine/https/interceptors/rate_limit_interceptor_test.dart`
- Modify: `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`
- Modify: `dart_falconnect/test/web/compile_smoke.dart:34`
- Modify: `dart_falconnect/test/web/engine_web_test.dart:31`

**Interfaces:**
- Consumes: `TokenBucketRateLimitInterceptor({required HttpClientConfig config, ...})` from Task 2.
- Produces: no `RateLimitInterceptor` symbol anywhere in the workspace.

- [ ] **Step 1: Delete the old files and export**

```bash
git rm dart_falconnect/lib/engine/https/interceptors/rate_limit_interceptor.dart \
  dart_falconnect/lib/utils/rate_limiter.dart \
  dart_falconnect/test/engine/https/interceptors/rate_limit_interceptor_test.dart
```

In `dart_falconnect/lib/engine/https/interceptors/interceptors.dart`, delete the line:

```dart
export 'rate_limit_interceptor.dart';
```

- [ ] **Step 2: Point the web gates at the new class**

In `dart_falconnect/test/web/compile_smoke.dart`, replace:

```dart
  _sink(RateLimitInterceptor(config: cfg));
```

with:

```dart
  _sink(TokenBucketRateLimitInterceptor(config: cfg));
```

In `dart_falconnect/test/web/engine_web_test.dart`, replace:

```dart
      expect(RateLimitInterceptor(config: cfg), isNotNull);
```

with:

```dart
      expect(TokenBucketRateLimitInterceptor(config: cfg), isNotNull);
```

- [ ] **Step 3: Check that nothing references the old names**

Run from the worktree root:

```bash
grep -rnw --include='*.dart' -e RateLimitInterceptor -e _TokenBucket -e clearQueues dart_*
grep -rn --include='*.dart' 'utils/rate_limiter' dart_*
```

Expected: both commands print nothing. (`-w` does not match inside `TokenBucketRateLimitInterceptor`.)

- [ ] **Step 4: Run every gate**

Run from the worktree root: `melos run analyze && melos run test`
Expected: `No issues found!` in every package, then `All tests passed!` in every package with a `test/` directory.

Run from `dart_falconnect/`:

```bash
dart compile js test/web/compile_smoke.dart -o /tmp/compile_smoke.js
dart test -p chrome test/web/engine_web_test.dart
```

Expected: `Compiled ... to ... JavaScript`, then `All tests passed!`.

- [ ] **Step 5: Commit**

```bash
git add dart_falconnect/lib/engine/https/interceptors/interceptors.dart \
  dart_falconnect/test/web/compile_smoke.dart dart_falconnect/test/web/engine_web_test.dart
git commit -m "refactor(dart_falconnect)!: remove RateLimitInterceptor in favour of TokenBucketRateLimitInterceptor"
```

---

### Task 4: Documentation and the consumer skill

**Files:**
- Modify: `skills/dart-falconx-package/SKILL.md:38`, `:53`
- Modify: `skills/dart-falconx-package/references/http.md` (catalog row at line 87, new section after the `HttpClientConfig` paragraph)
- Modify: `skills/dart-falconx-package/references/utils.md` (table)
- Modify: `skills/dart-falconx-package/references/third-party.md` (`## Via dart_faltool` table)
- Modify: `CLAUDE.md` (Utilities table, after the `retry` row)
- Modify: `dart_falconnect/CLAUDE.md:72`, `:87`

**Interfaces:**
- Consumes: the public API from Tasks 1 and 2.
- Produces: docs only.

Markdown tables in these files are column-aligned. Pad new or edited rows to the existing column widths.

- [ ] **Step 1: `SKILL.md`**

Line 38, in the Interceptors row, replace `` `RateLimitInterceptor` `` with `` `TokenBucketRateLimitInterceptor` ``.

Line 53, in the third-party row, insert `` `resilience` (without `Retry`, `Timeout`), `` before `` `retry` ``.

- [ ] **Step 2: `references/http.md`**

Replace the `RateLimitInterceptor` catalog row with:

```markdown
| `TokenBucketRateLimitInterceptor`           | `(config:, global: [], perHost: [], hosts: {}, queueRequests: true, maxQueueSize: 50, maxGlobalQueueSize: 500)` | token buckets from `TokenBucketPolicy` lists; no policy means unlimited; each request passes its host tiers (`hosts[host]`, else `perHost`) then `global`; full queue → 429 `DioException`; `getStatistics()`, `dispose()` |
```

After the `HttpClientConfig` paragraph (before `## Helpers`), insert:

````markdown
## Rate limiting

Every scope is unlimited until you give it a policy. A `TokenBucketPolicy` means "at most `permits` requests in any window of `per`"; `burst` (default 10% of `permits`, at least 1) is how many may leave back to back after idle time, and the steady rate is `permits - burst + 1` per `per`.

```dart
final rateLimit = TokenBucketRateLimitInterceptor(
  config: config,
  hosts: const {
    'api.partner.com': [
      TokenBucketPolicy(permits: 100, per: Duration(minutes: 1)),
      TokenBucketPolicy(permits: 5000, per: Duration(hours: 1), burst: 50),
    ],
  },
);
```

`hosts` keys must be lowercase. An empty list (`'api.my-backend.com': []`) opts a host out of `perHost`.

Refill timers outlive the last request, so call `dispose()` where timers must stop:

| Context                                           | Call `dispose()`                                                                                     |
|---------------------------------------------------|------------------------------------------------------------------------------------------------------|
| Flutter app, client lives as long as the app      | not needed                                                                                           |
| Scoped client (DI scope, logout, env switch)      | when the scope ends: get_it `dispose:`, injectable `@disposeMethod`, Riverpod `ref.onDispose`        |
| `testWidgets` with a real client                  | at the end of the test body or from a widget's `dispose`; `addTearDown` is too late and the test fails |
| Unit test under `fakeAsync`                       | at the end of the `fakeAsync` body                                                                   |
| CLI                                               | in a `finally` before `main` returns, or exit waits until every bucket refills                       |
| Server (dart_frog)                                | not needed                                                                                           |

On a server, build the client once per process (a top-level variable returned by `provider`). A client built inside a per-request `provider` starts with full buckets on every request and limits nothing.
````

- [ ] **Step 3: `references/utils.md`**

Append these rows to the table:

```markdown
| `TokenBucketPolicy`                                        | `const TokenBucketPolicy({required int permits, required Duration per, int? burst})`                     | at most `permits` per window of `per`; `burst` defaults to 10% of `permits` (at least 1); steady rate `permits - burst + 1` per `per` |
| `TokenBucketPolicy.validate()`                             | `void validate()`                                                                                        | throws `ArgumentError` for `permits < 1`, `per <= 0`, `burst` outside `1..permits`, or `per` shorter than one microsecond per refill |
| `TokenBucketPolicy.toRateLimiter()`                        | `RateLimiter toRateLimiter({int? maxQueueLength})`                                                       | `resilience` limiter enforcing the ceiling; call `dispose()` on it when done                                              |
```

- [ ] **Step 4: `references/third-party.md`**

In the `## Via dart_faltool` table, insert between the `numeral` and `retry` rows:

```markdown
| `resilience`                   | `RateLimiter`, `Bulkhead`, `CircuitBreaker`, `Hedge`, `ResiliencePipeline`, `withFallback` | `Retry`, `RetryEvent`, `Timeout` (they clash with `package:test`; import `package:resilience/resilience.dart` with a prefix to use them) |
```

After the table, add:

```markdown
Retry choices: `RetryInterceptor` for Dio requests, `retryWithBackoff` for a single `Future`, `retry()` / `RetryOptions` for a generic operation. In `fakeAsync` tests, build `CircuitBreaker` with `now: clock.now`; its default `Stopwatch` is not faked.
```

- [ ] **Step 5: Root `CLAUDE.md`**

In `### Utilities (dart_faltool, re-exported)`, insert after the `retry` row:

```markdown
| `resilience`     | Token bucket `RateLimiter`, `Bulkhead`, `CircuitBreaker` (re-exported without `Retry`, `RetryEvent`, `Timeout`) |
```

- [ ] **Step 6: `dart_falconnect/CLAUDE.md`**

Replace line 72 (`6. \`RateLimitInterceptor\` — Rate limiting`) with:

```markdown
6. `TokenBucketRateLimitInterceptor` — Token bucket rate limiting from `TokenBucketPolicy` lists; unlimited when no policy is set
```

Replace the gotcha at line 87 (`` `RateLimiter` in `utils/` is a placeholder ... ``) with:

```markdown
- `TokenBucketRateLimitInterceptor` refill timers outlive the last request: in `testWidgets` call `dispose()` in the test body (`addTearDown` is too late); on servers build one instance per process
```

- [ ] **Step 7: Commit**

```bash
git add skills/dart-falconx-package CLAUDE.md dart_falconnect/CLAUDE.md
git commit -m "docs: document TokenBucketRateLimitInterceptor and the resilience re-export"
```

---

### Task 5: Version 2.0.0 and final verification

**Files:**
- Modify: `pubspec.yaml:3`, `dart_falconnect/pubspec.yaml:3`, `dart_falconx/pubspec.yaml:3`, `dart_falmodel/pubspec.yaml:3`, `dart_faltool/pubspec.yaml:3`
- Modify: `skills/dart-falconx-package/SKILL.md:17`

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces: release-ready branch.

- [ ] **Step 1: Bump every version**

In each of the five pubspecs, replace `version: 1.0.11` with `version: 2.0.0`.

In `skills/dart-falconx-package/SKILL.md` line 17, replace `e.g. 1.0.11` with `e.g. 2.0.0`.

Run: `grep -rn "1\.0\.11" --include=pubspec.yaml . ; grep -n "1\.0\.11" skills/dart-falconx-package/SKILL.md`
Expected: no output.

- [ ] **Step 2: Run every gate**

Run from the worktree root: `dart pub get && melos run analyze && melos run test`
Expected: `No issues found!` and `All tests passed!` in every package.

Run from `dart_falconnect/`:

```bash
dart compile js test/web/compile_smoke.dart -o /tmp/compile_smoke.js
dart test -p chrome test/web/engine_web_test.dart
```

Expected: compile succeeds; `All tests passed!`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock dart_falconnect/pubspec.yaml dart_falconx/pubspec.yaml \
  dart_falmodel/pubspec.yaml dart_faltool/pubspec.yaml skills/dart-falconx-package/SKILL.md
git commit -m "chore(release): bump to 2.0.0"
```

- [ ] **Step 4: Hand off**

Use superpowers:finishing-a-development-branch. The owner decides merge versus PR and creates the `2.0.0` tag after merge.
