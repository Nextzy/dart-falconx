import 'package:dart_falmodel/lib.dart';

extension FalconObjectExceptionExtensions on Object {
  CommonException<Object> toException({
    Object? type,
    String? userMessage,
    String? developerMessage,
    StackTrace? stackTrace,
  }) {
    if (this is CommonException<Object>) {
      return this as CommonException<Object>;
    }

    if (this is DioException) {
      return _getExceptionFromResponse(
        (this as DioException).response,
        userMessage: userMessage,
        developerMessage: developerMessage,
        stackTrace: stackTrace,
      );
    }

    final detectedType = type ?? _detectErrorType();
    final trace = stackTrace ?? _getStackTrace();
    final message =
        userMessage ??
        (detectedType is ErrorType ? detectedType.defaultMessage : null);

    return CommonException(
      type: detectedType,
      userMessage: message,
      developerMessage: developerMessage ?? toString(),
      stackTrace: trace,
    );
  }

  StackTrace _getStackTrace() {
    if (this is Error) {
      return (this as Error).stackTrace ?? StackTrace.current;
    }
    return StackTrace.current;
  }

  Object _detectErrorType() {
    final exception = this;

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
    final statusCode = response?.statusCode ?? 0;

    String? type;
    String? finalUserMessage;
    String? finalDeveloperMessage;
    final finalStackTrace = stackTrace ?? StackTrace.current;
    if (response?.data is String) {
      finalUserMessage = response?.data as String?;
    } else if (response?.data is Map) {
      type = response?.data['type'] as String?;
      finalUserMessage = userMessage ?? response?.data['message'] as String?;
      finalDeveloperMessage =
          developerMessage ?? response?.data['developerMessage'] as String?;
    }

    if (statusCode >= 600) {
      return NetworkNonStandardException(
        statusCode: statusCode,
        userMessage: finalUserMessage,
        developerMessage: finalDeveloperMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      );
    } else if (statusCode >= 500 && statusCode < 600) {
      if (statusCode == 500) {
        return NetworkInternalServerException(
          statusCode: statusCode,
          type: type,
          userMessage: finalUserMessage ?? 'Sorry. Please try again later.',
          developerMessage: finalDeveloperMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 501) {
        return NetowrkNotImplementException(
          statusCode: statusCode,
          type: type,
          userMessage:
              finalUserMessage ?? 'This service is currently unavailable.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 502) {
        return NetworkBadGatewayException(
          statusCode: statusCode,
          type: type,
          userMessage: finalUserMessage ?? 'Sorry. Please try again later.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 503) {
        return ServiceUnavailableException(
          statusCode: statusCode,
          type: type,
          userMessage:
              finalUserMessage ?? 'This service is currently unavailable.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 504) {
        return NetworkGatewayTimeoutException(
          statusCode: statusCode,
          type: type,
          userMessage:
              finalUserMessage ?? 'Request timed out. Please try again.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else {
        return NetworkServerException(
          statusCode: statusCode,
          type: type,
          userMessage: finalUserMessage ?? 'Sorry. Please try again later.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      }
    } else if (statusCode >= 400 && statusCode < 500) {
      if (statusCode == 400) {
        return NetworkBadRequestException(
          statusCode: statusCode,
          type: type,
          userMessage: finalUserMessage ?? 'Invalid format.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 401) {
        return NetworkAuthenticationException(
          statusCode: statusCode,
          type: type,
          userMessage: finalUserMessage ?? 'Please log in to continue.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 403) {
        return NetworkForbiddenException(
          statusCode: statusCode,
          type: type,
          userMessage:
              finalUserMessage ??
              'You do not have permission to perform this action.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 404) {
        return NetworkNotFoundException(
          statusCode: statusCode,
          type: type,
          userMessage:
              finalUserMessage ?? 'The requested resource was not found.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 405) {
        return MethodNotAllowedException(
          statusCode: statusCode,
          type: type,
          userMessage: finalUserMessage ?? 'This operation is not allowed.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 408) {
        return NetworkTimeoutException(
          statusCode: statusCode,
          type: type,
          userMessage:
              finalUserMessage ?? 'Request timed out. Please try again.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 409) {
        return NetworkConflictException(
          statusCode: statusCode,
          type: type,
          userMessage:
              finalUserMessage ?? 'A conflict occurred. Please try again.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 422) {
        return NetworkInvalidException(
          statusCode: statusCode,
          type: type,
          userMessage:
              finalUserMessage ?? 'Invalid input. Please check your data.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else if (statusCode == 429) {
        return NetworkLimitExceededException(
          statusCode: statusCode,
          type: type,
          userMessage: finalUserMessage ?? 'Limit exceeded. Please try again.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      } else {
        return NetworkClientException(
          statusCode: statusCode,
          type: type,
          userMessage: finalUserMessage ?? 'Sorry. Please check your request.',
          developerMessage: finalDeveloperMessage ?? response?.statusMessage,
          requestOptions: response?.requestOptions,
          response: response,
          stackTrace: finalStackTrace,
        );
      }
    }
    return NetworkException(
      statusCode: statusCode,
      type: type,
      userMessage:
          finalUserMessage ?? 'Something went wrong. Please try again.',
      developerMessage: finalDeveloperMessage ?? response?.statusMessage,
      requestOptions: response?.requestOptions,
      response: response,
      stackTrace: finalStackTrace,
    );
  }
}
