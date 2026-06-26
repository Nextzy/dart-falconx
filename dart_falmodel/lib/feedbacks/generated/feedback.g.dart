// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Success _$SuccessFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Success', json, ($checkedConvert) {
      final val = Success(
        message: $checkedConvert('message', (v) => v as String?),
        level: $checkedConvert(
          'level',
          (v) =>
              $enumDecodeNullable(_$FeedbackLevelEnumMap, v) ??
              FeedbackLevel.medium,
        ),
        $type: $checkedConvert('runtimeType', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'runtimeType'});

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

Warning _$WarningFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Warning', json, ($checkedConvert) {
      final val = Warning(
        message: $checkedConvert('message', (v) => v as String?),
        level: $checkedConvert(
          'level',
          (v) =>
              $enumDecodeNullable(_$FeedbackLevelEnumMap, v) ??
              FeedbackLevel.medium,
        ),
        $type: $checkedConvert('runtimeType', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'runtimeType'});

Map<String, dynamic> _$WarningToJson(Warning instance) => <String, dynamic>{
  'message': instance.message,
  'level': _$FeedbackLevelEnumMap[instance.level]!,
  'runtimeType': instance.$type,
};

Failure _$FailureFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Failure', json, ($checkedConvert) {
      final val = Failure(
        message: $checkedConvert('message', (v) => v as String?),
        level: $checkedConvert(
          'level',
          (v) =>
              $enumDecodeNullable(_$FeedbackLevelEnumMap, v) ??
              FeedbackLevel.medium,
        ),
        $type: $checkedConvert('runtimeType', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'runtimeType'});

Map<String, dynamic> _$FailureToJson(Failure instance) => <String, dynamic>{
  'message': instance.message,
  'level': _$FeedbackLevelEnumMap[instance.level]!,
  'runtimeType': instance.$type,
};

Information _$InformationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Information', json, ($checkedConvert) {
      final val = Information(
        message: $checkedConvert('message', (v) => v as String?),
        level: $checkedConvert(
          'level',
          (v) =>
              $enumDecodeNullable(_$FeedbackLevelEnumMap, v) ??
              FeedbackLevel.medium,
        ),
        $type: $checkedConvert('runtimeType', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'runtimeType'});

Map<String, dynamic> _$InformationToJson(Information instance) =>
    <String, dynamic>{
      'message': instance.message,
      'level': _$FeedbackLevelEnumMap[instance.level]!,
      'runtimeType': instance.$type,
    };
