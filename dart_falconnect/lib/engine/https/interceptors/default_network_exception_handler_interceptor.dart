import 'package:dart_falconnect/lib.dart';

/// Concrete [NetworkExceptionHandlerInterceptor] that rejects every error
/// without custom recovery — all client, server, and non-standard errors are
/// passed to [ErrorInterceptorHandler.reject] as-is.
class DefaultNetworkExceptionHandlerInterceptor
    extends NetworkExceptionHandlerInterceptor {
  /// Creates a [DefaultNetworkExceptionHandlerInterceptor].
  DefaultNetworkExceptionHandlerInterceptor();

  @override
  void onClientError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(err);
  }

  @override
  void onServerError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(err);
  }

  @override
  void onNonStandardError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(err);
  }
}
