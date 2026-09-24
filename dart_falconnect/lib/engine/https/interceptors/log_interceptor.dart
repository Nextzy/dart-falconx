import 'package:dart_falconnect/lib.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/log_redaction.dart';

/// Prints each request, response, and error over several console lines,
/// for a developer watching an app's console.
///
/// `BaseHttpClient` places it at position 2 of the chain, after the app's
/// own interceptors, so it sees what they changed. Every response and
/// error prints its status and duration. The URL, request headers, and
/// response headers print redacted: see [redactHeaders] and
/// [redactQueryParameters].
class HttpLogInterceptor extends Interceptor {
  /// Creates an [HttpLogInterceptor].
  ///
  /// Each boolean flag controls which parts of the request/response cycle are
  /// logged. [logPrint] defaults to a chunked console printer that avoids
  /// truncation on long payloads. Colour follows `ansiColorDisabled`, which
  /// this class never writes.
  new({
    this.enabled = true,
    this.request = true,
    this.requestHeader = true,
    this.requestBody = true,
    this.responseHeader = false,
    this.responseBody = true,
    this.error = true,
    this.redactHeaders = defaultRedactedHeaders,
    this.redactQueryParameters = defaultRedactedQueryParameters,
    this.logPrint = _logPrintLong,
  });

  final AnsiPen _title = AnsiPen()..white(bold: true);
  final AnsiPen _error = AnsiPen()..red(bold: true);
  final AnsiPen _json = AnsiPen()..green(bold: true);

  /// Whether logging is active. When `false`, all log output is suppressed.
  bool enabled;

  /// Print request [Options]
  bool request;

  /// Print request header [Options.headers]
  bool requestHeader;

  /// Print request data
  bool requestBody;

  /// Print [Response.data]
  bool responseBody;

  /// Print [Response.headers]
  bool responseHeader;

  /// Print error message
  bool error;

  /// Headers printed as `REDACTED`, compared ignoring case.
  Set<String> redactHeaders;

  /// Query parameters whose values print as `REDACTED`, compared ignoring
  /// case.
  Set<String> redactQueryParameters;

  /// Log printer; defaults print log to console.
  /// In flutter, you'd better use debugPrint.
  /// you can also write log in a file, for example:
  ///```dart
  ///  var file=File("./log.txt");
  ///  var sink=file.openWrite();
  ///  dio.interceptors.add(
  ///    LogInterceptor(logPrint: sink.writeln),
  ///  );
  ///  ...
  ///  await sink.close();
  ///```
  void Function(Object? object) logPrint;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // A new map: extra may be const.
    options.extra = {...options.extra, logStartKey: clock.now()};
    if (enabled) {
      logPrint(_title('*** Request ***'));
      _printKV('URL', _url(options.uri));

      if (request) {
        _printKV('method', _title(options.method));
        _printKV('responseType', options.responseType.toString());
        _printKV('followRedirects', options.followRedirects);
        _printKV('connectTimeout', options.connectTimeout);
        _printKV('sendTimeout', options.sendTimeout);
        _printKV('receiveTimeout', options.receiveTimeout);
        _printKV(
          'receiveDataWhenStatusError',
          options.receiveDataWhenStatusError,
        );
        _printKV('extra', options.extra);
      }
      if (requestHeader) {
        logPrint('headers:');
        options.headers.forEach(
          (key, v) => _printKV(
            ' $key',
            _title(
              matchesName(key, redactHeaders)
                  ? redactedValue
                  : v?.toString() ?? '',
            ),
          ),
        );
      }
      if (requestBody) {
        final data = options.data;
        try {
          const encoder = JsonEncoder.withIndent('  ');
          String prettyPrint;
          if (data is FormData) {
            logPrint(_json('Form Data:'));
            final newList = data.fields.map((e) => {e.key: e.value}).toList()
              ..addAll(
                data.files
                    .map((e) => {e.key: _getMultipartFileString(e.value)})
                    .toList(),
              );
            prettyPrint = encoder.convert(newList);
          } else {
            logPrint(_json('Body Data:'));
            prettyPrint = encoder.convert(data);
          }
          _printAll(_json(prettyPrint));
          // Data may not be JSON-encodable.
          // ignore: avoid_catches_without_on_clauses
        } catch (e) {
          _printAll(_json(data?.toString() ?? ''));
        }
      }
      logPrint('');
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (enabled) {
      logPrint(_title('*** Response ***'));
      _printResponse(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      if (error) {
        logPrint(_error('*** DioError ***:'));
        final uri = err.requestOptions.uri;
        logPrint('URL: ${_url(uri)}');
        // An inner error such as dart:io's HttpException prints the raw URI.
        logPrint('$err'.replaceAll('$uri', _url(uri)));
        final response = err.response;
        if (response != null) {
          _printResponse(response);
        } else {
          _printKV('duration', _duration(err.requestOptions));
          logPrint('');
        }
      }
    }

    handler.next(err);
  }

  void _printResponse(Response<dynamic> response) {
    if (enabled) {
      _printKV('URL', _url(response.requestOptions.uri));
      _printKV('statusCode', response.statusCode ?? 0);
      _printKV('duration', _duration(response.requestOptions));
      if (responseHeader) {
        if (response.isRedirect) {
          _printKV('redirect', _url(response.realUri));
        }

        logPrint('headers:');
        response.headers.forEach(
          (key, v) => _printKV(
            ' $key',
            matchesName(key, redactHeaders) ? redactedValue : v.join('\r\n\t'),
          ),
        );
      }
      if (responseBody) {
        logPrint(_json('Response Text:'));
        try {
          const encoder = JsonEncoder.withIndent('  ');
          final prettyPrint = encoder.convert(response.data);
          _printAll(_json(prettyPrint));
          // Response data may not be JSON-encodable.
          // ignore: avoid_catches_without_on_clauses
        } catch (e) {
          _printAll(response.data.toString());
        }
      }
      logPrint('');
    }
  }

  String _url(Uri uri) => redactUrl(uri, redactQueryParameters);

  /// Milliseconds since `onRequest`; 0 when this log never saw the request.
  String _duration(RequestOptions options) {
    final start = options.extra[logStartKey];
    final elapsed = start is DateTime
        ? clock.now().difference(start)
        : Duration.zero;
    return '${elapsed.inMilliseconds}ms';
  }

  void _printKV(String key, Object? v) {
    if (enabled) {
      logPrint('$key: $v');
    }
  }

  void _printAll(Object msg) {
    if (enabled) {
      msg.toString().split('\n').forEach(logPrint);
    }
  }

  String _getMultipartFileString(MultipartFile file) {
    return 'Header: ${file.headers}, '
        'Content type: ${file.contentType}, '
        'File name: ${file.filename}, '
        'Length: ${file.length}';
  }

  static void _logPrintLong(Object? object) {
    const defaultPrintLength = 1020;
    if (object == null || object.toString().length <= defaultPrintLength) {
      // Intentional logging for HTTP diagnostics.
      // ignore: avoid_print
      print(object);
    } else {
      final log = object.toString();
      var start = 0;
      var endIndex = defaultPrintLength;
      final logLength = log.length;
      var tmpLogLength = log.length;
      while (endIndex < logLength) {
        // Intentional logging for HTTP diagnostics.
        // ignore: avoid_print
        print(log.substring(start, endIndex));
        endIndex += defaultPrintLength;
        start += defaultPrintLength;
        tmpLogLength -= defaultPrintLength;
      }
      if (tmpLogLength > 0) {
        // Intentional logging for HTTP diagnostics.
        // ignore: avoid_print
        print(log.substring(start, logLength));
      }
    }
  }
}
