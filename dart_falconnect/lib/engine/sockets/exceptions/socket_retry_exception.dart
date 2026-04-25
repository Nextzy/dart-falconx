import 'package:dart_falconnect/lib.dart';

/// Thrown each time the socket client attempts to reconnect after an error.
///
/// [retryCount] reflects how many retry attempts remain.
class SocketRetryException extends SocketException {
  /// Creates a [SocketRetryException].
  ///
  /// [retryCount] is the number of remaining retry attempts. The default
  /// [message] includes [retryCount] when no message is supplied.
  const SocketRetryException({
    required this.retryCount,
    super.response,
    String? message,
    super.exception,
    super.stackTrace,
  }) : super(
         message: message ?? 'Retry request at $retryCount',
       );

  /// Number of retry attempts remaining at the time this exception was thrown.
  final int retryCount;
}
