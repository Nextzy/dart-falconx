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

class CommonException<T> implements Exception {
  const CommonException({
    required this.type,
    this.userMessage,
    this.developerMessage,
    this.originalException,
    this.stackTrace,
  });

  final T type;
  final String? userMessage;
  final String? developerMessage;
  final Object? originalException;
  final StackTrace? stackTrace;

  String get message =>
      userMessage ??
      developerMessage ??
      'Something went wrong. Please try again.';

  CommonException<T> mapMessage({
    String Function(T type)? userMessage,
    String Function(T type)? developerMessage,
  }) {
    return copyWith(
      userMessage: userMessage?.call(type) ?? this.userMessage,
      developerMessage: developerMessage?.call(type) ?? this.developerMessage,
    );
  }

  CommonException<T> mapUserMessage(String Function(T type) f) {
    return mapMessage(userMessage: f);
  }

  CommonException<T> mapDeveloperMessage(String Function(T type) f) {
    return mapMessage(developerMessage: f);
  }

  CommonException<T> copyWith({
    T? type,
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
}
