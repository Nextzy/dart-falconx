import 'package:dart_falmodel/src/src.dart';

/// Exception representing HTTP 409 Conflict responses.
///
/// Raised when the request conflicts with the current state of the resource.
class NetworkConflictException extends NetworkClientException {
  /// Creates a [NetworkConflictException].
  const new({
    super.statusCode = 409,
    super.type = NetworkErrorType.conflict,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
