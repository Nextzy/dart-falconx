import 'package:dart_falmodel/lib.dart';

/// JSON-RPC exception that originates in the domain layer
/// (use cases, business logic).
class JsonRpcDomainLayerException extends JsonRpcCommonException {
  /// Creates a [JsonRpcDomainLayerException].
  const JsonRpcDomainLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });

  @override
  JsonRpcDomainLayerException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => JsonRpcDomainLayerException(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}

/// JSON-RPC exception caused by a failure inside the internal API domain logic.
///
/// Maps to [JsonRpcErrorCategory.API_ERROR] when converted
/// via [toJsonRpcError].
class JsonRpcInternalApiDomainLayerException
    extends JsonRpcDomainLayerException {
  /// Creates a [JsonRpcInternalApiDomainLayerException].
  const JsonRpcInternalApiDomainLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });

  @override
  JsonRpcInternalApiDomainLayerException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => JsonRpcInternalApiDomainLayerException(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}

/// JSON-RPC exception caused by a failure in an external API
/// at the domain layer.
///
/// Maps to [JsonRpcErrorCategory.EXTERNAL_API_ERROR] when converted
/// via [toJsonRpcError].
class JsonRpcExternalApiDomainLayerException
    extends JsonRpcDomainLayerException {
  /// Creates a [JsonRpcExternalApiDomainLayerException].
  const JsonRpcExternalApiDomainLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });

  @override
  JsonRpcExternalApiDomainLayerException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => JsonRpcExternalApiDomainLayerException(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}

/// JSON-RPC exception caused by an invalid client request at the domain layer.
///
/// Maps to [JsonRpcErrorCategory.INVALID_REQUEST_ERROR] when converted
/// via [toJsonRpcError].
class JsonRpcInvalidRequestDomainLayerException
    extends JsonRpcDomainLayerException {
  /// Creates a [JsonRpcInvalidRequestDomainLayerException].
  const JsonRpcInvalidRequestDomainLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });

  @override
  JsonRpcInvalidRequestDomainLayerException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => JsonRpcInvalidRequestDomainLayerException(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}

/// JSON-RPC exception for requests that are syntactically valid but
/// semantically incorrect.
///
/// Defaults [type] to [JsonRpcRequestErrorTypeEnum.BAD_REQUEST].
class JsonRpcBadRequestDomainLayerException
    extends JsonRpcDomainLayerException {
  /// Creates a [JsonRpcBadRequestDomainLayerException].
  const JsonRpcBadRequestDomainLayerException({
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  }) : super(type: JsonRpcRequestErrorTypeEnum.BAD_REQUEST);

  /// Returns a copy preserving the [JsonRpcBadRequestDomainLayerException]
  /// subclass. The [type] parameter is accepted for signature compatibility
  /// with [CommonException.copyWith] but ignored — this exception always
  /// carries [JsonRpcRequestErrorTypeEnum.BAD_REQUEST]. Callers needing
  /// a different type should construct a different subclass instead.
  @override
  JsonRpcBadRequestDomainLayerException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => JsonRpcBadRequestDomainLayerException(
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}
