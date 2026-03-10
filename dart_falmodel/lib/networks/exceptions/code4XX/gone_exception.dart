import 'package:dart_falmodel/lib.dart';

class NetworkGoneException extends NetworkClientException {
  const NetworkGoneException({
    super.statusCode = 410,
    super.type = NetworkErrorType.gone,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
