import 'package:dart_faltool/dart_faltool.dart';

part 'generated/request_metrics.freezed.dart';
part 'generated/request_metrics.g.dart';

/// Performance metrics for a single request.
///
/// Store and read [startTime] and [endTime] in the same clock zone: the
/// `totalDuration` fallback and [toJson] read `clock.now()` in the
/// reader's zone, so reading outside the request's zone reports
/// real-now minus zone-stamped start (a huge or negative duration).
@freezed
abstract class RequestMetrics with _$RequestMetrics {
  /// Creates metrics for a request identified by [method], [url], and
  /// [startTime].
  const factory({
    /// HTTP method (e.g. `GET`, `POST`).
    required String method,

    /// Full request URL.
    required String url,

    /// Timestamp when the request was initiated.
    required DateTime startTime,

    /// Timestamp when the response (or error) was received.
    DateTime? endTime,

    /// HTTP status code of the response, if available.
    int? statusCode,

    /// Error description if the request failed.
    String? error,

    /// Request body size in bytes.
    int? requestSize,

    /// Response body size in bytes.
    int? responseSize,
  }) = _RequestMetrics;

  /// Deserializes a [RequestMetrics] from a JSON map; `totalDuration` is
  /// recomputed, not read.
  factory fromJson(Map<String, dynamic> json) => _$RequestMetricsFromJson(json);

  const new _();

  /// Total request duration; the elapsed time so far while the request is
  /// still in flight.
  @DurationMillisecondsConverter()
  @JsonKey(includeToJson: true, includeFromJson: false)
  Duration get totalDuration => endTime != null
      ? endTime!.difference(startTime)
      : clock.now().difference(startTime);
}
