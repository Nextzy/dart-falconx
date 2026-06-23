import 'package:dart_falmodel/extensions/_io_stubs.dart'
    if (dart.library.io) '_io_real.dart';
import 'package:dart_falmodel/lib.dart';

/// Extensions on a nullable [Exception] for convenient
/// [CommonException] access.
extension FalconExceptionExtensions<T> on Exception? {
  /// Returns [CommonException.type] if this is a [CommonException],
  /// otherwise `null`.
  Object? get type {
    final exception = this;
    if (exception is CommonException) {
      return exception.type;
    }
    return null;
  }

  /// Returns [CommonException.userMessage] if this is a [CommonException],
  /// otherwise `null`.
  String? get userMessage {
    final exception = this;
    if (exception is CommonException) {
      return exception.userMessage;
    }
    return null;
  }

  /// Returns [CommonException.developerMessage] if this is a
  /// [CommonException], otherwise `null`.
  String? get developerMessage {
    final exception = this;
    if (exception is CommonException) {
      return exception.developerMessage;
    }
    return null;
  }

  /// Returns the stack trace from an [Error], [DioException], or
  /// [CommonException]; `null` otherwise.
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

  /// Wraps this exception in a `Result.failure` containing a [CommonException].
  ///
  /// [type] defaults to [SystemErrorType.unknown] when not provided.
  /// [developerMessage] defaults to `toString()` of this exception.
  Result<Never> toCommonResultFailure({
    Object? type,
    String? userMessage,
    String? developerMessage,
  }) {
    return Result.failure(
      CommonException(
        type: type ?? SystemErrorType.unknown,
        userMessage: userMessage,
        developerMessage: developerMessage ?? toString(),
        originalException: this,
        stackTrace: stackTrace,
      ),
    );
  }
}

