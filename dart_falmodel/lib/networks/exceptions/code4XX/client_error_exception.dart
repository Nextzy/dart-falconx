import 'package:dart_falmodel/lib.dart';

/// Base class for all 4XX client error exceptions.
///
/// Client errors indicate that the request contains bad syntax or cannot
/// be fulfilled. These errors are typically the client's responsibility.
///
/// Ref: https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
class NetworkClientException extends BaseHttpException {
  const NetworkClientException({
    required super.statusCode,
    super.type = NetworkErrorType.clientError,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  }) : assert(
         statusCode >= 400 && statusCode < 500,
         'Error code not 400 to 500',
       );

  @override
  String get message {
    // If userMessage is provided, use it
    if (userMessage != null && userMessage!.isNotEmpty) {
      return userMessage!;
    }

    // Otherwise, return status-code-specific default message
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication required. Please log in.';
      case 402:
        return 'Payment required.';
      case 403:
        return "Access denied. You don't have permission.";
      case 404:
        return 'The requested resource was not found.';
      case 405:
        return 'This operation is not allowed.';
      case 406:
        return 'Not acceptable.';
      case 407:
        return 'Proxy authentication required.';
      case 408:
        return 'Request timed out. Please try again.';
      case 409:
        return 'A conflict occurred. Please try again.';
      case 410:
        return 'The requested resource is no longer available.';
      case 411:
        return 'Content length required.';
      case 412:
        return 'Precondition failed.';
      case 413:
        return 'Content too large.';
      case 414:
        return 'URI too long.';
      case 415:
        return 'Unsupported media type.';
      case 416:
        return 'Range not satisfiable.';
      case 417:
        return 'Expectation failed.';
      case 421:
        return 'Misdirected request.';
      case 422:
        return 'Invalid input. Please check your data.';
      case 423:
        return 'Resource is locked.';
      case 424:
        return 'Failed dependency.';
      case 425:
        return 'Too early.';
      case 426:
        return 'Upgrade required.';
      case 428:
        return 'Precondition required.';
      case 429:
        return 'Too many requests. Please wait and try again.';
      case 431:
        return 'Request header fields too large.';
      case 451:
        return 'Unavailable for legal reasons.';
      default:
        return 'The request could not be processed. '
            'Please check your input and try again.';
    }
  }
}
