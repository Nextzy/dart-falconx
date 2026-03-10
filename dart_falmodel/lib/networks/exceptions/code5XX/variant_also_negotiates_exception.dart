import 'package:dart_falmodel/lib.dart';

class NetworkVariantAlsoNegotiatesException extends NetworkServerException {
  const NetworkVariantAlsoNegotiatesException({
    super.statusCode = 506,
    super.type = NetworkErrorType.variantAlsoNegotiates,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
