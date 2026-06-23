import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 506 Variant Also Negotiates responses.
///
/// Raised when the server has an internal configuration error due to
/// circular content negotiation.
class NetworkVariantAlsoNegotiatesException extends NetworkServerException {
  /// Creates a [NetworkVariantAlsoNegotiatesException].
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
