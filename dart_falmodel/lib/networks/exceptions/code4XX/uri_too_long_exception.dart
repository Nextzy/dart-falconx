import 'package:dart_falmodel/lib.dart';

class NetworkUriTooLongException extends NetworkClientException {
  const NetworkUriTooLongException({
    super.statusCode = 414,
    super.type = NetworkErrorType.uriTooLong,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
