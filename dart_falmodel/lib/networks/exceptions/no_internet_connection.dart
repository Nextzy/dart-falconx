import 'package:dart_falmodel/lib.dart';

/// Exception raised when no internet connection is available.
///
/// Uses status code 0 to indicate the absence of a server response.
class NoInternetConnectException extends NetworkException {
  /// Creates a [NoInternetConnectException].
  const NoInternetConnectException({
    super.statusCode = 0,
    super.type = NetworkErrorType.noInternet,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
