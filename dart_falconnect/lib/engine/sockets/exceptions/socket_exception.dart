import 'package:dart_falconnect/lib.dart';
import 'package:dart_falmodel/dart_falmodel.dart';

/// Base exception for WebSocket failures.
///
/// Carries the optional [response], human-readable [message], underlying
/// [exception], and [stackTrace] at the point of failure.
class SocketException implements Exception {
  /// Creates a [SocketException] with optional diagnostic context.
  const SocketException({
    this.response,
    this.message,
    this.exception,
    this.stackTrace,
  });

  /// Human-readable description of the failure.
  final String? message;

  /// The socket response present at the time of the failure, if any.
  final SocketResponse? response;

  /// The underlying exception that caused this socket failure, if any.
  final Exception? exception;

  /// The stack trace captured when the exception was thrown, if any.
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'SocketException{message: $message,\n'
        'response: $response,\n'
        'exception: $exception,\n'
        'stackTrace: $stackTrace}';
  }
}
