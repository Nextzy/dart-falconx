// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../concurrency_limit_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConcurrencyLimitStatistics {

/// Requests passed to the next handler since construction, retry
/// attempts included.
 int get forwarded;/// Requests rejected with a local 429 because a queue was full.
 int get rejected;/// Slots held in each host's own limit, keyed by host. Only hosts with a
/// request in flight or queued appear.
 Map<String, int> get activeByHost;/// Requests queued for each host's own limit, keyed by host.
 Map<String, int> get waitingByHost;/// Slots held in the global limit; 0 without one.
 int get globalActive;/// Requests queued for the global limit; 0 without one.
 int get globalWaiting;
/// Create a copy of ConcurrencyLimitStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConcurrencyLimitStatisticsCopyWith<ConcurrencyLimitStatistics> get copyWith => _$ConcurrencyLimitStatisticsCopyWithImpl<ConcurrencyLimitStatistics>(this as ConcurrencyLimitStatistics, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ConcurrencyLimitStatistics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConcurrencyLimitStatistics&&(identical(other.forwarded, _this.forwarded) || other.forwarded == _this.forwarded)&&(identical(other.rejected, _this.rejected) || other.rejected == _this.rejected)&&const DeepCollectionEquality().equals(other.activeByHost, _this.activeByHost)&&const DeepCollectionEquality().equals(other.waitingByHost, _this.waitingByHost)&&(identical(other.globalActive, _this.globalActive) || other.globalActive == _this.globalActive)&&(identical(other.globalWaiting, _this.globalWaiting) || other.globalWaiting == _this.globalWaiting));
}


@override
int get hashCode {
  final _this = this as ConcurrencyLimitStatistics;
  return Object.hash(runtimeType,_this.forwarded,_this.rejected,const DeepCollectionEquality().hash(_this.activeByHost),const DeepCollectionEquality().hash(_this.waitingByHost),_this.globalActive,_this.globalWaiting);
}

@override
String toString() {
  final _this = this as ConcurrencyLimitStatistics;
  return 'ConcurrencyLimitStatistics(forwarded: ${_this.forwarded}, rejected: ${_this.rejected}, activeByHost: ${_this.activeByHost}, waitingByHost: ${_this.waitingByHost}, globalActive: ${_this.globalActive}, globalWaiting: ${_this.globalWaiting})';
}


}

/// @nodoc
abstract mixin class $ConcurrencyLimitStatisticsCopyWith<$Res>  {
  factory $ConcurrencyLimitStatisticsCopyWith(ConcurrencyLimitStatistics value, $Res Function(ConcurrencyLimitStatistics) _then) = _$ConcurrencyLimitStatisticsCopyWithImpl;
@useResult
$Res call({
 int forwarded, int rejected, Map<String, int> activeByHost, Map<String, int> waitingByHost, int globalActive, int globalWaiting
});




}
/// @nodoc
class _$ConcurrencyLimitStatisticsCopyWithImpl<$Res>
    implements $ConcurrencyLimitStatisticsCopyWith<$Res> {
  _$ConcurrencyLimitStatisticsCopyWithImpl(this._self, this._then);

  final ConcurrencyLimitStatistics _self;
  final $Res Function(ConcurrencyLimitStatistics) _then;

/// Create a copy of ConcurrencyLimitStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? forwarded = null,Object? rejected = null,Object? activeByHost = null,Object? waitingByHost = null,Object? globalActive = null,Object? globalWaiting = null,}) {
  return _then(ConcurrencyLimitStatistics(
forwarded: null == forwarded ? _self.forwarded : forwarded // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,activeByHost: null == activeByHost ? _self.activeByHost : activeByHost // ignore: cast_nullable_to_non_nullable
as Map<String, int>,waitingByHost: null == waitingByHost ? _self.waitingByHost : waitingByHost // ignore: cast_nullable_to_non_nullable
as Map<String, int>,globalActive: null == globalActive ? _self.globalActive : globalActive // ignore: cast_nullable_to_non_nullable
as int,globalWaiting: null == globalWaiting ? _self.globalWaiting : globalWaiting // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ConcurrencyLimitStatistics].
extension ConcurrencyLimitStatisticsPatterns on ConcurrencyLimitStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConcurrencyLimitStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConcurrencyLimitStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConcurrencyLimitStatistics value)  $default,){
final _that = this;
switch (_that) {
case _ConcurrencyLimitStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConcurrencyLimitStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _ConcurrencyLimitStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int forwarded,  int rejected,  Map<String, int> activeByHost,  Map<String, int> waitingByHost,  int globalActive,  int globalWaiting)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConcurrencyLimitStatistics() when $default != null:
return $default(_that.forwarded,_that.rejected,_that.activeByHost,_that.waitingByHost,_that.globalActive,_that.globalWaiting);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int forwarded,  int rejected,  Map<String, int> activeByHost,  Map<String, int> waitingByHost,  int globalActive,  int globalWaiting)  $default,) {final _that = this;
switch (_that) {
case _ConcurrencyLimitStatistics():
return $default(_that.forwarded,_that.rejected,_that.activeByHost,_that.waitingByHost,_that.globalActive,_that.globalWaiting);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int forwarded,  int rejected,  Map<String, int> activeByHost,  Map<String, int> waitingByHost,  int globalActive,  int globalWaiting)?  $default,) {final _that = this;
switch (_that) {
case _ConcurrencyLimitStatistics() when $default != null:
return $default(_that.forwarded,_that.rejected,_that.activeByHost,_that.waitingByHost,_that.globalActive,_that.globalWaiting);case _:
  return null;

}
}

}

