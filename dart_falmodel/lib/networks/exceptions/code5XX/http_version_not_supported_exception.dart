import 'package:dart_falmodel/src/src.dart';

/// Exception representing HTTP 505 HTTP Version Not Supported responses.
///
/// Raised when the server does not support the HTTP protocol version used
/// in the request.
class NetworkHttpVersionNotSupportedException extends NetworkServerException {
  /// Creates a [NetworkHttpVersionNotSupportedException].
  const new({
    super.statusCode = 505,
    super.type = NetworkErrorType.httpVersionNotSupported,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
