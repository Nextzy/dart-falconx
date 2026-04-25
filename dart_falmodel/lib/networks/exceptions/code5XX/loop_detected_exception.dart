import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 508 Loop Detected responses.
///
/// Raised when the server detected an infinite loop while processing
/// the request.
class NetworkLoopDetectedException extends NetworkServerException {
  /// Creates a [NetworkLoopDetectedException].
  const NetworkLoopDetectedException({
    super.statusCode = 508,
    super.type = NetworkErrorType.loopDetected,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
