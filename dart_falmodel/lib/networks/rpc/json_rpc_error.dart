import 'package:dart_falmodel/lib.dart';

part 'generated/json_rpc_error.freezed.dart';

part 'generated/json_rpc_error.g.dart';

/// Domain-level exception that maps directly to a JSON-RPC error object.
///
/// Throw this anywhere in the service layer; the API boundary catches it and
/// serialises it into [JsonRpcErrorResponse].
@freezed
sealed class JsonRpcError with _$JsonRpcError implements Exception {
  const factory JsonRpcError({
    required JsonRpcErrorCategory category,
    required String code,
    required String userMessage,
    @JsonKey(includeIfNull: false) String? developerMessage,
  }) = _JsonRpcError;

  const JsonRpcError._();

  factory JsonRpcError.fromJson(Map<String, dynamic> json) =>
      _$JsonRpcErrorFromJson(json);

  /// Convenience factory for [JsonRpcErrorCategory.INVALID_REQUEST_ERROR].
  factory JsonRpcError.invalidRequest({
    required String code,
    required String userMessage,
    String? developerMessage,
  }) => JsonRpcError(
    category: JsonRpcErrorCategory.INVALID_REQUEST_ERROR,
    code: code,
    userMessage: userMessage,
    developerMessage: developerMessage,
  );

  factory JsonRpcError.external({
    required String code,
    required String userMessage,
    String? developerMessage,
  }) => JsonRpcError(
    category: JsonRpcErrorCategory.EXTERNAL_API_ERROR,
    code: code,
    userMessage: userMessage,
    developerMessage: developerMessage,
  );

  /// Convenience factory for method-not-found errors.
  factory JsonRpcError.methodNotImplement({
    required String userMessage,
    String? developerMessage,
  }) => JsonRpcError(
    category: JsonRpcErrorCategory.INVALID_REQUEST_ERROR,
    code: JsonRpcApiErrorType.METHOD_NOT_IMPLEMENTED.name,
    userMessage: userMessage,
    developerMessage: developerMessage,
  );

  /// Convenience factory for invalid-params errors.
  factory JsonRpcError.invalidParams({
    required String code,
    required String userMessage,
    String? developerMessage,
  }) => JsonRpcError(
    category: JsonRpcErrorCategory.INVALID_REQUEST_ERROR,
    code: code,
    userMessage: userMessage,
    developerMessage: developerMessage,
  );

  /// Convenience factory for [JsonRpcErrorCategory.API_ERROR].
  factory JsonRpcError.internal({
    String? code,
    required String userMessage,
    String? developerMessage,
  }) => JsonRpcError(
    category: JsonRpcErrorCategory.API_ERROR,
    code: code ?? JsonRpcApiErrorType.INTERNAL_SERVER_ERROR.name,
    userMessage: userMessage,
    developerMessage: developerMessage,
  );
}
