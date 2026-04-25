import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 511 Network Authentication Required responses.
///
/// Raised when the client must authenticate to gain network access.
class NetworkAuthRequiredException extends NetworkServerException {
  /// Creates a [NetworkAuthRequiredException].
  const NetworkAuthRequiredException({
    super.statusCode = 511,
    super.type = NetworkErrorType.networkAuthRequired,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
