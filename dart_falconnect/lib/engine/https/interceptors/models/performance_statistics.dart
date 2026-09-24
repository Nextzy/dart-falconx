import 'package:dart_faltool/dart_faltool.dart';

part 'generated/performance_statistics.freezed.dart';
part 'generated/performance_statistics.g.dart';

/// Aggregated performance statistics across multiple requests, as an
/// immutable snapshot of one moment.
///
/// The maps and the [recentDurations] window are unmodifiable: build a
/// new snapshot through the interceptor instead of mutating one.
@freezed
abstract class PerformanceStatistics with _$PerformanceStatistics {
  /// Creates a statistics snapshot.
  const factory({
    /// Total number of requests recorded.
    required int totalRequests,

    /// Number of requests that completed with a 2xx status code.
    required int successfulRequests,

    /// Number of requests that did not complete with a 2xx status code.
    required int failedRequests,

    /// Counts of responses grouped by HTTP status code.
    required Map<int, int> statusCodeCounts,

    /// Counts of errors grouped by error description string.
    required Map<String, int> errorCounts,

    /// Cumulative size of all request bodies in bytes.
    required int totalRequestSize,

    /// Cumulative size of all response bodies in bytes.
    required int totalResponseSize,

    /// Sum of all request durations.
    @DurationMillisecondsConverter() required Duration totalDuration,

    /// Shortest recorded request duration.
    @DurationMillisecondsConverter() required Duration minDuration,

    /// Longest recorded request duration.
    @DurationMillisecondsConverter() required Duration maxDuration,

    /// The most recent request durations, oldest first, capped at 100.
    ///
    /// Excluded from JSON: it is a rolling window, not a report field.
    @JsonKey(includeToJson: false) required List<Duration> recentDurations,
  }) = _PerformanceStatistics;

  /// Deserializes a [PerformanceStatistics] from a JSON map; the
  /// computed getters are recomputed, not read.
  factory fromJson(Map<String, dynamic> json) =>
      _$PerformanceStatisticsFromJson(json);

  const new _();

  /// Returns the mean request duration, or [Duration.zero] if no requests
  /// have been recorded.
  @DurationMillisecondsConverter()
  @JsonKey(includeToJson: true, includeFromJson: false)
  Duration get averageDuration => totalRequests > 0
      ? Duration(milliseconds: totalDuration.inMilliseconds ~/ totalRequests)
      : Duration.zero;

  /// Returns the median request duration from the recent-durations window,
  /// or [Duration.zero] if the window is empty.
  @DurationMillisecondsConverter()
  @JsonKey(includeToJson: true, includeFromJson: false)
  Duration get medianDuration {
    if (recentDurations.isEmpty) return Duration.zero;

    final sorted = List<Duration>.from(recentDurations)..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length.isOdd) {
      return sorted[middle];
    } else {
      return Duration(
        milliseconds:
            (sorted[middle - 1].inMilliseconds +
                sorted[middle].inMilliseconds) ~/
            2,
      );
    }
  }

  /// Returns the percentage of successful requests (0–100), or `0.0` if no
  /// requests have been recorded.
  @JsonKey(includeToJson: true, includeFromJson: false)
  double get successRate =>
      totalRequests > 0 ? successfulRequests / totalRequests * 100 : 0.0;

  /// Mean request body size in bytes across recorded requests.
  @JsonKey(includeToJson: true, includeFromJson: false)
  int get averageRequestSize =>
      totalRequests > 0 ? totalRequestSize ~/ totalRequests : 0;

  /// Mean response body size in bytes across recorded requests.
  @JsonKey(includeToJson: true, includeFromJson: false)
  int get averageResponseSize =>
      totalRequests > 0 ? totalResponseSize ~/ totalRequests : 0;
}
