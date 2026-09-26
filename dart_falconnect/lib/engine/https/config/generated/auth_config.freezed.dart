// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../auth_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthConfig {

/// Returns the current access token; null sends the request without
/// one. An app that refreshes before expiry does it here.
 AccessTokenCallback get accessToken;/// Refreshes the token and returns true on success; false or a throw
/// fails the refresh. A request sent from inside it never waits for
/// the refresh and never refreshes.
 RefreshCallback get refresh;/// Called once per failed refresh, and when a re-sent request gets a
/// 401 again. Not awaited; an error it throws goes to the diagnostics.
 AuthFailedCallback? get onAuthFailed;/// Header that carries the token. A `BaseHttpClient` redacts it in both
/// logs and keys the cache by it wherever it does so for `authorization`.
 String get headerName;/// Word placed before the token; an empty string sends the bare token.
 String get scheme;
/// Create a copy of AuthConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthConfigCopyWith<AuthConfig> get copyWith => _$AuthConfigCopyWithImpl<AuthConfig>(this as AuthConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthConfig&&(identical(other.accessToken, _this.accessToken) || other.accessToken == _this.accessToken)&&(identical(other.refresh, _this.refresh) || other.refresh == _this.refresh)&&(identical(other.onAuthFailed, _this.onAuthFailed) || other.onAuthFailed == _this.onAuthFailed)&&(identical(other.headerName, _this.headerName) || other.headerName == _this.headerName)&&(identical(other.scheme, _this.scheme) || other.scheme == _this.scheme));
}


@override
int get hashCode {
  final _this = this as AuthConfig;
  return Object.hash(runtimeType,_this.accessToken,_this.refresh,_this.onAuthFailed,_this.headerName,_this.scheme);
}

@override
String toString() {
  final _this = this as AuthConfig;
  return 'AuthConfig(accessToken: ${_this.accessToken}, refresh: ${_this.refresh}, onAuthFailed: ${_this.onAuthFailed}, headerName: ${_this.headerName}, scheme: ${_this.scheme})';
}


}

/// @nodoc
abstract mixin class $AuthConfigCopyWith<$Res>  {
  factory $AuthConfigCopyWith(AuthConfig value, $Res Function(AuthConfig) _then) = _$AuthConfigCopyWithImpl;
@useResult
$Res call({
 AccessTokenCallback accessToken, RefreshCallback refresh, AuthFailedCallback? onAuthFailed, String headerName, String scheme
});




}
/// @nodoc
class _$AuthConfigCopyWithImpl<$Res>
    implements $AuthConfigCopyWith<$Res> {
  _$AuthConfigCopyWithImpl(this._self, this._then);

  final AuthConfig _self;
  final $Res Function(AuthConfig) _then;

/// Create a copy of AuthConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refresh = null,Object? onAuthFailed = freezed,Object? headerName = null,Object? scheme = null,}) {
  return _then(AuthConfig(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as AccessTokenCallback,refresh: null == refresh ? _self.refresh : refresh // ignore: cast_nullable_to_non_nullable
as RefreshCallback,onAuthFailed: freezed == onAuthFailed ? _self.onAuthFailed : onAuthFailed // ignore: cast_nullable_to_non_nullable
as AuthFailedCallback?,headerName: null == headerName ? _self.headerName : headerName // ignore: cast_nullable_to_non_nullable
as String,scheme: null == scheme ? _self.scheme : scheme // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthConfig].
extension AuthConfigPatterns on AuthConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthConfig value)  $default,){
final _that = this;
switch (_that) {
case _AuthConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AuthConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AccessTokenCallback accessToken,  RefreshCallback refresh,  AuthFailedCallback? onAuthFailed,  String headerName,  String scheme)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthConfig() when $default != null:
return $default(_that.accessToken,_that.refresh,_that.onAuthFailed,_that.headerName,_that.scheme);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AccessTokenCallback accessToken,  RefreshCallback refresh,  AuthFailedCallback? onAuthFailed,  String headerName,  String scheme)  $default,) {final _that = this;
switch (_that) {
case _AuthConfig():
return $default(_that.accessToken,_that.refresh,_that.onAuthFailed,_that.headerName,_that.scheme);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AccessTokenCallback accessToken,  RefreshCallback refresh,  AuthFailedCallback? onAuthFailed,  String headerName,  String scheme)?  $default,) {final _that = this;
switch (_that) {
case _AuthConfig() when $default != null:
return $default(_that.accessToken,_that.refresh,_that.onAuthFailed,_that.headerName,_that.scheme);case _:
  return null;

}
}

}

