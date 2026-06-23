import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 409 Conflict responses.
///
/// Raised when the request conflicts with the current state of the resource.
class NetworkConflictException extends NetworkClientException {
  /// Creates a [NetworkConflictException].
  const NetworkConflictException({
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
