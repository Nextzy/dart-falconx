import 'package:dart_falmodel/lib.dart';

enum DefaultErrorCategory {
  remote,
  local,
  unknown,
}

sealed class DefaultErrorType {
  String get defaultMessage;
}

enum SystemErrorType implements DefaultErrorType {
  unknown('Something went wrong. Please try again.'),
  system('System error occurred.'),
  unexpected('An unexpected error occurred.'),
  concurrency('Concurrent modification error.');

  const SystemErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

enum InputErrorType implements DefaultErrorType {
  validation('Invalid input. Please check your data.'),
  invalidFormat('Invalid format.'),
  invalidValue('Invalid value provided.'),
  outOfRange('Value out of range.'),
  argument('Invalid argument provided.'),
  type('Type error occurred.');

  const InputErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

enum TimeoutErrorType implements DefaultErrorType {
  timeout('Request timed out. Please try again.'),
  deadline('Operation deadline exceeded.');

  const TimeoutErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

enum StorageErrorType implements DefaultErrorType {
  storage('Storage error occurred.'),
  cache('Cache error occurred.'),
  database('Database error occurred.'),
  fileSystem('File system error.');

  const StorageErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

enum ConnectivityErrorType implements DefaultErrorType {
  connection('Connection error.'),
  socket('Socket error.'),
  tls('TLS/SSL error.'),
  dns('DNS resolution failed.'),
  http('HTTP error.');

  const ConnectivityErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

enum AsyncErrorType implements DefaultErrorType {
  stream('Stream error occurred.'),
  future('Future error occurred.'),
  isolate('Isolate error occurred.');

  const AsyncErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

enum AccessErrorType implements DefaultErrorType {
  permission('Permission denied.'),
  unauthorized('Unauthorized access.'),
  deviceNotSupported('This device is not supported.');

  const AccessErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

enum ExternalErrorType implements DefaultErrorType {
  thirdParty('External service error.'),
  serviceUnavailable('Service is currently unavailable.');

  const ExternalErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

enum BusinessErrorType implements DefaultErrorType {
  businessRule('Operation not allowed.'),
  notFound('The requested resource was not found.'),
  conflict('A conflict occurred.'),
  deprecated('This feature is deprecated.');

  const BusinessErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

class CommonException implements Exception {
  const CommonException({
    required this.type,
    this.userMessage,
    this.developerMessage,
    this.originalException,
    this.stackTrace,
  });

  final Object type;
  final String? userMessage;
  final String? developerMessage;
  final Object? originalException;
  final StackTrace? stackTrace;

  String get message =>
      userMessage ??
      developerMessage ??
      'Something went wrong. Please try again.';

  CommonException mapMessage({
    String Function(Object type)? userMessage,
    String Function(Object type)? developerMessage,
  }) {
    return copyWith(
      userMessage: userMessage?.call(type) ?? this.userMessage,
      developerMessage: developerMessage?.call(type) ?? this.developerMessage,
    );
  }

  CommonException mapUserMessage(String Function(Object type) f) {
    return mapMessage(userMessage: f);
  }

  CommonException mapDeveloperMessage(String Function(Object type) f) {
    return mapMessage(developerMessage: f);
  }

  CommonException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => CommonException(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );

  @override
  String toString() {
    final buffer = StringBuffer('[$type]');
    if (userMessage != null && userMessage!.isNotEmpty) {
      buffer.write('\n | User: $userMessage');
    }
    if (developerMessage != null && developerMessage!.isNotEmpty) {
      buffer.write('\n | Dev: $developerMessage');
    }
    if (originalException != null) {
      buffer.write('\n | Original: $originalException');
    }
    if (stackTrace != null) {
      buffer.write('\n | StackTrace:\n$stackTrace');
    }
    return buffer.toString();
  }

  JsonRpcError toJsonRpcError({
    String? userMessage,
    String? developerMessage,
  }) {
    final resolveCategory = _resolveJsonRpcErrorCategory(type: type);
    final resolveCode = (type is Enum) ? (type as Enum).name : type.toString();

    return JsonRpcError(
      category: resolveCategory,
      code: resolveCode,
      userMessage:
          userMessage ??
          this.userMessage ??
          'Something went wrong. Please try again.',
      developerMessage: developerMessage ?? this.developerMessage,
    );
  }

  Information toInformation({FeedbackLevel level = FeedbackLevel.medium}) =>
      Information(
        message: userMessage,
        level: level,
      );

  Failure toFailure({FeedbackLevel level = FeedbackLevel.medium}) => Failure(
    message: userMessage,
    level: level,
  );

  Warning toWarning({FeedbackLevel level = FeedbackLevel.medium}) => Warning(
    message: userMessage,
    level: level,
  );

  JsonRpcErrorCategory _resolveJsonRpcErrorCategory({
    required Object? type,
  }) => switch (this) {
    JsonRpcInternalApiDomainLayerException() ||
    JsonRpcDatabaseException() => JsonRpcErrorCategory.API_ERROR,
    JsonRpcExternalApiDomainLayerException() ||
    JsonRpcExternalApiDataLayerException() =>
      JsonRpcErrorCategory.EXTERNAL_API_ERROR,
    JsonRpcInvalidRequestDomainLayerException() =>
      JsonRpcErrorCategory.INVALID_REQUEST_ERROR,
    _ => switch (type) {
      JsonRpcApiErrorType() => JsonRpcErrorCategory.API_ERROR,
      JsonRpcExternalApiErrorType() => JsonRpcErrorCategory.EXTERNAL_API_ERROR,
      JsonRpcRequestErrorType() => JsonRpcErrorCategory.INVALID_REQUEST_ERROR,
      _ => JsonRpcErrorCategory.API_ERROR,
    },
  };
}
