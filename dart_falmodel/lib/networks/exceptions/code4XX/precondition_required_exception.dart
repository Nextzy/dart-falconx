import 'package:dart_falmodel/lib.dart';

class NetworkPreconditionRequiredException extends NetworkClientException {
  const NetworkPreconditionRequiredException({
    super.statusCode = 428,
    super.type = NetworkErrorType.preconditionRequired,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
