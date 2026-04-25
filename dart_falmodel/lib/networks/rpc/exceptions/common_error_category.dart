/// JSON-RPC error categories aligned with the protocol specification.
enum JsonRpcErrorCategory {
  /// The error originated inside the API server.
  API_ERROR,

  /// The error originated in an external (third-party) API.
  EXTERNAL_API_ERROR,

  /// The error is due to an invalid or malformed request from the client.
  INVALID_REQUEST_ERROR,

  /// The error category could not be determined.
  UNKNOWN;

  /// Parses a [JsonRpcErrorCategory] from its string name.
  ///
  /// Throws an [ArgumentError] if [value] does not match any category.
  static JsonRpcErrorCategory fromJson(String value) =>
      JsonRpcErrorCategory.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown ErrorCategory: $value'),
      );
}
