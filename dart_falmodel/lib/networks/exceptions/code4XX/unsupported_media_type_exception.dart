import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 415 Unsupported Media Type responses.
///
/// Raised when the request's media type is not supported by the server.
class NetworkUnsupportedMediaTypeException extends NetworkClientException {
  /// Creates a [NetworkUnsupportedMediaTypeException].
  const NetworkUnsupportedMediaTypeException({
    super.statusCode = 415,
    super.type = NetworkErrorType.unsupportedMediaType,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
