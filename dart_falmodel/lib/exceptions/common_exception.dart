enum ErrorType {
  // General
  unknown,
  system,
  unexpected,

  // Network
  network,
  timeout,
  noInternet,
  clientError,
  serverError,
  serviceUnavailable,

  // Authentication & Authorization
  authentication,
  unauthorized,
  forbidden,
  sessionExpired,
  tokenInvalid,

  // Validation
  validation,
  invalidInput,
  invalidFormat,

  // Data
  notFound,
  conflict,
  duplicate,
  dataCorrupted,

  // Storage & Cache
  storage,
  cache,
  database,

  // Business Logic
  businessRule,
  limitExceeded,
  insufficientFunds,
  operationNotAllowed,

  // External Services
  thirdParty,
  paymentFailed,

  // Device
  permission,
  deviceNotSupported;

  String get defaultMessage {
    return switch (this) {
      ErrorType.unknown => 'Something went wrong. Please try again.',
      ErrorType.system => 'System error occurred.',
      ErrorType.unexpected => 'An unexpected error occurred.',
      ErrorType.network => 'Network error. Please check your connection.',
      ErrorType.timeout => 'Request timed out. Please try again.',
      ErrorType.noInternet => 'No internet connection.',
      ErrorType.clientError => 'Client error. Please check your request.',
      ErrorType.serverError => 'Server error. Please try again later.',
      ErrorType.serviceUnavailable => 'Service is currently unavailable.',
      ErrorType.authentication => 'Authentication failed.',
      ErrorType.unauthorized => 'Please log in to continue.',
      ErrorType.forbidden =>
        'You do not have permission to perform this action.',
      ErrorType.sessionExpired =>
        'Your session has expired. Please log in again.',
      ErrorType.tokenInvalid => 'Invalid token. Please log in again.',
      ErrorType.validation => 'Invalid input. Please check your data.',
      ErrorType.invalidInput => 'Invalid input provided.',
      ErrorType.invalidFormat => 'Invalid format.',
      ErrorType.notFound => 'The requested resource was not found.',
      ErrorType.conflict => 'A conflict occurred. Please try again.',
      ErrorType.duplicate => 'This item already exists.',
      ErrorType.dataCorrupted => 'Data is corrupted.',
      ErrorType.storage => 'Storage error occurred.',
      ErrorType.cache => 'Cache error occurred.',
      ErrorType.database => 'Database error occurred.',
      ErrorType.businessRule => 'Operation not allowed.',
      ErrorType.limitExceeded => 'Limit exceeded.',
      ErrorType.insufficientFunds => 'Insufficient funds.',
      ErrorType.operationNotAllowed => 'This operation is not allowed.',
      ErrorType.thirdParty => 'External service error.',
      ErrorType.paymentFailed => 'Payment failed. Please try again.',
      ErrorType.permission => 'Permission denied.',
      ErrorType.deviceNotSupported => 'This device is not supported.',
    };
  }
}

class CommonException<T> implements Exception {
  const CommonException({
    required this.code,
    this.userMessage,
    this.developerMessage,
    this.stackTrace,
  });

  final T code;
  final String? userMessage;
  final String? developerMessage;

  final StackTrace? stackTrace;

  String get message =>
      userMessage ??
      developerMessage ??
      'Something went wrong. Please try again.';

  /// Creates a copy of this CommonException with the given fields replaced.
  CommonException<T> copyWith({
    T? code,
    String? userMessage,
    String? developerMessage,
    StackTrace? stackTrace,
  }) => CommonException(
    code: code ?? this.code,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    stackTrace: stackTrace ?? this.stackTrace,
  );

  @override
  String toString() {
    final buffer = StringBuffer('[$code]');
    if (userMessage != null && userMessage!.isNotEmpty) {
      buffer.write('\n | User: $userMessage');
    }
    if (developerMessage != null && developerMessage!.isNotEmpty) {
      buffer.write('\n | Dev: $developerMessage');
    }
    if (stackTrace != null) {
      buffer.write('\n | StackTrace:\n$stackTrace');
    }
    return buffer.toString();
  }
}
