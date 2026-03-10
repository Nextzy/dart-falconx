import 'package:dart_falmodel/lib.dart';

class NetworkLimitExceededException extends NetworkClientException {
  const NetworkLimitExceededException({
    super.statusCode = 429,
    super.type = NetworkErrorType.tooManyRequests,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
