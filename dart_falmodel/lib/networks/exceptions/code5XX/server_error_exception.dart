import 'package:dart_falmodel/lib.dart';

/// Base class for all 5XX server error exceptions.
///
/// Server errors indicate that the server failed to fulfill a valid request.
/// These errors are typically the server's responsibility and often retryable.
///
/// Ref: https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
class NetworkServerException extends BaseHttpException {
  /// Creates a [NetworkServerException] with the given [statusCode].
  const NetworkServerException({
    required super.statusCode,
    super.type = NetworkErrorType.serverError,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  }) : assert(
         statusCode >= 500 && statusCode < 600,
         'Error code not 500 to 600',
       );

  @override
  String get message {
    // If userMessage is provided, use it
    if (userMessage != null && userMessage!.isNotEmpty) {
      return userMessage!;
    }

    // Otherwise, return status-code-specific default message
    switch (statusCode) {
      case 500:
        return 'Internal server error. Please try again later.';
      case 501:
        return 'This feature is not implemented yet.';
      case 502:
        return 'Server communication error. Please try again.';
      case 503:
        return 'Service temporarily unavailable. Please try again later.';
      case 504:
        return 'Server timeout. Please try again.';
      case 505:
        return 'HTTP version not supported.';
      case 506:
        return 'Variant also negotiates.';
      case 507:
        return 'Insufficient storage.';
      case 508:
        return 'Loop detected.';
      case 510:
        return 'Not extended.';
      case 511:
        return 'Network authentication required.';
      default:
        return 'The server encountered an error. Please try again later.';
    }
  }

  /// Server errors are generally retryable.
  @override
  bool get isRetryable => true;

  /// Server errors should have longer retry delays.
  @override
  Duration get recommendedRetryDelay {
    switch (statusCode) {
      case 503: // Service Unavailable might have Retry-After header
        final retryAfter = response?.headers.value('retry-after');
        if (retryAfter != null) {
          final seconds = int.tryParse(retryAfter);
          if (seconds != null) return Duration(seconds: seconds);
        }
        return const Duration(seconds: 30);
      case 502:
      case 504:
        return const Duration(seconds: 10);
      default:
        return const Duration(seconds: 5);
    }
  }
}
