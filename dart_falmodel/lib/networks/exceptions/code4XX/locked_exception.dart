import 'package:dart_falmodel/lib.dart';

class NetworkLockedException extends NetworkClientException {
  const NetworkLockedException({
    super.statusCode = 423,
    super.type = NetworkErrorType.locked,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
