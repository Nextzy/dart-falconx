import 'package:dart_falmodel/lib.dart';

part 'generated/json_rpc_request.freezed.dart';

part 'generated/json_rpc_request.g.dart';

/// Freezed model representing a JSON-RPC 2.0 request.
///
/// Contains the protocol version, method name, optional parameters, and
/// an optional id.
@freezed
abstract class JsonRpcRequest extends JsonRpc with _$JsonRpcRequest {
  /// Creates a [JsonRpcRequest] with the required [jsonrpc] version
  /// and [method].
  const factory JsonRpcRequest({
    @JsonKey(includeFromJson: true, includeToJson: true)
    required String jsonrpc,
    @JsonKey(includeFromJson: true, includeToJson: true) required String method,
    Map<String, dynamic>? params,
    int? id,
  }) = _JsonRpcRequest;

  const JsonRpcRequest._({
    super.jsonrpc,
    super.id,
  }) : super();

  /// Deserializes a [JsonRpcRequest] from a JSON map.
  factory JsonRpcRequest.fromJson(Map<String, dynamic> json) =>
      _$JsonRpcRequestFromJson(json);
}
