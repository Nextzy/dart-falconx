enum JsonRpcApiErrorType {
  INTERNAL_SERVER_ERROR,
  UNAUTHORIZED,
  TOKEN_INVALID,
  TOKEN_EXPIRED,
  TOKEN_REVOKED,
  FORBIDDEN,
  RATE_LIMITED,
  METHOD_NOT_IMPLEMENTED,
  BAD_GATEWAY,
  SERVICE_UNAVAILABLE,
  GATEWAY_TIMEOUT,
  METHOD_NOT_ALLOWED,
  NOT_FOUND,
  FEATURE_DISABLED;

  static JsonRpcApiErrorType fromJson(String value) =>
      JsonRpcApiErrorType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown ApiErrorCode: $value'),
      );
}

enum JsonRpcRequestErrorType {
  INVALID_JSON_RPC,
  BAD_REQUEST,
  INCORRECT_TYPE,
  INVALID_VALUE,
  CONFLICTING_PARAMETERS;

  static JsonRpcRequestErrorType fromJson(String value) =>
      JsonRpcRequestErrorType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown RequestErrorCode: $value'),
      );
}

enum JsonRpcExternalApiErrorType {
  INVALID_JSON_RPC,
  BAD_REQUEST,
  INCORRECT_TYPE,
  INVALID_VALUE,
  CONFLICTING_PARAMETERS;

  static JsonRpcExternalApiErrorType fromJson(String value) =>
      JsonRpcExternalApiErrorType.values.firstWhere(
        (e) => e.name == value,
        orElse: () =>
            throw ArgumentError('Unknown RemoteExternalApiErrorCode: $value'),
      );
}
