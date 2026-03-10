import 'package:dart_falmodel/lib.dart';

class NetworkGatewayTimeoutException extends NetworkServerException {
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

  final int? timeout;
}
