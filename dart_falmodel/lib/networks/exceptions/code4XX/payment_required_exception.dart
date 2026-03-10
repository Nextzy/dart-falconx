import 'package:dart_falmodel/lib.dart';

class NetworkPaymentRequiredException extends NetworkClientException {
  const NetworkPaymentRequiredException({
    super.statusCode = 402,
    super.type = NetworkErrorType.paymentRequired,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
