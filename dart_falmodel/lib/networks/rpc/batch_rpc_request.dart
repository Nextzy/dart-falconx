import 'package:dart_falmodel/lib.dart';

part 'generated/batch_rpc_request.g.dart';

/// Represents a single request item within a JSON-RPC batch call.
///
/// Encapsulates the method name, optional parameters, and an optional
/// result deserializer used when parsing the batch response.
@JsonSerializable(includeIfNull: false)
class BatchJsonRpcBody<RESULT> extends JsonRpc {
  /// Creates a [BatchJsonRpcBody] with the required [method] and
  /// optional parameters.
  const new({
    @JsonKey(includeToJson: false, includeFromJson: false) super.jsonrpc,
    @JsonKey(includeToJson: false, includeFromJson: false) super.id,
    required this.method,
    this.params,
    this.fromResultJson,
  }) : super();

  /// Deserializes a [BatchJsonRpcBody] from a JSON map; the envelope
  /// keys and [fromResultJson] are not read.
  factory fromJson(Map<String, dynamic> json) =>
      _$BatchJsonRpcBodyFromJson(json);

  /// The name of the JSON-RPC method to invoke.
  final String? method;

  /// Optional named parameters to pass with the method call.
  final Map<String, dynamic>? params;

  /// Optional function to deserialize the result JSON into [RESULT].
  ///
  /// Excluded from JSON: a function has no wire representation.
  @JsonKey(includeToJson: false, includeFromJson: false)
  final RESULT Function(Map<String, dynamic>? json)? fromResultJson;

  /// Serializes this request body to a JSON map, omitting null fields.
  Map<String, dynamic> toJson() => _$BatchJsonRpcBodyToJson(this);
}
