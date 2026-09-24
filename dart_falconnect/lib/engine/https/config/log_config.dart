import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/log_config.freezed.dart';

/// Headers both logs print as `REDACTED` by default; compared ignoring case.
const Set<String> defaultRedactedHeaders = {
  'authorization',
  'cookie',
  'proxy-authorization',
  'set-cookie',
  'x-api-key',
};

/// Query parameters whose values both logs print as `REDACTED` by default;
/// compared ignoring case. Includes the OpenTelemetry `url.full` defaults.
const Set<String> defaultRedactedQueryParameters = {
  'access_token',
  'api_key',
  'apikey',
  'awsaccesskeyid',
  'key',
  'password',
  'secret',
  'sig',
  'signature',
  'token',
  'x-amz-signature',
  'x-goog-signature',
};

/// HTTP logging settings: a multi-line console log for apps, or one JSON
/// line per attempt for servers. A non-null box adds the matching log
/// interceptor at position 2 of the chain.
@freezed
sealed class LogConfig with _$LogConfig {
  /// Multi-line console log; builds `HttpLogInterceptor`. Defaults match
  /// `HttpLogInterceptor()`.
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

    /// Headers printed as `REDACTED`, compared ignoring case.
    @Default(defaultRedactedHeaders) Set<String> redactHeaders,

    /// Query parameters whose values print as `REDACTED`, compared ignoring
    /// case.
    @Default(defaultRedactedQueryParameters) Set<String> redactQueryParameters,

    /// Printer for HTTP logs and diagnostics; null prints to the console.
    void Function(Object? object)? logPrint,

    /// Whether interceptors print their diagnostics through [logPrint].
    @Default(true) bool diagnostics,
  }) = PrettyLogConfig;

  /// One JSON line per attempt, OpenTelemetry field names; builds
  /// `HttpJsonLogInterceptor`. Headers and bodies are off by default.
  const factory json({
    /// Adds each request header as `http.request.header.<name>`.
    @Default(false) bool requestHeaders,

    /// Adds each response header as `http.response.header.<name>`.
    @Default(false) bool responseHeaders,

    /// Adds the request body as `falconx.request.body`.
    @Default(false) bool requestBody,

    /// Adds the response body as `falconx.response.body`.
    @Default(false) bool responseBody,

    /// Most UTF-8 bytes of a logged body; a longer body is cut and flagged.
    @Default(4096) int maxBodyBytes,

    /// Headers logged as `["REDACTED"]`, compared ignoring case. Bodies are
    /// never redacted.
    @Default(defaultRedactedHeaders) Set<String> redactHeaders,

    /// Query parameters whose values log as `REDACTED`, compared ignoring
    /// case.
    @Default(defaultRedactedQueryParameters) Set<String> redactQueryParameters,

    /// Printer for HTTP logs and diagnostics; null prints to stdout.
    void Function(Object? object)? logPrint,

    /// Whether interceptors print their diagnostics through [logPrint], as
    /// JSON lines inside a `BaseHttpClient`.
    @Default(true) bool diagnostics,
  }) = JsonLogConfig;
}
