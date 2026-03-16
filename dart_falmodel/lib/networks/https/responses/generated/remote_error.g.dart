// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../remote_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RemoteError _$RemoteErrorFromJson(Map<String, dynamic> json) => _RemoteError(
  code: (json['code'] as num?)?.toInt(),
  message: json['message'] as String?,
  userMessage: json['userMessage'] as String?,
  developerMessage: json['developerMessage'] as String?,
);

Map<String, dynamic> _$RemoteErrorToJson(_RemoteError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'userMessage': instance.userMessage,
      'developerMessage': instance.developerMessage,
    };
