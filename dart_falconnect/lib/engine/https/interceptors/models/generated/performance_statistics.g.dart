// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../performance_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PerformanceStatistics _$PerformanceStatisticsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_PerformanceStatistics', json, ($checkedConvert) {
  final val = _PerformanceStatistics(
    totalRequests: $checkedConvert('totalRequests', (v) => (v as num).toInt()),
    successfulRequests: $checkedConvert(
      'successfulRequests',
      (v) => (v as num).toInt(),
    ),
    failedRequests: $checkedConvert(
      'failedRequests',
      (v) => (v as num).toInt(),
    ),
    statusCodeCounts: $checkedConvert(
      'statusCodeCounts',
      (v) => (v as Map<String, dynamic>).map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ),
    ),
    errorCounts: $checkedConvert(
      'errorCounts',
      (v) => Map<String, int>.from(v as Map),
    ),
    totalRequestSize: $checkedConvert(
      'totalRequestSize',
      (v) => (v as num).toInt(),
    ),
    totalResponseSize: $checkedConvert(
      'totalResponseSize',
      (v) => (v as num).toInt(),
    ),
    totalDuration: $checkedConvert(
      'totalDuration',
      (v) => const DurationMillisecondsConverter().fromJson((v as num).toInt()),
    ),
    minDuration: $checkedConvert(
      'minDuration',
      (v) => const DurationMillisecondsConverter().fromJson((v as num).toInt()),
    ),
    maxDuration: $checkedConvert(
      'maxDuration',
      (v) => const DurationMillisecondsConverter().fromJson((v as num).toInt()),
    ),
    recentDurations: $checkedConvert(
      'recentDurations',
      (v) => (v as List<dynamic>)
          .map((e) => Duration(microseconds: (e as num).toInt()))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$PerformanceStatisticsToJson(
  _PerformanceStatistics instance,
) => <String, dynamic>{
  'averageDuration': const DurationMillisecondsConverter().toJson(
    instance.averageDuration,
  ),
  'medianDuration': const DurationMillisecondsConverter().toJson(
    instance.medianDuration,
  ),
  'successRate': instance.successRate,
  'averageRequestSize': instance.averageRequestSize,
  'averageResponseSize': instance.averageResponseSize,
  'totalRequests': instance.totalRequests,
  'successfulRequests': instance.successfulRequests,
  'failedRequests': instance.failedRequests,
  'statusCodeCounts': instance.statusCodeCounts.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
  'errorCounts': instance.errorCounts,
  'totalRequestSize': instance.totalRequestSize,
  'totalResponseSize': instance.totalResponseSize,
  'totalDuration': const DurationMillisecondsConverter().toJson(
    instance.totalDuration,
  ),
  'minDuration': const DurationMillisecondsConverter().toJson(
    instance.minDuration,
  ),
  'maxDuration': const DurationMillisecondsConverter().toJson(
    instance.maxDuration,
  ),
};
