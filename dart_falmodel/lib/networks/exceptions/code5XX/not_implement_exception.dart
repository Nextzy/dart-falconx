import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 501 Not Implemented responses.
///
/// Raised when the server does not support the functionality required to
/// fulfill the request.
// Note: The class name intentionally omits "ed" in "Implemented" — preserved
// for backward compatibility.
class NetworkNotImplementException extends NetworkServerException {
  /// Creates a [NetworkNotImplementException].
  const NetworkNotImplementException({
    super.statusCode = 501,
    super.type = NetworkErrorType.notImplemented,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
