// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../feedback.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
UserFeedback _$UserFeedbackFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'success':
          return Success.fromJson(
            json
          );
                case 'warning':
          return Warning.fromJson(
            json
          );
                case 'failure':
          return Failure.fromJson(
            json
          );
                case 'information':
          return Information.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'UserFeedback',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$UserFeedback {

 String? get message; FeedbackLevel get level;
/// Create a copy of UserFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserFeedbackCopyWith<UserFeedback> get copyWith => _$UserFeedbackCopyWithImpl<UserFeedback>(this as UserFeedback, _$identity);

  /// Serializes this UserFeedback to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserFeedback&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,level);

@override
String toString() {
  return 'UserFeedback(message: $message, level: $level)';
}


}

/// @nodoc
abstract mixin class $UserFeedbackCopyWith<$Res>  {
  factory $UserFeedbackCopyWith(UserFeedback value, $Res Function(UserFeedback) _then) = _$UserFeedbackCopyWithImpl;
@useResult
$Res call({
 String? message, FeedbackLevel level
});




}
/// @nodoc
class _$UserFeedbackCopyWithImpl<$Res>
    implements $UserFeedbackCopyWith<$Res> {
  _$UserFeedbackCopyWithImpl(this._self, this._then);

  final UserFeedback _self;
  final $Res Function(UserFeedback) _then;

/// Create a copy of UserFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = freezed,Object? level = null,}) {
  return _then(_self.copyWith(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as FeedbackLevel,
  ));
}

}


