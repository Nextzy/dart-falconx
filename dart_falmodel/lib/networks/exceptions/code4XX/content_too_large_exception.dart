import 'package:dart_falmodel/lib.dart';

class NetworkContentTooLargeException extends NetworkClientException {
  const NetworkContentTooLargeException({
    super.statusCode = 413,
    super.type = NetworkErrorType.contentTooLarge,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
