import 'package:dart_falmodel/lib.dart';

class BadGatewayException extends ServerNetworkException {
  const BadGatewayException({
    super.statusCode = 502,
    super.type,
    super.statusMessage,
    super.errorMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
