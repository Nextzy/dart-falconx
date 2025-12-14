import 'package:dart_falmodel/lib.dart';

class NetworkBadRequestException extends NetworkClientException {
  const NetworkBadRequestException({
    super.statusCode = 400,
    super.type,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
