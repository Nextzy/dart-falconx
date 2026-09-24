// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../batch_rpc_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchJsonRpcBody<RESULT> _$BatchJsonRpcBodyFromJson<RESULT>(
  Map<String, dynamic> json,
) => $checkedCreate('BatchJsonRpcBody', json, ($checkedConvert) {
  final val = BatchJsonRpcBody<RESULT>(
    method: $checkedConvert('method', (v) => v as String?),
    params: $checkedConvert('params', (v) => v as Map<String, dynamic>?),
  );
  return val;
});

Map<String, dynamic> _$BatchJsonRpcBodyToJson<RESULT>(
  BatchJsonRpcBody<RESULT> instance,
) => <String, dynamic>{'method': ?instance.method, 'params': ?instance.params};
