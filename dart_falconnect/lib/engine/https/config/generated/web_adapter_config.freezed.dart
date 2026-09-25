// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../web_adapter_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WebAdapterConfig {

/// Whether cross-site requests send cookies and authorization headers.
/// A request's `extra['withCredentials']` overrides it.
 bool get withCredentials;
/// Create a copy of WebAdapterConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebAdapterConfigCopyWith<WebAdapterConfig> get copyWith => _$WebAdapterConfigCopyWithImpl<WebAdapterConfig>(this as WebAdapterConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WebAdapterConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebAdapterConfig&&(identical(other.withCredentials, _this.withCredentials) || other.withCredentials == _this.withCredentials));
}


@override
int get hashCode {
  final _this = this as WebAdapterConfig;
  return Object.hash(runtimeType,_this.withCredentials);
}

@override
String toString() {
  final _this = this as WebAdapterConfig;
  return 'WebAdapterConfig(withCredentials: ${_this.withCredentials})';
}


}

/// @nodoc
abstract mixin class $WebAdapterConfigCopyWith<$Res>  {
  factory $WebAdapterConfigCopyWith(WebAdapterConfig value, $Res Function(WebAdapterConfig) _then) = _$WebAdapterConfigCopyWithImpl;
@useResult
$Res call({
 bool withCredentials
});




}
/// @nodoc
class _$WebAdapterConfigCopyWithImpl<$Res>
    implements $WebAdapterConfigCopyWith<$Res> {
  _$WebAdapterConfigCopyWithImpl(this._self, this._then);

  final WebAdapterConfig _self;
  final $Res Function(WebAdapterConfig) _then;

/// Create a copy of WebAdapterConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? withCredentials = null,}) {
  return _then(WebAdapterConfig(
withCredentials: null == withCredentials ? _self.withCredentials : withCredentials // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WebAdapterConfig].
extension WebAdapterConfigPatterns on WebAdapterConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebAdapterConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebAdapterConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebAdapterConfig value)  $default,){
final _that = this;
switch (_that) {
case _WebAdapterConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebAdapterConfig value)?  $default,){
final _that = this;
switch (_that) {
case _WebAdapterConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool withCredentials)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebAdapterConfig() when $default != null:
return $default(_that.withCredentials);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool withCredentials)  $default,) {final _that = this;
switch (_that) {
case _WebAdapterConfig():
return $default(_that.withCredentials);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool withCredentials)?  $default,) {final _that = this;
switch (_that) {
case _WebAdapterConfig() when $default != null:
return $default(_that.withCredentials);case _:
  return null;

}
}

}

/// @nodoc


class _WebAdapterConfig implements WebAdapterConfig {
  const _WebAdapterConfig({this.withCredentials = false});
  

/// Whether cross-site requests send cookies and authorization headers.
/// A request's `extra['withCredentials']` overrides it.
@override@JsonKey() final  bool withCredentials;

/// Create a copy of WebAdapterConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebAdapterConfigCopyWith<_WebAdapterConfig> get copyWith => __$WebAdapterConfigCopyWithImpl<_WebAdapterConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebAdapterConfig&&(identical(other.withCredentials, withCredentials) || other.withCredentials == withCredentials));
}


@override
int get hashCode {
    return Object.hash(runtimeType,withCredentials);
}

@override
String toString() {
    return 'WebAdapterConfig(withCredentials: $withCredentials)';
}


}

/// @nodoc
abstract mixin class _$WebAdapterConfigCopyWith<$Res> implements $WebAdapterConfigCopyWith<$Res> {
  factory _$WebAdapterConfigCopyWith(_WebAdapterConfig value, $Res Function(_WebAdapterConfig) _then) = __$WebAdapterConfigCopyWithImpl;
@override @useResult
$Res call({
 bool withCredentials
});




}
/// @nodoc
class __$WebAdapterConfigCopyWithImpl<$Res>
    implements _$WebAdapterConfigCopyWith<$Res> {
  __$WebAdapterConfigCopyWithImpl(this._self, this._then);

  final _WebAdapterConfig _self;
  final $Res Function(_WebAdapterConfig) _then;

/// Create a copy of WebAdapterConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? withCredentials = null,}) {
  return _then(_WebAdapterConfig(
withCredentials: null == withCredentials ? _self.withCredentials : withCredentials // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
