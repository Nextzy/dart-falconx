enum RemoteApiErrorCode {
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
  NOT_FOUND;

  static RemoteApiErrorCode fromJson(String value) =>
      RemoteApiErrorCode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown ApiErrorCode: $value'),
      );
}

enum RemoteRequestErrorCode {
  INVALID_JSON_RPC,
  BAD_REQUEST,
  INCORRECT_TYPE,
  INVALID_VALUE,
  CONFLICTING_PARAMETERS;

  static RemoteRequestErrorCode fromJson(String value) =>
      RemoteRequestErrorCode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown RequestErrorCode: $value'),
      );
}
