import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 417 Expectation Failed responses.
///
/// Raised when the server cannot meet the requirements of the Expect header.
class NetworkExpectationFailedException extends NetworkClientException {
  /// Creates a [NetworkExpectationFailedException].
  const NetworkExpectationFailedException({
    super.statusCode = 417,
    super.type = NetworkErrorType.expectationFailed,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
