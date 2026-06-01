/// Base class for all JSON-RPC result objects.
///
/// Every `Remote...Result` freezed class implements this interface,
/// which guarantees a `toJson()` method for serialization at the
/// protocol boundary.
abstract class JsonRpcResult {
  const JsonRpcResult();
}

abstract class JsonRpcModelResult extends JsonRpcResult {
  /// Serializes this result to a JSON-compatible map.
  Map<String, dynamic> toJson();
}

class JsonRpcListResult<T extends JsonRpcResult> extends JsonRpcResult {
  const JsonRpcListResult(this.data);

  final List<T> data;

  List<dynamic> toJson() {
    return data
        .map(
          (result) => switch (result) {
            JsonRpcModelResult() => result.toJson(),
            JsonRpcListResult() => result.toJson(),
            JsonRpcRawResult() => result.toJson(),
            JsonRpcIntResult() => result.data,
            JsonRpcStringResult() => result.data,
            JsonRpcBoolResult() => result.data,
            _ => throw UnimplementedError(
              'Unsupported JsonRpcResult subtype: ${result.runtimeType}',
            ),
          },
        )
        .toList();
  }
}

class JsonRpcIntResult extends JsonRpcResult {
  const JsonRpcIntResult(this.data);

  final int data;
}

abstract class JsonRpcStringResult extends JsonRpcResult {
  const JsonRpcStringResult(this.data);

  final String data;
}

abstract class JsonRpcBoolResult extends JsonRpcResult {
  const JsonRpcBoolResult(this.data);

  final bool data;
}

/// Wraps a pre-built [Map] as a [JsonRpcResult] for handlers that
/// construct their response maps manually.
class JsonRpcRawResult implements JsonRpcResult {
  /// Creates a [JsonRpcRawResult] wrapping the given data map.
  const JsonRpcRawResult(this._data);

  final Map<String, dynamic> _data;

  Map<String, dynamic> toJson() => _data;
}
