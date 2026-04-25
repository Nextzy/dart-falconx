import 'package:dart_falmodel/lib.dart';

/// Broad origin category for a [CommonException].
enum DefaultErrorCategory {
  /// Error that originated from a remote source (network, API).
  remote,

  /// Error that originated locally (storage, device).
  local,

  /// Error whose origin cannot be determined.
  unknown,
}

/// Contract that every error-type enum must satisfy.
///
/// Implementing this interface guarantees a [defaultMessage] suitable
/// for display when no explicit user message is provided.
sealed class DefaultErrorType {
  /// Human-readable default message for this error type.
  String get defaultMessage;
}

/// Error types covering general system and runtime failures.
enum SystemErrorType implements DefaultErrorType {
  /// An unclassified error occurred.
  unknown('Something went wrong. Please try again.'),

  /// A system-level error occurred.
  system('System error occurred.'),

  /// An error that was not anticipated by the application.
  unexpected('An unexpected error occurred.'),

  /// A concurrent modification was detected.
  concurrency('Concurrent modification error.');

  const SystemErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

/// Error types covering invalid user or caller input.
enum InputErrorType implements DefaultErrorType {
  /// Input failed validation rules.
  validation('Invalid input. Please check your data.'),

  /// Input was in an unexpected or unrecognised format.
  invalidFormat('Invalid format.'),

  /// The provided value is logically invalid.
  invalidValue('Invalid value provided.'),

  /// The value falls outside the acceptable range.
  outOfRange('Value out of range.'),

  /// An invalid argument was passed to a function.
  argument('Invalid argument provided.'),

  /// A type mismatch or cast error occurred.
  type('Type error occurred.');

  const InputErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

/// Error types for operations that exceeded their time budget.
enum TimeoutErrorType implements DefaultErrorType {
  /// A request or operation timed out.
  timeout('Request timed out. Please try again.'),

  /// The operation deadline was exceeded.
  deadline('Operation deadline exceeded.');

  const TimeoutErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

/// Error types for persistence and file-system failures.
enum StorageErrorType implements DefaultErrorType {
  /// A generic storage error occurred.
  storage('Storage error occurred.'),

  /// A cache read or write error occurred.
  cache('Cache error occurred.'),

  /// A database operation failed.
  database('Database error occurred.'),

  /// A file-system operation failed.
  fileSystem('File system error.');

  const StorageErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

/// Error types for network connectivity problems.
enum ConnectivityErrorType implements DefaultErrorType {
  /// A network connection could not be established or was lost.
  connection('Connection error.'),

  /// A socket-level error occurred.
  socket('Socket error.'),

  /// A TLS or SSL handshake failed.
  tls('TLS/SSL error.'),

  /// DNS name resolution failed.
  dns('DNS resolution failed.'),

  /// An HTTP-level connectivity error occurred.
  http('HTTP error.');

  const ConnectivityErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

/// Error types for asynchronous operation failures.
enum AsyncErrorType implements DefaultErrorType {
  /// An error occurred inside a stream.
  stream('Stream error occurred.'),

  /// An error occurred inside a future.
  future('Future error occurred.'),

  /// An error occurred inside an isolate.
  isolate('Isolate error occurred.');

  const AsyncErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

/// Error types for permission and access-control failures.
enum AccessErrorType implements DefaultErrorType {
  /// The caller does not have the required permission.
  permission('Permission denied.'),

  /// The caller is not authenticated.
  unauthorized('Unauthorized access.'),

  /// The current device does not support the requested operation.
  deviceNotSupported('This device is not supported.');

  const AccessErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

/// Error types for failures in third-party or external services.
enum ExternalErrorType implements DefaultErrorType {
  /// A third-party integration returned an error.
  thirdParty('External service error.'),

  /// The external service is not currently available.
  serviceUnavailable('Service is currently unavailable.');

  const ExternalErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

/// Error types for domain and business-rule violations.
enum BusinessErrorType implements DefaultErrorType {
  /// The operation violates a business rule.
  businessRule('Operation not allowed.'),

  /// The requested resource does not exist.
  notFound('The requested resource was not found.'),

  /// A state or data conflict was detected.
  conflict('A conflict occurred.'),

  /// The feature or API is deprecated and no longer active.
  deprecated('This feature is deprecated.');

  const BusinessErrorType(this._message);

  final String _message;

  @override
  String get defaultMessage => _message;
}

/// Base exception class used across all layers of the application.
///
/// Carries a typed [type] discriminant, optional human-readable messages,
/// the original cause, and a stack trace. Subclass for layer-specific semantics
/// (e.g. [DataLayerException], [DomainLayerException]).
class CommonException implements Exception {
  /// Creates a [CommonException].
  ///
  /// [type] is required and identifies the error category.
  /// [userMessage] is shown to end users; [developerMessage] is for logs.
  const CommonException({
    required this.type,
    this.userMessage,
    this.developerMessage,
    this.originalException,
    this.stackTrace,
  });

  /// Discriminant that identifies the error category.
  final Object type;

  /// Optional message suitable for display to the end user.
  final String? userMessage;

  /// Optional message intended for developer logs or debugging.
  final String? developerMessage;

  /// The underlying exception that caused this error, if any.
  final Object? originalException;

  /// Stack trace captured at the point the exception was created.
  final StackTrace? stackTrace;

  /// The most relevant message available, falling back to a generic string.
  String get message =>
      userMessage ??
      developerMessage ??
      'Something went wrong. Please try again.';

  /// Returns a copy of this exception with optionally overridden messages.
  ///
  /// [userMessage] and [developerMessage] are computed from [type]
  /// when provided.
  CommonException mapMessage({
    String Function(Object type)? userMessage,
    String Function(Object type)? developerMessage,
  }) {
    return copyWith(
      userMessage: userMessage?.call(type) ?? this.userMessage,
      developerMessage: developerMessage?.call(type) ?? this.developerMessage,
    );
  }

  /// Returns a copy of this exception with [userMessage] set by [f].
  CommonException mapUserMessage(String Function(Object type) f) {
    return mapMessage(userMessage: f);
  }

  /// Returns a copy of this exception with [developerMessage] set by [f].
  CommonException mapDeveloperMessage(String Function(Object type) f) {
    return mapMessage(developerMessage: f);
  }

  /// Returns a shallow copy of this exception with the given fields replaced.
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

  /// Converts this exception to a [JsonRpcError] suitable for an RPC response.
  ///
  /// The [JsonRpcErrorCategory] is inferred from the concrete subclass and
  /// [type]. Provide [userMessage] or [developerMessage] to override the
  /// stored values.
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

  /// Converts this exception to an [Information] feedback with the given
  /// [level].
  Information toInformation({FeedbackLevel level = FeedbackLevel.medium}) =>
      Information(
        message: userMessage,
        level: level,
      );

  /// Converts this exception to a [Failure] feedback with the given [level].
  Failure toFailure({FeedbackLevel level = FeedbackLevel.medium}) => Failure(
    message: userMessage,
    level: level,
  );

  /// Converts this exception to a [Warning] feedback with the given [level].
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
