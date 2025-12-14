import 'package:dart_falmodel/lib.dart';

class MethodNotAllowedException extends NetworkClientException {
  const MethodNotAllowedException({
    super.statusCode = 405,
    super.type,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
