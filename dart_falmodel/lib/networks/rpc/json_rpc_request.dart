import 'package:dart_falmodel/lib.dart';

part 'generated/json_rpc_request.freezed.dart';

part 'generated/json_rpc_request.g.dart';

@freezed
abstract class JsonRpcRequest extends JsonRpc with _$JsonRpcRequest {
  const factory JsonRpcRequest({
    required String jsonrpc,
    required String method,
    Map<String, dynamic>? params,
    int? id,
  }) = _JsonRpcRequest;

  const JsonRpcRequest._({
    super.jsonrpc,
    super.id,
  }) : super();

  factory JsonRpcRequest.fromJson(Map<String, dynamic> json) =>
      _$JsonRpcRequestFromJson(json);
}
