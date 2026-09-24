import 'package:dart_falconnect/lib.dart';

/// The shared [BaseHttpClient]. Its default configuration gives JSON
/// content type, 20-second connect and receive timeouts, and
/// [DefaultNetworkExceptionHandlerInterceptor]; call [configure] to change
/// it at any time.
class DefaultHttpClient extends BaseHttpClient {
  new _singleton({required super.dio});

  /// The shared instance.
  static final DefaultHttpClient instance = DefaultHttpClient._singleton(
    dio: Dio(),
  );
}
