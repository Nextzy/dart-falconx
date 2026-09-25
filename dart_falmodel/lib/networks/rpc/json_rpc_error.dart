import 'package:dart_falmodel/src/src.dart';

part 'generated/json_rpc_error.freezed.dart';

part 'generated/json_rpc_error.g.dart';

/// Domain-level exception that maps directly to a JSON-RPC error object.
///
/// Throw this anywhere in the service layer; the API boundary catches it and
/// serialises it into [JsonRpcErrorResponse].
@freezed
sealed class JsonRpcError with _$JsonRpcError implements Exception {
  const factory({
    required JsonRpcErrorCategory category,
    required String code,
    String? userMessage,
    @JsonKey(includeIfNull: false) String? developerMessage,
    @JsonKey(includeIfNull: false) Map<String, dynamic>? data,
  }) = _JsonRpcError;

  const new _();

  factory fromJson(Map<String, dynamic> json) => _$JsonRpcErrorFromJson(json);

  /// Convenience factory for [JsonRpcErrorCategory.INVALID_REQUEST_ERROR].
  factory invalidRequest({
    required String code,
    String? userMessage,
    String? developerMessage,
    Map<String, dynamic>? data,
  }) => JsonRpcError(
    category: JsonRpcErrorCategory.INVALID_REQUEST_ERROR,
    code: code,
    userMessage: userMessage,
    developerMessage: developerMessage,
    data: data,
  );

  factory external({
    required String code,
    String? userMessage,
    String? developerMessage,
    Map<String, dynamic>? data,
  }) => JsonRpcError(
    category: JsonRpcErrorCategory.EXTERNAL_API_ERROR,
    code: code,
    userMessage: userMessage,
    developerMessage: developerMessage,
    data: data,
  );

  /// Convenience factory for method-not-found errors.
  factory methodNotImplement({
    String? userMessage,
    String? developerMessage,
    Map<String, dynamic>? data,
  }) => JsonRpcError(
    category: JsonRpcErrorCategory.INVALID_REQUEST_ERROR,
    code: JsonRpcApiErrorTypeEnum.METHOD_NOT_IMPLEMENTED.name,
    userMessage: userMessage,
    developerMessage: developerMessage,
    data: data,
  );

  /// Convenience factory for invalid-params errors.
  factory invalidParams({
    required String code,
    String? userMessage,
    String? developerMessage,
    Map<String, dynamic>? data,
  }) => JsonRpcError(
    category: JsonRpcErrorCategory.INVALID_REQUEST_ERROR,
    code: code,
    userMessage: userMessage,
    developerMessage: developerMessage,
    data: data,
  );

  /// Convenience factory for [JsonRpcErrorCategory.API_ERROR].
  factory internal({
    String? code,
    String? userMessage,
    String? developerMessage,
    Map<String, dynamic>? data,
  }) => JsonRpcError(
    category: JsonRpcErrorCategory.API_ERROR,
    code: code ?? JsonRpcApiErrorTypeEnum.INTERNAL_SERVER_ERROR.name,
    userMessage: userMessage,
    developerMessage: developerMessage,
    data: data,
  );
}
