// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../concurrency_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConcurrencyConfig {

/// Most requests in flight to all hosts together; null means no limit.
 int? get global;/// Most requests in flight to a host missing from [hosts]; null means
/// no limit.
 int? get perHost;/// Per-host limits keyed by bare lowercase host; a null value opts the
/// host out of [perHost].
 Map<String, int?> get hosts;/// Whether a request with no free slot waits (`true`) or is rejected.
 bool get queueRequests;/// Queue capacity of each host limit.
 int get maxQueueSize;/// Queue capacity of the global limit.
 int get maxGlobalQueueSize;
/// Create a copy of ConcurrencyConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConcurrencyConfigCopyWith<ConcurrencyConfig> get copyWith => _$ConcurrencyConfigCopyWithImpl<ConcurrencyConfig>(this as ConcurrencyConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ConcurrencyConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConcurrencyConfig&&(identical(other.global, _this.global) || other.global == _this.global)&&(identical(other.perHost, _this.perHost) || other.perHost == _this.perHost)&&const DeepCollectionEquality().equals(other.hosts, _this.hosts)&&(identical(other.queueRequests, _this.queueRequests) || other.queueRequests == _this.queueRequests)&&(identical(other.maxQueueSize, _this.maxQueueSize) || other.maxQueueSize == _this.maxQueueSize)&&(identical(other.maxGlobalQueueSize, _this.maxGlobalQueueSize) || other.maxGlobalQueueSize == _this.maxGlobalQueueSize));
}


@override
int get hashCode {
  final _this = this as ConcurrencyConfig;
  return Object.hash(runtimeType,_this.global,_this.perHost,const DeepCollectionEquality().hash(_this.hosts),_this.queueRequests,_this.maxQueueSize,_this.maxGlobalQueueSize);
}

@override
String toString() {
  final _this = this as ConcurrencyConfig;
  return 'ConcurrencyConfig(global: ${_this.global}, perHost: ${_this.perHost}, hosts: ${_this.hosts}, queueRequests: ${_this.queueRequests}, maxQueueSize: ${_this.maxQueueSize}, maxGlobalQueueSize: ${_this.maxGlobalQueueSize})';
}


}

/// @nodoc
abstract mixin class $ConcurrencyConfigCopyWith<$Res>  {
  factory $ConcurrencyConfigCopyWith(ConcurrencyConfig value, $Res Function(ConcurrencyConfig) _then) = _$ConcurrencyConfigCopyWithImpl;
@useResult
$Res call({
 int? global, int? perHost, Map<String, int?> hosts, bool queueRequests, int maxQueueSize, int maxGlobalQueueSize
});




}
/// @nodoc
class _$ConcurrencyConfigCopyWithImpl<$Res>
    implements $ConcurrencyConfigCopyWith<$Res> {
  _$ConcurrencyConfigCopyWithImpl(this._self, this._then);

  final ConcurrencyConfig _self;
  final $Res Function(ConcurrencyConfig) _then;

/// Create a copy of ConcurrencyConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? global = freezed,Object? perHost = freezed,Object? hosts = null,Object? queueRequests = null,Object? maxQueueSize = null,Object? maxGlobalQueueSize = null,}) {
  return _then(ConcurrencyConfig(
global: freezed == global ? _self.global : global // ignore: cast_nullable_to_non_nullable
as int?,perHost: freezed == perHost ? _self.perHost : perHost // ignore: cast_nullable_to_non_nullable
as int?,hosts: null == hosts ? _self.hosts : hosts // ignore: cast_nullable_to_non_nullable
as Map<String, int?>,queueRequests: null == queueRequests ? _self.queueRequests : queueRequests // ignore: cast_nullable_to_non_nullable
as bool,maxQueueSize: null == maxQueueSize ? _self.maxQueueSize : maxQueueSize // ignore: cast_nullable_to_non_nullable
as int,maxGlobalQueueSize: null == maxGlobalQueueSize ? _self.maxGlobalQueueSize : maxGlobalQueueSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ConcurrencyConfig].
extension ConcurrencyConfigPatterns on ConcurrencyConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConcurrencyConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConcurrencyConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConcurrencyConfig value)  $default,){
final _that = this;
switch (_that) {
case _ConcurrencyConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConcurrencyConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ConcurrencyConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? global,  int? perHost,  Map<String, int?> hosts,  bool queueRequests,  int maxQueueSize,  int maxGlobalQueueSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConcurrencyConfig() when $default != null:
return $default(_that.global,_that.perHost,_that.hosts,_that.queueRequests,_that.maxQueueSize,_that.maxGlobalQueueSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? global,  int? perHost,  Map<String, int?> hosts,  bool queueRequests,  int maxQueueSize,  int maxGlobalQueueSize)  $default,) {final _that = this;
switch (_that) {
case _ConcurrencyConfig():
return $default(_that.global,_that.perHost,_that.hosts,_that.queueRequests,_that.maxQueueSize,_that.maxGlobalQueueSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? global,  int? perHost,  Map<String, int?> hosts,  bool queueRequests,  int maxQueueSize,  int maxGlobalQueueSize)?  $default,) {final _that = this;
switch (_that) {
case _ConcurrencyConfig() when $default != null:
return $default(_that.global,_that.perHost,_that.hosts,_that.queueRequests,_that.maxQueueSize,_that.maxGlobalQueueSize);case _:
  return null;

}
}

}

/// @nodoc


class _ConcurrencyConfig implements ConcurrencyConfig {
  const _ConcurrencyConfig({this.global, this.perHost,  Map<String, int?> hosts = const <String, int?>{}, this.queueRequests = true, this.maxQueueSize = 50, this.maxGlobalQueueSize = 500}): _hosts = hosts;
  

/// Most requests in flight to all hosts together; null means no limit.
@override final  int? global;
/// Most requests in flight to a host missing from [hosts]; null means
/// no limit.
@override final  int? perHost;
/// Per-host limits keyed by bare lowercase host; a null value opts the
/// host out of [perHost].
 final  Map<String, int?> _hosts;
/// Per-host limits keyed by bare lowercase host; a null value opts the
/// host out of [perHost].
@override@JsonKey() Map<String, int?> get hosts {
  if (_hosts is EqualUnmodifiableMapView) return _hosts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_hosts);
}

/// Whether a request with no free slot waits (`true`) or is rejected.
@override@JsonKey() final  bool queueRequests;
/// Queue capacity of each host limit.
@override@JsonKey() final  int maxQueueSize;
/// Queue capacity of the global limit.
@override@JsonKey() final  int maxGlobalQueueSize;

/// Create a copy of ConcurrencyConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConcurrencyConfigCopyWith<_ConcurrencyConfig> get copyWith => __$ConcurrencyConfigCopyWithImpl<_ConcurrencyConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConcurrencyConfig&&(identical(other.global, global) || other.global == global)&&(identical(other.perHost, perHost) || other.perHost == perHost)&&const DeepCollectionEquality().equals(other.hosts, _hosts)&&(identical(other.queueRequests, queueRequests) || other.queueRequests == queueRequests)&&(identical(other.maxQueueSize, maxQueueSize) || other.maxQueueSize == maxQueueSize)&&(identical(other.maxGlobalQueueSize, maxGlobalQueueSize) || other.maxGlobalQueueSize == maxGlobalQueueSize));
}


