// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../remote_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RemoteError {

 int? get code; String? get message; String? get userMessage; String? get developerMessage;
/// Create a copy of RemoteError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoteErrorCopyWith<RemoteError> get copyWith => _$RemoteErrorCopyWithImpl<RemoteError>(this as RemoteError, _$identity);

  /// Serializes this RemoteError to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoteError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.userMessage, userMessage) || other.userMessage == userMessage)&&(identical(other.developerMessage, developerMessage) || other.developerMessage == developerMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,userMessage,developerMessage);

@override
String toString() {
  return 'RemoteError(code: $code, message: $message, userMessage: $userMessage, developerMessage: $developerMessage)';
}


}

/// @nodoc
abstract mixin class $RemoteErrorCopyWith<$Res>  {
  factory $RemoteErrorCopyWith(RemoteError value, $Res Function(RemoteError) _then) = _$RemoteErrorCopyWithImpl;
@useResult
$Res call({
 int? code, String? message, String? userMessage, String? developerMessage
});




}
/// @nodoc
class _$RemoteErrorCopyWithImpl<$Res>
    implements $RemoteErrorCopyWith<$Res> {
  _$RemoteErrorCopyWithImpl(this._self, this._then);

  final RemoteError _self;
  final $Res Function(RemoteError) _then;

/// Create a copy of RemoteError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = freezed,Object? message = freezed,Object? userMessage = freezed,Object? developerMessage = freezed,}) {
  return _then(RemoteError(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,userMessage: freezed == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as String?,developerMessage: freezed == developerMessage ? _self.developerMessage : developerMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RemoteError].
extension RemoteErrorPatterns on RemoteError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RemoteError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RemoteError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RemoteError value)  $default,){
final _that = this;
switch (_that) {
case _RemoteError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RemoteError value)?  $default,){
final _that = this;
switch (_that) {
case _RemoteError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? code,  String? message,  String? userMessage,  String? developerMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RemoteError() when $default != null:
return $default(_that.code,_that.message,_that.userMessage,_that.developerMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? code,  String? message,  String? userMessage,  String? developerMessage)  $default,) {final _that = this;
switch (_that) {
case _RemoteError():
return $default(_that.code,_that.message,_that.userMessage,_that.developerMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? code,  String? message,  String? userMessage,  String? developerMessage)?  $default,) {final _that = this;
switch (_that) {
case _RemoteError() when $default != null:
return $default(_that.code,_that.message,_that.userMessage,_that.developerMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RemoteError implements RemoteError {
  const _RemoteError({this.code, this.message, this.userMessage, this.developerMessage});
  factory _RemoteError.fromJson(Map<String, dynamic> json) => _$RemoteErrorFromJson(json);

@override final  int? code;
@override final  String? message;
@override final  String? userMessage;
@override final  String? developerMessage;

/// Create a copy of RemoteError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoteErrorCopyWith<_RemoteError> get copyWith => __$RemoteErrorCopyWithImpl<_RemoteError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RemoteErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoteError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.userMessage, userMessage) || other.userMessage == userMessage)&&(identical(other.developerMessage, developerMessage) || other.developerMessage == developerMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,userMessage,developerMessage);

@override
String toString() {
  return 'RemoteError(code: $code, message: $message, userMessage: $userMessage, developerMessage: $developerMessage)';
}


}

/// @nodoc
abstract mixin class _$RemoteErrorCopyWith<$Res> implements $RemoteErrorCopyWith<$Res> {
  factory _$RemoteErrorCopyWith(_RemoteError value, $Res Function(_RemoteError) _then) = __$RemoteErrorCopyWithImpl;
@override @useResult
$Res call({
 int? code, String? message, String? userMessage, String? developerMessage
});




}
/// @nodoc
class __$RemoteErrorCopyWithImpl<$Res>
    implements _$RemoteErrorCopyWith<$Res> {
  __$RemoteErrorCopyWithImpl(this._self, this._then);

  final _RemoteError _self;
  final $Res Function(_RemoteError) _then;

/// Create a copy of RemoteError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = freezed,Object? message = freezed,Object? userMessage = freezed,Object? developerMessage = freezed,}) {
  return _then(_RemoteError(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,userMessage: freezed == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as String?,developerMessage: freezed == developerMessage ? _self.developerMessage : developerMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
