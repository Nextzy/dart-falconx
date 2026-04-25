import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 428 Precondition Required responses.
///
/// Raised when the server requires the request to be conditional.
class NetworkPreconditionRequiredException extends NetworkClientException {
  /// Creates a [NetworkPreconditionRequiredException].
  const NetworkPreconditionRequiredException({
    super.statusCode = 428,
    super.type = NetworkErrorType.preconditionRequired,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
