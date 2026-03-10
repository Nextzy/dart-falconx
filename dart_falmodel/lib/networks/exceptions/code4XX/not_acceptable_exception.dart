import 'package:dart_falmodel/lib.dart';

class NetworkNotAcceptableException extends NetworkClientException {
  const NetworkNotAcceptableException({
    super.statusCode = 406,
    super.type = NetworkErrorType.notAcceptable,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
