// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../request_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RequestMetrics {

/// HTTP method (e.g. `GET`, `POST`).
 String get method;/// Full request URL.
 String get url;/// Timestamp when the request was initiated.
 DateTime get startTime;/// Timestamp when the response (or error) was received.
 DateTime? get endTime;/// HTTP status code of the response, if available.
 int? get statusCode;/// Error description if the request failed.
 String? get error;/// Request body size in bytes.
 int? get requestSize;/// Response body size in bytes.
 int? get responseSize;
/// Create a copy of RequestMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequestMetricsCopyWith<RequestMetrics> get copyWith => _$RequestMetricsCopyWithImpl<RequestMetrics>(this as RequestMetrics, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RequestMetrics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestMetrics&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.startTime, _this.startTime) || other.startTime == _this.startTime)&&(identical(other.endTime, _this.endTime) || other.endTime == _this.endTime)&&(identical(other.statusCode, _this.statusCode) || other.statusCode == _this.statusCode)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.requestSize, _this.requestSize) || other.requestSize == _this.requestSize)&&(identical(other.responseSize, _this.responseSize) || other.responseSize == _this.responseSize));
}


@override
int get hashCode {
  final _this = this as RequestMetrics;
  return Object.hash(runtimeType,_this.method,_this.url,_this.startTime,_this.endTime,_this.statusCode,_this.error,_this.requestSize,_this.responseSize);
}

@override
String toString() {
  final _this = this as RequestMetrics;
  return 'RequestMetrics(method: ${_this.method}, url: ${_this.url}, startTime: ${_this.startTime}, endTime: ${_this.endTime}, statusCode: ${_this.statusCode}, error: ${_this.error}, requestSize: ${_this.requestSize}, responseSize: ${_this.responseSize})';
}


}

/// @nodoc
abstract mixin class $RequestMetricsCopyWith<$Res>  {
  factory $RequestMetricsCopyWith(RequestMetrics value, $Res Function(RequestMetrics) _then) = _$RequestMetricsCopyWithImpl;
@useResult
$Res call({
 String method, String url, DateTime startTime, DateTime? endTime, int? statusCode, String? error, int? requestSize, int? responseSize
});




}
/// @nodoc
class _$RequestMetricsCopyWithImpl<$Res>
    implements $RequestMetricsCopyWith<$Res> {
  _$RequestMetricsCopyWithImpl(this._self, this._then);

  final RequestMetrics _self;
  final $Res Function(RequestMetrics) _then;

/// Create a copy of RequestMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? method = null,Object? url = null,Object? startTime = null,Object? endTime = freezed,Object? statusCode = freezed,Object? error = freezed,Object? requestSize = freezed,Object? responseSize = freezed,}) {
  return _then(RequestMetrics(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,requestSize: freezed == requestSize ? _self.requestSize : requestSize // ignore: cast_nullable_to_non_nullable
as int?,responseSize: freezed == responseSize ? _self.responseSize : responseSize // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RequestMetrics].
extension RequestMetricsPatterns on RequestMetrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RequestMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RequestMetrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RequestMetrics value)  $default,){
final _that = this;
switch (_that) {
case _RequestMetrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RequestMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _RequestMetrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String method,  String url,  DateTime startTime,  DateTime? endTime,  int? statusCode,  String? error,  int? requestSize,  int? responseSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RequestMetrics() when $default != null:
return $default(_that.method,_that.url,_that.startTime,_that.endTime,_that.statusCode,_that.error,_that.requestSize,_that.responseSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String method,  String url,  DateTime startTime,  DateTime? endTime,  int? statusCode,  String? error,  int? requestSize,  int? responseSize)  $default,) {final _that = this;
switch (_that) {
case _RequestMetrics():
return $default(_that.method,_that.url,_that.startTime,_that.endTime,_that.statusCode,_that.error,_that.requestSize,_that.responseSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String method,  String url,  DateTime startTime,  DateTime? endTime,  int? statusCode,  String? error,  int? requestSize,  int? responseSize)?  $default,) {final _that = this;
switch (_that) {
case _RequestMetrics() when $default != null:
return $default(_that.method,_that.url,_that.startTime,_that.endTime,_that.statusCode,_that.error,_that.requestSize,_that.responseSize);case _:
  return null;

}
}

}

/// @nodoc


class _RequestMetrics extends RequestMetrics {
  const _RequestMetrics({required this.method, required this.url, required this.startTime, this.endTime, this.statusCode, this.error, this.requestSize, this.responseSize}): super._();
  

/// HTTP method (e.g. `GET`, `POST`).
@override final  String method;
/// Full request URL.
@override final  String url;
/// Timestamp when the request was initiated.
@override final  DateTime startTime;
/// Timestamp when the response (or error) was received.
@override final  DateTime? endTime;
/// HTTP status code of the response, if available.
@override final  int? statusCode;
/// Error description if the request failed.
@override final  String? error;
/// Request body size in bytes.
@override final  int? requestSize;
/// Response body size in bytes.
@override final  int? responseSize;

/// Create a copy of RequestMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RequestMetricsCopyWith<_RequestMetrics> get copyWith => __$RequestMetricsCopyWithImpl<_RequestMetrics>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RequestMetrics&&(identical(other.method, method) || other.method == method)&&(identical(other.url, url) || other.url == url)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.error, error) || other.error == error)&&(identical(other.requestSize, requestSize) || other.requestSize == requestSize)&&(identical(other.responseSize, responseSize) || other.responseSize == responseSize));
}


@override
int get hashCode {
    return Object.hash(runtimeType,method,url,startTime,endTime,statusCode,error,requestSize,responseSize);
}

@override
String toString() {
    return 'RequestMetrics(method: $method, url: $url, startTime: $startTime, endTime: $endTime, statusCode: $statusCode, error: $error, requestSize: $requestSize, responseSize: $responseSize)';
}


}

/// @nodoc
abstract mixin class _$RequestMetricsCopyWith<$Res> implements $RequestMetricsCopyWith<$Res> {
  factory _$RequestMetricsCopyWith(_RequestMetrics value, $Res Function(_RequestMetrics) _then) = __$RequestMetricsCopyWithImpl;
@override @useResult
$Res call({
 String method, String url, DateTime startTime, DateTime? endTime, int? statusCode, String? error, int? requestSize, int? responseSize
});




}
/// @nodoc
class __$RequestMetricsCopyWithImpl<$Res>
    implements _$RequestMetricsCopyWith<$Res> {
  __$RequestMetricsCopyWithImpl(this._self, this._then);

  final _RequestMetrics _self;
  final $Res Function(_RequestMetrics) _then;

/// Create a copy of RequestMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? method = null,Object? url = null,Object? startTime = null,Object? endTime = freezed,Object? statusCode = freezed,Object? error = freezed,Object? requestSize = freezed,Object? responseSize = freezed,}) {
  return _then(_RequestMetrics(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,requestSize: freezed == requestSize ? _self.requestSize : requestSize // ignore: cast_nullable_to_non_nullable
as int?,responseSize: freezed == responseSize ? _self.responseSize : responseSize // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
