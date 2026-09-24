// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../retry_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RetryConfig {

/// Most retries of one request.
 int get maxAttempts;/// Base delay of the exponential backoff.
 Duration get delay;/// Longest wait before one retry, and the cap on `Retry-After`.
 Duration get maxDelay;/// Most time spent retrying one request, from its first failure.
 Duration get maxDuration;/// Called before each retry waits.
 RetryCallback? get onRetry;
/// Create a copy of RetryConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RetryConfigCopyWith<RetryConfig> get copyWith => _$RetryConfigCopyWithImpl<RetryConfig>(this as RetryConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RetryConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RetryConfig&&(identical(other.maxAttempts, _this.maxAttempts) || other.maxAttempts == _this.maxAttempts)&&(identical(other.delay, _this.delay) || other.delay == _this.delay)&&(identical(other.maxDelay, _this.maxDelay) || other.maxDelay == _this.maxDelay)&&(identical(other.maxDuration, _this.maxDuration) || other.maxDuration == _this.maxDuration)&&(identical(other.onRetry, _this.onRetry) || other.onRetry == _this.onRetry));
}


@override
int get hashCode {
  final _this = this as RetryConfig;
  return Object.hash(runtimeType,_this.maxAttempts,_this.delay,_this.maxDelay,_this.maxDuration,_this.onRetry);
}

@override
String toString() {
  final _this = this as RetryConfig;
  return 'RetryConfig(maxAttempts: ${_this.maxAttempts}, delay: ${_this.delay}, maxDelay: ${_this.maxDelay}, maxDuration: ${_this.maxDuration}, onRetry: ${_this.onRetry})';
}


}

/// @nodoc
abstract mixin class $RetryConfigCopyWith<$Res>  {
  factory $RetryConfigCopyWith(RetryConfig value, $Res Function(RetryConfig) _then) = _$RetryConfigCopyWithImpl;
@useResult
$Res call({
 int maxAttempts, Duration delay, Duration maxDelay, Duration maxDuration, RetryCallback? onRetry
});




}
/// @nodoc
class _$RetryConfigCopyWithImpl<$Res>
    implements $RetryConfigCopyWith<$Res> {
  _$RetryConfigCopyWithImpl(this._self, this._then);

  final RetryConfig _self;
  final $Res Function(RetryConfig) _then;

/// Create a copy of RetryConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxAttempts = null,Object? delay = null,Object? maxDelay = null,Object? maxDuration = null,Object? onRetry = freezed,}) {
  return _then(RetryConfig(
maxAttempts: null == maxAttempts ? _self.maxAttempts : maxAttempts // ignore: cast_nullable_to_non_nullable
as int,delay: null == delay ? _self.delay : delay // ignore: cast_nullable_to_non_nullable
as Duration,maxDelay: null == maxDelay ? _self.maxDelay : maxDelay // ignore: cast_nullable_to_non_nullable
as Duration,maxDuration: null == maxDuration ? _self.maxDuration : maxDuration // ignore: cast_nullable_to_non_nullable
as Duration,onRetry: freezed == onRetry ? _self.onRetry : onRetry // ignore: cast_nullable_to_non_nullable
as RetryCallback?,
  ));
}

}


/// Adds pattern-matching-related methods to [RetryConfig].
extension RetryConfigPatterns on RetryConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RetryConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RetryConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RetryConfig value)  $default,){
final _that = this;
switch (_that) {
case _RetryConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RetryConfig value)?  $default,){
final _that = this;
switch (_that) {
case _RetryConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maxAttempts,  Duration delay,  Duration maxDelay,  Duration maxDuration,  RetryCallback? onRetry)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RetryConfig() when $default != null:
return $default(_that.maxAttempts,_that.delay,_that.maxDelay,_that.maxDuration,_that.onRetry);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maxAttempts,  Duration delay,  Duration maxDelay,  Duration maxDuration,  RetryCallback? onRetry)  $default,) {final _that = this;
switch (_that) {
case _RetryConfig():
return $default(_that.maxAttempts,_that.delay,_that.maxDelay,_that.maxDuration,_that.onRetry);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maxAttempts,  Duration delay,  Duration maxDelay,  Duration maxDuration,  RetryCallback? onRetry)?  $default,) {final _that = this;
switch (_that) {
case _RetryConfig() when $default != null:
return $default(_that.maxAttempts,_that.delay,_that.maxDelay,_that.maxDuration,_that.onRetry);case _:
  return null;

}
}

}

