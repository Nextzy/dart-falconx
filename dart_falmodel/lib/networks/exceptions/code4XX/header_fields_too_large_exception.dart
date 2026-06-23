import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 431 Request Header Fields Too Large responses.
///
/// Raised when the server refuses to process the request because header
/// fields are too large.
class NetworkHeaderFieldsTooLargeException extends NetworkClientException {
  /// Creates a [NetworkHeaderFieldsTooLargeException].
  const NetworkHeaderFieldsTooLargeException({
    super.statusCode = 431,
    super.type = NetworkErrorType.headerFieldsTooLarge,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
