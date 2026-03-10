import 'package:dart_falmodel/lib.dart';

class NetworkTooEarlyException extends NetworkClientException {
  const NetworkTooEarlyException({
    super.statusCode = 425,
    super.type = NetworkErrorType.tooEarly,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
