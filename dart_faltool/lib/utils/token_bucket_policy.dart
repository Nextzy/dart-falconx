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
