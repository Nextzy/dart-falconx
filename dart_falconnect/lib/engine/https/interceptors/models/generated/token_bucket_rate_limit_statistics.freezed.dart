// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../token_bucket_rate_limit_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TokenBucketRateLimitStatistics {

/// Requests passed to the next handler since construction. A request
/// cancelled before it was forwarded is not counted.
 int get forwarded;/// Requests rejected with a local 429 since construction, for a full
/// queue or a paused host.
 int get rejected;/// Requests waiting in each host's own tiers, keyed by host. An idle
/// host whose buckets have refilled drops out once a new host arrives.
 Map<String, int> get waitingByHost;/// Requests waiting in the global tiers.
 int get globalWaiting;/// Requests held by a pause, keyed by host.
 Map<String, int> get heldByHost;/// End time of each active pause, keyed by host.
 Map<String, DateTime> get pausedUntilByHost;
/// Create a copy of TokenBucketRateLimitStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenBucketRateLimitStatisticsCopyWith<TokenBucketRateLimitStatistics> get copyWith => _$TokenBucketRateLimitStatisticsCopyWithImpl<TokenBucketRateLimitStatistics>(this as TokenBucketRateLimitStatistics, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TokenBucketRateLimitStatistics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenBucketRateLimitStatistics&&(identical(other.forwarded, _this.forwarded) || other.forwarded == _this.forwarded)&&(identical(other.rejected, _this.rejected) || other.rejected == _this.rejected)&&const DeepCollectionEquality().equals(other.waitingByHost, _this.waitingByHost)&&(identical(other.globalWaiting, _this.globalWaiting) || other.globalWaiting == _this.globalWaiting)&&const DeepCollectionEquality().equals(other.heldByHost, _this.heldByHost)&&const DeepCollectionEquality().equals(other.pausedUntilByHost, _this.pausedUntilByHost));
}


@override
int get hashCode {
  final _this = this as TokenBucketRateLimitStatistics;
  return Object.hash(runtimeType,_this.forwarded,_this.rejected,const DeepCollectionEquality().hash(_this.waitingByHost),_this.globalWaiting,const DeepCollectionEquality().hash(_this.heldByHost),const DeepCollectionEquality().hash(_this.pausedUntilByHost));
}

@override
String toString() {
  final _this = this as TokenBucketRateLimitStatistics;
  return 'TokenBucketRateLimitStatistics(forwarded: ${_this.forwarded}, rejected: ${_this.rejected}, waitingByHost: ${_this.waitingByHost}, globalWaiting: ${_this.globalWaiting}, heldByHost: ${_this.heldByHost}, pausedUntilByHost: ${_this.pausedUntilByHost})';
}


}

/// @nodoc
abstract mixin class $TokenBucketRateLimitStatisticsCopyWith<$Res>  {
  factory $TokenBucketRateLimitStatisticsCopyWith(TokenBucketRateLimitStatistics value, $Res Function(TokenBucketRateLimitStatistics) _then) = _$TokenBucketRateLimitStatisticsCopyWithImpl;
@useResult
$Res call({
 int forwarded, int rejected, Map<String, int> waitingByHost, int globalWaiting, Map<String, int> heldByHost, Map<String, DateTime> pausedUntilByHost
});




}
/// @nodoc
class _$TokenBucketRateLimitStatisticsCopyWithImpl<$Res>
    implements $TokenBucketRateLimitStatisticsCopyWith<$Res> {
  _$TokenBucketRateLimitStatisticsCopyWithImpl(this._self, this._then);

  final TokenBucketRateLimitStatistics _self;
  final $Res Function(TokenBucketRateLimitStatistics) _then;

/// Create a copy of TokenBucketRateLimitStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? forwarded = null,Object? rejected = null,Object? waitingByHost = null,Object? globalWaiting = null,Object? heldByHost = null,Object? pausedUntilByHost = null,}) {
  return _then(TokenBucketRateLimitStatistics(
forwarded: null == forwarded ? _self.forwarded : forwarded // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,waitingByHost: null == waitingByHost ? _self.waitingByHost : waitingByHost // ignore: cast_nullable_to_non_nullable
as Map<String, int>,globalWaiting: null == globalWaiting ? _self.globalWaiting : globalWaiting // ignore: cast_nullable_to_non_nullable
as int,heldByHost: null == heldByHost ? _self.heldByHost : heldByHost // ignore: cast_nullable_to_non_nullable
as Map<String, int>,pausedUntilByHost: null == pausedUntilByHost ? _self.pausedUntilByHost : pausedUntilByHost // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenBucketRateLimitStatistics].
extension TokenBucketRateLimitStatisticsPatterns on TokenBucketRateLimitStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokenBucketRateLimitStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokenBucketRateLimitStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokenBucketRateLimitStatistics value)  $default,){
final _that = this;
switch (_that) {
case _TokenBucketRateLimitStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokenBucketRateLimitStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _TokenBucketRateLimitStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int forwarded,  int rejected,  Map<String, int> waitingByHost,  int globalWaiting,  Map<String, int> heldByHost,  Map<String, DateTime> pausedUntilByHost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokenBucketRateLimitStatistics() when $default != null:
return $default(_that.forwarded,_that.rejected,_that.waitingByHost,_that.globalWaiting,_that.heldByHost,_that.pausedUntilByHost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int forwarded,  int rejected,  Map<String, int> waitingByHost,  int globalWaiting,  Map<String, int> heldByHost,  Map<String, DateTime> pausedUntilByHost)  $default,) {final _that = this;
switch (_that) {
case _TokenBucketRateLimitStatistics():
return $default(_that.forwarded,_that.rejected,_that.waitingByHost,_that.globalWaiting,_that.heldByHost,_that.pausedUntilByHost);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int forwarded,  int rejected,  Map<String, int> waitingByHost,  int globalWaiting,  Map<String, int> heldByHost,  Map<String, DateTime> pausedUntilByHost)?  $default,) {final _that = this;
switch (_that) {
case _TokenBucketRateLimitStatistics() when $default != null:
return $default(_that.forwarded,_that.rejected,_that.waitingByHost,_that.globalWaiting,_that.heldByHost,_that.pausedUntilByHost);case _:
  return null;

}
}

}

/// @nodoc


class _TokenBucketRateLimitStatistics implements TokenBucketRateLimitStatistics {
  const _TokenBucketRateLimitStatistics({required this.forwarded, required this.rejected, required  Map<String, int> waitingByHost, required this.globalWaiting, required  Map<String, int> heldByHost, required  Map<String, DateTime> pausedUntilByHost}): _waitingByHost = waitingByHost,_heldByHost = heldByHost,_pausedUntilByHost = pausedUntilByHost;
  

/// Requests passed to the next handler since construction. A request
/// cancelled before it was forwarded is not counted.
@override final  int forwarded;
/// Requests rejected with a local 429 since construction, for a full
/// queue or a paused host.
@override final  int rejected;
/// Requests waiting in each host's own tiers, keyed by host. An idle
/// host whose buckets have refilled drops out once a new host arrives.
 final  Map<String, int> _waitingByHost;
/// Requests waiting in each host's own tiers, keyed by host. An idle
/// host whose buckets have refilled drops out once a new host arrives.
@override Map<String, int> get waitingByHost {
  if (_waitingByHost is EqualUnmodifiableMapView) return _waitingByHost;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_waitingByHost);
}

/// Requests waiting in the global tiers.
@override final  int globalWaiting;
/// Requests held by a pause, keyed by host.
 final  Map<String, int> _heldByHost;
/// Requests held by a pause, keyed by host.
@override Map<String, int> get heldByHost {
  if (_heldByHost is EqualUnmodifiableMapView) return _heldByHost;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_heldByHost);
}

