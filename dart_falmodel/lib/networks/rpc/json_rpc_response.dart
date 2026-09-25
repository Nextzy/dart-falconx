import 'package:dart_falmodel/src/src.dart';

part 'generated/json_rpc_response.freezed.dart';

part 'generated/json_rpc_response.g.dart';

/// Successful JSON-RPC response envelope.
@Freezed(genericArgumentFactories: true)
sealed class JsonRpcResponse<RESULT extends JsonRpcResult>
    with _$JsonRpcResponse<RESULT> {
  const factory({
    @JsonKey(includeFromJson: true, includeToJson: true)
    required String jsonrpc,
    @JsonKey(includeFromJson: true, includeToJson: true) required int id,
    @JsonKey(includeFromJson: true, includeToJson: true) required RESULT result,
  }) = _JsonRpcResponse;

  factory fromJson(
    Map<String, dynamic> json,
    RESULT Function(Object?) fromJsonResult,
  ) => _$JsonRpcResponseFromJson(json, fromJsonResult);
}

/// Error JSON-RPC response envelope carrying one or more [JsonRpcError]s.
@freezed
sealed class JsonRpcErrorResponse with _$JsonRpcErrorResponse {
  const factory({
    @JsonKey(includeFromJson: true, includeToJson: true)
    required String jsonrpc,
    @JsonKey(includeFromJson: true, includeToJson: true) required int id,
    @JsonKey(includeFromJson: true, includeToJson: true)
    required List<JsonRpcError> errors,
  }) = _JsonRpcErrorResponse;

  factory fromJson(Map<String, dynamic> json) =>
      _$JsonRpcErrorResponseFromJson(json);

  /// Shorthand for a response with a single error.
  factory single({
    required String jsonrpc,
    required int id,
    required JsonRpcError error,
  }) => JsonRpcErrorResponse(jsonrpc: jsonrpc, id: id, errors: [error]);
}
