import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/log_config.freezed.dart';

/// HTTP logging settings; a non-null box adds `HttpLogInterceptor`.
@freezed
abstract class LogConfig with _$LogConfig {
  /// Creates logging settings. Defaults match `HttpLogInterceptor()`.
  const factory({
    /// Logs the request line and options.
    @Default(true) bool request,

    /// Logs request headers.
    @Default(true) bool requestHeader,

    /// Logs the request body.
    @Default(true) bool requestBody,

    /// Logs response headers.
    @Default(false) bool responseHeader,

    /// Logs the response body.
    @Default(true) bool responseBody,

    /// Logs errors.
    @Default(true) bool error,

    /// Printer for HTTP logs and diagnostics; null prints to the console.
    void Function(Object? object)? logPrint,

    /// Whether interceptors print their diagnostics through [logPrint].
    @Default(true) bool diagnostics,
  }) = _LogConfig;
}
