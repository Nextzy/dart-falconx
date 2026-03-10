import 'package:dart_falmodel/lib.dart';

class NetworkHeaderFieldsTooLargeException extends NetworkClientException {
  const NetworkHeaderFieldsTooLargeException({
    super.statusCode = 431,
    super.type = NetworkErrorType.headerFieldsTooLarge,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
