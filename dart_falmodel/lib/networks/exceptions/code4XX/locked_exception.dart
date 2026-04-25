import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 423 Locked responses.
///
/// Raised when the requested resource is currently locked.
class NetworkLockedException extends NetworkClientException {
  /// Creates a [NetworkLockedException].
  const NetworkLockedException({
    super.statusCode = 423,
    super.type = NetworkErrorType.locked,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
