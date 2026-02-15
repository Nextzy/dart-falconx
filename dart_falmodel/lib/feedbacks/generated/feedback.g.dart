// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Success _$SuccessFromJson(Map<String, dynamic> json) => Success(
  message: json['message'] as String?,
  level:
      $enumDecodeNullable(_$FeedbackLevelEnumMap, json['level']) ??
      FeedbackLevel.medium,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$SuccessToJson(Success instance) => <String, dynamic>{
  'message': instance.message,
  'level': _$FeedbackLevelEnumMap[instance.level]!,
  'runtimeType': instance.$type,
};

const _$FeedbackLevelEnumMap = {
  FeedbackLevel.low: 'low',
  FeedbackLevel.medium: 'medium',
  FeedbackLevel.high: 'high',
  FeedbackLevel.critical: 'critical',
};

Warning _$WarningFromJson(Map<String, dynamic> json) => Warning(
  message: json['message'] as String?,
  level:
      $enumDecodeNullable(_$FeedbackLevelEnumMap, json['level']) ??
      FeedbackLevel.medium,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$WarningToJson(Warning instance) => <String, dynamic>{
  'message': instance.message,
  'level': _$FeedbackLevelEnumMap[instance.level]!,
  'runtimeType': instance.$type,
};

Failure _$FailureFromJson(Map<String, dynamic> json) => Failure(
  message: json['message'] as String?,
  level:
      $enumDecodeNullable(_$FeedbackLevelEnumMap, json['level']) ??
      FeedbackLevel.medium,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$FailureToJson(Failure instance) => <String, dynamic>{
  'message': instance.message,
  'level': _$FeedbackLevelEnumMap[instance.level]!,
  'runtimeType': instance.$type,
};

Information _$InformationFromJson(Map<String, dynamic> json) => Information(
  message: json['message'] as String?,
  level:
      $enumDecodeNullable(_$FeedbackLevelEnumMap, json['level']) ??
      FeedbackLevel.medium,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$InformationToJson(Information instance) =>
    <String, dynamic>{
      'message': instance.message,
      'level': _$FeedbackLevelEnumMap[instance.level]!,
      'runtimeType': instance.$type,
    };
