import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 503 Service Unavailable responses.
///
/// Raised when the server is temporarily unable to handle the request,
/// often due to maintenance or overload.
class ServiceUnavailableException extends NetworkServerException {
  /// Creates a [ServiceUnavailableException].
  const ServiceUnavailableException({
    super.statusCode = 503,
    super.type = NetworkErrorType.serviceUnavailable,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
