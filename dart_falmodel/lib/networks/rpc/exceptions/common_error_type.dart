/// Marker interface for all JSON-RPC error type discriminants.
interface class JsonRpcErrorType {}

/// Marker interface for server-side API error types.
interface class JsonRpcApiErrorType implements JsonRpcErrorType {}

/// Concrete server-side API error codes used in JSON-RPC error responses.
enum JsonRpcApiErrorTypeEnum implements JsonRpcApiErrorType {
  /// An unhandled error occurred on the server.
  INTERNAL_SERVER_ERROR,

  /// The caller is not authenticated.
  UNAUTHORIZED,

  /// The supplied token is invalid.
  TOKEN_INVALID,

  /// The supplied token has expired.
  TOKEN_EXPIRED,

  /// The supplied token has been revoked.
  TOKEN_REVOKED,

  /// The caller does not have permission to perform this operation.
  FORBIDDEN,

  /// The caller has exceeded the allowed request rate.
  RATE_LIMITED,

  /// The requested RPC method is not yet implemented.
  METHOD_NOT_IMPLEMENTED,

  /// An upstream gateway returned an invalid response.
  BAD_GATEWAY,

  /// The service is temporarily unavailable.
  SERVICE_UNAVAILABLE,

  /// The gateway did not receive a timely response from an upstream server.
  GATEWAY_TIMEOUT,

  /// The requested HTTP method is not allowed on the target resource.
  METHOD_NOT_ALLOWED,

  /// The requested resource was not found.
  NOT_FOUND,

  /// The requested feature is disabled on the server.
  FEATURE_DISABLED;

  /// Parses a [JsonRpcApiErrorTypeEnum] from its string name.
  ///
  /// Throws an [ArgumentError] if [value] does not match any case.
  static JsonRpcApiErrorTypeEnum fromJson(String value) =>
      JsonRpcApiErrorTypeEnum.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown ApiErrorCode: $value'),
      );
}

/// Marker interface for client-side request error types.
interface class JsonRpcRequestErrorType implements JsonRpcErrorType {}

/// Concrete client-side request error codes used in JSON-RPC error responses.
enum JsonRpcRequestErrorTypeEnum implements JsonRpcRequestErrorType {
  /// The request body is not valid JSON-RPC 2.0.
  INVALID_JSON_RPC,

  /// The request is syntactically valid but semantically incorrect.
  BAD_REQUEST,

  /// A parameter has the wrong type.
  INCORRECT_TYPE,

  /// A parameter contains an invalid value.
  INVALID_VALUE,

  /// Two or more parameters conflict with each other.
  CONFLICTING_PARAMETERS;

  /// Parses a [JsonRpcRequestErrorTypeEnum] from its string name.
  ///
  /// Throws an [ArgumentError] if [value] does not match any case.
  static JsonRpcRequestErrorTypeEnum fromJson(String value) =>
      JsonRpcRequestErrorTypeEnum.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown RequestErrorCode: $value'),
      );
}

/// Marker interface for external-API error types.
interface class JsonRpcExternalApiErrorType implements JsonRpcErrorType {}

/// Concrete external-API error codes used in JSON-RPC error responses.
enum JsonRpcExternalApiErrorTypeEnum {
  /// The external API returned a response that is not valid JSON-RPC 2.0.
  INVALID_JSON_RPC,

  /// The external API rejected the request as a bad request.
  BAD_REQUEST,

  /// The external API returned a value of an unexpected type.
  INCORRECT_TYPE,

  /// The external API returned an invalid value.
  INVALID_VALUE,

  /// Conflicting parameters were sent to the external API.
  CONFLICTING_PARAMETERS;

  /// Parses a [JsonRpcExternalApiErrorTypeEnum] from its string name.
  ///
  /// Throws an [ArgumentError] if [value] does not match any case.
  static JsonRpcExternalApiErrorTypeEnum fromJson(String value) =>
      JsonRpcExternalApiErrorTypeEnum.values.firstWhere(
        (e) => e.name == value,
        orElse: () =>
            throw ArgumentError('Unknown RemoteExternalApiErrorCode: $value'),
      );
}