/// Adds pattern-matching-related methods to [UserFeedback].
extension UserFeedbackPatterns on UserFeedback {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Success value)?  success,TResult Function( Warning value)?  warning,TResult Function( Failure value)?  failure,TResult Function( Information value)?  information,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Success() when success != null:
return success(_that);case Warning() when warning != null:
return warning(_that);case Failure() when failure != null:
return failure(_that);case Information() when information != null:
return information(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Success value)  success,required TResult Function( Warning value)  warning,required TResult Function( Failure value)  failure,required TResult Function( Information value)  information,}){
final _that = this;
switch (_that) {
case Success():
return success(_that);case Warning():
return warning(_that);case Failure():
return failure(_that);case Information():
return information(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Success value)?  success,TResult? Function( Warning value)?  warning,TResult? Function( Failure value)?  failure,TResult? Function( Information value)?  information,}){
final _that = this;
switch (_that) {
case Success() when success != null:
return success(_that);case Warning() when warning != null:
return warning(_that);case Failure() when failure != null:
return failure(_that);case Information() when information != null:
return information(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? message,  FeedbackLevel level)?  success,TResult Function( String? message,  FeedbackLevel level)?  warning,TResult Function( String? message,  FeedbackLevel level)?  failure,TResult Function( String? message,  FeedbackLevel level)?  information,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Success() when success != null:
return success(_that.message,_that.level);case Warning() when warning != null:
return warning(_that.message,_that.level);case Failure() when failure != null:
return failure(_that.message,_that.level);case Information() when information != null:
return information(_that.message,_that.level);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? message,  FeedbackLevel level)  success,required TResult Function( String? message,  FeedbackLevel level)  warning,required TResult Function( String? message,  FeedbackLevel level)  failure,required TResult Function( String? message,  FeedbackLevel level)  information,}) {final _that = this;
switch (_that) {
case Success():
return success(_that.message,_that.level);case Warning():
return warning(_that.message,_that.level);case Failure():
return failure(_that.message,_that.level);case Information():
return information(_that.message,_that.level);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? message,  FeedbackLevel level)?  success,TResult? Function( String? message,  FeedbackLevel level)?  warning,TResult? Function( String? message,  FeedbackLevel level)?  failure,TResult? Function( String? message,  FeedbackLevel level)?  information,}) {final _that = this;
switch (_that) {
case Success() when success != null:
return success(_that.message,_that.level);case Warning() when warning != null:
return warning(_that.message,_that.level);case Failure() when failure != null:
return failure(_that.message,_that.level);case Information() when information != null:
return information(_that.message,_that.level);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class Success extends UserFeedback {
  const Success({this.message, this.level = FeedbackLevel.medium,  String? $type}): $type = $type ?? 'success',super._();
  factory Success.fromJson(Map<String, dynamic> json) => _$SuccessFromJson(json);

@override final  String? message;
@override@JsonKey() final  FeedbackLevel level;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of UserFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SuccessCopyWith<Success> get copyWith => _$SuccessCopyWithImpl<Success>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SuccessToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Success&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,level);

@override
String toString() {
  return 'UserFeedback.success(message: $message, level: $level)';
}


}

/// @nodoc
abstract mixin class $SuccessCopyWith<$Res> implements $UserFeedbackCopyWith<$Res> {
  factory $SuccessCopyWith(Success value, $Res Function(Success) _then) = _$SuccessCopyWithImpl;
@override @useResult
$Res call({
 String? message, FeedbackLevel level
});




}
/// @nodoc
class _$SuccessCopyWithImpl<$Res>
    implements $SuccessCopyWith<$Res> {
  _$SuccessCopyWithImpl(this._self, this._then);

  final Success _self;
  final $Res Function(Success) _then;

/// Create a copy of UserFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? level = null,}) {
  return _then(Success(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as FeedbackLevel,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Warning extends UserFeedback {
  const Warning({this.message, this.level = FeedbackLevel.medium,  String? $type}): $type = $type ?? 'warning',super._();
  factory Warning.fromJson(Map<String, dynamic> json) => _$WarningFromJson(json);

@override final  String? message;
@override@JsonKey() final  FeedbackLevel level;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of UserFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarningCopyWith<Warning> get copyWith => _$WarningCopyWithImpl<Warning>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WarningToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Warning&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,level);

@override
String toString() {
  return 'UserFeedback.warning(message: $message, level: $level)';
}


}

/// @nodoc
abstract mixin class $WarningCopyWith<$Res> implements $UserFeedbackCopyWith<$Res> {
  factory $WarningCopyWith(Warning value, $Res Function(Warning) _then) = _$WarningCopyWithImpl;
@override @useResult
$Res call({
 String? message, FeedbackLevel level
});




}
/// @nodoc
class _$WarningCopyWithImpl<$Res>
    implements $WarningCopyWith<$Res> {
  _$WarningCopyWithImpl(this._self, this._then);

  final Warning _self;
  final $Res Function(Warning) _then;

/// Create a copy of UserFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? level = null,}) {
  return _then(Warning(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as FeedbackLevel,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Failure extends UserFeedback {
  const Failure({this.message, this.level = FeedbackLevel.medium,  String? $type}): $type = $type ?? 'failure',super._();
  factory Failure.fromJson(Map<String, dynamic> json) => _$FailureFromJson(json);

@override final  String? message;
@override@JsonKey() final  FeedbackLevel level;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of UserFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FailureCopyWith<Failure> get copyWith => _$FailureCopyWithImpl<Failure>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FailureToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,level);

@override
String toString() {
  return 'UserFeedback.failure(message: $message, level: $level)';
}


}

/// @nodoc
abstract mixin class $FailureCopyWith<$Res> implements $UserFeedbackCopyWith<$Res> {
  factory $FailureCopyWith(Failure value, $Res Function(Failure) _then) = _$FailureCopyWithImpl;
@override @useResult
$Res call({
 String? message, FeedbackLevel level
});




}
/// @nodoc
class _$FailureCopyWithImpl<$Res>
    implements $FailureCopyWith<$Res> {
  _$FailureCopyWithImpl(this._self, this._then);

  final Failure _self;
  final $Res Function(Failure) _then;

/// Create a copy of UserFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? level = null,}) {
  return _then(Failure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as FeedbackLevel,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Information extends UserFeedback {
  const Information({this.message, this.level = FeedbackLevel.medium,  String? $type}): $type = $type ?? 'information',super._();
  factory Information.fromJson(Map<String, dynamic> json) => _$InformationFromJson(json);

@override final  String? message;
@override@JsonKey() final  FeedbackLevel level;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of UserFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InformationCopyWith<Information> get copyWith => _$InformationCopyWithImpl<Information>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InformationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Information&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,level);

@override
String toString() {
  return 'UserFeedback.information(message: $message, level: $level)';
}


}

/// @nodoc
abstract mixin class $InformationCopyWith<$Res> implements $UserFeedbackCopyWith<$Res> {
  factory $InformationCopyWith(Information value, $Res Function(Information) _then) = _$InformationCopyWithImpl;
@override @useResult
$Res call({
 String? message, FeedbackLevel level
});




}
/// @nodoc
class _$InformationCopyWithImpl<$Res>
    implements $InformationCopyWith<$Res> {
  _$InformationCopyWithImpl(this._self, this._then);

  final Information _self;
  final $Res Function(Information) _then;

/// Create a copy of UserFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? level = null,}) {
  return _then(Information(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as FeedbackLevel,
  ));
}


}

// dart format on
