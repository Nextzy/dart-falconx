// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../io_adapter_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IoAdapterConfig {

/// Most open connections to one host; null means no limit. Requests
/// past the limit wait inside `HttpClient`, and that wait counts
/// toward `connectTimeout`: keep it at or above any per-host limit of
/// `ConcurrencyConfig`.
 int? get maxConnectionsPerHost;/// How long an idle connection stays open for reuse. The default is
/// the value dio uses.
 Duration get idleTimeout;/// Proxy for every request, as `host:port`; null keeps the dart:io
/// default, which reads `https_proxy`, `http_proxy`, and `no_proxy`
/// (either case) from the environment. A request that cannot reach
/// the proxy goes direct, except to a pinned host.
 String? get proxy;/// Certificate pins keyed by host. Each pin is `sha256/` followed by
/// the base64 SHA-256 of the leaf certificate's SubjectPublicKeyInfo.
/// A request to a listed host succeeds only when the leaf matches one
/// pin, and fails when it goes through a proxy or over plain `http`.
/// List a backup pin for every host.
 Map<String, Set<String>> get pins;/// Trusts every certificate chain, for a debugging proxy such as
/// Proxyman. It takes effect only while assertions are enabled:
/// Flutter debug builds, `dart test`, and `dart run --enable-asserts`.
/// Release builds and `dart compile exe` ignore it. Pins still apply.
 bool get debugTrustAnyCertificate;
/// Create a copy of IoAdapterConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IoAdapterConfigCopyWith<IoAdapterConfig> get copyWith => _$IoAdapterConfigCopyWithImpl<IoAdapterConfig>(this as IoAdapterConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as IoAdapterConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IoAdapterConfig&&(identical(other.maxConnectionsPerHost, _this.maxConnectionsPerHost) || other.maxConnectionsPerHost == _this.maxConnectionsPerHost)&&(identical(other.idleTimeout, _this.idleTimeout) || other.idleTimeout == _this.idleTimeout)&&(identical(other.proxy, _this.proxy) || other.proxy == _this.proxy)&&const DeepCollectionEquality().equals(other.pins, _this.pins)&&(identical(other.debugTrustAnyCertificate, _this.debugTrustAnyCertificate) || other.debugTrustAnyCertificate == _this.debugTrustAnyCertificate));
}


@override
int get hashCode {
  final _this = this as IoAdapterConfig;
  return Object.hash(runtimeType,_this.maxConnectionsPerHost,_this.idleTimeout,_this.proxy,const DeepCollectionEquality().hash(_this.pins),_this.debugTrustAnyCertificate);
}

@override
String toString() {
  final _this = this as IoAdapterConfig;
  return 'IoAdapterConfig(maxConnectionsPerHost: ${_this.maxConnectionsPerHost}, idleTimeout: ${_this.idleTimeout}, proxy: ${_this.proxy}, pins: ${_this.pins}, debugTrustAnyCertificate: ${_this.debugTrustAnyCertificate})';
}


}