@override
int get hashCode {
    return Object.hash(runtimeType,global,perHost,const DeepCollectionEquality().hash(_hosts),queueRequests,maxQueueSize,maxGlobalQueueSize);
}

@override
String toString() {
    return 'ConcurrencyConfig(global: $global, perHost: $perHost, hosts: $hosts, queueRequests: $queueRequests, maxQueueSize: $maxQueueSize, maxGlobalQueueSize: $maxGlobalQueueSize)';
}


}

/// @nodoc
abstract mixin class _$ConcurrencyConfigCopyWith<$Res> implements $ConcurrencyConfigCopyWith<$Res> {
  factory _$ConcurrencyConfigCopyWith(_ConcurrencyConfig value, $Res Function(_ConcurrencyConfig) _then) = __$ConcurrencyConfigCopyWithImpl;
@override @useResult
$Res call({
 int? global, int? perHost, Map<String, int?> hosts, bool queueRequests, int maxQueueSize, int maxGlobalQueueSize
});




}
/// @nodoc
class __$ConcurrencyConfigCopyWithImpl<$Res>
    implements _$ConcurrencyConfigCopyWith<$Res> {
  __$ConcurrencyConfigCopyWithImpl(this._self, this._then);

  final _ConcurrencyConfig _self;
  final $Res Function(_ConcurrencyConfig) _then;

/// Create a copy of ConcurrencyConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? global = freezed,Object? perHost = freezed,Object? hosts = null,Object? queueRequests = null,Object? maxQueueSize = null,Object? maxGlobalQueueSize = null,}) {
  return _then(_ConcurrencyConfig(
global: freezed == global ? _self.global : global // ignore: cast_nullable_to_non_nullable
as int?,perHost: freezed == perHost ? _self.perHost : perHost // ignore: cast_nullable_to_non_nullable
as int?,hosts: null == hosts ? _self._hosts : hosts // ignore: cast_nullable_to_non_nullable
as Map<String, int?>,queueRequests: null == queueRequests ? _self.queueRequests : queueRequests // ignore: cast_nullable_to_non_nullable
as bool,maxQueueSize: null == maxQueueSize ? _self.maxQueueSize : maxQueueSize // ignore: cast_nullable_to_non_nullable
as int,maxGlobalQueueSize: null == maxGlobalQueueSize ? _self.maxGlobalQueueSize : maxGlobalQueueSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
