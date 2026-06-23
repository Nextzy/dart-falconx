import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 401 Unauthorized responses.
///
/// Raised when a request requires authentication and none was provided.
class NetworkAuthenticationException extends NetworkClientException {
  /// Creates a [NetworkAuthenticationException].
  const NetworkAuthenticationException({
    super.statusCode = 401,
    super.type = NetworkErrorType.unauthorized,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
