import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 401 Unauthorized responses.
///
/// Alias for [NetworkAuthenticationException] — both represent 401 for
/// backward compatibility.
class UnauthorizedException extends NetworkClientException {
  /// Creates an [UnauthorizedException].
  const UnauthorizedException({
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
