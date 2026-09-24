import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/token_bucket_rate_limit_statistics.freezed.dart';

/// Activity counters of a `TokenBucketRateLimitInterceptor`.
@freezed
abstract class TokenBucketRateLimitStatistics
    with _$TokenBucketRateLimitStatistics {
  /// Creates a statistics snapshot.
  const factory({
    /// Requests passed to the next handler since construction. A request
    /// cancelled before it was forwarded is not counted.
    required int forwarded,

    /// Requests rejected with a local 429 since construction, for a full
    /// queue or a paused host.
    required int rejected,

    /// Requests waiting in each host's own tiers, keyed by host. An idle
    /// host whose buckets have refilled drops out once a new host arrives.
    required Map<String, int> waitingByHost,

    /// Requests waiting in the global tiers.
    required int globalWaiting,

    /// Requests held by a pause, keyed by host.
    required Map<String, int> heldByHost,

    /// End time of each active pause, keyed by host.
    required Map<String, DateTime> pausedUntilByHost,
  }) = _TokenBucketRateLimitStatistics;
}
