import 'package:dart_falconnect/lib.dart';

class DefaultNetworkExceptionHandlerInterceptor
    extends NetworkExceptionHandlerInterceptor {
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
