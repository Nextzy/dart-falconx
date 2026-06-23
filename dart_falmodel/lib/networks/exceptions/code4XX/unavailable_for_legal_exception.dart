import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 451 Unavailable For Legal Reasons responses.
///
/// Raised when the server is denying access to the resource due to
/// legal demands.
class NetworkUnavailableForLegalException extends NetworkClientException {
  /// Creates a [NetworkUnavailableForLegalException].
  const NetworkUnavailableForLegalException({
    super.statusCode = 451,
    super.type = NetworkErrorType.unavailableForLegal,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
