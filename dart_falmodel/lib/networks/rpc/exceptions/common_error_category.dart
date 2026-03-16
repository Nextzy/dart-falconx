/// JSON-RPC error categories aligned with the protocol specification.
enum RemoteErrorCategory {
  API_ERROR,
  EXTERNAL_API_ERROR,
  INVALID_REQUEST_ERROR
  ;

  static RemoteErrorCategory fromJson(String value) =>
      RemoteErrorCategory.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown ErrorCategory: $value'),
      );
}
