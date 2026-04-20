interface class JsonRpcErrorType {}

interface class JsonRpcApiErrorType implements JsonRpcErrorType {}

enum JsonRpcApiErrorTypeEnum implements JsonRpcApiErrorType {
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

  static JsonRpcApiErrorTypeEnum fromJson(String value) =>
      JsonRpcApiErrorTypeEnum.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown ApiErrorCode: $value'),
      );
}

interface class JsonRpcRequestErrorType implements JsonRpcErrorType {}

enum JsonRpcRequestErrorTypeEnum implements JsonRpcRequestErrorType {
  INVALID_JSON_RPC,
  BAD_REQUEST,
  INCORRECT_TYPE,
  INVALID_VALUE,
  CONFLICTING_PARAMETERS;

  static JsonRpcRequestErrorTypeEnum fromJson(String value) =>
      JsonRpcRequestErrorTypeEnum.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown RequestErrorCode: $value'),
      );
}

interface class JsonRpcExternalApiErrorType implements JsonRpcErrorType {}

enum JsonRpcExternalApiErrorTypeEnum {
  INVALID_JSON_RPC,
  BAD_REQUEST,
  INCORRECT_TYPE,
  INVALID_VALUE,
  CONFLICTING_PARAMETERS;

  static JsonRpcExternalApiErrorTypeEnum fromJson(String value) =>
      JsonRpcExternalApiErrorTypeEnum.values.firstWhere(
        (e) => e.name == value,
        orElse: () =>
            throw ArgumentError('Unknown RemoteExternalApiErrorCode: $value'),
      );
}
