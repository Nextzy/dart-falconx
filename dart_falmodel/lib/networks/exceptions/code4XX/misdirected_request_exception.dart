import 'package:dart_falmodel/lib.dart';

/// Exception representing HTTP 421 Misdirected Request responses.
///
/// Raised when the request was directed at a server unable to produce
/// a response.
class NetworkMisdirectedRequestException extends NetworkClientException {
  /// Creates a [NetworkMisdirectedRequestException].
  const NetworkMisdirectedRequestException({
    super.statusCode = 421,
    super.type = NetworkErrorType.misdirectedRequest,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
