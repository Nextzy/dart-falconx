// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../performance_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PerformanceConfig {

/// Most request metrics kept in memory.
 int get maxMetricsHistory;
/// Create a copy of PerformanceConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerformanceConfigCopyWith<PerformanceConfig> get copyWith => _$PerformanceConfigCopyWithImpl<PerformanceConfig>(this as PerformanceConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PerformanceConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerformanceConfig&&(identical(other.maxMetricsHistory, _this.maxMetricsHistory) || other.maxMetricsHistory == _this.maxMetricsHistory));
}


@override
int get hashCode {
  final _this = this as PerformanceConfig;
  return Object.hash(runtimeType,_this.maxMetricsHistory);
}

@override
String toString() {
  final _this = this as PerformanceConfig;
  return 'PerformanceConfig(maxMetricsHistory: ${_this.maxMetricsHistory})';
}


}

/// @nodoc
abstract mixin class $PerformanceConfigCopyWith<$Res>  {
  factory $PerformanceConfigCopyWith(PerformanceConfig value, $Res Function(PerformanceConfig) _then) = _$PerformanceConfigCopyWithImpl;
@useResult
$Res call({
 int maxMetricsHistory
});




}
/// @nodoc
class _$PerformanceConfigCopyWithImpl<$Res>
    implements $PerformanceConfigCopyWith<$Res> {
  _$PerformanceConfigCopyWithImpl(this._self, this._then);

  final PerformanceConfig _self;
  final $Res Function(PerformanceConfig) _then;

/// Create a copy of PerformanceConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxMetricsHistory = null,}) {
  return _then(PerformanceConfig(
maxMetricsHistory: null == maxMetricsHistory ? _self.maxMetricsHistory : maxMetricsHistory // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PerformanceConfig].
extension PerformanceConfigPatterns on PerformanceConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerformanceConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerformanceConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerformanceConfig value)  $default,){
final _that = this;
switch (_that) {
case _PerformanceConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerformanceConfig value)?  $default,){
final _that = this;
switch (_that) {
case _PerformanceConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maxMetricsHistory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerformanceConfig() when $default != null:
return $default(_that.maxMetricsHistory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maxMetricsHistory)  $default,) {final _that = this;
switch (_that) {
case _PerformanceConfig():
return $default(_that.maxMetricsHistory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maxMetricsHistory)?  $default,) {final _that = this;
switch (_that) {
case _PerformanceConfig() when $default != null:
return $default(_that.maxMetricsHistory);case _:
  return null;

}
}

}

/// @nodoc


class _PerformanceConfig implements PerformanceConfig {
  const _PerformanceConfig({this.maxMetricsHistory = 1000});
  

/// Most request metrics kept in memory.
@override@JsonKey() final  int maxMetricsHistory;

/// Create a copy of PerformanceConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerformanceConfigCopyWith<_PerformanceConfig> get copyWith => __$PerformanceConfigCopyWithImpl<_PerformanceConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerformanceConfig&&(identical(other.maxMetricsHistory, maxMetricsHistory) || other.maxMetricsHistory == maxMetricsHistory));
}


@override
int get hashCode {
    return Object.hash(runtimeType,maxMetricsHistory);
}

@override
String toString() {
    return 'PerformanceConfig(maxMetricsHistory: $maxMetricsHistory)';
}


}

/// @nodoc
abstract mixin class _$PerformanceConfigCopyWith<$Res> implements $PerformanceConfigCopyWith<$Res> {
  factory _$PerformanceConfigCopyWith(_PerformanceConfig value, $Res Function(_PerformanceConfig) _then) = __$PerformanceConfigCopyWithImpl;
@override @useResult
$Res call({
 int maxMetricsHistory
});




}
/// @nodoc
class __$PerformanceConfigCopyWithImpl<$Res>
    implements _$PerformanceConfigCopyWith<$Res> {
  __$PerformanceConfigCopyWithImpl(this._self, this._then);

  final _PerformanceConfig _self;
  final $Res Function(_PerformanceConfig) _then;

/// Create a copy of PerformanceConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxMetricsHistory = null,}) {
  return _then(_PerformanceConfig(
maxMetricsHistory: null == maxMetricsHistory ? _self.maxMetricsHistory : maxMetricsHistory // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
