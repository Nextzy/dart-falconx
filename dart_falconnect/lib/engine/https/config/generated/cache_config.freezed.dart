// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../cache_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CacheConfig {

/// How long a response stays valid when its headers set no lifetime.
 Duration get duration;/// Largest total cache size in bytes.
 int get maxSize;
/// Create a copy of CacheConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CacheConfigCopyWith<CacheConfig> get copyWith => _$CacheConfigCopyWithImpl<CacheConfig>(this as CacheConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CacheConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CacheConfig&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.maxSize, _this.maxSize) || other.maxSize == _this.maxSize));
}


@override
int get hashCode {
  final _this = this as CacheConfig;
  return Object.hash(runtimeType,_this.duration,_this.maxSize);
}

@override
String toString() {
  final _this = this as CacheConfig;
  return 'CacheConfig(duration: ${_this.duration}, maxSize: ${_this.maxSize})';
}


}

/// @nodoc
abstract mixin class $CacheConfigCopyWith<$Res>  {
  factory $CacheConfigCopyWith(CacheConfig value, $Res Function(CacheConfig) _then) = _$CacheConfigCopyWithImpl;
@useResult
$Res call({
 Duration duration, int maxSize
});




}
/// @nodoc
class _$CacheConfigCopyWithImpl<$Res>
    implements $CacheConfigCopyWith<$Res> {
  _$CacheConfigCopyWithImpl(this._self, this._then);

  final CacheConfig _self;
  final $Res Function(CacheConfig) _then;

/// Create a copy of CacheConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? duration = null,Object? maxSize = null,}) {
  return _then(CacheConfig(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,maxSize: null == maxSize ? _self.maxSize : maxSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CacheConfig].
extension CacheConfigPatterns on CacheConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CacheConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CacheConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CacheConfig value)  $default,){
final _that = this;
switch (_that) {
case _CacheConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CacheConfig value)?  $default,){
final _that = this;
switch (_that) {
case _CacheConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration duration,  int maxSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CacheConfig() when $default != null:
return $default(_that.duration,_that.maxSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration duration,  int maxSize)  $default,) {final _that = this;
switch (_that) {
case _CacheConfig():
return $default(_that.duration,_that.maxSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration duration,  int maxSize)?  $default,) {final _that = this;
switch (_that) {
case _CacheConfig() when $default != null:
return $default(_that.duration,_that.maxSize);case _:
  return null;

}
}

}

/// @nodoc


class _CacheConfig implements CacheConfig {
  const _CacheConfig({this.duration = const Duration(minutes: 15), this.maxSize = 50 * 1024 * 1024});
  

/// How long a response stays valid when its headers set no lifetime.
@override@JsonKey() final  Duration duration;
/// Largest total cache size in bytes.
@override@JsonKey() final  int maxSize;

/// Create a copy of CacheConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CacheConfigCopyWith<_CacheConfig> get copyWith => __$CacheConfigCopyWithImpl<_CacheConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CacheConfig&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.maxSize, maxSize) || other.maxSize == maxSize));
}


@override
int get hashCode {
    return Object.hash(runtimeType,duration,maxSize);
}

@override
String toString() {
    return 'CacheConfig(duration: $duration, maxSize: $maxSize)';
}


}

/// @nodoc
abstract mixin class _$CacheConfigCopyWith<$Res> implements $CacheConfigCopyWith<$Res> {
  factory _$CacheConfigCopyWith(_CacheConfig value, $Res Function(_CacheConfig) _then) = __$CacheConfigCopyWithImpl;
@override @useResult
$Res call({
 Duration duration, int maxSize
});




}
/// @nodoc
class __$CacheConfigCopyWithImpl<$Res>
    implements _$CacheConfigCopyWith<$Res> {
  __$CacheConfigCopyWithImpl(this._self, this._then);

  final _CacheConfig _self;
  final $Res Function(_CacheConfig) _then;

/// Create a copy of CacheConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? duration = null,Object? maxSize = null,}) {
  return _then(_CacheConfig(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,maxSize: null == maxSize ? _self.maxSize : maxSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
