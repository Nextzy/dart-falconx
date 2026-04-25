import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 414 URI Too Long responses.
///
/// Raised when the URI provided in the request is longer than the server
/// is willing to interpret.
class NetworkUriTooLongException extends NetworkClientException {
  /// Creates a [NetworkUriTooLongException].
  const NetworkUriTooLongException({
    super.statusCode = 414,
    super.type = NetworkErrorType.uriTooLong,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
