import 'package:dart_falmodel/lib.dart';

part 'generated/json_rpc_response.freezed.dart';

part 'generated/json_rpc_response.g.dart';

/// Successful JSON-RPC response envelope.
@Freezed(genericArgumentFactories: true)
sealed class JsonRpcResponse<RESULT extends JsonRpcResult>
    with _$JsonRpcResponse<RESULT> {
  const factory JsonRpcResponse({
    required String jsonrpc,
    required int id,
    required RESULT result,
  }) = _JsonRpcResponse;

  factory JsonRpcResponse.fromJson(
    Map<String, dynamic> json,
    RESULT Function(Object?) fromJsonResult,
  ) => _$JsonRpcResponseFromJson(json, fromJsonResult);
}

/// Error JSON-RPC response envelope carrying one or more [JsonRpcError]s.
@freezed
sealed class JsonRpcErrorResponse with _$JsonRpcErrorResponse {
  const factory JsonRpcErrorResponse({
    required String jsonrpc,
    required int id,
    required List<JsonRpcError> errors,
  }) = _JsonRpcErrorResponse;

  factory JsonRpcErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$JsonRpcErrorResponseFromJson(json);

  /// Shorthand for a response with a single error.
  factory JsonRpcErrorResponse.single({
    required String jsonrpc,
    required int id,
    required JsonRpcError error,
  }) => JsonRpcErrorResponse(jsonrpc: jsonrpc, id: id, errors: [error]);
}