/// End time of each active pause, keyed by host.
 final  Map<String, DateTime> _pausedUntilByHost;
/// End time of each active pause, keyed by host.
@override Map<String, DateTime> get pausedUntilByHost {
  if (_pausedUntilByHost is EqualUnmodifiableMapView) return _pausedUntilByHost;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pausedUntilByHost);
}


/// Create a copy of TokenBucketRateLimitStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenBucketRateLimitStatisticsCopyWith<_TokenBucketRateLimitStatistics> get copyWith => __$TokenBucketRateLimitStatisticsCopyWithImpl<_TokenBucketRateLimitStatistics>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenBucketRateLimitStatistics&&(identical(other.forwarded, forwarded) || other.forwarded == forwarded)&&(identical(other.rejected, rejected) || other.rejected == rejected)&&const DeepCollectionEquality().equals(other.waitingByHost, _waitingByHost)&&(identical(other.globalWaiting, globalWaiting) || other.globalWaiting == globalWaiting)&&const DeepCollectionEquality().equals(other.heldByHost, _heldByHost)&&const DeepCollectionEquality().equals(other.pausedUntilByHost, _pausedUntilByHost));
}


@override
int get hashCode {
    return Object.hash(runtimeType,forwarded,rejected,const DeepCollectionEquality().hash(_waitingByHost),globalWaiting,const DeepCollectionEquality().hash(_heldByHost),const DeepCollectionEquality().hash(_pausedUntilByHost));
}

@override
String toString() {
    return 'TokenBucketRateLimitStatistics(forwarded: $forwarded, rejected: $rejected, waitingByHost: $waitingByHost, globalWaiting: $globalWaiting, heldByHost: $heldByHost, pausedUntilByHost: $pausedUntilByHost)';
}


}

/// @nodoc
abstract mixin class _$TokenBucketRateLimitStatisticsCopyWith<$Res> implements $TokenBucketRateLimitStatisticsCopyWith<$Res> {
  factory _$TokenBucketRateLimitStatisticsCopyWith(_TokenBucketRateLimitStatistics value, $Res Function(_TokenBucketRateLimitStatistics) _then) = __$TokenBucketRateLimitStatisticsCopyWithImpl;
@override @useResult
$Res call({
 int forwarded, int rejected, Map<String, int> waitingByHost, int globalWaiting, Map<String, int> heldByHost, Map<String, DateTime> pausedUntilByHost
});




}
/// @nodoc
class __$TokenBucketRateLimitStatisticsCopyWithImpl<$Res>
    implements _$TokenBucketRateLimitStatisticsCopyWith<$Res> {
  __$TokenBucketRateLimitStatisticsCopyWithImpl(this._self, this._then);

  final _TokenBucketRateLimitStatistics _self;
  final $Res Function(_TokenBucketRateLimitStatistics) _then;

/// Create a copy of TokenBucketRateLimitStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? forwarded = null,Object? rejected = null,Object? waitingByHost = null,Object? globalWaiting = null,Object? heldByHost = null,Object? pausedUntilByHost = null,}) {
  return _then(_TokenBucketRateLimitStatistics(
forwarded: null == forwarded ? _self.forwarded : forwarded // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,waitingByHost: null == waitingByHost ? _self._waitingByHost : waitingByHost // ignore: cast_nullable_to_non_nullable
as Map<String, int>,globalWaiting: null == globalWaiting ? _self.globalWaiting : globalWaiting // ignore: cast_nullable_to_non_nullable
as int,heldByHost: null == heldByHost ? _self._heldByHost : heldByHost // ignore: cast_nullable_to_non_nullable
as Map<String, int>,pausedUntilByHost: null == pausedUntilByHost ? _self._pausedUntilByHost : pausedUntilByHost // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,
  ));
}


}

// dart format on