/// @nodoc


class _RetryConfig implements RetryConfig {
  const _RetryConfig({this.maxAttempts = 3, this.delay = const Duration(seconds: 1), this.maxDelay = const Duration(seconds: 30), this.maxDuration = const Duration(seconds: 60), this.onRetry});
  

/// Most retries of one request.
@override@JsonKey() final  int maxAttempts;
/// Base delay of the exponential backoff.
@override@JsonKey() final  Duration delay;
/// Longest wait before one retry, and the cap on `Retry-After`.
@override@JsonKey() final  Duration maxDelay;
/// Most time spent retrying one request, from its first failure.
@override@JsonKey() final  Duration maxDuration;
/// Called before each retry waits.
@override final  RetryCallback? onRetry;

/// Create a copy of RetryConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RetryConfigCopyWith<_RetryConfig> get copyWith => __$RetryConfigCopyWithImpl<_RetryConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RetryConfig&&(identical(other.maxAttempts, maxAttempts) || other.maxAttempts == maxAttempts)&&(identical(other.delay, delay) || other.delay == delay)&&(identical(other.maxDelay, maxDelay) || other.maxDelay == maxDelay)&&(identical(other.maxDuration, maxDuration) || other.maxDuration == maxDuration)&&(identical(other.onRetry, onRetry) || other.onRetry == onRetry));
}


@override
int get hashCode {
    return Object.hash(runtimeType,maxAttempts,delay,maxDelay,maxDuration,onRetry);
}

@override
String toString() {
    return 'RetryConfig(maxAttempts: $maxAttempts, delay: $delay, maxDelay: $maxDelay, maxDuration: $maxDuration, onRetry: $onRetry)';
}


}

/// @nodoc
abstract mixin class _$RetryConfigCopyWith<$Res> implements $RetryConfigCopyWith<$Res> {
  factory _$RetryConfigCopyWith(_RetryConfig value, $Res Function(_RetryConfig) _then) = __$RetryConfigCopyWithImpl;
@override @useResult
$Res call({
 int maxAttempts, Duration delay, Duration maxDelay, Duration maxDuration, RetryCallback? onRetry
});




}
/// @nodoc
class __$RetryConfigCopyWithImpl<$Res>
    implements _$RetryConfigCopyWith<$Res> {
  __$RetryConfigCopyWithImpl(this._self, this._then);

  final _RetryConfig _self;
  final $Res Function(_RetryConfig) _then;

/// Create a copy of RetryConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxAttempts = null,Object? delay = null,Object? maxDelay = null,Object? maxDuration = null,Object? onRetry = freezed,}) {
  return _then(_RetryConfig(
maxAttempts: null == maxAttempts ? _self.maxAttempts : maxAttempts // ignore: cast_nullable_to_non_nullable
as int,delay: null == delay ? _self.delay : delay // ignore: cast_nullable_to_non_nullable
as Duration,maxDelay: null == maxDelay ? _self.maxDelay : maxDelay // ignore: cast_nullable_to_non_nullable
as Duration,maxDuration: null == maxDuration ? _self.maxDuration : maxDuration // ignore: cast_nullable_to_non_nullable
as Duration,onRetry: freezed == onRetry ? _self.onRetry : onRetry // ignore: cast_nullable_to_non_nullable
as RetryCallback?,
  ));
}


}

// dart format on
