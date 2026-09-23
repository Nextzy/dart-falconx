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
  group('TokenBucketPolicy ceiling', () {
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
  }, timeout: const Timeout(Duration(seconds: 30)));
}
