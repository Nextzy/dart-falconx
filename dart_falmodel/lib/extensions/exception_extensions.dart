import 'package:dart_falmodel/lib.dart';

extension FalconObjectExceptionExtensions on Object? {
  CommonException<Object> toException({
    Object? type,
    String? userMessage,
    String? developerMessage,
    StackTrace? stackTrace,
  }) {
    final exception = this;

    if (exception == null) {
      return CommonException(
        code: ErrorType.unknown,
        userMessage: userMessage,
        developerMessage: developerMessage ?? 'Null object.',
        stackTrace: stackTrace ?? StackTrace.current,
      );
    }

    if (exception is CommonException<Object>) {
      return exception;
    }

    if (exception is DioException) {
      return _getExceptionFromResponse(
        exception.response,
        userMessage: userMessage,
        developerMessage: developerMessage,
        stackTrace: stackTrace,
      );
    }

    final detectedType = type ?? _detectErrorType(exception);
    final trace = stackTrace ?? _getStackTrace(exception);
    final message =
        userMessage ??
        (detectedType is ErrorType ? detectedType.defaultMessage : null);

    return CommonException(
      code: detectedType,
      userMessage: message,
      developerMessage: developerMessage ?? toString(),
      stackTrace: trace,
    );
  }

  StackTrace _getStackTrace(Object? exception) {
    if (exception is Error) {
      return exception.stackTrace ?? StackTrace.current;
    }
    return StackTrace.current;
  }

  Object _detectErrorType(Object? exception) {
    // Network & Connection
    if (exception is SocketException) return ErrorType.noInternet;
    if (exception is HttpException) return ErrorType.network;
    if (exception is HandshakeException) return ErrorType.network;
    if (exception is CertificateException) return ErrorType.network;

    // Timeout
    if (exception is TimeoutException) return ErrorType.timeout;

    // Format & Parsing
    if (exception is FormatException) return ErrorType.invalidFormat;
    if (exception is TypeError) return ErrorType.unexpected;

    // File & Storage
    if (exception is FileSystemException) return ErrorType.storage;
    if (exception is IOException) return ErrorType.storage;

    // State & Argument
    if (exception is StateError) return ErrorType.system;
    if (exception is ArgumentError) return ErrorType.invalidInput;
    if (exception is RangeError) return ErrorType.invalidInput;
    if (exception is UnsupportedError) return ErrorType.operationNotAllowed;

    // Async
    if (exception is AsyncError) return ErrorType.system;

    return ErrorType.unknown;
  }

  ///========================= PRIVATE METHOD =========================///
  CommonException<String> _getExceptionFromResponse(
    Response? response, {
    String? userMessage,
    String? developerMessage,
    StackTrace? stackTrace,
  }) {
    final finalStatusCode = response?.statusCode ?? 0;
    String? finalType;
    String? finalUserMessage;
    String? finalDeveloperMessage;
    final finalStackTrace = stackTrace ?? StackTrace.current;
    if (response?.data is String) {
      finalUserMessage = response?.data as String?;
    } else if (response?.data is Map) {
      finalType = response?.data['type'] as String?;
      finalUserMessage = userMessage ?? response?.data['message'] as String?;
      finalDeveloperMessage =
          developerMessage ??
          response?.data['developerMessage'] as String? ??
          toString();
    }

    if (finalStatusCode >= 600) {
      return NetworkNonStandardException(
        statusCode: finalStatusCode,
        type: finalType,
        userMessage: finalUserMessage,
        developerMessage: finalDeveloperMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      );
    } else if (finalStatusCode >= 500 && finalStatusCode < 600) {
      if (finalStatusCode == 500) {
        return NetworkInternalServerException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage: finalUserMessage ?? 'Sorry. Please try again later.',
          developerMessage: finalDeveloperMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 501) {
        return NetowrkNotImplementException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage:
              finalUserMessage ?? 'This service is currently unavailable.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 502) {
        return NetworkBadGatewayException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage: finalUserMessage ?? 'Sorry. Please try again later.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 503) {
        return ServiceUnavailableException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage:
              finalUserMessage ?? 'This service is currently unavailable.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 504) {
        return NetworkGatewayTimeoutException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage:
              finalUserMessage ?? 'Request timed out. Please try again.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else {
        return NetworkServerException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage: finalUserMessage ?? 'Sorry. Please try again later.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      }
    } else if (finalStatusCode >= 400 && finalStatusCode < 500) {
      if (finalStatusCode == 400) {
        return NetworkBadRequestException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage: finalUserMessage ?? 'Invalid format.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 401) {
        return NetworkAuthenticationException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage: finalUserMessage ?? 'Please log in to continue.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 403) {
        return NetworkForbiddenException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage:
              finalUserMessage ??
              'You do not have permission to perform this action.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 404) {
        return NetworkNotFoundException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage:
              finalUserMessage ?? 'The requested resource was not found.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 405) {
        return MethodNotAllowedException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage: finalUserMessage ?? 'This operation is not allowed.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 408) {
        return NetworkTimeoutException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage:
              finalUserMessage ?? 'Request timed out. Please try again.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 409) {
        return NetworkConflictException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage:
              finalUserMessage ?? 'A conflict occurred. Please try again.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 422) {
        return NetworkInvalidException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage:
              finalUserMessage ?? 'Invalid input. Please check your data.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (finalStatusCode == 429) {
        return NetworkLimitExceededException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage: finalUserMessage ?? 'Limit exceeded. Please try again.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else {
        return NetworkClientException(
          statusCode: finalStatusCode,
          type: finalType,
          userMessage: finalUserMessage ?? 'Sorry. Please check your request.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      }
    }
    return NetworkException(
      statusCode: finalStatusCode,
      type: finalType,
      userMessage:
          finalUserMessage ?? 'Something went wrong. Please try again.',
      developerMessage: finalDeveloperMessage ?? response?.statusMessage,
      requestOptions: response?.requestOptions,
      response: response,
      stackTrace: finalStackTrace,
    );
  }
}
