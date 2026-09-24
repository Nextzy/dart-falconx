import 'dart:collection';

import 'package:dart_falconnect/engine/https/config/performance_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/models/performance_statistics.dart';
import 'package:dart_falconnect/engine/https/interceptors/models/request_metrics.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:dio/dio.dart';

/// Mutable accumulator behind [PerformanceInterceptor]'s immutable
/// [PerformanceStatistics] snapshots.
class _PerformanceAccumulator {
  int totalRequests = 0;
  int successfulRequests = 0;
  int failedRequests = 0;
  final Map<int, int> statusCodeCounts = {};
  final Map<String, int> errorCounts = {};
  int totalRequestSize = 0;
  int totalResponseSize = 0;
  Duration totalDuration = Duration.zero;
  Duration minDuration = const Duration(days: 365);
  Duration maxDuration = Duration.zero;
  final List<Duration> recentDurations = [];
  static const int _maxRecentDurations = 100;

  /// Incorporates [metrics] from a completed request into the aggregated
  /// statistics.
  void addMetrics(RequestMetrics metrics) {
    totalRequests++;

    if (metrics.statusCode != null &&
        metrics.statusCode! >= 200 &&
        metrics.statusCode! < 300) {
      successfulRequests++;
    } else {
      failedRequests++;
    }

    if (metrics.statusCode != null) {
      statusCodeCounts[metrics.statusCode!] =
          (statusCodeCounts[metrics.statusCode!] ?? 0) + 1;
    }

    if (metrics.error != null) {
      errorCounts[metrics.error!] = (errorCounts[metrics.error!] ?? 0) + 1;
    }

    if (metrics.requestSize != null) {
      totalRequestSize += metrics.requestSize!;
    }

    if (metrics.responseSize != null) {
      totalResponseSize += metrics.responseSize!;
    }

    final duration = metrics.totalDuration;
    totalDuration += duration;

    if (duration < minDuration) {
      minDuration = duration;
    }

    if (duration > maxDuration) {
      maxDuration = duration;
    }

    recentDurations.add(duration);
    if (recentDurations.length > _maxRecentDurations) {
      recentDurations.removeAt(0);
    }
  }

  /// Zeroes every counter, as an empty snapshot would read.
  void reset() {
    totalRequests = 0;
    successfulRequests = 0;
    failedRequests = 0;
    statusCodeCounts.clear();
    errorCounts.clear();
    totalRequestSize = 0;
    totalResponseSize = 0;
    totalDuration = Duration.zero;
    minDuration = const Duration(days: 365);
    maxDuration = Duration.zero;
    recentDurations.clear();
  }

  /// Builds the immutable snapshot of the current counters.
  PerformanceStatistics snapshot() => PerformanceStatistics(
    totalRequests: totalRequests,
    successfulRequests: successfulRequests,
    failedRequests: failedRequests,
    statusCodeCounts: Map.unmodifiable(statusCodeCounts),
    errorCounts: Map.unmodifiable(errorCounts),
    totalRequestSize: totalRequestSize,
    totalResponseSize: totalResponseSize,
    totalDuration: totalDuration,
    minDuration: minDuration,
    maxDuration: maxDuration,
    recentDurations: List.unmodifiable(recentDurations),
  );
}

/// Interceptor that monitors HTTP request performance.
///
/// This interceptor collects detailed performance metrics for
/// each request and provides aggregated statistics.
class PerformanceInterceptor extends Interceptor {
  /// Creates a new performance interceptor.
  new({this.config = const PerformanceConfig(), this.logPrint});

  /// History size and timing detail.
  final PerformanceConfig config;

  /// Prints diagnostics; null prints nothing.
  final void Function(String message)? logPrint;

  /// Maximum number of detailed metrics to keep in memory.
  int get maxMetricsHistory => config.maxMetricsHistory;

  /// Recent request metrics.
  final Queue<RequestMetrics> _metricsHistory = Queue<RequestMetrics>();

  /// Aggregated statistics.
  final _PerformanceAccumulator _statistics = _PerformanceAccumulator();

  /// Metrics by URL pattern.
  final Map<String, _PerformanceAccumulator> _urlStatistics = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Create metrics for this request
    final metrics = RequestMetrics(
      method: options.method,
      url: options.uri.toString(),
      startTime: clock.now(),
      requestSize: _estimateRequestSize(options),
    );

    // Store metrics in request options
    options.extra['performanceMetrics'] = metrics;

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // Get metrics from request
    final metrics =
        response.requestOptions.extra['performanceMetrics'] as RequestMetrics?;
    if (metrics == null) {
      return handler.next(response);
    }

