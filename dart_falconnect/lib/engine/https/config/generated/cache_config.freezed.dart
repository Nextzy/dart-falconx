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

/// Default policy; [CachePolicy.request] follows the server's cache
/// headers and stores nothing a response does not mark cacheable.
 CachePolicy get policy;/// Drops an entry this long after it was stored, whatever its headers
/// say; null keeps an entry as long as its headers allow.
 Duration? get maxStale;/// Byte budget of the default memory store, evicted least recently
/// used; must be positive. A single response over 512,000 bytes, or
/// over a fifth of this budget, is not stored.
 int get maxSize;/// Where entries live; null builds a `MemCacheStore` of [maxSize]
/// bytes. The client never closes a store passed here.
 CacheStore? get store;/// Request headers that split one URL into separate entries, compared
/// ignoring case. On a server that serves many users, keep
/// `authorization` here, or one user reads another's cached responses.
 Set<String> get keyHeaders;
/// Create a copy of CacheConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CacheConfigCopyWith<CacheConfig> get copyWith => _$CacheConfigCopyWithImpl<CacheConfig>(this as CacheConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CacheConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CacheConfig&&(identical(other.policy, _this.policy) || other.policy == _this.policy)&&(identical(other.maxStale, _this.maxStale) || other.maxStale == _this.maxStale)&&(identical(other.maxSize, _this.maxSize) || other.maxSize == _this.maxSize)&&(identical(other.store, _this.store) || other.store == _this.store)&&const DeepCollectionEquality().equals(other.keyHeaders, _this.keyHeaders));
}


@override
int get hashCode {
  final _this = this as CacheConfig;
  return Object.hash(runtimeType,_this.policy,_this.maxStale,_this.maxSize,_this.store,const DeepCollectionEquality().hash(_this.keyHeaders));
}

@override
String toString() {
  final _this = this as CacheConfig;
  return 'CacheConfig(policy: ${_this.policy}, maxStale: ${_this.maxStale}, maxSize: ${_this.maxSize}, store: ${_this.store}, keyHeaders: ${_this.keyHeaders})';
}


}

/// @nodoc
abstract mixin class $CacheConfigCopyWith<$Res>  {
  factory $CacheConfigCopyWith(CacheConfig value, $Res Function(CacheConfig) _then) = _$CacheConfigCopyWithImpl;
@useResult
$Res call({
 CachePolicy policy, Duration? maxStale, int maxSize, CacheStore? store, Set<String> keyHeaders
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
@pragma('vm:prefer-inline') @override $Res call({Object? policy = null,Object? maxStale = freezed,Object? maxSize = null,Object? store = freezed,Object? keyHeaders = null,}) {
  return _then(CacheConfig(
policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as CachePolicy,maxStale: freezed == maxStale ? _self.maxStale : maxStale // ignore: cast_nullable_to_non_nullable
as Duration?,maxSize: null == maxSize ? _self.maxSize : maxSize // ignore: cast_nullable_to_non_nullable
as int,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as CacheStore?,keyHeaders: null == keyHeaders ? _self.keyHeaders : keyHeaders // ignore: cast_nullable_to_non_nullable
as Set<String>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CachePolicy policy,  Duration? maxStale,  int maxSize,  CacheStore? store,  Set<String> keyHeaders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CacheConfig() when $default != null:
return $default(_that.policy,_that.maxStale,_that.maxSize,_that.store,_that.keyHeaders);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CachePolicy policy,  Duration? maxStale,  int maxSize,  CacheStore? store,  Set<String> keyHeaders)  $default,) {final _that = this;
switch (_that) {
case _CacheConfig():
return $default(_that.policy,_that.maxStale,_that.maxSize,_that.store,_that.keyHeaders);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CachePolicy policy,  Duration? maxStale,  int maxSize,  CacheStore? store,  Set<String> keyHeaders)?  $default,) {final _that = this;
switch (_that) {
case _CacheConfig() when $default != null:
return $default(_that.policy,_that.maxStale,_that.maxSize,_that.store,_that.keyHeaders);case _:
  return null;

}
}

}

/// @nodoc


class _CacheConfig implements CacheConfig {
  const _CacheConfig({this.policy = CachePolicy.request, this.maxStale, this.maxSize = 50 * 1024 * 1024, this.store,  Set<String> keyHeaders = const {'authorization', 'accept', 'accept-language'}}): _keyHeaders = keyHeaders;
  

/// Default policy; [CachePolicy.request] follows the server's cache
/// headers and stores nothing a response does not mark cacheable.
@override@JsonKey() final  CachePolicy policy;
/// Drops an entry this long after it was stored, whatever its headers
/// say; null keeps an entry as long as its headers allow.
@override final  Duration? maxStale;
/// Byte budget of the default memory store, evicted least recently
/// used; must be positive. A single response over 512,000 bytes, or
/// over a fifth of this budget, is not stored.
@override@JsonKey() final  int maxSize;
/// Where entries live; null builds a `MemCacheStore` of [maxSize]
/// bytes. The client never closes a store passed here.
@override final  CacheStore? store;
/// Request headers that split one URL into separate entries, compared
/// ignoring case. On a server that serves many users, keep
/// `authorization` here, or one user reads another's cached responses.
 final  Set<String> _keyHeaders;
/// Request headers that split one URL into separate entries, compared
/// ignoring case. On a server that serves many users, keep
/// `authorization` here, or one user reads another's cached responses.
@override@JsonKey() Set<String> get keyHeaders {
  if (_keyHeaders is EqualUnmodifiableSetView) return _keyHeaders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_keyHeaders);
}


/// Create a copy of CacheConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CacheConfigCopyWith<_CacheConfig> get copyWith => __$CacheConfigCopyWithImpl<_CacheConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CacheConfig&&(identical(other.policy, policy) || other.policy == policy)&&(identical(other.maxStale, maxStale) || other.maxStale == maxStale)&&(identical(other.maxSize, maxSize) || other.maxSize == maxSize)&&(identical(other.store, store) || other.store == store)&&const DeepCollectionEquality().equals(other.keyHeaders, _keyHeaders));
}


@override
int get hashCode {
    return Object.hash(runtimeType,policy,maxStale,maxSize,store,const DeepCollectionEquality().hash(_keyHeaders));
}

@override
String toString() {
    return 'CacheConfig(policy: $policy, maxStale: $maxStale, maxSize: $maxSize, store: $store, keyHeaders: $keyHeaders)';
}


}

/// @nodoc
abstract mixin class _$CacheConfigCopyWith<$Res> implements $CacheConfigCopyWith<$Res> {
  factory _$CacheConfigCopyWith(_CacheConfig value, $Res Function(_CacheConfig) _then) = __$CacheConfigCopyWithImpl;
@override @useResult
$Res call({
 CachePolicy policy, Duration? maxStale, int maxSize, CacheStore? store, Set<String> keyHeaders
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
@override @pragma('vm:prefer-inline') $Res call({Object? policy = null,Object? maxStale = freezed,Object? maxSize = null,Object? store = freezed,Object? keyHeaders = null,}) {
  return _then(_CacheConfig(
policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as CachePolicy,maxStale: freezed == maxStale ? _self.maxStale : maxStale // ignore: cast_nullable_to_non_nullable
as Duration?,maxSize: null == maxSize ? _self.maxSize : maxSize // ignore: cast_nullable_to_non_nullable
as int,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as CacheStore?,keyHeaders: null == keyHeaders ? _self._keyHeaders : keyHeaders // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
