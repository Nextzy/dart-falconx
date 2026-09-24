// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../rate_limit_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RateLimitConfig {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RateLimitConfig);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RateLimitConfig()';
}


}

/// @nodoc
class $RateLimitConfigCopyWith<$Res>  {
$RateLimitConfigCopyWith(RateLimitConfig _, $Res Function(RateLimitConfig) __);
}


/// Adds pattern-matching-related methods to [RateLimitConfig].
extension RateLimitConfigPatterns on RateLimitConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NoRateLimitConfig value)?  none,TResult Function( PauseOnlyRateLimitConfig value)?  pauseOnly,TResult Function( TokenBucketRateLimitConfig value)?  tokenBucket,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NoRateLimitConfig() when none != null:
return none(_that);case PauseOnlyRateLimitConfig() when pauseOnly != null:
return pauseOnly(_that);case TokenBucketRateLimitConfig() when tokenBucket != null:
return tokenBucket(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NoRateLimitConfig value)  none,required TResult Function( PauseOnlyRateLimitConfig value)  pauseOnly,required TResult Function( TokenBucketRateLimitConfig value)  tokenBucket,}){
final _that = this;
switch (_that) {
case NoRateLimitConfig():
return none(_that);case PauseOnlyRateLimitConfig():
return pauseOnly(_that);case TokenBucketRateLimitConfig():
return tokenBucket(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NoRateLimitConfig value)?  none,TResult? Function( PauseOnlyRateLimitConfig value)?  pauseOnly,TResult? Function( TokenBucketRateLimitConfig value)?  tokenBucket,}){
final _that = this;
switch (_that) {
case NoRateLimitConfig() when none != null:
return none(_that);case PauseOnlyRateLimitConfig() when pauseOnly != null:
return pauseOnly(_that);case TokenBucketRateLimitConfig() when tokenBucket != null:
return tokenBucket(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  none,TResult Function( PauseConfig pause,  int maxQueueSize)?  pauseOnly,TResult Function( List<TokenBucketPolicy> global,  List<TokenBucketPolicy> perHost,  Map<String, List<TokenBucketPolicy>> hosts,  bool queueRequests,  int maxQueueSize,  int maxGlobalQueueSize,  PauseConfig pause)?  tokenBucket,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NoRateLimitConfig() when none != null:
return none();case PauseOnlyRateLimitConfig() when pauseOnly != null:
return pauseOnly(_that.pause,_that.maxQueueSize);case TokenBucketRateLimitConfig() when tokenBucket != null:
return tokenBucket(_that.global,_that.perHost,_that.hosts,_that.queueRequests,_that.maxQueueSize,_that.maxGlobalQueueSize,_that.pause);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  none,required TResult Function( PauseConfig pause,  int maxQueueSize)  pauseOnly,required TResult Function( List<TokenBucketPolicy> global,  List<TokenBucketPolicy> perHost,  Map<String, List<TokenBucketPolicy>> hosts,  bool queueRequests,  int maxQueueSize,  int maxGlobalQueueSize,  PauseConfig pause)  tokenBucket,}) {final _that = this;
switch (_that) {
case NoRateLimitConfig():
return none();case PauseOnlyRateLimitConfig():
return pauseOnly(_that.pause,_that.maxQueueSize);case TokenBucketRateLimitConfig():
return tokenBucket(_that.global,_that.perHost,_that.hosts,_that.queueRequests,_that.maxQueueSize,_that.maxGlobalQueueSize,_that.pause);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  none,TResult? Function( PauseConfig pause,  int maxQueueSize)?  pauseOnly,TResult? Function( List<TokenBucketPolicy> global,  List<TokenBucketPolicy> perHost,  Map<String, List<TokenBucketPolicy>> hosts,  bool queueRequests,  int maxQueueSize,  int maxGlobalQueueSize,  PauseConfig pause)?  tokenBucket,}) {final _that = this;
switch (_that) {
case NoRateLimitConfig() when none != null:
return none();case PauseOnlyRateLimitConfig() when pauseOnly != null:
return pauseOnly(_that.pause,_that.maxQueueSize);case TokenBucketRateLimitConfig() when tokenBucket != null:
return tokenBucket(_that.global,_that.perHost,_that.hosts,_that.queueRequests,_that.maxQueueSize,_that.maxGlobalQueueSize,_that.pause);case _:
  return null;

}
}

}

/// @nodoc


