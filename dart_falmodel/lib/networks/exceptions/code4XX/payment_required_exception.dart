import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 402 Payment Required responses.
///
/// Raised when payment is required to access the requested resource.
class NetworkPaymentRequiredException extends NetworkClientException {
  /// Creates a [NetworkPaymentRequiredException].
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
