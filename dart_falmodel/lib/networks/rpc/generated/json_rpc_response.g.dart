// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../json_rpc_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JsonRpcResponse<RESULT>
_$JsonRpcResponseFromJson<RESULT extends JsonRpcResult>(
  Map<String, dynamic> json,
  RESULT Function(Object? json) fromJsonRESULT,
) => $checkedCreate('_JsonRpcResponse', json, ($checkedConvert) {
  final val = _JsonRpcResponse<RESULT>(
    jsonrpc: $checkedConvert('jsonrpc', (v) => v as String),
    id: $checkedConvert('id', (v) => (v as num).toInt()),
    result: $checkedConvert('result', (v) => fromJsonRESULT(v)),
  );
  return val;
});

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
) => $checkedCreate('_JsonRpcErrorResponse', json, ($checkedConvert) {
  final val = _JsonRpcErrorResponse(
    jsonrpc: $checkedConvert('jsonrpc', (v) => v as String),
    id: $checkedConvert('id', (v) => (v as num).toInt()),
    errors: $checkedConvert(
      'errors',
      (v) => (v as List<dynamic>)
          .map((e) => JsonRpcError.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$JsonRpcErrorResponseToJson(
  _JsonRpcErrorResponse instance,
) => <String, dynamic>{
  'jsonrpc': instance.jsonrpc,
  'id': instance.id,
  'errors': instance.errors.map((e) => e.toJson()).toList(),
};
