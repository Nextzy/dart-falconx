import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 407 Proxy Authentication Required responses.
///
/// Raised when the client must authenticate with the proxy before the
/// request can be fulfilled.
class NetworkProxyAuthRequiredException extends NetworkClientException {
  /// Creates a [NetworkProxyAuthRequiredException].
  const NetworkProxyAuthRequiredException({
    super.statusCode = 407,
    super.type = NetworkErrorType.proxyAuthRequired,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
