import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 405 Method Not Allowed responses.
///
/// Raised when the HTTP method used is not supported for the target resource.
class MethodNotAllowedException extends NetworkClientException {
  /// Creates a [MethodNotAllowedException].
  const MethodNotAllowedException({
    super.statusCode = 405,
    super.type = NetworkErrorType.methodNotAllowed,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
