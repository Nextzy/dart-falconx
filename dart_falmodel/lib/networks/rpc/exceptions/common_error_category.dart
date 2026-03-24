/// JSON-RPC error categories aligned with the protocol specification.
enum JsonRpcErrorCategory {
  API_ERROR,
  EXTERNAL_API_ERROR,
  INVALID_REQUEST_ERROR,
  UNKNOWN;

  static JsonRpcErrorCategory fromJson(String value) =>
      JsonRpcErrorCategory.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown ErrorCategory: $value'),
      );
}