/// Extensions on a nullable [Object] for converting arbitrary values
/// to [CommonException].
extension FalconObjectExceptionExtensions on Object? {
  /// Converts this object to a [CommonException].
  ///
  /// Handles [CommonException] (returned as-is), [DioException] (mapped to an
  /// appropriate [NetworkException]), standard [Exception], and bare [Error]
  /// objects. The [type] is inferred from the runtime type when not provided.
  CommonException toException({
    Object? type,
    String? userMessage,
    String? developerMessage,
    StackTrace? stackTrace,
  }) {
    final exception = this;

    if (exception == null) {
      return CommonException(
        type: type ?? SystemErrorType.unknown,
        userMessage: userMessage,
        developerMessage: developerMessage,
        originalException: null,
        stackTrace: stackTrace ?? StackTrace.current,
      );
    }

    if (exception is CommonException) {
      return exception;
    }

    if (exception is DioException) {
      return _getExceptionFromDioException(
        exception,
        userMessage: userMessage,
        developerMessage: developerMessage,
        stackTrace: stackTrace,
      );
    }

    final detectedType = type ?? _detectErrorType(exception);
    final trace = stackTrace ?? _getStackTrace(exception);
    final resolveUserMessage =
        userMessage ??
        (detectedType is DefaultErrorType ? detectedType.defaultMessage : null);

    if (exception is Exception) {
      return CommonException(
        type: detectedType,
        userMessage: resolveUserMessage,
        developerMessage: developerMessage ?? toString(),
        originalException: exception,
        stackTrace: trace,
      );
    }

    return CommonException(
      type: detectedType,
      userMessage: resolveUserMessage,
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
    // ─── Connectivity (specific) ───
    if (exception is SocketException) return ConnectivityErrorType.socket;
    if (exception is HandshakeException) return ConnectivityErrorType.tls;
    if (exception is CertificateException) return ConnectivityErrorType.tls;
    if (exception is TlsException) return ConnectivityErrorType.tls;
    if (exception is HttpException) return ConnectivityErrorType.http;

    // ─── Storage (specific) ───
    if (exception is PathNotFoundException) return StorageErrorType.fileSystem;
    if (exception is FileSystemException) return StorageErrorType.fileSystem;

    // ─── Input ───
    if (exception is FormatException) return InputErrorType.invalidFormat;
    if (exception is TypeError) return InputErrorType.type;
    if (exception is RangeError) return InputErrorType.outOfRange;
    if (exception is ArgumentError) return InputErrorType.argument;
    if (exception is NoSuchMethodError) return InputErrorType.type;

    // ─── Timeout ───
    if (exception is TimeoutException) return TimeoutErrorType.timeout;

    // ─── System (specific) ───
    if (exception is ConcurrentModificationError) {
      return SystemErrorType.concurrency;
    }
    if (exception is OutOfMemoryError) return SystemErrorType.system;
    if (exception is StackOverflowError) return SystemErrorType.system;
    if (exception is StateError) return SystemErrorType.system;
    if (exception is UnsupportedError) return SystemErrorType.unexpected;

    // ─── Async ───
    if (exception is AsyncError) return AsyncErrorType.stream;

    // ─── Parent class fallback ───
    if (exception is IOException) return StorageErrorType.storage;
    if (exception is Error) return SystemErrorType.unexpected;

    return SystemErrorType.unknown;
  }

  ///========================= PRIVATE METHOD =========================///
  NetworkException _getExceptionFromDioException(
    DioException? exception, {
    String? userMessage,
    String? developerMessage,
    StackTrace? stackTrace,
  }) {
    final resolveStatusCode = exception?.response?.statusCode ?? 0;
    String? resolveUserMessage;
    String? resolveDeveloperMessage;
    final responseData = exception?.response?.data;
    if (responseData is String) {
      resolveUserMessage = responseData;
    } else if (responseData is Map) {
      resolveUserMessage = userMessage ?? responseData['message'] as String?;
      resolveDeveloperMessage =
          developerMessage ??
          responseData['developerMessage'] as String? ??
          exception?.response?.statusMessage;
    }
    final resolveStackTrace =
        stackTrace ?? exception.stackTrace ?? StackTrace.current;

    final errorType = NetworkErrorType.fromStatusCode(resolveStatusCode);

    return switch (resolveStatusCode) {
      400 => NetworkBadRequestException(
        userMessage: resolveUserMessage ?? 'Invalid format.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      401 => NetworkAuthenticationException(
        userMessage: resolveUserMessage ?? 'Please log in to continue.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      402 => NetworkPaymentRequiredException(
        userMessage: resolveUserMessage ?? 'Payment required.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      403 => NetworkForbiddenException(
        userMessage:
            resolveUserMessage ??
            'You do not have permission to perform this action.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      404 => NetworkNotFoundException(
        userMessage:
            resolveUserMessage ?? 'The requested resource was not found.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      405 => MethodNotAllowedException(
        userMessage: resolveUserMessage ?? 'This operation is not allowed.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      406 => NetworkNotAcceptableException(
        userMessage: resolveUserMessage ?? 'Not acceptable.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      407 => NetworkProxyAuthRequiredException(
        userMessage: resolveUserMessage ?? 'Proxy authentication required.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      408 => NetworkTimeoutException(
        userMessage:
            resolveUserMessage ?? 'Request timed out. Please try again.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      409 => NetworkConflictException(
        userMessage:
            resolveUserMessage ?? 'A conflict occurred. Please try again.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      410 => NetworkGoneException(
        userMessage:
            resolveUserMessage ??
            'The requested resource is no longer available.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      411 => NetworkLengthRequiredException(
        userMessage: resolveUserMessage ?? 'Content length required.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      412 => NetworkPreconditionFailedException(
        userMessage: resolveUserMessage ?? 'Precondition failed.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      413 => NetworkContentTooLargeException(
        userMessage: resolveUserMessage ?? 'Content too large.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      414 => NetworkUriTooLongException(
        userMessage: resolveUserMessage ?? 'URI too long.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      415 => NetworkUnsupportedMediaTypeException(
        userMessage: resolveUserMessage ?? 'Unsupported media type.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      416 => NetworkRangeNotSatisfiableException(
        userMessage: resolveUserMessage ?? 'Range not satisfiable.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      417 => NetworkExpectationFailedException(
        userMessage: resolveUserMessage ?? 'Expectation failed.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      421 => NetworkMisdirectedRequestException(
        userMessage: resolveUserMessage ?? 'Misdirected request.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      422 => NetworkInvalidException(
        userMessage:
            resolveUserMessage ?? 'Invalid input. Please check your data.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      423 => NetworkLockedException(
        userMessage: resolveUserMessage ?? 'Resource is locked.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      424 => NetworkFailedDependencyException(
        userMessage: resolveUserMessage ?? 'Failed dependency.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      425 => NetworkTooEarlyException(
        userMessage: resolveUserMessage ?? 'Too early.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      426 => NetworkUpgradeRequiredException(
        userMessage: resolveUserMessage ?? 'Upgrade required.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      428 => NetworkPreconditionRequiredException(
        userMessage: resolveUserMessage ?? 'Precondition required.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      429 => NetworkLimitExceededException(
        userMessage: resolveUserMessage ?? 'Limit exceeded. Please try again.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      431 => NetworkHeaderFieldsTooLargeException(
        userMessage: resolveUserMessage ?? 'Request header fields too large.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      451 => NetworkUnavailableForLegalException(
        userMessage: resolveUserMessage ?? 'Unavailable for legal reasons.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      >= 400 && < 500 => NetworkClientException(
        statusCode: resolveStatusCode,
        type: errorType,
        userMessage: resolveUserMessage ?? 'Sorry. Please check your request.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      500 => NetworkInternalServerException(
        userMessage: resolveUserMessage ?? 'Sorry. Please try again later.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      501 => NetworkNotImplementException(
        userMessage:
            resolveUserMessage ?? 'This service is currently unavailable.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      502 => NetworkBadGatewayException(
        userMessage: resolveUserMessage ?? 'Sorry. Please try again later.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      503 => ServiceUnavailableException(
        userMessage:
            resolveUserMessage ?? 'This service is currently unavailable.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      504 => NetworkGatewayTimeoutException(
        userMessage:
            resolveUserMessage ?? 'Request timed out. Please try again.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      505 => NetworkHttpVersionNotSupportedException(
        userMessage: resolveUserMessage ?? 'HTTP version not supported.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      506 => NetworkVariantAlsoNegotiatesException(
        userMessage: resolveUserMessage ?? 'Variant also negotiates.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      507 => NetworkInsufficientStorageException(
        userMessage: resolveUserMessage ?? 'Insufficient storage.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      508 => NetworkLoopDetectedException(
        userMessage: resolveUserMessage ?? 'Loop detected.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      510 => NetworkNotExtendedException(
        userMessage: resolveUserMessage ?? 'Not extended.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      511 => NetworkAuthRequiredException(
        userMessage: resolveUserMessage ?? 'Network authentication required.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      >= 500 && < 600 => NetworkServerException(
        statusCode: resolveStatusCode,
        type: errorType,
        userMessage: resolveUserMessage ?? 'Sorry. Please try again later.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
      _ => NetworkException(
        statusCode: resolveStatusCode,
        type: errorType,
        userMessage:
            resolveUserMessage ?? 'Something went wrong. Please try again.',
        developerMessage: resolveDeveloperMessage,
        requestOptions: exception?.requestOptions,
        response: exception?.response,
        stackTrace: resolveStackTrace,
      ),
    };
  }
}
