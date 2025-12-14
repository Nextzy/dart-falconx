import 'package:dart_falmodel/lib.dart';

class NetworkInternalServerException extends NetworkServerException {
  const NetworkInternalServerException({
    super.statusCode = 500,
    super.type,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
