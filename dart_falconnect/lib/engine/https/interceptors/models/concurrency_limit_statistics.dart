import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/concurrency_limit_statistics.freezed.dart';

/// Activity counters of a `ConcurrencyLimitInterceptor`.
@freezed
abstract class ConcurrencyLimitStatistics with _$ConcurrencyLimitStatistics {
  /// Creates a statistics snapshot.
  const factory({
    /// Requests passed to the next handler since construction, retry
    /// attempts included.
    required int forwarded,

    /// Requests rejected with a local 429 because a queue was full.
    required int rejected,

    /// Slots held in each host's own limit, keyed by host. Only hosts with a
    /// request in flight or queued appear.
    required Map<String, int> activeByHost,

    /// Requests queued for each host's own limit, keyed by host.
    required Map<String, int> waitingByHost,

    /// Slots held in the global limit; 0 without one.
    required int globalActive,

    /// Requests queued for the global limit; 0 without one.
    required int globalWaiting,
  }) = _ConcurrencyLimitStatistics;
}
