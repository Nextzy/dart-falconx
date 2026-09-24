import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/performance_config.freezed.dart';

/// Performance monitoring settings; a non-null box adds
/// `PerformanceInterceptor`.
@freezed
abstract class PerformanceConfig with _$PerformanceConfig {
  /// Creates performance monitoring settings.
  const factory({
    /// Most request metrics kept in memory.
    @Default(1000) int maxMetricsHistory,

    /// Whether to collect detailed timing information.
    @Default(true) bool collectDetailedTimings,
  }) = _PerformanceConfig;
}