/// @nodoc


class _ConcurrencyLimitStatistics implements ConcurrencyLimitStatistics {
  const _ConcurrencyLimitStatistics({required this.forwarded, required this.rejected, required  Map<String, int> activeByHost, required  Map<String, int> waitingByHost, required this.globalActive, required this.globalWaiting}): _activeByHost = activeByHost,_waitingByHost = waitingByHost;
  

/// Requests passed to the next handler since construction, retry
/// attempts included.
@override final  int forwarded;
/// Requests rejected with a local 429 because a queue was full.
@override final  int rejected;
/// Slots held in each host's own limit, keyed by host. Only hosts with a
/// request in flight or queued appear.
 final  Map<String, int> _activeByHost;
/// Slots held in each host's own limit, keyed by host. Only hosts with a
/// request in flight or queued appear.
@override Map<String, int> get activeByHost {
  if (_activeByHost is EqualUnmodifiableMapView) return _activeByHost;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_activeByHost);
}

/// Requests queued for each host's own limit, keyed by host.
 final  Map<String, int> _waitingByHost;
/// Requests queued for each host's own limit, keyed by host.
@override Map<String, int> get waitingByHost {
  if (_waitingByHost is EqualUnmodifiableMapView) return _waitingByHost;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_waitingByHost);
}

/// Slots held in the global limit; 0 without one.
@override final  int globalActive;
/// Requests queued for the global limit; 0 without one.
@override final  int globalWaiting;

/// Create a copy of ConcurrencyLimitStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConcurrencyLimitStatisticsCopyWith<_ConcurrencyLimitStatistics> get copyWith => __$ConcurrencyLimitStatisticsCopyWithImpl<_ConcurrencyLimitStatistics>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConcurrencyLimitStatistics&&(identical(other.forwarded, forwarded) || other.forwarded == forwarded)&&(identical(other.rejected, rejected) || other.rejected == rejected)&&const DeepCollectionEquality().equals(other.activeByHost, _activeByHost)&&const DeepCollectionEquality().equals(other.waitingByHost, _waitingByHost)&&(identical(other.globalActive, globalActive) || other.globalActive == globalActive)&&(identical(other.globalWaiting, globalWaiting) || other.globalWaiting == globalWaiting));
}


@override
int get hashCode {
    return Object.hash(runtimeType,forwarded,rejected,const DeepCollectionEquality().hash(_activeByHost),const DeepCollectionEquality().hash(_waitingByHost),globalActive,globalWaiting);
}

@override
String toString() {
    return 'ConcurrencyLimitStatistics(forwarded: $forwarded, rejected: $rejected, activeByHost: $activeByHost, waitingByHost: $waitingByHost, globalActive: $globalActive, globalWaiting: $globalWaiting)';
}


}

/// @nodoc
abstract mixin class _$ConcurrencyLimitStatisticsCopyWith<$Res> implements $ConcurrencyLimitStatisticsCopyWith<$Res> {
  factory _$ConcurrencyLimitStatisticsCopyWith(_ConcurrencyLimitStatistics value, $Res Function(_ConcurrencyLimitStatistics) _then) = __$ConcurrencyLimitStatisticsCopyWithImpl;
@override @useResult
$Res call({
 int forwarded, int rejected, Map<String, int> activeByHost, Map<String, int> waitingByHost, int globalActive, int globalWaiting
});




}
/// @nodoc
class __$ConcurrencyLimitStatisticsCopyWithImpl<$Res>
    implements _$ConcurrencyLimitStatisticsCopyWith<$Res> {
  __$ConcurrencyLimitStatisticsCopyWithImpl(this._self, this._then);

  final _ConcurrencyLimitStatistics _self;
  final $Res Function(_ConcurrencyLimitStatistics) _then;

/// Create a copy of ConcurrencyLimitStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? forwarded = null,Object? rejected = null,Object? activeByHost = null,Object? waitingByHost = null,Object? globalActive = null,Object? globalWaiting = null,}) {
  return _then(_ConcurrencyLimitStatistics(
forwarded: null == forwarded ? _self.forwarded : forwarded // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,activeByHost: null == activeByHost ? _self._activeByHost : activeByHost // ignore: cast_nullable_to_non_nullable
as Map<String, int>,waitingByHost: null == waitingByHost ? _self._waitingByHost : waitingByHost // ignore: cast_nullable_to_non_nullable
as Map<String, int>,globalActive: null == globalActive ? _self.globalActive : globalActive // ignore: cast_nullable_to_non_nullable
as int,globalWaiting: null == globalWaiting ? _self.globalWaiting : globalWaiting // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
