import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 500 Internal Server Error responses.
///
/// Raised when the server encountered an unexpected condition that prevented
/// it from fulfilling the request.
class NetworkInternalServerException extends NetworkServerException {
  /// Creates a [NetworkInternalServerException].
  const NetworkInternalServerException({
    super.statusCode = 500,
    super.type = NetworkErrorType.internalServerError,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
