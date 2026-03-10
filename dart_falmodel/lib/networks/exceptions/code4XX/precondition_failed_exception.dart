import 'package:dart_falmodel/lib.dart';

class NetworkPreconditionFailedException extends NetworkClientException {
  const NetworkPreconditionFailedException({
    super.statusCode = 412,
    super.type = NetworkErrorType.preconditionFailed,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
