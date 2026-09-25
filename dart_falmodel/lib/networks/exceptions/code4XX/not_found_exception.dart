import 'package:dart_falmodel/src/src.dart';

/// Exception representing HTTP 404 Not Found responses.
///
/// Raised when the server cannot find the requested resource.
class NetworkNotFoundException extends NetworkClientException {
  /// Creates a [NetworkNotFoundException].
  const new({
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
