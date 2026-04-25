import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 422 Unprocessable Content responses.
///
/// Raised when the server understands the request but cannot process the
/// contained instructions.
class NetworkInvalidException extends NetworkClientException {
  /// Creates a [NetworkInvalidException].
  const NetworkInvalidException({
    super.statusCode = 422,
    super.type = NetworkErrorType.unprocessableContent,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
