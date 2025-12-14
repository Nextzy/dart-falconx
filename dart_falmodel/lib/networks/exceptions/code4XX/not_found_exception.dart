import 'package:dart_falmodel/lib.dart';

class NetworkNotFoundException extends NetworkClientException {
  const NetworkNotFoundException({
    super.statusCode = 404,
    super.type,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
