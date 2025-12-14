import 'package:dart_falmodel/lib.dart';

class NetworkConflictException extends NetworkClientException {
  const NetworkConflictException({
    super.statusCode = 409,
    super.type,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
