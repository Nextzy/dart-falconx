import 'package:dart_falmodel/lib.dart';

/// Exception for non-standard HTTP error status codes.
///
/// This exception handles HTTP status codes that are valid error codes
/// (4XX or 5XX range) but not explicitly defined in the standard HTTP
/// specification or not commonly used.
class NetworkNonStandardException extends BaseHttpException {
  /// Creates a [NetworkNonStandardException] with the given [statusCode].
  const NetworkNonStandardException({
    required super.statusCode,
    super.type = NetworkErrorType.unknown,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  }) : assert(
         statusCode >= 400 && statusCode < 600,
         'Status code must be in error range (400-599)',
       );

  @override
  String get message {
    // If userMessage is provided, use it
    if (userMessage != null && userMessage!.isNotEmpty) {
      return userMessage!;
    }

    // Otherwise, provide generic messages based on status code range
    if (statusCode >= 400 && statusCode < 500) {
      return 'Request error ($statusCode). Please check your request.';
    }
    if (statusCode >= 500 && statusCode < 600) {
      return 'Server error ($statusCode). Please try again later.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  @override
  bool get isRetryable {
    // Non-standard server errors are potentially retryable
    if (isServerError) return true;

    // Some non-standard client errors might be retryable
    const potentiallyRetryableCodes = [
      420, // Enhance Your Calm (Twitter)
      430, // Request Header Fields Too Large (Shopify)
      450, // Blocked by Windows Parental Controls
      509, // Bandwidth Limit Exceeded
      598, // Network read timeout error
      599, // Network connect timeout error
    ];

    return potentiallyRetryableCodes.contains(statusCode);
  }

  @override
  String toString() {
    return 'NonStandardErrorException:'
        ' HTTP $statusCode - ${userMessage ?? 'Unknown error'}';
  }
}
