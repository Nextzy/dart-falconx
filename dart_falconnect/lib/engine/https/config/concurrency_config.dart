import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/concurrency_config.freezed.dart';

/// Concurrency limit settings; a non-null box adds
/// `ConcurrencyLimitInterceptor`.
@freezed
abstract class ConcurrencyConfig with _$ConcurrencyConfig {
  /// Creates concurrency limit settings. Every scope is unlimited until it
  /// gets a number.
  const factory({
    /// Most requests in flight to all hosts together; null means no limit.
    int? global,

    /// Most requests in flight to a host missing from [hosts]; null means
    /// no limit.
    int? perHost,

    /// Per-host limits keyed by bare lowercase host; a null value opts the
    /// host out of [perHost].
    @Default(<String, int?>{}) Map<String, int?> hosts,

    /// Whether a request with no free slot waits (`true`) or is rejected.
    @Default(true) bool queueRequests,

    /// Queue capacity of each host limit.
    @Default(50) int maxQueueSize,

    /// Queue capacity of the global limit.
    @Default(500) int maxGlobalQueueSize,
  }) = _ConcurrencyConfig;
}
