// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../json_rpc_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JsonRpcResponse<RESULT>
_$JsonRpcResponseFromJson<RESULT extends JsonRpcResult>(
  Map<String, dynamic> json,
  RESULT Function(Object? json) fromJsonRESULT,
) => _JsonRpcResponse<RESULT>(
  jsonrpc: json['jsonrpc'] as String,
  id: (json['id'] as num).toInt(),
  result: fromJsonRESULT(json['result']),
);

Map<String, dynamic> _$JsonRpcResponseToJson<RESULT extends JsonRpcResult>(
  _JsonRpcResponse<RESULT> instance,
  Object? Function(RESULT value) toJsonRESULT,
) => <String, dynamic>{
  'jsonrpc': instance.jsonrpc,
  'id': instance.id,
  'result': toJsonRESULT(instance.result),
};

_JsonRpcErrorResponse _$JsonRpcErrorResponseFromJson(
  Map<String, dynamic> json,
) => _JsonRpcErrorResponse(
  jsonrpc: json['jsonrpc'] as String,
  id: (json['id'] as num).toInt(),
  errors: (json['errors'] as List<dynamic>)
      .map((e) => JsonRpcError.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$JsonRpcErrorResponseToJson(
  _JsonRpcErrorResponse instance,
) => <String, dynamic>{
  'jsonrpc': instance.jsonrpc,
  'id': instance.id,
  'errors': instance.errors,
};
