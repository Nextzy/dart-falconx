import 'package:dart_falmodel/lib.dart';

class NetworkNotExtendedException extends NetworkServerException {
  const NetworkNotExtendedException({
    super.statusCode = 510,
    super.type = NetworkErrorType.notExtended,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
