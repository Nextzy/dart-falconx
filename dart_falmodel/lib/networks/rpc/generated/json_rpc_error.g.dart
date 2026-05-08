// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../json_rpc_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JsonRpcError _$JsonRpcErrorFromJson(Map<String, dynamic> json) =>
    _JsonRpcError(
      category: $enumDecode(_$JsonRpcErrorCategoryEnumMap, json['category']),
      code: json['code'] as String,
      userMessage: json['userMessage'] as String?,
      developerMessage: json['developerMessage'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );

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
