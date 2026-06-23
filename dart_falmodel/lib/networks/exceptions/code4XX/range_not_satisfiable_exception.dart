import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 416 Range Not Satisfiable responses.
///
/// Raised when the server cannot serve the requested byte range.
class NetworkRangeNotSatisfiableException extends NetworkClientException {
  /// Creates a [NetworkRangeNotSatisfiableException].
  const NetworkRangeNotSatisfiableException({
    super.statusCode = 416,
    super.type = NetworkErrorType.rangeNotSatisfiable,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
