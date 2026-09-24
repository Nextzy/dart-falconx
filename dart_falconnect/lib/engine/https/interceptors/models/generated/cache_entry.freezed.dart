// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../cache_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CacheEntry {

/// The cached HTTP response.
 Response<dynamic> get response;/// The time at which this entry was stored.
 DateTime get timestamp;/// The maximum duration this entry remains valid.
 Duration get maxAge;
/// Create a copy of CacheEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CacheEntryCopyWith<CacheEntry> get copyWith => _$CacheEntryCopyWithImpl<CacheEntry>(this as CacheEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CacheEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CacheEntry&&(identical(other.response, _this.response) || other.response == _this.response)&&(identical(other.timestamp, _this.timestamp) || other.timestamp == _this.timestamp)&&(identical(other.maxAge, _this.maxAge) || other.maxAge == _this.maxAge));
}


@override
int get hashCode {
  final _this = this as CacheEntry;
  return Object.hash(runtimeType,_this.response,_this.timestamp,_this.maxAge);
}

@override
String toString() {
  final _this = this as CacheEntry;
  return 'CacheEntry(response: ${_this.response}, timestamp: ${_this.timestamp}, maxAge: ${_this.maxAge})';
}


}

/// @nodoc
abstract mixin class $CacheEntryCopyWith<$Res>  {
  factory $CacheEntryCopyWith(CacheEntry value, $Res Function(CacheEntry) _then) = _$CacheEntryCopyWithImpl;
@useResult
$Res call({
 Response<dynamic> response, DateTime timestamp, Duration maxAge
});




}
/// @nodoc
class _$CacheEntryCopyWithImpl<$Res>
    implements $CacheEntryCopyWith<$Res> {
  _$CacheEntryCopyWithImpl(this._self, this._then);

  final CacheEntry _self;
  final $Res Function(CacheEntry) _then;

/// Create a copy of CacheEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? response = null,Object? timestamp = null,Object? maxAge = null,}) {
  return _then(CacheEntry(
response: null == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as Response<dynamic>,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,maxAge: null == maxAge ? _self.maxAge : maxAge // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [CacheEntry].
extension CacheEntryPatterns on CacheEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CacheEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CacheEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CacheEntry value)  $default,){
final _that = this;
switch (_that) {
case _CacheEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CacheEntry value)?  $default,){
final _that = this;
switch (_that) {
case _CacheEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Response<dynamic> response,  DateTime timestamp,  Duration maxAge)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CacheEntry() when $default != null:
return $default(_that.response,_that.timestamp,_that.maxAge);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Response<dynamic> response,  DateTime timestamp,  Duration maxAge)  $default,) {final _that = this;
switch (_that) {
case _CacheEntry():
return $default(_that.response,_that.timestamp,_that.maxAge);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Response<dynamic> response,  DateTime timestamp,  Duration maxAge)?  $default,) {final _that = this;
switch (_that) {
case _CacheEntry() when $default != null:
return $default(_that.response,_that.timestamp,_that.maxAge);case _:
  return null;

}
}

}

/// @nodoc


class _CacheEntry extends CacheEntry {
  const _CacheEntry({required this.response, required this.timestamp, required this.maxAge}): super._();
  

/// The cached HTTP response.
@override final  Response<dynamic> response;
/// The time at which this entry was stored.
@override final  DateTime timestamp;
/// The maximum duration this entry remains valid.
@override final  Duration maxAge;

/// Create a copy of CacheEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CacheEntryCopyWith<_CacheEntry> get copyWith => __$CacheEntryCopyWithImpl<_CacheEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CacheEntry&&(identical(other.response, response) || other.response == response)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.maxAge, maxAge) || other.maxAge == maxAge));
}


@override
int get hashCode {
    return Object.hash(runtimeType,response,timestamp,maxAge);
}

@override
String toString() {
    return 'CacheEntry(response: $response, timestamp: $timestamp, maxAge: $maxAge)';
}


}

/// @nodoc
abstract mixin class _$CacheEntryCopyWith<$Res> implements $CacheEntryCopyWith<$Res> {
  factory _$CacheEntryCopyWith(_CacheEntry value, $Res Function(_CacheEntry) _then) = __$CacheEntryCopyWithImpl;
@override @useResult
$Res call({
 Response<dynamic> response, DateTime timestamp, Duration maxAge
});




}
/// @nodoc
class __$CacheEntryCopyWithImpl<$Res>
    implements _$CacheEntryCopyWith<$Res> {
  __$CacheEntryCopyWithImpl(this._self, this._then);

  final _CacheEntry _self;
  final $Res Function(_CacheEntry) _then;

/// Create a copy of CacheEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? response = null,Object? timestamp = null,Object? maxAge = null,}) {
  return _then(_CacheEntry(
response: null == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as Response<dynamic>,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,maxAge: null == maxAge ? _self.maxAge : maxAge // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

// dart format on
