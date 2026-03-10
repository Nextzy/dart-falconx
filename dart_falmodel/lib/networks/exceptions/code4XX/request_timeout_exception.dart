import 'package:dart_falmodel/lib.dart';

class NetworkTimeoutException extends NetworkClientException {
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

  final Duration? timeout;
}
