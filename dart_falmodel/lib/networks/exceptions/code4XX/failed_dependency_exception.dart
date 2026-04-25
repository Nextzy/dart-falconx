import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 424 Failed Dependency responses.
///
/// Raised when the request failed because it depended on another request
/// that failed.
class NetworkFailedDependencyException extends NetworkClientException {
  /// Creates a [NetworkFailedDependencyException].
  const NetworkFailedDependencyException({
    super.statusCode = 424,
    super.type = NetworkErrorType.failedDependency,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
