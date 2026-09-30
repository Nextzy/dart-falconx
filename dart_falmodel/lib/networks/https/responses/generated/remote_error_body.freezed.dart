// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../remote_error_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RemoteErrorBody {

 int? get code; String? get message; String? get userMessage; String? get developerMessage;
/// Create a copy of RemoteErrorBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoteErrorBodyCopyWith<RemoteErrorBody> get copyWith => _$RemoteErrorBodyCopyWithImpl<RemoteErrorBody>(this as RemoteErrorBody, _$identity);

  /// Serializes this RemoteErrorBody to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RemoteErrorBody;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoteErrorBody&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.userMessage, _this.userMessage) || other.userMessage == _this.userMessage)&&(identical(other.developerMessage, _this.developerMessage) || other.developerMessage == _this.developerMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RemoteErrorBody;
  return Object.hash(runtimeType,_this.code,_this.message,_this.userMessage,_this.developerMessage);
}

@override
String toString() {
  final _this = this as RemoteErrorBody;
  return 'RemoteErrorBody(code: ${_this.code}, message: ${_this.message}, userMessage: ${_this.userMessage}, developerMessage: ${_this.developerMessage})';
}


}

/// @nodoc
abstract mixin class $RemoteErrorBodyCopyWith<$Res>  {
  factory $RemoteErrorBodyCopyWith(RemoteErrorBody value, $Res Function(RemoteErrorBody) _then) = _$RemoteErrorBodyCopyWithImpl;
@useResult
$Res call({
 int? code, String? message, String? userMessage, String? developerMessage
});




}
/// @nodoc
class _$RemoteErrorBodyCopyWithImpl<$Res>
    implements $RemoteErrorBodyCopyWith<$Res> {
  _$RemoteErrorBodyCopyWithImpl(this._self, this._then);

  final RemoteErrorBody _self;
  final $Res Function(RemoteErrorBody) _then;

/// Create a copy of RemoteErrorBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = freezed,Object? message = freezed,Object? userMessage = freezed,Object? developerMessage = freezed,}) {
  return _then(RemoteErrorBody(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,userMessage: freezed == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as String?,developerMessage: freezed == developerMessage ? _self.developerMessage : developerMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RemoteErrorBody].
extension RemoteErrorBodyPatterns on RemoteErrorBody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RemoteErrorBody value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RemoteErrorBody() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RemoteErrorBody value)  $default,){
final _that = this;
switch (_that) {
case _RemoteErrorBody():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RemoteErrorBody value)?  $default,){
final _that = this;
switch (_that) {
case _RemoteErrorBody() when $default != null:
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
case _RemoteErrorBody() when $default != null:
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
case _RemoteErrorBody():
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
case _RemoteErrorBody() when $default != null:
return $default(_that.code,_that.message,_that.userMessage,_that.developerMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RemoteErrorBody implements RemoteErrorBody {
  const _RemoteErrorBody({this.code, this.message, this.userMessage, this.developerMessage});
  factory _RemoteErrorBody.fromJson(Map<String, dynamic> json) => _$RemoteErrorBodyFromJson(json);

@override final  int? code;
@override final  String? message;
@override final  String? userMessage;
@override final  String? developerMessage;

/// Create a copy of RemoteErrorBody
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoteErrorBodyCopyWith<_RemoteErrorBody> get copyWith => __$RemoteErrorBodyCopyWithImpl<_RemoteErrorBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RemoteErrorBodyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoteErrorBody&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.userMessage, userMessage) || other.userMessage == userMessage)&&(identical(other.developerMessage, developerMessage) || other.developerMessage == developerMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,message,userMessage,developerMessage);
}

@override
String toString() {
    return 'RemoteErrorBody(code: $code, message: $message, userMessage: $userMessage, developerMessage: $developerMessage)';
}


}

/// @nodoc
abstract mixin class _$RemoteErrorBodyCopyWith<$Res> implements $RemoteErrorBodyCopyWith<$Res> {
  factory _$RemoteErrorBodyCopyWith(_RemoteErrorBody value, $Res Function(_RemoteErrorBody) _then) = __$RemoteErrorBodyCopyWithImpl;
@override @useResult
$Res call({
 int? code, String? message, String? userMessage, String? developerMessage
});




}
/// @nodoc
class __$RemoteErrorBodyCopyWithImpl<$Res>
    implements _$RemoteErrorBodyCopyWith<$Res> {
  __$RemoteErrorBodyCopyWithImpl(this._self, this._then);

  final _RemoteErrorBody _self;
  final $Res Function(_RemoteErrorBody) _then;

/// Create a copy of RemoteErrorBody
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = freezed,Object? message = freezed,Object? userMessage = freezed,Object? developerMessage = freezed,}) {
  return _then(_RemoteErrorBody(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,userMessage: freezed == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as String?,developerMessage: freezed == developerMessage ? _self.developerMessage : developerMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
