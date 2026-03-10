import 'package:dart_falmodel/lib.dart';

class NetworkExpectationFailedException extends NetworkClientException {
  const NetworkExpectationFailedException({
    super.statusCode = 417,
    super.type = NetworkErrorType.expectationFailed,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
