import 'package:dart_falconnect/lib.dart';

/// Thrown when an inbound socket response does not match any known operation.
class SocketOperationNotFound extends SocketException {
  /// Creates a [SocketOperationNotFound] with a default message of
  /// `'Operation not match'` when [message] is omitted.
  const SocketOperationNotFound({
    super.response,
    String? message,
    super.exception,
    super.stackTrace,
  }) : super(
         message: message ?? 'Operation not match',
       );
}
