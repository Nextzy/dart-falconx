// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../token_bucket_policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TokenBucketPolicy {

/// Most requests allowed in any window of length [per].
 int get permits;/// Window length.
 Duration get per;/// Requests allowed back to back after an idle period, as given; null
/// means the default that [effectiveBurst] computes.
 int? get burst;
/// Create a copy of TokenBucketPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenBucketPolicyCopyWith<TokenBucketPolicy> get copyWith => _$TokenBucketPolicyCopyWithImpl<TokenBucketPolicy>(this as TokenBucketPolicy, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TokenBucketPolicy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenBucketPolicy&&(identical(other.permits, _this.permits) || other.permits == _this.permits)&&(identical(other.per, _this.per) || other.per == _this.per)&&(identical(other.burst, _this.burst) || other.burst == _this.burst));
}


@override
int get hashCode {
  final _this = this as TokenBucketPolicy;
  return Object.hash(runtimeType,_this.permits,_this.per,_this.burst);
}

@override
String toString() {
  final _this = this as TokenBucketPolicy;
  return 'TokenBucketPolicy(permits: ${_this.permits}, per: ${_this.per}, burst: ${_this.burst})';
}


}

/// @nodoc
abstract mixin class $TokenBucketPolicyCopyWith<$Res>  {
  factory $TokenBucketPolicyCopyWith(TokenBucketPolicy value, $Res Function(TokenBucketPolicy) _then) = _$TokenBucketPolicyCopyWithImpl;
@useResult
$Res call({
 int permits, Duration per, int? burst
});




}
/// @nodoc
class _$TokenBucketPolicyCopyWithImpl<$Res>
    implements $TokenBucketPolicyCopyWith<$Res> {
  _$TokenBucketPolicyCopyWithImpl(this._self, this._then);

  final TokenBucketPolicy _self;
  final $Res Function(TokenBucketPolicy) _then;

/// Create a copy of TokenBucketPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? permits = null,Object? per = null,Object? burst = freezed,}) {
  return _then(TokenBucketPolicy(
permits: null == permits ? _self.permits : permits // ignore: cast_nullable_to_non_nullable
as int,per: null == per ? _self.per : per // ignore: cast_nullable_to_non_nullable
as Duration,burst: freezed == burst ? _self.burst : burst // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenBucketPolicy].
extension TokenBucketPolicyPatterns on TokenBucketPolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokenBucketPolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokenBucketPolicy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokenBucketPolicy value)  $default,){
final _that = this;
switch (_that) {
case _TokenBucketPolicy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokenBucketPolicy value)?  $default,){
final _that = this;
switch (_that) {
case _TokenBucketPolicy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int permits,  Duration per,  int? burst)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokenBucketPolicy() when $default != null:
return $default(_that.permits,_that.per,_that.burst);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int permits,  Duration per,  int? burst)  $default,) {final _that = this;
switch (_that) {
case _TokenBucketPolicy():
return $default(_that.permits,_that.per,_that.burst);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int permits,  Duration per,  int? burst)?  $default,) {final _that = this;
switch (_that) {
case _TokenBucketPolicy() when $default != null:
return $default(_that.permits,_that.per,_that.burst);case _:
  return null;

}
}

}

/// @nodoc


class _TokenBucketPolicy extends TokenBucketPolicy {
  const _TokenBucketPolicy({required this.permits, required this.per, this.burst}): super._();
  

/// Most requests allowed in any window of length [per].
@override final  int permits;
/// Window length.
@override final  Duration per;
/// Requests allowed back to back after an idle period, as given; null
/// means the default that [effectiveBurst] computes.
@override final  int? burst;

/// Create a copy of TokenBucketPolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenBucketPolicyCopyWith<_TokenBucketPolicy> get copyWith => __$TokenBucketPolicyCopyWithImpl<_TokenBucketPolicy>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenBucketPolicy&&(identical(other.permits, permits) || other.permits == permits)&&(identical(other.per, per) || other.per == per)&&(identical(other.burst, burst) || other.burst == burst));
}


@override
int get hashCode {
    return Object.hash(runtimeType,permits,per,burst);
}

@override
String toString() {
    return 'TokenBucketPolicy(permits: $permits, per: $per, burst: $burst)';
}


}

/// @nodoc
abstract mixin class _$TokenBucketPolicyCopyWith<$Res> implements $TokenBucketPolicyCopyWith<$Res> {
  factory _$TokenBucketPolicyCopyWith(_TokenBucketPolicy value, $Res Function(_TokenBucketPolicy) _then) = __$TokenBucketPolicyCopyWithImpl;
@override @useResult
$Res call({
 int permits, Duration per, int? burst
});




}
/// @nodoc
class __$TokenBucketPolicyCopyWithImpl<$Res>
    implements _$TokenBucketPolicyCopyWith<$Res> {
  __$TokenBucketPolicyCopyWithImpl(this._self, this._then);

  final _TokenBucketPolicy _self;
  final $Res Function(_TokenBucketPolicy) _then;

/// Create a copy of TokenBucketPolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? permits = null,Object? per = null,Object? burst = freezed,}) {
  return _then(_TokenBucketPolicy(
permits: null == permits ? _self.permits : permits // ignore: cast_nullable_to_non_nullable
as int,per: null == per ? _self.per : per // ignore: cast_nullable_to_non_nullable
as Duration,burst: freezed == burst ? _self.burst : burst // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
