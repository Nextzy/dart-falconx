import 'package:dart_falmodel/lib.dart';

class ServiceUnavailableException extends NetworkServerException {
  const ServiceUnavailableException({
    super.statusCode = 503,
    super.type,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
