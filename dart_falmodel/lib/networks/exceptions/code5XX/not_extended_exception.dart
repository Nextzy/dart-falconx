import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 510 Not Extended responses.
///
/// Raised when further extensions are required for the server to fulfill
/// the request.
class NetworkNotExtendedException extends NetworkServerException {
  /// Creates a [NetworkNotExtendedException].
  const NetworkNotExtendedException({
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
