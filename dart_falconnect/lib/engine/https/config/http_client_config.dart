import 'dart:async';

import 'package:dart_falconnect/engine/https/config/auth_config.dart';
import 'package:dart_falconnect/engine/https/config/cache_config.dart';
import 'package:dart_falconnect/engine/https/config/concurrency_config.dart';
import 'package:dart_falconnect/engine/https/config/log_config.dart';
import 'package:dart_falconnect/engine/https/config/rate_limit_config.dart';
import 'package:dart_falconnect/engine/https/config/request_id_config.dart';
import 'package:dart_falconnect/engine/https/config/retry_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/network_exception_handler_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/http_client_config.freezed.dart';

/// Returns headers for one request.
typedef HeaderProvider = FutureOr<Map<String, String>> Function(
  RequestOptions options,
);

/// Configuration of a `BaseHttpClient`: the dio options it owns and one box
/// per feature. A null box turns its feature off.
@freezed
abstract class HttpClientConfig with _$HttpClientConfig {
  /// Creates a configuration. The defaults reproduce the options and chain
  /// of `DefaultHttpClient` before configuration existed.
  const factory({
    /// Base URL of every request.
    @Default('') String baseUrl,

    /// Timeout for opening a connection.
    @Default(Duration(seconds: 20)) Duration connectTimeout,

    /// Timeout between two received chunks.
    @Default(Duration(seconds: 20)) Duration receiveTimeout,

    /// Timeout for sending the body; null means no limit.
    Duration? sendTimeout,

    /// Default `Content-Type`.
    @Default(Headers.jsonContentType) String contentType,

    /// Default headers the configuration owns.
    @Default(<String, String>{}) Map<String, String> headers,

    /// `User-Agent` header; null leaves it unset.
    String? userAgent,

    /// Whether dio follows redirects.
    @Default(true) bool followRedirects,

    /// Most redirects followed.
    @Default(5) int maxRedirects,

    /// Which statuses succeed; null keeps dio's default, 2xx only.
    ValidateStatus? validateStatus,

    /// HTTP logging; null turns it off.
    LogConfig? log,

    /// Response cache; null turns it off.
    CacheConfig? cache,

    /// Concurrency limit; null turns it off.
    ConcurrencyConfig? concurrency,

    /// Rate limit and `Retry-After` pause.
    @Default(RateLimitConfig.none()) RateLimitConfig rateLimit,

    /// Retry; null turns it off.
    RetryConfig? retry,

    /// The app's own interceptors, placed first in the chain.
    @Default(<Interceptor>[]) List<Interceptor> interceptors,

    /// Last interceptor of the chain; null means
    /// `DefaultNetworkExceptionHandlerInterceptor`.
    NetworkExceptionHandlerInterceptor? exceptionHandler,

    /// Headers computed for each request; null turns them off. They
    /// override [headers] and lose to the request's own headers.
    HeaderProvider? headerProvider,

    /// Request ID header; null turns it off.
    RequestIdConfig? requestId,

    /// Access token and 401 refresh; null turns them off.
    AuthConfig? auth,
  }) = _HttpClientConfig;

  const new _();

  /// [headers] plus `User-Agent` when [userAgent] is set.
  Map<String, String> get effectiveHeaders => {
    ...headers,
    'User-Agent': ?userAgent,
  };

  /// Writes the options this configuration owns onto `dio.options` and
  /// merges [effectiveHeaders] into its header map. Other fields are left
  /// alone; `validateStatus` is written only when it is not null.
  void applyTo(Dio dio) {
    final options = dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = connectTimeout
      ..receiveTimeout = receiveTimeout
      ..sendTimeout = sendTimeout
      ..contentType = contentType
      ..followRedirects = followRedirects
      ..maxRedirects = maxRedirects;
    if (validateStatus != null) {
      options.validateStatus = validateStatus!;
    }
    options.headers.addAll(effectiveHeaders);
  }
}
