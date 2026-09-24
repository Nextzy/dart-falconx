// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../request_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RequestMetrics _$RequestMetricsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_RequestMetrics', json, ($checkedConvert) {
  final val = _RequestMetrics(
    method: $checkedConvert('method', (v) => v as String),
    url: $checkedConvert('url', (v) => v as String),
    startTime: $checkedConvert('startTime', (v) => DateTime.parse(v as String)),
    endTime: $checkedConvert(
      'endTime',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    statusCode: $checkedConvert('statusCode', (v) => (v as num?)?.toInt()),
    error: $checkedConvert('error', (v) => v as String?),
    requestSize: $checkedConvert('requestSize', (v) => (v as num?)?.toInt()),
    responseSize: $checkedConvert('responseSize', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$RequestMetricsToJson(_RequestMetrics instance) =>
    <String, dynamic>{
      'totalDuration': const DurationMillisecondsConverter().toJson(
        instance.totalDuration,
      ),
      'method': instance.method,
      'url': instance.url,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'statusCode': instance.statusCode,
      'error': instance.error,
      'requestSize': instance.requestSize,
      'responseSize': instance.responseSize,
    };
