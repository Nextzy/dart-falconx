import 'package:dart_falmodel/src/src.dart';

/// Exception representing HTTP 510 Not Extended responses.
///
/// Raised when further extensions are required for the server to fulfill
/// the request.
class NetworkNotExtendedException extends NetworkServerException {
  /// Creates a [NetworkNotExtendedException].
  const new({
    super.statusCode = 510,
    super.type = NetworkErrorType.notExtended,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
