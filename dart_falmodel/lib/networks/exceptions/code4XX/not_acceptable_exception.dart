import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 406 Not Acceptable responses.
///
/// Raised when the server cannot produce a response matching the client's
/// Accept headers.
class NetworkNotAcceptableException extends NetworkClientException {
  /// Creates a [NetworkNotAcceptableException].
  const NetworkNotAcceptableException({
    super.statusCode = 406,
    super.type = NetworkErrorType.notAcceptable,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
