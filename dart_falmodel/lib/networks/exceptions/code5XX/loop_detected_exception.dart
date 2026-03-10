import 'package:dart_falmodel/lib.dart';

class NetworkLoopDetectedException extends NetworkServerException {
  const NetworkLoopDetectedException({
    super.statusCode = 508,
    super.type = NetworkErrorType.loopDetected,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
