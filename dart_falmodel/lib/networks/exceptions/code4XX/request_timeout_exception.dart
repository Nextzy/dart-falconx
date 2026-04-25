import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 408 Request Timeout responses.
///
/// Raised when the server timed out waiting for the client's request.
class NetworkTimeoutException extends NetworkClientException {
  /// Creates a [NetworkTimeoutException].
  const NetworkTimeoutException({
    super.statusCode = 408,
    super.type = NetworkErrorType.requestTimeout,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
    this.timeout,
  });

  /// The duration after which the request was considered timed out.
  final Duration? timeout;
}
