// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../json_rpc_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JsonRpcRequest _$JsonRpcRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_JsonRpcRequest', json, ($checkedConvert) {
      final val = _JsonRpcRequest(
        jsonrpc: $checkedConvert('jsonrpc', (v) => v as String),
        method: $checkedConvert('method', (v) => v as String),
        params: $checkedConvert('params', (v) => v as Map<String, dynamic>?),
        id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$JsonRpcRequestToJson(_JsonRpcRequest instance) =>
    <String, dynamic>{
      'jsonrpc': instance.jsonrpc,
      'id': instance.id,
      'method': instance.method,
      'params': instance.params,
    };
