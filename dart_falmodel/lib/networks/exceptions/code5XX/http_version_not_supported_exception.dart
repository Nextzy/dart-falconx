import 'package:dart_falmodel/lib.dart';

class NetworkHttpVersionNotSupportedException extends NetworkServerException {
  const NetworkHttpVersionNotSupportedException({
    super.statusCode = 505,
    super.type = NetworkErrorType.httpVersionNotSupported,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
