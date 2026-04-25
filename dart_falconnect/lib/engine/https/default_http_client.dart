import 'package:dart_falconnect/lib.dart';

/// A ready-to-use singleton [BaseHttpClient] with JSON content type,
/// 20-second timeouts, and [DefaultNetworkExceptionHandlerInterceptor].
class DefaultHttpClient extends BaseHttpClient {
  DefaultHttpClient._singleton({required super.dio});

  /// The shared singleton instance used for all health probe API requests.
  static final DefaultHttpClient instance = DefaultHttpClient._singleton(
    dio: Dio(),
  );

  @override
  void setupOptions(Dio dio, BaseOptions options) {
    super.setupOptions(dio, options);
    options
      ..contentType = Headers.jsonContentType
      ..connectTimeout = 20.seconds
      ..receiveTimeout = 20.seconds;
  }

  @override
  void setupInterceptors(Dio dio, Interceptors interceptors) {
    super.setupInterceptors(dio, interceptors);
    interceptors.addAll([
      DefaultNetworkExceptionHandlerInterceptor(),
    ]);
  }
}
