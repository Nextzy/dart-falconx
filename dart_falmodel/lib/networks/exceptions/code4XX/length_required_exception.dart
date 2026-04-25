import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 411 Length Required responses.
///
/// Raised when the server requires a Content-Length header that is absent.
class NetworkLengthRequiredException extends NetworkClientException {
  /// Creates a [NetworkLengthRequiredException].
  const NetworkLengthRequiredException({
    super.statusCode = 411,
    super.type = NetworkErrorType.lengthRequired,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
