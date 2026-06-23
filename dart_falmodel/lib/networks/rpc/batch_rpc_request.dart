import 'package:dart_falmodel/lib.dart';

/// Represents a single request item within a JSON-RPC batch call.
///
/// Encapsulates the method name, optional parameters, and an optional
/// result deserializer used when parsing the batch response.
class BatchJsonRpcBody<RESULT> extends JsonRpc {
  /// Creates a [BatchJsonRpcBody] with the required [method] and
  /// optional parameters.
  const BatchJsonRpcBody({
    super.jsonrpc,
    super.id,
    required this.method,
    this.params,
    this.fromResultJson,
  }) : super();

  /// The name of the JSON-RPC method to invoke.
  final String? method;

  /// Optional named parameters to pass with the method call.
  final Map<String, dynamic>? params;

  /// Optional function to deserialize the result JSON into [RESULT].
  final RESULT Function(Map<String, dynamic>? json)? fromResultJson;

  /// Serializes this request body to a JSON map, omitting null fields.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['method'] = method;
    json['params'] = params;
    json.removeWhere((k, v) => v == null);
    return json;
  }
}
