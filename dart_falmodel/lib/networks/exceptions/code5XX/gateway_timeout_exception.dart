import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 504 Gateway Timeout responses.
///
/// Raised when the server acting as a gateway did not receive a timely
/// response from upstream.
class NetworkGatewayTimeoutException extends NetworkServerException {
  /// Creates a [NetworkGatewayTimeoutException].
  const NetworkGatewayTimeoutException({
    super.statusCode = 504,
    super.type = NetworkErrorType.gatewayTimeout,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
    this.timeout,
  });

  /// The timeout duration in seconds, if provided by the server.
  final int? timeout;
}
