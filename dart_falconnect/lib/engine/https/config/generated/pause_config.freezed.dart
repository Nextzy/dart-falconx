// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../pause_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PauseConfig {

/// Longest remaining pause a request waits out instead of failing.
 Duration get maxPauseWait;/// Longest pause any response can start.
 Duration get maxPause;/// Pause for a 429 without a readable `Retry-After`; null means none.
 Duration? get defaultPause;
/// Create a copy of PauseConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PauseConfigCopyWith<PauseConfig> get copyWith => _$PauseConfigCopyWithImpl<PauseConfig>(this as PauseConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PauseConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PauseConfig&&(identical(other.maxPauseWait, _this.maxPauseWait) || other.maxPauseWait == _this.maxPauseWait)&&(identical(other.maxPause, _this.maxPause) || other.maxPause == _this.maxPause)&&(identical(other.defaultPause, _this.defaultPause) || other.defaultPause == _this.defaultPause));
}


@override
int get hashCode {
  final _this = this as PauseConfig;
  return Object.hash(runtimeType,_this.maxPauseWait,_this.maxPause,_this.defaultPause);
}

@override
String toString() {
  final _this = this as PauseConfig;
  return 'PauseConfig(maxPauseWait: ${_this.maxPauseWait}, maxPause: ${_this.maxPause}, defaultPause: ${_this.defaultPause})';
}


}

/// @nodoc
abstract mixin class $PauseConfigCopyWith<$Res>  {
  factory $PauseConfigCopyWith(PauseConfig value, $Res Function(PauseConfig) _then) = _$PauseConfigCopyWithImpl;
@useResult
$Res call({
 Duration maxPauseWait, Duration maxPause, Duration? defaultPause
});




}
/// @nodoc
class _$PauseConfigCopyWithImpl<$Res>
    implements $PauseConfigCopyWith<$Res> {
  _$PauseConfigCopyWithImpl(this._self, this._then);

  final PauseConfig _self;
  final $Res Function(PauseConfig) _then;

/// Create a copy of PauseConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxPauseWait = null,Object? maxPause = null,Object? defaultPause = freezed,}) {
  return _then(PauseConfig(
maxPauseWait: null == maxPauseWait ? _self.maxPauseWait : maxPauseWait // ignore: cast_nullable_to_non_nullable
as Duration,maxPause: null == maxPause ? _self.maxPause : maxPause // ignore: cast_nullable_to_non_nullable
as Duration,defaultPause: freezed == defaultPause ? _self.defaultPause : defaultPause // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [PauseConfig].
extension PauseConfigPatterns on PauseConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PauseConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PauseConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PauseConfig value)  $default,){
final _that = this;
switch (_that) {
case _PauseConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PauseConfig value)?  $default,){
final _that = this;
switch (_that) {
case _PauseConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration maxPauseWait,  Duration maxPause,  Duration? defaultPause)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PauseConfig() when $default != null:
return $default(_that.maxPauseWait,_that.maxPause,_that.defaultPause);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration maxPauseWait,  Duration maxPause,  Duration? defaultPause)  $default,) {final _that = this;
switch (_that) {
case _PauseConfig():
return $default(_that.maxPauseWait,_that.maxPause,_that.defaultPause);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration maxPauseWait,  Duration maxPause,  Duration? defaultPause)?  $default,) {final _that = this;
switch (_that) {
case _PauseConfig() when $default != null:
return $default(_that.maxPauseWait,_that.maxPause,_that.defaultPause);case _:
  return null;

}
}

}

/// @nodoc


class _PauseConfig implements PauseConfig {
  const _PauseConfig({this.maxPauseWait = const Duration(seconds: 10), this.maxPause = const Duration(minutes: 10), this.defaultPause = const Duration(seconds: 5)});
  

/// Longest remaining pause a request waits out instead of failing.
@override@JsonKey() final  Duration maxPauseWait;
/// Longest pause any response can start.
@override@JsonKey() final  Duration maxPause;
/// Pause for a 429 without a readable `Retry-After`; null means none.
@override@JsonKey() final  Duration? defaultPause;

/// Create a copy of PauseConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PauseConfigCopyWith<_PauseConfig> get copyWith => __$PauseConfigCopyWithImpl<_PauseConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PauseConfig&&(identical(other.maxPauseWait, maxPauseWait) || other.maxPauseWait == maxPauseWait)&&(identical(other.maxPause, maxPause) || other.maxPause == maxPause)&&(identical(other.defaultPause, defaultPause) || other.defaultPause == defaultPause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,maxPauseWait,maxPause,defaultPause);
}

@override
String toString() {
    return 'PauseConfig(maxPauseWait: $maxPauseWait, maxPause: $maxPause, defaultPause: $defaultPause)';
}


}

/// @nodoc
abstract mixin class _$PauseConfigCopyWith<$Res> implements $PauseConfigCopyWith<$Res> {
  factory _$PauseConfigCopyWith(_PauseConfig value, $Res Function(_PauseConfig) _then) = __$PauseConfigCopyWithImpl;
@override @useResult
$Res call({
 Duration maxPauseWait, Duration maxPause, Duration? defaultPause
});




}
/// @nodoc
class __$PauseConfigCopyWithImpl<$Res>
    implements _$PauseConfigCopyWith<$Res> {
  __$PauseConfigCopyWithImpl(this._self, this._then);

  final _PauseConfig _self;
  final $Res Function(_PauseConfig) _then;

/// Create a copy of PauseConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxPauseWait = null,Object? maxPause = null,Object? defaultPause = freezed,}) {
  return _then(_PauseConfig(
maxPauseWait: null == maxPauseWait ? _self.maxPauseWait : maxPauseWait // ignore: cast_nullable_to_non_nullable
as Duration,maxPause: null == maxPause ? _self.maxPause : maxPause // ignore: cast_nullable_to_non_nullable
as Duration,defaultPause: freezed == defaultPause ? _self.defaultPause : defaultPause // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

// dart format on
