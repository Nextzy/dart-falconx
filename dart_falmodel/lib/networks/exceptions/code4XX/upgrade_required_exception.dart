import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 426 Upgrade Required responses.
///
/// Raised when the client must switch to a different protocol (e.g., TLS).
class NetworkUpgradeRequiredException extends NetworkClientException {
  /// Creates a [NetworkUpgradeRequiredException].
  const NetworkUpgradeRequiredException({
    super.statusCode = 426,
    super.type = NetworkErrorType.upgradeRequired,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
