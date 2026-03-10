import 'package:dart_falmodel/lib.dart';

class NetworkRangeNotSatisfiableException extends NetworkClientException {
  const NetworkRangeNotSatisfiableException({
    super.statusCode = 416,
    super.type = NetworkErrorType.rangeNotSatisfiable,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
