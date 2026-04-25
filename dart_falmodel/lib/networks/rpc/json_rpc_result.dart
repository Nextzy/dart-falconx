/// Base class for all JSON-RPC result objects.
///
/// Every `Remote...Result` freezed class implements this interface,
/// which guarantees a `toJson()` method for serialization at the
/// protocol boundary.
// ignore: one_member_abstracts
abstract class JsonRpcResult {
  /// Serializes this result to a JSON-compatible map.
  Map<String, dynamic> toJson();
}

/// Wraps a pre-built [Map] as a [JsonRpcResult] for handlers that
/// construct their response maps manually.
class RawJsonRpcResult implements JsonRpcResult {
  /// Creates a [RawJsonRpcResult] wrapping the given data map.
  const RawJsonRpcResult(this._data);

  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> toJson() => _data;
}