class NoRateLimitConfig implements RateLimitConfig {
  const NoRateLimitConfig();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NoRateLimitConfig);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RateLimitConfig.none()';
}


}




/// @nodoc


class PauseOnlyRateLimitConfig implements RateLimitConfig {
  const PauseOnlyRateLimitConfig({this.pause = const PauseConfig(), this.maxQueueSize = 50});
  

/// Pause settings.
@JsonKey() final  PauseConfig pause;
/// Most requests held per paused host.
@JsonKey() final  int maxQueueSize;

/// Create a copy of RateLimitConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PauseOnlyRateLimitConfigCopyWith<PauseOnlyRateLimitConfig> get copyWith => _$PauseOnlyRateLimitConfigCopyWithImpl<PauseOnlyRateLimitConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PauseOnlyRateLimitConfig&&(identical(other.pause, pause) || other.pause == pause)&&(identical(other.maxQueueSize, maxQueueSize) || other.maxQueueSize == maxQueueSize));
}


@override
int get hashCode {
    return Object.hash(runtimeType,pause,maxQueueSize);
}

@override
String toString() {
    return 'RateLimitConfig.pauseOnly(pause: $pause, maxQueueSize: $maxQueueSize)';
}


}

/// @nodoc
abstract mixin class $PauseOnlyRateLimitConfigCopyWith<$Res> implements $RateLimitConfigCopyWith<$Res> {
  factory $PauseOnlyRateLimitConfigCopyWith(PauseOnlyRateLimitConfig value, $Res Function(PauseOnlyRateLimitConfig) _then) = _$PauseOnlyRateLimitConfigCopyWithImpl;
@useResult
$Res call({
 PauseConfig pause, int maxQueueSize
});


$PauseConfigCopyWith<$Res> get pause;

}
/// @nodoc
class _$PauseOnlyRateLimitConfigCopyWithImpl<$Res>
    implements $PauseOnlyRateLimitConfigCopyWith<$Res> {
  _$PauseOnlyRateLimitConfigCopyWithImpl(this._self, this._then);

  final PauseOnlyRateLimitConfig _self;
  final $Res Function(PauseOnlyRateLimitConfig) _then;

/// Create a copy of RateLimitConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pause = null,Object? maxQueueSize = null,}) {
  return _then(PauseOnlyRateLimitConfig(
pause: null == pause ? _self.pause : pause // ignore: cast_nullable_to_non_nullable
as PauseConfig,maxQueueSize: null == maxQueueSize ? _self.maxQueueSize : maxQueueSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of RateLimitConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PauseConfigCopyWith<$Res> get pause {
  
  return $PauseConfigCopyWith<$Res>(_self.pause, (value) {
    return _then(_self.copyWith(pause: value));
  });
}
}

/// @nodoc


class TokenBucketRateLimitConfig implements RateLimitConfig {
  const TokenBucketRateLimitConfig({ List<TokenBucketPolicy> global = const <TokenBucketPolicy>[],  List<TokenBucketPolicy> perHost = const <TokenBucketPolicy>[],  Map<String, List<TokenBucketPolicy>> hosts = const <String, List<TokenBucketPolicy>>{}, this.queueRequests = true, this.maxQueueSize = 50, this.maxGlobalQueueSize = 500, this.pause = const PauseConfig()}): _global = global,_perHost = perHost,_hosts = hosts;
  

/// Tiers every request passes.
 final  List<TokenBucketPolicy> _global;
/// Tiers every request passes.
@JsonKey() List<TokenBucketPolicy> get global {
  if (_global is EqualUnmodifiableListView) return _global;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_global);
}

/// Tiers of a host missing from `hosts`.
 final  List<TokenBucketPolicy> _perHost;
/// Tiers of a host missing from `hosts`.
@JsonKey() List<TokenBucketPolicy> get perHost {
  if (_perHost is EqualUnmodifiableListView) return _perHost;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_perHost);
}

/// Tiers keyed by bare lowercase host; an empty list opts the host out
/// of `perHost`.
 final  Map<String, List<TokenBucketPolicy>> _hosts;
/// Tiers keyed by bare lowercase host; an empty list opts the host out
/// of `perHost`.
@JsonKey() Map<String, List<TokenBucketPolicy>> get hosts {
  if (_hosts is EqualUnmodifiableMapView) return _hosts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_hosts);
}

