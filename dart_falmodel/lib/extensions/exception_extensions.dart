import 'package:dart_falmodel/lib.dart';

extension FalconObjectExceptionExtensions on Object {
  CommonException<ErrorType> toException({
    ErrorType? type,
    String? userMessage,
    String? developerMessage,
    StackTrace? stackTrace,
  }) {
    if (this is CommonException<ErrorType>) {
      return this as CommonException<ErrorType>;
    }

    final detectedType = type ?? _detectErrorType();
    final trace = stackTrace ?? _getStackTrace();

    return CommonException(
      type: detectedType,
      userMessage: userMessage ?? detectedType.defaultMessage,
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

  ErrorType _detectErrorType() {
    final exception = this;

    // Dio
    if (exception is DioException) {
      return switch (exception.type) {
        DioExceptionType.connectionTimeout => ErrorType.timeout,
        DioExceptionType.sendTimeout => ErrorType.timeout,
        DioExceptionType.receiveTimeout => ErrorType.timeout,
        DioExceptionType.connectionError => ErrorType.noInternet,
        DioExceptionType.cancel => ErrorType.operationNotAllowed,
        DioExceptionType.badResponse => _mapStatusCode(
          exception.response?.statusCode,
        ),
        DioExceptionType.unknown => ErrorType.network,
        DioExceptionType.badCertificate => ErrorType.network,
      };
    }

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

  ErrorType _mapStatusCode(int? statusCode) {
    if (statusCode == null) return ErrorType.network;

    return switch (statusCode) {
      400 => ErrorType.invalidInput,
      401 => ErrorType.unauthorized,
      403 => ErrorType.forbidden,
      404 => ErrorType.notFound,
      409 => ErrorType.conflict,
      422 => ErrorType.validation,
      429 => ErrorType.limitExceeded,
      >= 500 && < 600 => ErrorType.serverError,
      _ => ErrorType.network,
    };
  }
}
