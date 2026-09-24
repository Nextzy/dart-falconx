// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../performance_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PerformanceStatistics {

/// Total number of requests recorded.
 int get totalRequests;/// Number of requests that completed with a 2xx status code.
 int get successfulRequests;/// Number of requests that did not complete with a 2xx status code.
 int get failedRequests;/// Counts of responses grouped by HTTP status code.
 Map<int, int> get statusCodeCounts;/// Counts of errors grouped by error description string.
 Map<String, int> get errorCounts;/// Cumulative size of all request bodies in bytes.
 int get totalRequestSize;/// Cumulative size of all response bodies in bytes.
 int get totalResponseSize;/// Sum of all request durations.
 Duration get totalDuration;/// Shortest recorded request duration.
 Duration get minDuration;/// Longest recorded request duration.
 Duration get maxDuration;/// The most recent request durations, oldest first, capped at 100.
 List<Duration> get recentDurations;
/// Create a copy of PerformanceStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerformanceStatisticsCopyWith<PerformanceStatistics> get copyWith => _$PerformanceStatisticsCopyWithImpl<PerformanceStatistics>(this as PerformanceStatistics, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PerformanceStatistics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerformanceStatistics&&(identical(other.totalRequests, _this.totalRequests) || other.totalRequests == _this.totalRequests)&&(identical(other.successfulRequests, _this.successfulRequests) || other.successfulRequests == _this.successfulRequests)&&(identical(other.failedRequests, _this.failedRequests) || other.failedRequests == _this.failedRequests)&&const DeepCollectionEquality().equals(other.statusCodeCounts, _this.statusCodeCounts)&&const DeepCollectionEquality().equals(other.errorCounts, _this.errorCounts)&&(identical(other.totalRequestSize, _this.totalRequestSize) || other.totalRequestSize == _this.totalRequestSize)&&(identical(other.totalResponseSize, _this.totalResponseSize) || other.totalResponseSize == _this.totalResponseSize)&&(identical(other.totalDuration, _this.totalDuration) || other.totalDuration == _this.totalDuration)&&(identical(other.minDuration, _this.minDuration) || other.minDuration == _this.minDuration)&&(identical(other.maxDuration, _this.maxDuration) || other.maxDuration == _this.maxDuration)&&const DeepCollectionEquality().equals(other.recentDurations, _this.recentDurations));
}


@override
int get hashCode {
  final _this = this as PerformanceStatistics;
  return Object.hash(runtimeType,_this.totalRequests,_this.successfulRequests,_this.failedRequests,const DeepCollectionEquality().hash(_this.statusCodeCounts),const DeepCollectionEquality().hash(_this.errorCounts),_this.totalRequestSize,_this.totalResponseSize,_this.totalDuration,_this.minDuration,_this.maxDuration,const DeepCollectionEquality().hash(_this.recentDurations));
}

@override
String toString() {
  final _this = this as PerformanceStatistics;
  return 'PerformanceStatistics(totalRequests: ${_this.totalRequests}, successfulRequests: ${_this.successfulRequests}, failedRequests: ${_this.failedRequests}, statusCodeCounts: ${_this.statusCodeCounts}, errorCounts: ${_this.errorCounts}, totalRequestSize: ${_this.totalRequestSize}, totalResponseSize: ${_this.totalResponseSize}, totalDuration: ${_this.totalDuration}, minDuration: ${_this.minDuration}, maxDuration: ${_this.maxDuration}, recentDurations: ${_this.recentDurations})';
}


}

/// @nodoc
abstract mixin class $PerformanceStatisticsCopyWith<$Res>  {
  factory $PerformanceStatisticsCopyWith(PerformanceStatistics value, $Res Function(PerformanceStatistics) _then) = _$PerformanceStatisticsCopyWithImpl;
@useResult
$Res call({
 int totalRequests, int successfulRequests, int failedRequests, Map<int, int> statusCodeCounts, Map<String, int> errorCounts, int totalRequestSize, int totalResponseSize, Duration totalDuration, Duration minDuration, Duration maxDuration, List<Duration> recentDurations
});




}
/// @nodoc
class _$PerformanceStatisticsCopyWithImpl<$Res>
    implements $PerformanceStatisticsCopyWith<$Res> {
  _$PerformanceStatisticsCopyWithImpl(this._self, this._then);

  final PerformanceStatistics _self;
  final $Res Function(PerformanceStatistics) _then;

/// Create a copy of PerformanceStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalRequests = null,Object? successfulRequests = null,Object? failedRequests = null,Object? statusCodeCounts = null,Object? errorCounts = null,Object? totalRequestSize = null,Object? totalResponseSize = null,Object? totalDuration = null,Object? minDuration = null,Object? maxDuration = null,Object? recentDurations = null,}) {
  return _then(PerformanceStatistics(
totalRequests: null == totalRequests ? _self.totalRequests : totalRequests // ignore: cast_nullable_to_non_nullable
as int,successfulRequests: null == successfulRequests ? _self.successfulRequests : successfulRequests // ignore: cast_nullable_to_non_nullable
as int,failedRequests: null == failedRequests ? _self.failedRequests : failedRequests // ignore: cast_nullable_to_non_nullable
as int,statusCodeCounts: null == statusCodeCounts ? _self.statusCodeCounts : statusCodeCounts // ignore: cast_nullable_to_non_nullable
as Map<int, int>,errorCounts: null == errorCounts ? _self.errorCounts : errorCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,totalRequestSize: null == totalRequestSize ? _self.totalRequestSize : totalRequestSize // ignore: cast_nullable_to_non_nullable
as int,totalResponseSize: null == totalResponseSize ? _self.totalResponseSize : totalResponseSize // ignore: cast_nullable_to_non_nullable
as int,totalDuration: null == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as Duration,minDuration: null == minDuration ? _self.minDuration : minDuration // ignore: cast_nullable_to_non_nullable
as Duration,maxDuration: null == maxDuration ? _self.maxDuration : maxDuration // ignore: cast_nullable_to_non_nullable
as Duration,recentDurations: null == recentDurations ? _self.recentDurations : recentDurations // ignore: cast_nullable_to_non_nullable
as List<Duration>,
  ));
}

}


