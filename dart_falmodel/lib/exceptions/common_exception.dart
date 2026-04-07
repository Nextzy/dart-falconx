import 'package:dart_falmodel/lib.dart';

enum ErrorType {
  unknown,
  system,
  unexpected,
  validation,
  invalidInput,
  invalidFormat,
  notFound,
  storage,
  cache,
  database,
  businessRule,
  thirdParty,
  permission,
  deviceNotSupported;

  String get defaultMessage {
    return switch (this) {
      ErrorType.unknown => 'Something went wrong. Please try again.',
      ErrorType.system => 'System error occurred.',
      ErrorType.unexpected => 'An unexpected error occurred.',
      ErrorType.validation => 'Invalid input. Please check your data.',
      ErrorType.invalidInput => 'Invalid input provided.',
      ErrorType.invalidFormat => 'Invalid format.',
      ErrorType.notFound => 'The requested resource was not found.',
      ErrorType.storage => 'Storage error occurred.',
      ErrorType.cache => 'Cache error occurred.',
      ErrorType.database => 'Database error occurred.',
      ErrorType.businessRule => 'Operation not allowed.',
      ErrorType.thirdParty => 'External service error.',
      ErrorType.permission => 'Permission denied.',
      ErrorType.deviceNotSupported => 'This device is not supported.',
    };
  }
}

class CommonException implements Exception {
  const CommonException({
    this.category,
    required this.type,
    this.userMessage,
    this.developerMessage,
    this.originalException,
    this.stackTrace,
  });

  final Object? category;
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
    Object? category,
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => CommonException(
    category: category ?? this.category,
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
    JsonRpcErrorCategory? category,
    String? userMessage,
    String? developerMessage,
  }) {
    final tmpCode = code;

    final resolveCategory =
        category ??
        _resolveJsonRpcErrorCategory(category: this.category, code: type);
    final resolveCode = (tmpCode is Enum) ? tmpCode.name : tmpCode.toString();

    return JsonRpcError(
      category: resolveCategory ?? JsonRpcErrorCategory.API_ERROR,
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

  JsonRpcErrorCategory? _resolveJsonRpcErrorCategory({
    required Object? category,
    required Object? code,
  }) {
    return switch (category) {
      JsonRpcErrorCategory() => category,
      _ => switch (code) {
        JsonRpcRequestErrorType() => JsonRpcErrorCategory.INVALID_REQUEST_ERROR,
        JsonRpcApiErrorType() => JsonRpcErrorCategory.API_ERROR,
        _ => null,
      },
    };
  }
}
