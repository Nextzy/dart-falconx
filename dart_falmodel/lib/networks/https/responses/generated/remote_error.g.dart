// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../remote_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RemoteError _$RemoteErrorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RemoteError', json, ($checkedConvert) {
      final val = _RemoteError(
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

Map<String, dynamic> _$RemoteErrorToJson(_RemoteError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'userMessage': instance.userMessage,
      'developerMessage': instance.developerMessage,
    };
