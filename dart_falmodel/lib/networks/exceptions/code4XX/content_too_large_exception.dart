import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 413 Content Too Large responses.
///
/// Raised when the request body exceeds the limit the server is willing
/// to process.
class NetworkContentTooLargeException extends NetworkClientException {
  /// Creates a [NetworkContentTooLargeException].
  const NetworkContentTooLargeException({
    super.statusCode = 413,
    super.type = NetworkErrorType.contentTooLarge,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
