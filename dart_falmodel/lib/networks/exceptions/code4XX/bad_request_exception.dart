import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 400 Bad Request responses.
///
/// Raised when the server cannot process the request due to malformed syntax.
class NetworkBadRequestException extends NetworkClientException {
  /// Creates a [NetworkBadRequestException].
  const NetworkBadRequestException({
    super.statusCode = 400,
    super.type = NetworkErrorType.badRequest,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