/// Adds pattern-matching-related methods to [PerformanceStatistics].
extension PerformanceStatisticsPatterns on PerformanceStatistics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerformanceStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerformanceStatistics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerformanceStatistics value)  $default,){
final _that = this;
switch (_that) {
case _PerformanceStatistics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerformanceStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _PerformanceStatistics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalRequests,  int successfulRequests,  int failedRequests,  Map<int, int> statusCodeCounts,  Map<String, int> errorCounts,  int totalRequestSize,  int totalResponseSize,  Duration totalDuration,  Duration minDuration,  Duration maxDuration,  List<Duration> recentDurations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerformanceStatistics() when $default != null:
return $default(_that.totalRequests,_that.successfulRequests,_that.failedRequests,_that.statusCodeCounts,_that.errorCounts,_that.totalRequestSize,_that.totalResponseSize,_that.totalDuration,_that.minDuration,_that.maxDuration,_that.recentDurations);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalRequests,  int successfulRequests,  int failedRequests,  Map<int, int> statusCodeCounts,  Map<String, int> errorCounts,  int totalRequestSize,  int totalResponseSize,  Duration totalDuration,  Duration minDuration,  Duration maxDuration,  List<Duration> recentDurations)  $default,) {final _that = this;
switch (_that) {
case _PerformanceStatistics():
return $default(_that.totalRequests,_that.successfulRequests,_that.failedRequests,_that.statusCodeCounts,_that.errorCounts,_that.totalRequestSize,_that.totalResponseSize,_that.totalDuration,_that.minDuration,_that.maxDuration,_that.recentDurations);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalRequests,  int successfulRequests,  int failedRequests,  Map<int, int> statusCodeCounts,  Map<String, int> errorCounts,  int totalRequestSize,  int totalResponseSize,  Duration totalDuration,  Duration minDuration,  Duration maxDuration,  List<Duration> recentDurations)?  $default,) {final _that = this;
switch (_that) {
case _PerformanceStatistics() when $default != null:
return $default(_that.totalRequests,_that.successfulRequests,_that.failedRequests,_that.statusCodeCounts,_that.errorCounts,_that.totalRequestSize,_that.totalResponseSize,_that.totalDuration,_that.minDuration,_that.maxDuration,_that.recentDurations);case _:
  return null;

}
}

}

/// @nodoc


class _PerformanceStatistics extends PerformanceStatistics {
  const _PerformanceStatistics({required this.totalRequests, required this.successfulRequests, required this.failedRequests, required  Map<int, int> statusCodeCounts, required  Map<String, int> errorCounts, required this.totalRequestSize, required this.totalResponseSize, required this.totalDuration, required this.minDuration, required this.maxDuration, required  List<Duration> recentDurations}): _statusCodeCounts = statusCodeCounts,_errorCounts = errorCounts,_recentDurations = recentDurations,super._();
  

/// Total number of requests recorded.
@override final  int totalRequests;
/// Number of requests that completed with a 2xx status code.
@override final  int successfulRequests;
/// Number of requests that did not complete with a 2xx status code.
@override final  int failedRequests;
/// Counts of responses grouped by HTTP status code.
 final  Map<int, int> _statusCodeCounts;
/// Counts of responses grouped by HTTP status code.
@override Map<int, int> get statusCodeCounts {
  if (_statusCodeCounts is EqualUnmodifiableMapView) return _statusCodeCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_statusCodeCounts);
}

/// Counts of errors grouped by error description string.
 final  Map<String, int> _errorCounts;
/// Counts of errors grouped by error description string.
@override Map<String, int> get errorCounts {
  if (_errorCounts is EqualUnmodifiableMapView) return _errorCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_errorCounts);
}

/// Cumulative size of all request bodies in bytes.
@override final  int totalRequestSize;
/// Cumulative size of all response bodies in bytes.
@override final  int totalResponseSize;
/// Sum of all request durations.
@override final  Duration totalDuration;
/// Shortest recorded request duration.
@override final  Duration minDuration;
/// Longest recorded request duration.
@override final  Duration maxDuration;
/// The most recent request durations, oldest first, capped at 100.
 final  List<Duration> _recentDurations;