/// Whether a request with no token, or to a briefly paused host, waits.
@JsonKey() final  bool queueRequests;
/// Wait-queue capacity of each host tier, and of each host's pause.
@JsonKey() final  int maxQueueSize;
/// Wait-queue capacity of each global tier.
@JsonKey() final  int maxGlobalQueueSize;
/// Pause settings.
@JsonKey() final  PauseConfig pause;

/// Create a copy of RateLimitConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenBucketRateLimitConfigCopyWith<TokenBucketRateLimitConfig> get copyWith => _$TokenBucketRateLimitConfigCopyWithImpl<TokenBucketRateLimitConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenBucketRateLimitConfig&&const DeepCollectionEquality().equals(other.global, _global)&&const DeepCollectionEquality().equals(other.perHost, _perHost)&&const DeepCollectionEquality().equals(other.hosts, _hosts)&&(identical(other.queueRequests, queueRequests) || other.queueRequests == queueRequests)&&(identical(other.maxQueueSize, maxQueueSize) || other.maxQueueSize == maxQueueSize)&&(identical(other.maxGlobalQueueSize, maxGlobalQueueSize) || other.maxGlobalQueueSize == maxGlobalQueueSize)&&(identical(other.pause, pause) || other.pause == pause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_global),const DeepCollectionEquality().hash(_perHost),const DeepCollectionEquality().hash(_hosts),queueRequests,maxQueueSize,maxGlobalQueueSize,pause);
}

@override
String toString() {
    return 'RateLimitConfig.tokenBucket(global: $global, perHost: $perHost, hosts: $hosts, queueRequests: $queueRequests, maxQueueSize: $maxQueueSize, maxGlobalQueueSize: $maxGlobalQueueSize, pause: $pause)';
}


}

/// @nodoc
abstract mixin class $TokenBucketRateLimitConfigCopyWith<$Res> implements $RateLimitConfigCopyWith<$Res> {
  factory $TokenBucketRateLimitConfigCopyWith(TokenBucketRateLimitConfig value, $Res Function(TokenBucketRateLimitConfig) _then) = _$TokenBucketRateLimitConfigCopyWithImpl;
@useResult
$Res call({
 List<TokenBucketPolicy> global, List<TokenBucketPolicy> perHost, Map<String, List<TokenBucketPolicy>> hosts, bool queueRequests, int maxQueueSize, int maxGlobalQueueSize, PauseConfig pause
});


$PauseConfigCopyWith<$Res> get pause;

}
/// @nodoc
class _$TokenBucketRateLimitConfigCopyWithImpl<$Res>
    implements $TokenBucketRateLimitConfigCopyWith<$Res> {
  _$TokenBucketRateLimitConfigCopyWithImpl(this._self, this._then);

  final TokenBucketRateLimitConfig _self;
  final $Res Function(TokenBucketRateLimitConfig) _then;

/// Create a copy of RateLimitConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? global = null,Object? perHost = null,Object? hosts = null,Object? queueRequests = null,Object? maxQueueSize = null,Object? maxGlobalQueueSize = null,Object? pause = null,}) {
  return _then(TokenBucketRateLimitConfig(
global: null == global ? _self._global : global // ignore: cast_nullable_to_non_nullable
as List<TokenBucketPolicy>,perHost: null == perHost ? _self._perHost : perHost // ignore: cast_nullable_to_non_nullable
as List<TokenBucketPolicy>,hosts: null == hosts ? _self._hosts : hosts // ignore: cast_nullable_to_non_nullable
as Map<String, List<TokenBucketPolicy>>,queueRequests: null == queueRequests ? _self.queueRequests : queueRequests // ignore: cast_nullable_to_non_nullable
as bool,maxQueueSize: null == maxQueueSize ? _self.maxQueueSize : maxQueueSize // ignore: cast_nullable_to_non_nullable
as int,maxGlobalQueueSize: null == maxGlobalQueueSize ? _self.maxGlobalQueueSize : maxGlobalQueueSize // ignore: cast_nullable_to_non_nullable
as int,pause: null == pause ? _self.pause : pause // ignore: cast_nullable_to_non_nullable
as PauseConfig,
  ));
}

/// Create a copy of RateLimitConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PauseConfigCopyWith<$Res> get pause {
  
  return $PauseConfigCopyWith<$Res>(_self.pause, (value) {
    return _then(_self.copyWith(pause: value));
  });
}
}

// dart format on
