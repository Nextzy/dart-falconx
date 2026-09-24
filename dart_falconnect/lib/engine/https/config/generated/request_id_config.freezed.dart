// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../request_id_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RequestIdConfig {

/// Header that carries the ID.
 String get headerName;/// Makes a new ID; null makes a UUID v7.
 RequestIdGenerator? get generate;
/// Create a copy of RequestIdConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequestIdConfigCopyWith<RequestIdConfig> get copyWith => _$RequestIdConfigCopyWithImpl<RequestIdConfig>(this as RequestIdConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RequestIdConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestIdConfig&&(identical(other.headerName, _this.headerName) || other.headerName == _this.headerName)&&(identical(other.generate, _this.generate) || other.generate == _this.generate));
}


@override
int get hashCode {
  final _this = this as RequestIdConfig;
  return Object.hash(runtimeType,_this.headerName,_this.generate);
}

@override
String toString() {
  final _this = this as RequestIdConfig;
  return 'RequestIdConfig(headerName: ${_this.headerName}, generate: ${_this.generate})';
}


}

/// @nodoc
abstract mixin class $RequestIdConfigCopyWith<$Res>  {
  factory $RequestIdConfigCopyWith(RequestIdConfig value, $Res Function(RequestIdConfig) _then) = _$RequestIdConfigCopyWithImpl;
@useResult
$Res call({
 String headerName, RequestIdGenerator? generate
});




}
/// @nodoc
class _$RequestIdConfigCopyWithImpl<$Res>
    implements $RequestIdConfigCopyWith<$Res> {
  _$RequestIdConfigCopyWithImpl(this._self, this._then);

  final RequestIdConfig _self;
  final $Res Function(RequestIdConfig) _then;

/// Create a copy of RequestIdConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? headerName = null,Object? generate = freezed,}) {
  return _then(RequestIdConfig(
headerName: null == headerName ? _self.headerName : headerName // ignore: cast_nullable_to_non_nullable
as String,generate: freezed == generate ? _self.generate : generate // ignore: cast_nullable_to_non_nullable
as RequestIdGenerator?,
  ));
}

}


/// Adds pattern-matching-related methods to [RequestIdConfig].
extension RequestIdConfigPatterns on RequestIdConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RequestIdConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RequestIdConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RequestIdConfig value)  $default,){
final _that = this;
switch (_that) {
case _RequestIdConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RequestIdConfig value)?  $default,){
final _that = this;
switch (_that) {
case _RequestIdConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String headerName,  RequestIdGenerator? generate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RequestIdConfig() when $default != null:
return $default(_that.headerName,_that.generate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String headerName,  RequestIdGenerator? generate)  $default,) {final _that = this;
switch (_that) {
case _RequestIdConfig():
return $default(_that.headerName,_that.generate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String headerName,  RequestIdGenerator? generate)?  $default,) {final _that = this;
switch (_that) {
case _RequestIdConfig() when $default != null:
return $default(_that.headerName,_that.generate);case _:
  return null;

}
}

}

/// @nodoc


class _RequestIdConfig implements RequestIdConfig {
  const _RequestIdConfig({this.headerName = 'X-Request-ID', this.generate});
  

/// Header that carries the ID.
@override@JsonKey() final  String headerName;
/// Makes a new ID; null makes a UUID v7.
@override final  RequestIdGenerator? generate;

/// Create a copy of RequestIdConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RequestIdConfigCopyWith<_RequestIdConfig> get copyWith => __$RequestIdConfigCopyWithImpl<_RequestIdConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RequestIdConfig&&(identical(other.headerName, headerName) || other.headerName == headerName)&&(identical(other.generate, generate) || other.generate == generate));
}


@override
int get hashCode {
    return Object.hash(runtimeType,headerName,generate);
}

@override
String toString() {
    return 'RequestIdConfig(headerName: $headerName, generate: $generate)';
}


}

/// @nodoc
abstract mixin class _$RequestIdConfigCopyWith<$Res> implements $RequestIdConfigCopyWith<$Res> {
  factory _$RequestIdConfigCopyWith(_RequestIdConfig value, $Res Function(_RequestIdConfig) _then) = __$RequestIdConfigCopyWithImpl;
@override @useResult
$Res call({
 String headerName, RequestIdGenerator? generate
});




}
/// @nodoc
class __$RequestIdConfigCopyWithImpl<$Res>
    implements _$RequestIdConfigCopyWith<$Res> {
  __$RequestIdConfigCopyWithImpl(this._self, this._then);

  final _RequestIdConfig _self;
  final $Res Function(_RequestIdConfig) _then;

/// Create a copy of RequestIdConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? headerName = null,Object? generate = freezed,}) {
  return _then(_RequestIdConfig(
headerName: null == headerName ? _self.headerName : headerName // ignore: cast_nullable_to_non_nullable
as String,generate: freezed == generate ? _self.generate : generate // ignore: cast_nullable_to_non_nullable
as RequestIdGenerator?,
  ));
}


}

// dart format on
