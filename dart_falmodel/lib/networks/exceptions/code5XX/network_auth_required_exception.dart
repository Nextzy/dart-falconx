import 'package:dart_falmodel/lib.dart';

class NetworkAuthRequiredException extends NetworkServerException {
  const NetworkAuthRequiredException({
    super.statusCode = 511,
    super.type = NetworkErrorType.networkAuthRequired,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
