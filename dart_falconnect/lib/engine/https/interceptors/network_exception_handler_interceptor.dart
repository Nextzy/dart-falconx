// Ignore because is not necessary
// ignore_for_file: avoid_dynamic_calls

import 'package:dart_falconnect/lib.dart';

/// Support Error Response:
/// {
///   "type": "ERROR_TYPE",
///   "message": "Message show to user",
///   "developerMessage": "Message show to developer",
///   "errors": {
///     ...
///   }
/// }
abstract class NetworkExceptionHandlerInterceptor extends QueuedInterceptor {
  NetworkExceptionHandlerInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    final exception = err.toException();
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      final timeout = err.requestOptions.connectTimeout;
      handler.reject(
        err.copyWith(
          error: exception,
          stackTrace: err.stackTrace,
        ),
      );
    } else if (_isServerError(response)) {
      onServerError(err.copyWith(error: exception), handler);
    } else if (_isClientError(response)) {
      onClientError(err.copyWith(error: exception), handler);
    } else {
      onNonStandardError(err, handler);
    }
  }

  void onClientError(DioException err, ErrorInterceptorHandler handler);

  void onServerError(DioException err, ErrorInterceptorHandler handler);

  void onNonStandardError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }

  bool _isClientError(Response? response) =>
      response != null &&
      (response.statusCode ?? 0) >= 400 &&
      (response.statusCode ?? 0) < 500;

  bool _isServerError(Response? response) =>
      response != null &&
      (response.statusCode ?? 0) >= 500 &&
      (response.statusCode ?? 0) < 600;
}
