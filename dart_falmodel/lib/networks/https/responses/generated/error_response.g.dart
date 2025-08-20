// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../error_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ErrorResponseResponse _$ErrorResponseResponseFromJson(
  Map<String, dynamic> json,
) => _ErrorResponseResponse(
  code: (json['code'] as num?)?.toInt(),
  message: json['message'] as String?,
  userMessage: json['userMessage'] as String?,
  developerMessage: json['developerMessage'] as String?,
);

Map<String, dynamic> _$ErrorResponseResponseToJson(
  _ErrorResponseResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'userMessage': instance.userMessage,
  'developerMessage': instance.developerMessage,
};
