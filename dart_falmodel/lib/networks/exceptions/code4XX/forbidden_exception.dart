import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 403 Forbidden responses.
///
/// Raised when the server understands the request but refuses to authorize it.
class NetworkForbiddenException extends NetworkClientException {
  /// Creates a [NetworkForbiddenException].
  const NetworkForbiddenException({
    super.statusCode = 403,
    super.type = NetworkErrorType.forbidden,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
