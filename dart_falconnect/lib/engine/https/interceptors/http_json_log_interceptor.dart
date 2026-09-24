import 'dart:convert';

import 'package:dart_falconnect/engine/https/config/log_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/cache_interceptor.dart';
import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falconnect/engine/https/interceptors/retry_interceptor.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/log_redaction.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:dio/dio.dart';

/// Logs each HTTP attempt as one JSON line with OpenTelemetry field names,
/// for a server whose stdout feeds a log aggregator.
///
/// `onRequest` stamps the start time; `onResponse` and `onError` print the
/// line and pass the request on, so it never resolves or rejects. Placed
/// before `RetryInterceptor`, as `BaseHttpClient` places it at position 2,
/// it prints one line per attempt, and the duration includes the time spent
/// in the limiters' queues. An attempt that failed before this interceptor
/// saw it logs a duration of 0.
///
/// Sensitive headers and query values print as `REDACTED`; bodies, when
/// enabled, are never redacted.
class HttpJsonLogInterceptor extends Interceptor {
  /// Creates a JSON log.
  ///
  /// Throws an [ArgumentError] when `config.maxBodyBytes` is negative.
  new({this.config = const JsonLogConfig()}) {
    if (config.maxBodyBytes < 0) {
      throw ArgumentError.value(
        config.maxBodyBytes,
        'maxBodyBytes',
        'must not be negative',
      );
    }
  }

  /// Which headers and bodies to add, and what to redact.
  final JsonLogConfig config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // A new map: extra may be const.
    options.extra = {...options.extra, logStartKey: clock.now()};
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _print(response.requestOptions, response, null);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _print(err.requestOptions, err.response, err.type);
    handler.next(err);
  }

  /// Prints the line of one attempt. A printer that throws is ignored, so
  /// logging never fails a request.
  void _print(
    RequestOptions options,
    Response<dynamic>? response,
    DioExceptionType? errorType,
  ) {
    try {
      final line = _line(options, response, errorType);
      final printer = config.logPrint;
      if (printer != null) {
        printer(line);
      } else {
        // The JSON log writes to stdout when the config sets no printer.
        // ignore: avoid_print
        print(line);
      }
    } on Object {
      // A broken log sink must not turn a finished request into a failure.
    }
  }

  /// The JSON line of one attempt, or a minimal `WARN` line when a header or
  /// body value cannot be turned into text.
  String _line(
    RequestOptions options,
    Response<dynamic>? response,
    DioExceptionType? errorType,
  ) {
    try {
      return jsonEncode(_fields(options, response, errorType));
    } on Object {
      return jsonEncode({
        'timestamp': clock.now().toUtc().toIso8601String(),
        'severity_text': 'WARN',
        'body':
            '${options.method.toUpperCase()} ${options.uri.host} (log failed)',
      });
    }
  }

  Map<String, Object?> _fields(
    RequestOptions options,
    Response<dynamic>? response,
    DioExceptionType? errorType,
  ) {
    final now = clock.now();
    final start = options.extra[logStartKey];
    final duration = start is DateTime ? now.difference(start) : Duration.zero;
    final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
    final status = response?.statusCode;
    final outcome = _outcome(status, errorType);
    final method = options.method.toUpperCase();
    final url = redactUrl(options.uri, config.redactQueryParameters);
    final cacheHit = response?.isCacheHit ?? false;
    final resendCount = options.retryAttempt;
    return {
      'timestamp': now.toUtc().toIso8601String(),
      'severity_text': outcome.severity,
      'body':
          '$method $url ${outcome.errorType ?? status} '
          '${seconds.toStringAsFixed(3)}s${cacheHit ? ' (cache)' : ''}',
      'http.request.method': method,
      'url.full': url,
      'server.address': options.uri.host,
      'server.port': options.uri.port,
      'http.response.status_code': ?status,
      'error.type': ?outcome.errorType,
      'http.client.request.duration': seconds,
      if (resendCount > 0) 'http.request.resend_count': resendCount,
      if (cacheHit) 'falconx.cache.hit': true,
      if (response?.isLocalRateLimit ?? false) 'falconx.rate_limit.local': true,
      if (config.requestHeaders) ..._headers('request', options.headers),
      if (config.responseHeaders && response != null)
        ..._headers('response', response.headers.map),
      if (config.requestBody) ..._body('request', options.data),
      if (config.responseBody && response != null)
        ..._body(
          'response',
          options.responseType == ResponseType.stream
              ? '<stream>'
              : response.data,
        ),
    };
  }

  /// `http.<side>.header.<lower-case name>` for each header, redacted.
  Map<String, List<String>> _headers(
    String side,
    Map<String, Object?> headers,
  ) => {
    for (final MapEntry(:key, :value) in headers.entries)
      'http.$side.header.${key.toLowerCase()}': logHeader(
        key,
        value,
        config.redactHeaders,
      ),
  };

  /// `falconx.<side>.body` and its truncation flag; nothing for no body.
  Map<String, Object> _body(String side, Object? data) {
    if (data == null) return const {};
    final cut = truncateUtf8(_bodyText(data), config.maxBodyBytes);
    return {
      'falconx.$side.body': cut.text,
      if (cut.truncated) 'falconx.$side.body.truncated': true,
    };
  }

  /// Severity and `error.type` of an attempt; a status decides when there
  /// is one, else the exception type.
  static ({String severity, String? errorType}) _outcome(
    int? status,
    DioExceptionType? errorType,
  ) {
    if (status != null) {
      if (status >= 500) return (severity: 'ERROR', errorType: '$status');
      // A status below 400 that validateStatus rejected is still a failure.
      if (status >= 400 || errorType != null) {
        return (severity: 'WARN', errorType: '$status');
      }
      return (severity: 'INFO', errorType: null);
    }
    return switch (errorType) {
      null => (severity: 'INFO', errorType: null),
      DioExceptionType.cancel => (severity: 'INFO', errorType: 'cancel'),
      _ => (severity: 'ERROR', errorType: errorType.name),
    };
  }

  static String _bodyText(Object data) {
    if (data is String) return data;
    if (data is FormData) {
      return jsonEncode({
        'fields': [for (final field in data.fields) field.key],
        'files': [
          for (final file in data.files) file.value.filename ?? file.key,
        ],
      });
    }
    if (data is Map || data is List) {
      try {
        return jsonEncode(data);
        // jsonEncode wraps whatever a toJson throws in an Error.
      } on Object {
        return data.toString();
      }
    }
    return data.toString();
  }
}
