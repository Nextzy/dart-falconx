import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 507 Insufficient Storage responses.
///
/// Raised when the server is unable to store the representation needed
/// to complete the request.
class NetworkInsufficientStorageException extends NetworkServerException {
  /// Creates a [NetworkInsufficientStorageException].
  const NetworkInsufficientStorageException({
    super.statusCode = 507,
    super.type = NetworkErrorType.insufficientStorage,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
