import 'package:dart_falmodel/lib.dart';

class NetworkMisdirectedRequestException extends NetworkClientException {
  const NetworkMisdirectedRequestException({
    super.statusCode = 421,
    super.type = NetworkErrorType.misdirectedRequest,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
