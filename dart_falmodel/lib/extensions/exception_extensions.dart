import 'package:dart_falmodel/lib.dart';

extension FalconExceptionExtensions<T> on Exception? {
  Object? get code {
    final exception = this;
    if (exception is CommonException) {
      return exception.type;
    }
    return null;
  }

  String? get userMessage {
    final exception = this;
    if (exception is CommonException) {
      return exception.userMessage;
    }
    return null;
  }

  String? get developerMessage {
    final exception = this;
    if (exception is CommonException) {
      return exception.developerMessage;
    }
    return null;
  }

  StackTrace? get stackTrace {
    final exception = this;
    if (exception is Error) {
      return exception.stackTrace;
    } else if (exception is DioException) {
      return exception.stackTrace;
    } else if (exception is CommonException) {
      return exception.stackTrace;
    }
    return null;
  }

  Result<Never> toCommonResultFailure({
    String? userMessage,
    String? developerMessage,
  }) {
    return Result.failure(
      CommonException(
        type: ErrorType.unknown,
        userMessage: userMessage,
        developerMessage: developerMessage ?? toString(),
        originalException: this,
        stackTrace: stackTrace,
      ),
    );
  }
}

extension FalconObjectExceptionExtensions on Object? {
  CommonException toException({
    Object? type,
    String? userMessage,
    String? developerMessage,
    StackTrace? stackTrace,
  }) {
    final exception = this;

    if (exception == null) {
      return CommonException(
        type: ErrorType.unknown,
        userMessage: userMessage,
        developerMessage: developerMessage ?? 'Null object.',
        originalException: null,
        stackTrace: stackTrace ?? StackTrace.current,
      );
    }

    if (exception is CommonException) {
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

    if (exception is Exception) {
      return CommonException(
        type: detectedType,
        userMessage: message,
        developerMessage: developerMessage ?? toString(),
        originalException: exception,
        stackTrace: trace,
      );
    }

    return CommonException(
      type: detectedType,
      userMessage: message,
      developerMessage: developerMessage ?? toString(),
      originalException: null,
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
    if (exception is SocketException) return ErrorType.system;
    if (exception is HttpException) return ErrorType.system;
    if (exception is HandshakeException) return ErrorType.system;
    if (exception is CertificateException) return ErrorType.system;

    // Timeout
    if (exception is TimeoutException) return ErrorType.system;

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
    if (exception is UnsupportedError) return ErrorType.unexpected;

    // Async
    if (exception is AsyncError) return ErrorType.system;

    return ErrorType.unknown;
  }

  ///========================= PRIVATE METHOD =========================///
  NetworkException _getExceptionFromResponse(
    Response<dynamic>? response, {
    String? userMessage,
    String? developerMessage,
    StackTrace? stackTrace,
  }) {
    final finalStatusCode = response?.statusCode ?? 0;
    String? finalUserMessage;
    String? finalDeveloperMessage;
    final finalStackTrace = stackTrace ?? StackTrace.current;
    final responseData = response?.data;
    if (responseData is String) {
      finalUserMessage = responseData;
    } else if (responseData is Map) {
      finalUserMessage = userMessage ?? responseData['message'] as String?;
      finalDeveloperMessage =
          developerMessage ??
          responseData['developerMessage'] as String? ??
          toString();
    }

    final errorType = NetworkErrorType.fromStatusCode(finalStatusCode);

    return switch (finalStatusCode) {
      400 => NetworkBadRequestException(
        userMessage: finalUserMessage ?? 'Invalid format.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      401 => NetworkAuthenticationException(
        userMessage: finalUserMessage ?? 'Please log in to continue.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      402 => NetworkPaymentRequiredException(
        userMessage: finalUserMessage ?? 'Payment required.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      403 => NetworkForbiddenException(
        userMessage:
            finalUserMessage ??
            'You do not have permission to perform this action.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      404 => NetworkNotFoundException(
        userMessage:
            finalUserMessage ?? 'The requested resource was not found.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      405 => MethodNotAllowedException(
        userMessage: finalUserMessage ?? 'This operation is not allowed.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      406 => NetworkNotAcceptableException(
        userMessage: finalUserMessage ?? 'Not acceptable.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      407 => NetworkProxyAuthRequiredException(
        userMessage: finalUserMessage ?? 'Proxy authentication required.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      408 => NetworkTimeoutException(
        userMessage: finalUserMessage ?? 'Request timed out. Please try again.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      409 => NetworkConflictException(
        userMessage:
            finalUserMessage ?? 'A conflict occurred. Please try again.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      410 => NetworkGoneException(
        userMessage:
            finalUserMessage ??
            'The requested resource is no longer available.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      411 => NetworkLengthRequiredException(
        userMessage: finalUserMessage ?? 'Content length required.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      412 => NetworkPreconditionFailedException(
        userMessage: finalUserMessage ?? 'Precondition failed.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      413 => NetworkContentTooLargeException(
        userMessage: finalUserMessage ?? 'Content too large.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      414 => NetworkUriTooLongException(
        userMessage: finalUserMessage ?? 'URI too long.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      415 => NetworkUnsupportedMediaTypeException(
        userMessage: finalUserMessage ?? 'Unsupported media type.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      416 => NetworkRangeNotSatisfiableException(
        userMessage: finalUserMessage ?? 'Range not satisfiable.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      417 => NetworkExpectationFailedException(
        userMessage: finalUserMessage ?? 'Expectation failed.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      421 => NetworkMisdirectedRequestException(
        userMessage: finalUserMessage ?? 'Misdirected request.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      422 => NetworkInvalidException(
        userMessage:
            finalUserMessage ?? 'Invalid input. Please check your data.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      423 => NetworkLockedException(
        userMessage: finalUserMessage ?? 'Resource is locked.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      424 => NetworkFailedDependencyException(
        userMessage: finalUserMessage ?? 'Failed dependency.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      425 => NetworkTooEarlyException(
        userMessage: finalUserMessage ?? 'Too early.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      426 => NetworkUpgradeRequiredException(
        userMessage: finalUserMessage ?? 'Upgrade required.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      428 => NetworkPreconditionRequiredException(
        userMessage: finalUserMessage ?? 'Precondition required.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      429 => NetworkLimitExceededException(
        userMessage: finalUserMessage ?? 'Limit exceeded. Please try again.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      431 => NetworkHeaderFieldsTooLargeException(
        userMessage: finalUserMessage ?? 'Request header fields too large.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      451 => NetworkUnavailableForLegalException(
        userMessage: finalUserMessage ?? 'Unavailable for legal reasons.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      >= 400 && < 500 => NetworkClientException(
        statusCode: finalStatusCode,
        type: errorType,
        userMessage: finalUserMessage ?? 'Sorry. Please check your request.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      500 => NetworkInternalServerException(
        userMessage: finalUserMessage ?? 'Sorry. Please try again later.',
        developerMessage: finalDeveloperMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      501 => NetworkNotImplementException(
        userMessage:
            finalUserMessage ?? 'This service is currently unavailable.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      502 => NetworkBadGatewayException(
        userMessage: finalUserMessage ?? 'Sorry. Please try again later.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      503 => ServiceUnavailableException(
        userMessage:
            finalUserMessage ?? 'This service is currently unavailable.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      504 => NetworkGatewayTimeoutException(
        userMessage: finalUserMessage ?? 'Request timed out. Please try again.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      505 => NetworkHttpVersionNotSupportedException(
        userMessage: finalUserMessage ?? 'HTTP version not supported.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      506 => NetworkVariantAlsoNegotiatesException(
        userMessage: finalUserMessage ?? 'Variant also negotiates.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      507 => NetworkInsufficientStorageException(
        userMessage: finalUserMessage ?? 'Insufficient storage.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      508 => NetworkLoopDetectedException(
        userMessage: finalUserMessage ?? 'Loop detected.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      510 => NetworkNotExtendedException(
        userMessage: finalUserMessage ?? 'Not extended.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      511 => NetworkAuthRequiredException(
        userMessage: finalUserMessage ?? 'Network authentication required.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      >= 500 && < 600 => NetworkServerException(
        statusCode: finalStatusCode,
        type: errorType,
        userMessage: finalUserMessage ?? 'Sorry. Please try again later.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
      _ => NetworkException(
        statusCode: finalStatusCode,
        type: errorType,
        userMessage:
            finalUserMessage ?? 'Something went wrong. Please try again.',
        developerMessage: finalDeveloperMessage ?? response?.statusMessage,
        requestOptions: response?.requestOptions,
        response: response,
        stackTrace: finalStackTrace,
      ),
    };
  }
}
