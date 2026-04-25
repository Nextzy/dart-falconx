import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 412 Precondition Failed responses.
///
/// Raised when one or more conditions in the request header fields were false.
class NetworkPreconditionFailedException extends NetworkClientException {
  /// Creates a [NetworkPreconditionFailedException].
  const NetworkPreconditionFailedException({
    super.statusCode = 412,
    super.type = NetworkErrorType.preconditionFailed,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