/// @nodoc


class _AuthConfig implements AuthConfig {
  const _AuthConfig({required this.accessToken, required this.refresh, this.onAuthFailed, this.headerName = 'Authorization', this.scheme = 'Bearer'});
  

/// Returns the current access token; null sends the request without
/// one. An app that refreshes before expiry does it here.
@override final  AccessTokenCallback accessToken;
/// Refreshes the token and returns true on success; false or a throw
/// fails the refresh. A request sent from inside it never waits for
/// the refresh and never refreshes.
@override final  RefreshCallback refresh;
/// Called once per failed refresh, and when a re-sent request gets a
/// 401 again. Not awaited; an error it throws goes to the diagnostics.
@override final  AuthFailedCallback? onAuthFailed;
/// Header that carries the token. A `BaseHttpClient` redacts it in both
/// logs and keys the cache by it wherever it does so for `authorization`.
@override@JsonKey() final  String headerName;
/// Word placed before the token; an empty string sends the bare token.
@override@JsonKey() final  String scheme;

/// Create a copy of AuthConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthConfigCopyWith<_AuthConfig> get copyWith => __$AuthConfigCopyWithImpl<_AuthConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthConfig&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refresh, refresh) || other.refresh == refresh)&&(identical(other.onAuthFailed, onAuthFailed) || other.onAuthFailed == onAuthFailed)&&(identical(other.headerName, headerName) || other.headerName == headerName)&&(identical(other.scheme, scheme) || other.scheme == scheme));
}


@override
int get hashCode {
    return Object.hash(runtimeType,accessToken,refresh,onAuthFailed,headerName,scheme);
}

@override
String toString() {
    return 'AuthConfig(accessToken: $accessToken, refresh: $refresh, onAuthFailed: $onAuthFailed, headerName: $headerName, scheme: $scheme)';
}


}

/// @nodoc
abstract mixin class _$AuthConfigCopyWith<$Res> implements $AuthConfigCopyWith<$Res> {
  factory _$AuthConfigCopyWith(_AuthConfig value, $Res Function(_AuthConfig) _then) = __$AuthConfigCopyWithImpl;
@override @useResult
$Res call({
 AccessTokenCallback accessToken, RefreshCallback refresh, AuthFailedCallback? onAuthFailed, String headerName, String scheme
});




}
/// @nodoc
class __$AuthConfigCopyWithImpl<$Res>
    implements _$AuthConfigCopyWith<$Res> {
  __$AuthConfigCopyWithImpl(this._self, this._then);

  final _AuthConfig _self;
  final $Res Function(_AuthConfig) _then;

/// Create a copy of AuthConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refresh = null,Object? onAuthFailed = freezed,Object? headerName = null,Object? scheme = null,}) {
  return _then(_AuthConfig(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as AccessTokenCallback,refresh: null == refresh ? _self.refresh : refresh // ignore: cast_nullable_to_non_nullable
as RefreshCallback,onAuthFailed: freezed == onAuthFailed ? _self.onAuthFailed : onAuthFailed // ignore: cast_nullable_to_non_nullable
as AuthFailedCallback?,headerName: null == headerName ? _self.headerName : headerName // ignore: cast_nullable_to_non_nullable
as String,scheme: null == scheme ? _self.scheme : scheme // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
