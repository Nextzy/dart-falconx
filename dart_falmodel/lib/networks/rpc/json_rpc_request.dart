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
  const factory({
    @JsonKey(includeFromJson: true, includeToJson: true)
    required String jsonrpc,
    @JsonKey(includeFromJson: true, includeToJson: true) required String method,
    Map<String, dynamic>? params,
    int? id,
  }) = _JsonRpcRequest;

  const new _({super.jsonrpc, super.id}) : super();

  /// Deserializes a [JsonRpcRequest] from a JSON map.
  factory fromJson(Map<String, dynamic> json) => _$JsonRpcRequestFromJson(json);
}