/// The most recent request durations, oldest first, capped at 100.
@override List<Duration> get recentDurations {
  if (_recentDurations is EqualUnmodifiableListView) return _recentDurations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentDurations);
}


/// Create a copy of PerformanceStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerformanceStatisticsCopyWith<_PerformanceStatistics> get copyWith => __$PerformanceStatisticsCopyWithImpl<_PerformanceStatistics>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerformanceStatistics&&(identical(other.totalRequests, totalRequests) || other.totalRequests == totalRequests)&&(identical(other.successfulRequests, successfulRequests) || other.successfulRequests == successfulRequests)&&(identical(other.failedRequests, failedRequests) || other.failedRequests == failedRequests)&&const DeepCollectionEquality().equals(other.statusCodeCounts, _statusCodeCounts)&&const DeepCollectionEquality().equals(other.errorCounts, _errorCounts)&&(identical(other.totalRequestSize, totalRequestSize) || other.totalRequestSize == totalRequestSize)&&(identical(other.totalResponseSize, totalResponseSize) || other.totalResponseSize == totalResponseSize)&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration)&&(identical(other.minDuration, minDuration) || other.minDuration == minDuration)&&(identical(other.maxDuration, maxDuration) || other.maxDuration == maxDuration)&&const DeepCollectionEquality().equals(other.recentDurations, _recentDurations));
}


@override
int get hashCode {
    return Object.hash(runtimeType,totalRequests,successfulRequests,failedRequests,const DeepCollectionEquality().hash(_statusCodeCounts),const DeepCollectionEquality().hash(_errorCounts),totalRequestSize,totalResponseSize,totalDuration,minDuration,maxDuration,const DeepCollectionEquality().hash(_recentDurations));
}

@override
String toString() {
    return 'PerformanceStatistics(totalRequests: $totalRequests, successfulRequests: $successfulRequests, failedRequests: $failedRequests, statusCodeCounts: $statusCodeCounts, errorCounts: $errorCounts, totalRequestSize: $totalRequestSize, totalResponseSize: $totalResponseSize, totalDuration: $totalDuration, minDuration: $minDuration, maxDuration: $maxDuration, recentDurations: $recentDurations)';
}


}

/// @nodoc
abstract mixin class _$PerformanceStatisticsCopyWith<$Res> implements $PerformanceStatisticsCopyWith<$Res> {
  factory _$PerformanceStatisticsCopyWith(_PerformanceStatistics value, $Res Function(_PerformanceStatistics) _then) = __$PerformanceStatisticsCopyWithImpl;
@override @useResult
$Res call({
 int totalRequests, int successfulRequests, int failedRequests, Map<int, int> statusCodeCounts, Map<String, int> errorCounts, int totalRequestSize, int totalResponseSize, Duration totalDuration, Duration minDuration, Duration maxDuration, List<Duration> recentDurations
});




}
/// @nodoc
class __$PerformanceStatisticsCopyWithImpl<$Res>
    implements _$PerformanceStatisticsCopyWith<$Res> {
  __$PerformanceStatisticsCopyWithImpl(this._self, this._then);

  final _PerformanceStatistics _self;
  final $Res Function(_PerformanceStatistics) _then;

/// Create a copy of PerformanceStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalRequests = null,Object? successfulRequests = null,Object? failedRequests = null,Object? statusCodeCounts = null,Object? errorCounts = null,Object? totalRequestSize = null,Object? totalResponseSize = null,Object? totalDuration = null,Object? minDuration = null,Object? maxDuration = null,Object? recentDurations = null,}) {
  return _then(_PerformanceStatistics(
totalRequests: null == totalRequests ? _self.totalRequests : totalRequests // ignore: cast_nullable_to_non_nullable
as int,successfulRequests: null == successfulRequests ? _self.successfulRequests : successfulRequests // ignore: cast_nullable_to_non_nullable
as int,failedRequests: null == failedRequests ? _self.failedRequests : failedRequests // ignore: cast_nullable_to_non_nullable
as int,statusCodeCounts: null == statusCodeCounts ? _self._statusCodeCounts : statusCodeCounts // ignore: cast_nullable_to_non_nullable
as Map<int, int>,errorCounts: null == errorCounts ? _self._errorCounts : errorCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,totalRequestSize: null == totalRequestSize ? _self.totalRequestSize : totalRequestSize // ignore: cast_nullable_to_non_nullable
as int,totalResponseSize: null == totalResponseSize ? _self.totalResponseSize : totalResponseSize // ignore: cast_nullable_to_non_nullable
as int,totalDuration: null == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as Duration,minDuration: null == minDuration ? _self.minDuration : minDuration // ignore: cast_nullable_to_non_nullable
as Duration,maxDuration: null == maxDuration ? _self.maxDuration : maxDuration // ignore: cast_nullable_to_non_nullable
as Duration,recentDurations: null == recentDurations ? _self._recentDurations : recentDurations // ignore: cast_nullable_to_non_nullable
as List<Duration>,
  ));
}


}

// dart format on
