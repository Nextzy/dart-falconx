import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 502 Bad Gateway responses.
///
/// Raised when the server received an invalid response from an upstream server.
class NetworkBadGatewayException extends NetworkServerException {
  /// Creates a [NetworkBadGatewayException].
  const NetworkBadGatewayException({
    super.statusCode = 502,
    super.type = NetworkErrorType.badGateway,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
