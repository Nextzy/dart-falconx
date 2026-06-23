import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 429 Too Many Requests responses.
///
/// Raised when the client has sent too many requests in a given time window.
class NetworkLimitExceededException extends NetworkClientException {
  /// Creates a [NetworkLimitExceededException].
  const NetworkLimitExceededException({
    super.statusCode = 429,
    super.type = NetworkErrorType.tooManyRequests,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
