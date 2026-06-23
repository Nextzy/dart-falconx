import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 425 Too Early responses.
///
/// Raised when the server is unwilling to process a request that may
/// be replayed.
class NetworkTooEarlyException extends NetworkClientException {
  /// Creates a [NetworkTooEarlyException].
  const NetworkTooEarlyException({
    super.statusCode = 425,
    super.type = NetworkErrorType.tooEarly,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
