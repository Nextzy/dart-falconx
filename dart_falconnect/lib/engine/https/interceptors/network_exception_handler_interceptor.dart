import 'package:dart_falconnect/lib.dart';

/// Abstract queued interceptor that routes Dio errors to typed handler methods
/// based on HTTP status-code ranges.
///
/// Subclasses must implement [onClientError] (4xx) and [onServerError] (5xx).
/// Connection timeouts are converted to [NetworkTimeoutException] before
/// dispatch. Errors that match neither range are forwarded to
/// [onNonStandardError], which defaults to calling `handler.next`.
///
/// Expected server error-response shape:
/// ```json
/// {
///   "type": "ERROR_TYPE",
///   "message": "Message shown to user",
///   "developerMessage": "Message shown to developer",
///   "errors": { ... }
/// }
/// ```
abstract class NetworkExceptionHandlerInterceptor extends QueuedInterceptor {
  /// Creates a [NetworkExceptionHandlerInterceptor].
  NetworkExceptionHandlerInterceptor();

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final response = err.response;
    final exception = err.toException();
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      final timeout = err.requestOptions.connectTimeout;

      handler.reject(
        err.copyWith(
          error: NetworkTimeoutException(
            timeout: timeout,
            requestOptions: err.requestOptions,
            response: err.response,
            userMessage: err.message,
            stackTrace: err.stackTrace,
          ),
          stackTrace: err.stackTrace,
        ),
      );
    } else if (_isServerError(response)) {
      onServerError(
        err.copyWith(error: exception),
        handler,
      );
    } else if (_isClientError(response)) {
      onClientError(
        err.copyWith(error: exception),
        handler,
      );
    } else {
      onNonStandardError(err, handler);
    }
  }

  /// Called when the response status code is in the 4xx range.
  ///
  /// Implementors may resolve, reject, or forward [err] via [handler].
  void onClientError(
    DioException err,
    ErrorInterceptorHandler handler,
  );

  /// Called when the response status code is in the 5xx range.
  ///
  /// Implementors may resolve, reject, or forward [err] via [handler].
  void onServerError(
    DioException err,
    ErrorInterceptorHandler handler,
  );

  /// Called when the error does not fall into the 4xx or 5xx ranges.
  ///
  /// Defaults to forwarding [err] via `handler.next`. Override to add
  /// custom handling for non-standard errors.
  void onNonStandardError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    handler.next(err);
  }

  bool _isClientError(Response<dynamic>? response) =>
      response != null &&
      (response.statusCode ?? 0) >= 400 &&
      (response.statusCode ?? 0) < 500;

  bool _isServerError(Response<dynamic>? response) =>
      response != null &&
      (response.statusCode ?? 0) >= 500 &&
      (response.statusCode ?? 0) < 600;
}
