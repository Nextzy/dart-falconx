import 'package:dart_falmodel/lib.dart';

class NetworkBadGatewayException extends NetworkServerException {
  const NetworkBadGatewayException({
    super.statusCode = 502,
    super.type,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
