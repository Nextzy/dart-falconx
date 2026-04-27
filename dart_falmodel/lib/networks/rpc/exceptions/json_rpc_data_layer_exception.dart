import 'package:dart_falmodel/lib.dart';

/// JSON-RPC exception that originates in the data layer
/// (repositories, data sources).
class JsonRpcDataLayerException extends JsonRpcCommonException {
  /// Creates a [JsonRpcDataLayerException].
  const JsonRpcDataLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });

  @override
  JsonRpcDataLayerException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => JsonRpcDataLayerException(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}

/// JSON-RPC exception caused by a database operation failure.
class JsonRpcDatabaseException extends JsonRpcDataLayerException {
  /// Creates a [JsonRpcDatabaseException].
  const JsonRpcDatabaseException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });

  @override
  JsonRpcDatabaseException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => JsonRpcDatabaseException(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}

/// JSON-RPC exception caused by a failure in an external API data source.
class JsonRpcExternalApiDataLayerException extends JsonRpcDataLayerException {
  /// Creates a [JsonRpcExternalApiDataLayerException].
  const JsonRpcExternalApiDataLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });

  @override
  JsonRpcExternalApiDataLayerException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => JsonRpcExternalApiDataLayerException(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}
