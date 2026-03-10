import 'package:dart_falmodel/lib.dart';

class NetworkUnsupportedMediaTypeException extends NetworkClientException {
  const NetworkUnsupportedMediaTypeException({
    super.statusCode = 415,
    super.type = NetworkErrorType.unsupportedMediaType,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
