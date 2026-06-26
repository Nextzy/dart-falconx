// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../json_rpc_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JsonRpcError _$JsonRpcErrorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_JsonRpcError', json, ($checkedConvert) {
      final val = _JsonRpcError(
        category: $checkedConvert(
          'category',
          (v) => $enumDecode(_$JsonRpcErrorCategoryEnumMap, v),
        ),
        code: $checkedConvert('code', (v) => v as String),
        userMessage: $checkedConvert('userMessage', (v) => v as String?),
        developerMessage: $checkedConvert(
          'developerMessage',
          (v) => v as String?,
        ),
        data: $checkedConvert('data', (v) => v as Map<String, dynamic>?),
      );
      return val;
    });

Map<String, dynamic> _$JsonRpcErrorToJson(_JsonRpcError instance) =>
    <String, dynamic>{
      'category': _$JsonRpcErrorCategoryEnumMap[instance.category]!,
      'code': instance.code,
      'userMessage': instance.userMessage,
      'developerMessage': ?instance.developerMessage,
      'data': ?instance.data,
    };

const _$JsonRpcErrorCategoryEnumMap = {
  JsonRpcErrorCategory.API_ERROR: 'API_ERROR',
  JsonRpcErrorCategory.EXTERNAL_API_ERROR: 'EXTERNAL_API_ERROR',
  JsonRpcErrorCategory.INVALID_REQUEST_ERROR: 'INVALID_REQUEST_ERROR',
  JsonRpcErrorCategory.UNKNOWN: 'UNKNOWN',
};
