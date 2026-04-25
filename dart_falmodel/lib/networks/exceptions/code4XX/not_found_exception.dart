import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 404 Not Found responses.
///
/// Raised when the server cannot find the requested resource.
class NetworkNotFoundException extends NetworkClientException {
  /// Creates a [NetworkNotFoundException].
  const NetworkNotFoundException({
    super.statusCode = 404,
    super.type = NetworkErrorType.notFound,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