    // Complete the metrics snapshot and record the copy
    final completed = metrics.copyWith(
      endTime: clock.now(),
      statusCode: response.statusCode,
      responseSize: _estimateResponseSize(response),
    );
    _addMetrics(completed);

    _log(
      '${completed.method} ${completed.url} - '
      '${completed.totalDuration.inMilliseconds}ms, '
      'status: ${completed.statusCode}, '
      'response: ${completed.responseSize} bytes',
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Get metrics from request
    final metrics =
        err.requestOptions.extra['performanceMetrics'] as RequestMetrics?;
    if (metrics == null) {
      return handler.next(err);
    }

    // Complete the metrics snapshot and record the copy
    final response = err.response;
    final completed = metrics.copyWith(
      endTime: clock.now(),
      statusCode: response?.statusCode,
      error: err.type.toString(),
      responseSize: response == null ? null : _estimateResponseSize(response),
    );
    _addMetrics(completed);

    _log(
      '${completed.method} ${completed.url} - '
      'FAILED: '
      '${completed.totalDuration.inMilliseconds}ms, '
      'error: ${completed.error}',
    );

    handler.next(err);
  }

  void _log(String message) =>
      logPrint?.call('[PerformanceInterceptor] $message');

  /// Adds metrics to history and updates statistics.
  void _addMetrics(RequestMetrics metrics) {
    // Add to history
    _metricsHistory.add(metrics);
    if (_metricsHistory.length > maxMetricsHistory) {
      _metricsHistory.removeFirst();
    }

    // Update global statistics
    _statistics.addMetrics(metrics);

    // Update URL pattern statistics
    final urlPattern = _getUrlPattern(metrics.url);
    _urlStatistics
        .putIfAbsent(urlPattern, _PerformanceAccumulator.new)
        .addMetrics(metrics);
  }

  /// Gets a normalized URL pattern for grouping
  /// statistics.
  String _getUrlPattern(String url) {
    try {
      final uri = Uri.parse(url);

      // Remove query parameters and numeric path
      // segments
      final pathSegments = uri.pathSegments
          .map((segment) => int.tryParse(segment) != null ? '{id}' : segment)
          .toList();

      return '${uri.scheme}://${uri.host}'
          '/${pathSegments.join('/')}';
      // URI parsing may throw FormatException or other types.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      return url;
    }
  }

  /// Estimates the size of a request in bytes.
  int _estimateRequestSize(RequestOptions options) {
    var size = 0;

    // Add method and URL
    size += options.method.length + options.uri.toString().length;

    // Add headers
    options.headers.forEach((key, value) {
      size += key.length + value.toString().length;
    });

    // Add body
    if (options.data != null) {
      if (options.data is String) {
        size += (options.data as String).length;
      } else if (options.data is List<int>) {
        size += (options.data as List<int>).length;
      } else if (options.data is FormData) {
        // Estimate FormData size
        final formData = options.data as FormData;
        for (final field in formData.fields) {
          size += field.key.length + field.value.length;
        }
        // Note: File sizes are not included in this
        // estimate
      }
    }

    return size;
  }

  /// Estimates the size of a response in bytes.
  int _estimateResponseSize(Response<dynamic> response) {
    var size = 0;

    // Add status line
    size += 20; // Approximate size of status line

    // Add headers
    response.headers.forEach((key, values) {
      size += key.length;
      for (final value in values) {
        size += value.length;
      }
    });

    // Add body
    if (response.data != null) {
      if (response.data is String) {
        size += (response.data as String).length;
      } else if (response.data is List<int>) {
        size += (response.data as List<int>).length;
      }
    }

    return size;
  }

  /// Gets recent performance metrics.
  List<RequestMetrics> getRecentMetrics({int? limit}) {
    final metrics = _metricsHistory.toList();
    if (limit != null && metrics.length > limit) {
      return metrics.sublist(metrics.length - limit);
    }
    return metrics;
  }

  /// Gets an immutable snapshot of the aggregated performance statistics.
  PerformanceStatistics getStatistics() => _statistics.snapshot();

  /// Gets immutable performance statistics snapshots grouped by URL
  /// pattern.
  Map<String, PerformanceStatistics> getUrlStatistics() => Map.unmodifiable({
    for (final entry in _urlStatistics.entries)
      entry.key: entry.value.snapshot(),
  });

  /// Clears all collected metrics and statistics.
  void clear() {
    _metricsHistory.clear();
    _statistics.reset();
    _urlStatistics.clear();
  }
}
