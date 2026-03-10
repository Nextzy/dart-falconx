import 'package:dart_falmodel/lib.dart';

class NetworkLengthRequiredException extends NetworkClientException {
  const NetworkLengthRequiredException({
    super.statusCode = 411,
    super.type = NetworkErrorType.lengthRequired,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
