import 'package:dart_falmodel/lib.dart';

class NetworkNotImplementException extends NetworkServerException {
  const NetworkNotImplementException({
    super.statusCode = 501,
    super.type = NetworkErrorType.notImplemented,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