/// @nodoc
abstract mixin class $IoAdapterConfigCopyWith<$Res>  {
  factory $IoAdapterConfigCopyWith(IoAdapterConfig value, $Res Function(IoAdapterConfig) _then) = _$IoAdapterConfigCopyWithImpl;
@useResult
$Res call({
 int? maxConnectionsPerHost, Duration idleTimeout, String? proxy, Map<String, Set<String>> pins, bool debugTrustAnyCertificate
});




}
/// @nodoc
class _$IoAdapterConfigCopyWithImpl<$Res>
    implements $IoAdapterConfigCopyWith<$Res> {
  _$IoAdapterConfigCopyWithImpl(this._self, this._then);

  final IoAdapterConfig _self;
  final $Res Function(IoAdapterConfig) _then;

/// Create a copy of IoAdapterConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxConnectionsPerHost = freezed,Object? idleTimeout = null,Object? proxy = freezed,Object? pins = null,Object? debugTrustAnyCertificate = null,}) {
  return _then(IoAdapterConfig(
maxConnectionsPerHost: freezed == maxConnectionsPerHost ? _self.maxConnectionsPerHost : maxConnectionsPerHost // ignore: cast_nullable_to_non_nullable
as int?,idleTimeout: null == idleTimeout ? _self.idleTimeout : idleTimeout // ignore: cast_nullable_to_non_nullable
as Duration,proxy: freezed == proxy ? _self.proxy : proxy // ignore: cast_nullable_to_non_nullable
as String?,pins: null == pins ? _self.pins : pins // ignore: cast_nullable_to_non_nullable
as Map<String, Set<String>>,debugTrustAnyCertificate: null == debugTrustAnyCertificate ? _self.debugTrustAnyCertificate : debugTrustAnyCertificate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [IoAdapterConfig].
extension IoAdapterConfigPatterns on IoAdapterConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IoAdapterConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IoAdapterConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IoAdapterConfig value)  $default,){
final _that = this;
switch (_that) {
case _IoAdapterConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IoAdapterConfig value)?  $default,){
final _that = this;
switch (_that) {
case _IoAdapterConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? maxConnectionsPerHost,  Duration idleTimeout,  String? proxy,  Map<String, Set<String>> pins,  bool debugTrustAnyCertificate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IoAdapterConfig() when $default != null:
return $default(_that.maxConnectionsPerHost,_that.idleTimeout,_that.proxy,_that.pins,_that.debugTrustAnyCertificate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? maxConnectionsPerHost,  Duration idleTimeout,  String? proxy,  Map<String, Set<String>> pins,  bool debugTrustAnyCertificate)  $default,) {final _that = this;
switch (_that) {
case _IoAdapterConfig():
return $default(_that.maxConnectionsPerHost,_that.idleTimeout,_that.proxy,_that.pins,_that.debugTrustAnyCertificate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? maxConnectionsPerHost,  Duration idleTimeout,  String? proxy,  Map<String, Set<String>> pins,  bool debugTrustAnyCertificate)?  $default,) {final _that = this;
switch (_that) {
case _IoAdapterConfig() when $default != null:
return $default(_that.maxConnectionsPerHost,_that.idleTimeout,_that.proxy,_that.pins,_that.debugTrustAnyCertificate);case _:
  return null;

}
}

}

/// @nodoc


class _IoAdapterConfig extends IoAdapterConfig {
  const _IoAdapterConfig({this.maxConnectionsPerHost, this.idleTimeout = const Duration(seconds: 3), this.proxy,  Map<String, Set<String>> pins = const <String, Set<String>>{}, this.debugTrustAnyCertificate = false}): _pins = pins,super._();
  

/// Most open connections to one host; null means no limit. Requests
/// past the limit wait inside `HttpClient`, and that wait counts
/// toward `connectTimeout`: keep it at or above any per-host limit of
/// `ConcurrencyConfig`.
@override final  int? maxConnectionsPerHost;
/// How long an idle connection stays open for reuse. The default is
/// the value dio uses.
@override@JsonKey() final  Duration idleTimeout;
/// Proxy for every request, as `host:port`; null keeps the dart:io
/// default, which reads `https_proxy`, `http_proxy`, and `no_proxy`
/// (either case) from the environment. A request that cannot reach
/// the proxy goes direct, except to a pinned host.
@override final  String? proxy;
/// Certificate pins keyed by host. Each pin is `sha256/` followed by
/// the base64 SHA-256 of the leaf certificate's SubjectPublicKeyInfo.
/// A request to a listed host succeeds only when the leaf matches one
/// pin, and fails when it goes through a proxy or over plain `http`.
/// List a backup pin for every host.
 final  Map<String, Set<String>> _pins;
/// Certificate pins keyed by host. Each pin is `sha256/` followed by
/// the base64 SHA-256 of the leaf certificate's SubjectPublicKeyInfo.
/// A request to a listed host succeeds only when the leaf matches one
/// pin, and fails when it goes through a proxy or over plain `http`.
/// List a backup pin for every host.
@override@JsonKey() Map<String, Set<String>> get pins {
  if (_pins is EqualUnmodifiableMapView) return _pins;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pins);
}

/// Trusts every certificate chain, for a debugging proxy such as
/// Proxyman. It takes effect only while assertions are enabled:
/// Flutter debug builds, `dart test`, and `dart run --enable-asserts`.
/// Release builds and `dart compile exe` ignore it. Pins still apply.
@override@JsonKey() final  bool debugTrustAnyCertificate;

/// Create a copy of IoAdapterConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IoAdapterConfigCopyWith<_IoAdapterConfig> get copyWith => __$IoAdapterConfigCopyWithImpl<_IoAdapterConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IoAdapterConfig&&(identical(other.maxConnectionsPerHost, maxConnectionsPerHost) || other.maxConnectionsPerHost == maxConnectionsPerHost)&&(identical(other.idleTimeout, idleTimeout) || other.idleTimeout == idleTimeout)&&(identical(other.proxy, proxy) || other.proxy == proxy)&&const DeepCollectionEquality().equals(other.pins, _pins)&&(identical(other.debugTrustAnyCertificate, debugTrustAnyCertificate) || other.debugTrustAnyCertificate == debugTrustAnyCertificate));
}


@override
int get hashCode {
    return Object.hash(runtimeType,maxConnectionsPerHost,idleTimeout,proxy,const DeepCollectionEquality().hash(_pins),debugTrustAnyCertificate);
}

@override
String toString() {
    return 'IoAdapterConfig(maxConnectionsPerHost: $maxConnectionsPerHost, idleTimeout: $idleTimeout, proxy: $proxy, pins: $pins, debugTrustAnyCertificate: $debugTrustAnyCertificate)';
}


}

/// @nodoc
abstract mixin class _$IoAdapterConfigCopyWith<$Res> implements $IoAdapterConfigCopyWith<$Res> {
  factory _$IoAdapterConfigCopyWith(_IoAdapterConfig value, $Res Function(_IoAdapterConfig) _then) = __$IoAdapterConfigCopyWithImpl;
@override @useResult
$Res call({
 int? maxConnectionsPerHost, Duration idleTimeout, String? proxy, Map<String, Set<String>> pins, bool debugTrustAnyCertificate
});




}
/// @nodoc
class __$IoAdapterConfigCopyWithImpl<$Res>
    implements _$IoAdapterConfigCopyWith<$Res> {
  __$IoAdapterConfigCopyWithImpl(this._self, this._then);

  final _IoAdapterConfig _self;
  final $Res Function(_IoAdapterConfig) _then;

/// Create a copy of IoAdapterConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxConnectionsPerHost = freezed,Object? idleTimeout = null,Object? proxy = freezed,Object? pins = null,Object? debugTrustAnyCertificate = null,}) {
  return _then(_IoAdapterConfig(
maxConnectionsPerHost: freezed == maxConnectionsPerHost ? _self.maxConnectionsPerHost : maxConnectionsPerHost // ignore: cast_nullable_to_non_nullable
as int?,idleTimeout: null == idleTimeout ? _self.idleTimeout : idleTimeout // ignore: cast_nullable_to_non_nullable
as Duration,proxy: freezed == proxy ? _self.proxy : proxy // ignore: cast_nullable_to_non_nullable
as String?,pins: null == pins ? _self._pins : pins // ignore: cast_nullable_to_non_nullable
as Map<String, Set<String>>,debugTrustAnyCertificate: null == debugTrustAnyCertificate ? _self.debugTrustAnyCertificate : debugTrustAnyCertificate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
