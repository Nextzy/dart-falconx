import 'package:dart_falmodel/lib.dart';

class NetworkInvalidException extends NetworkClientException {
  const NetworkInvalidException({
    super.statusCode = 422,
    super.type = NetworkErrorType.unprocessableContent,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
