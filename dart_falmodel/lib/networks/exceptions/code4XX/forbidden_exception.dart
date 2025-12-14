import 'package:dart_falmodel/lib.dart';

class NetworkForbiddenException extends NetworkClientException {
  const NetworkForbiddenException({
    super.statusCode = 403,
    super.type,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
