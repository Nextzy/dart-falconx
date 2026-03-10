import 'package:dart_falmodel/lib.dart';

class NetworkUnavailableForLegalException extends NetworkClientException {
  const NetworkUnavailableForLegalException({
    super.statusCode = 451,
    super.type = NetworkErrorType.unavailableForLegal,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
