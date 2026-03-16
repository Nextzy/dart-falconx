// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../json_rpc_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JsonRpcError _$JsonRpcErrorFromJson(Map<String, dynamic> json) =>
    _JsonRpcError(
      category: $enumDecode(_$RemoteErrorCategoryEnumMap, json['category']),
      code: json['code'] as String,
      userMessage: json['userMessage'] as String,
      developerMessage: json['developerMessage'] as String?,
    );

Map<String, dynamic> _$JsonRpcErrorToJson(_JsonRpcError instance) =>
    <String, dynamic>{
      'category': _$RemoteErrorCategoryEnumMap[instance.category]!,
      'code': instance.code,
      'userMessage': instance.userMessage,
      'developerMessage': ?instance.developerMessage,
    };

const _$RemoteErrorCategoryEnumMap = {
  RemoteErrorCategory.API_ERROR: 'API_ERROR',
  RemoteErrorCategory.EXTERNAL_API_ERROR: 'EXTERNAL_API_ERROR',
  RemoteErrorCategory.INVALID_REQUEST_ERROR: 'INVALID_REQUEST_ERROR',
};
