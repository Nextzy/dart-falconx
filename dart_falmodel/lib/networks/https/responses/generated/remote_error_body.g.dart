// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../remote_error_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RemoteErrorBody _$RemoteErrorBodyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RemoteErrorBody', json, ($checkedConvert) {
      final val = _RemoteErrorBody(
        code: $checkedConvert('code', (v) => (v as num?)?.toInt()),
        message: $checkedConvert('message', (v) => v as String?),
        userMessage: $checkedConvert('userMessage', (v) => v as String?),
        developerMessage: $checkedConvert(
          'developerMessage',
          (v) => v as String?,
        ),
      );
      return val;
    });

Map<String, dynamic> _$RemoteErrorBodyToJson(_RemoteErrorBody instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'userMessage': instance.userMessage,
      'developerMessage': instance.developerMessage,
    };
