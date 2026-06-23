// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../decoded_typeid.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DecodedTypeId {

 String get prefix; String get suffix; String get uuid;
/// Create a copy of DecodedTypeId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DecodedTypeIdCopyWith<DecodedTypeId> get copyWith => _$DecodedTypeIdCopyWithImpl<DecodedTypeId>(this as DecodedTypeId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DecodedTypeId&&(identical(other.prefix, prefix) || other.prefix == prefix)&&(identical(other.suffix, suffix) || other.suffix == suffix)&&(identical(other.uuid, uuid) || other.uuid == uuid));
}


@override
int get hashCode => Object.hash(runtimeType,prefix,suffix,uuid);



}

/// @nodoc
abstract mixin class $DecodedTypeIdCopyWith<$Res>  {
  factory $DecodedTypeIdCopyWith(DecodedTypeId value, $Res Function(DecodedTypeId) _then) = _$DecodedTypeIdCopyWithImpl;
@useResult
$Res call({
 String prefix, String suffix, String uuid
});




}
/// @nodoc
class _$DecodedTypeIdCopyWithImpl<$Res>
    implements $DecodedTypeIdCopyWith<$Res> {
  _$DecodedTypeIdCopyWithImpl(this._self, this._then);

  final DecodedTypeId _self;
  final $Res Function(DecodedTypeId) _then;

/// Create a copy of DecodedTypeId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? prefix = null,Object? suffix = null,Object? uuid = null,}) {
  return _then(_self.copyWith(
prefix: null == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as String,suffix: null == suffix ? _self.suffix : suffix // ignore: cast_nullable_to_non_nullable
as String,uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DecodedTypeId].
extension DecodedTypeIdPatterns on DecodedTypeId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DecodedTypeId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DecodedTypeId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DecodedTypeId value)  $default,){
final _that = this;
switch (_that) {
case _DecodedTypeId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DecodedTypeId value)?  $default,){
final _that = this;
switch (_that) {
case _DecodedTypeId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String prefix,  String suffix,  String uuid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DecodedTypeId() when $default != null:
return $default(_that.prefix,_that.suffix,_that.uuid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String prefix,  String suffix,  String uuid)  $default,) {final _that = this;
switch (_that) {
case _DecodedTypeId():
return $default(_that.prefix,_that.suffix,_that.uuid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String prefix,  String suffix,  String uuid)?  $default,) {final _that = this;
switch (_that) {
case _DecodedTypeId() when $default != null:
return $default(_that.prefix,_that.suffix,_that.uuid);case _:
  return null;

}
}

}

/// @nodoc


class _DecodedTypeId extends DecodedTypeId {
  const _DecodedTypeId({required this.prefix, required this.suffix, required this.uuid}): super._();
  

@override final  String prefix;
@override final  String suffix;
@override final  String uuid;

/// Create a copy of DecodedTypeId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DecodedTypeIdCopyWith<_DecodedTypeId> get copyWith => __$DecodedTypeIdCopyWithImpl<_DecodedTypeId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DecodedTypeId&&(identical(other.prefix, prefix) || other.prefix == prefix)&&(identical(other.suffix, suffix) || other.suffix == suffix)&&(identical(other.uuid, uuid) || other.uuid == uuid));
}


@override
int get hashCode => Object.hash(runtimeType,prefix,suffix,uuid);



}

/// @nodoc
abstract mixin class _$DecodedTypeIdCopyWith<$Res> implements $DecodedTypeIdCopyWith<$Res> {
  factory _$DecodedTypeIdCopyWith(_DecodedTypeId value, $Res Function(_DecodedTypeId) _then) = __$DecodedTypeIdCopyWithImpl;
@override @useResult
$Res call({
 String prefix, String suffix, String uuid
});




}
/// @nodoc
class __$DecodedTypeIdCopyWithImpl<$Res>
    implements _$DecodedTypeIdCopyWith<$Res> {
  __$DecodedTypeIdCopyWithImpl(this._self, this._then);

  final _DecodedTypeId _self;
  final $Res Function(_DecodedTypeId) _then;

/// Create a copy of DecodedTypeId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? prefix = null,Object? suffix = null,Object? uuid = null,}) {
  return _then(_DecodedTypeId(
prefix: null == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as String,suffix: null == suffix ? _self.suffix : suffix // ignore: cast_nullable_to_non_nullable
as String,uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
