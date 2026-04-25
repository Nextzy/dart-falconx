import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 410 Gone responses.
///
/// Raised when the requested resource is permanently unavailable.
class NetworkGoneException extends NetworkClientException {
  /// Creates a [NetworkGoneException].
  const NetworkGoneException({
    super.statusCode = 410,
    super.type = NetworkErrorType.gone,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
