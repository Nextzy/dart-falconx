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
