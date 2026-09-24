// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../log_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LogConfig {

/// Logs the request line and options.
 bool get request;/// Logs request headers.
 bool get requestHeader;/// Logs the request body.
 bool get requestBody;/// Logs response headers.
 bool get responseHeader;/// Logs the response body.
 bool get responseBody;/// Logs errors.
 bool get error;/// Printer for HTTP logs and diagnostics; null prints to the console.
 void Function(Object? object)? get logPrint;/// Whether interceptors print their diagnostics through [logPrint].
 bool get diagnostics;
/// Create a copy of LogConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogConfigCopyWith<LogConfig> get copyWith => _$LogConfigCopyWithImpl<LogConfig>(this as LogConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LogConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogConfig&&(identical(other.request, _this.request) || other.request == _this.request)&&(identical(other.requestHeader, _this.requestHeader) || other.requestHeader == _this.requestHeader)&&(identical(other.requestBody, _this.requestBody) || other.requestBody == _this.requestBody)&&(identical(other.responseHeader, _this.responseHeader) || other.responseHeader == _this.responseHeader)&&(identical(other.responseBody, _this.responseBody) || other.responseBody == _this.responseBody)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.logPrint, _this.logPrint) || other.logPrint == _this.logPrint)&&(identical(other.diagnostics, _this.diagnostics) || other.diagnostics == _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as LogConfig;
  return Object.hash(runtimeType,_this.request,_this.requestHeader,_this.requestBody,_this.responseHeader,_this.responseBody,_this.error,_this.logPrint,_this.diagnostics);
}

@override
String toString() {
  final _this = this as LogConfig;
  return 'LogConfig(request: ${_this.request}, requestHeader: ${_this.requestHeader}, requestBody: ${_this.requestBody}, responseHeader: ${_this.responseHeader}, responseBody: ${_this.responseBody}, error: ${_this.error}, logPrint: ${_this.logPrint}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $LogConfigCopyWith<$Res>  {
  factory $LogConfigCopyWith(LogConfig value, $Res Function(LogConfig) _then) = _$LogConfigCopyWithImpl;
@useResult
$Res call({
 bool request, bool requestHeader, bool requestBody, bool responseHeader, bool responseBody, bool error, void Function(Object? object)? logPrint, bool diagnostics
});




}
/// @nodoc
class _$LogConfigCopyWithImpl<$Res>
    implements $LogConfigCopyWith<$Res> {
  _$LogConfigCopyWithImpl(this._self, this._then);

  final LogConfig _self;
  final $Res Function(LogConfig) _then;

/// Create a copy of LogConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? request = null,Object? requestHeader = null,Object? requestBody = null,Object? responseHeader = null,Object? responseBody = null,Object? error = null,Object? logPrint = freezed,Object? diagnostics = null,}) {
  return _then(LogConfig(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as bool,requestHeader: null == requestHeader ? _self.requestHeader : requestHeader // ignore: cast_nullable_to_non_nullable
as bool,requestBody: null == requestBody ? _self.requestBody : requestBody // ignore: cast_nullable_to_non_nullable
as bool,responseHeader: null == responseHeader ? _self.responseHeader : responseHeader // ignore: cast_nullable_to_non_nullable
as bool,responseBody: null == responseBody ? _self.responseBody : responseBody // ignore: cast_nullable_to_non_nullable
as bool,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as bool,logPrint: freezed == logPrint ? _self.logPrint : logPrint // ignore: cast_nullable_to_non_nullable
as void Function(Object? object)?,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LogConfig].
extension LogConfigPatterns on LogConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogConfig value)  $default,){
final _that = this;
switch (_that) {
case _LogConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogConfig value)?  $default,){
final _that = this;
switch (_that) {
case _LogConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool request,  bool requestHeader,  bool requestBody,  bool responseHeader,  bool responseBody,  bool error,  void Function(Object? object)? logPrint,  bool diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogConfig() when $default != null:
return $default(_that.request,_that.requestHeader,_that.requestBody,_that.responseHeader,_that.responseBody,_that.error,_that.logPrint,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool request,  bool requestHeader,  bool requestBody,  bool responseHeader,  bool responseBody,  bool error,  void Function(Object? object)? logPrint,  bool diagnostics)  $default,) {final _that = this;
switch (_that) {
case _LogConfig():
return $default(_that.request,_that.requestHeader,_that.requestBody,_that.responseHeader,_that.responseBody,_that.error,_that.logPrint,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool request,  bool requestHeader,  bool requestBody,  bool responseHeader,  bool responseBody,  bool error,  void Function(Object? object)? logPrint,  bool diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _LogConfig() when $default != null:
return $default(_that.request,_that.requestHeader,_that.requestBody,_that.responseHeader,_that.responseBody,_that.error,_that.logPrint,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _LogConfig implements LogConfig {
  const _LogConfig({this.request = true, this.requestHeader = true, this.requestBody = true, this.responseHeader = false, this.responseBody = true, this.error = true, this.logPrint, this.diagnostics = true});
  

/// Logs the request line and options.
@override@JsonKey() final  bool request;
/// Logs request headers.
@override@JsonKey() final  bool requestHeader;
/// Logs the request body.
@override@JsonKey() final  bool requestBody;
/// Logs response headers.
@override@JsonKey() final  bool responseHeader;
/// Logs the response body.
@override@JsonKey() final  bool responseBody;
/// Logs errors.
@override@JsonKey() final  bool error;
/// Printer for HTTP logs and diagnostics; null prints to the console.
@override final  void Function(Object? object)? logPrint;
/// Whether interceptors print their diagnostics through [logPrint].
@override@JsonKey() final  bool diagnostics;

/// Create a copy of LogConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogConfigCopyWith<_LogConfig> get copyWith => __$LogConfigCopyWithImpl<_LogConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogConfig&&(identical(other.request, request) || other.request == request)&&(identical(other.requestHeader, requestHeader) || other.requestHeader == requestHeader)&&(identical(other.requestBody, requestBody) || other.requestBody == requestBody)&&(identical(other.responseHeader, responseHeader) || other.responseHeader == responseHeader)&&(identical(other.responseBody, responseBody) || other.responseBody == responseBody)&&(identical(other.error, error) || other.error == error)&&(identical(other.logPrint, logPrint) || other.logPrint == logPrint)&&(identical(other.diagnostics, diagnostics) || other.diagnostics == diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,request,requestHeader,requestBody,responseHeader,responseBody,error,logPrint,diagnostics);
}

@override
String toString() {
    return 'LogConfig(request: $request, requestHeader: $requestHeader, requestBody: $requestBody, responseHeader: $responseHeader, responseBody: $responseBody, error: $error, logPrint: $logPrint, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$LogConfigCopyWith<$Res> implements $LogConfigCopyWith<$Res> {
  factory _$LogConfigCopyWith(_LogConfig value, $Res Function(_LogConfig) _then) = __$LogConfigCopyWithImpl;
@override @useResult
$Res call({
 bool request, bool requestHeader, bool requestBody, bool responseHeader, bool responseBody, bool error, void Function(Object? object)? logPrint, bool diagnostics
});




}
/// @nodoc
class __$LogConfigCopyWithImpl<$Res>
    implements _$LogConfigCopyWith<$Res> {
  __$LogConfigCopyWithImpl(this._self, this._then);

  final _LogConfig _self;
  final $Res Function(_LogConfig) _then;

/// Create a copy of LogConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? request = null,Object? requestHeader = null,Object? requestBody = null,Object? responseHeader = null,Object? responseBody = null,Object? error = null,Object? logPrint = freezed,Object? diagnostics = null,}) {
  return _then(_LogConfig(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as bool,requestHeader: null == requestHeader ? _self.requestHeader : requestHeader // ignore: cast_nullable_to_non_nullable
as bool,requestBody: null == requestBody ? _self.requestBody : requestBody // ignore: cast_nullable_to_non_nullable
as bool,responseHeader: null == responseHeader ? _self.responseHeader : responseHeader // ignore: cast_nullable_to_non_nullable
as bool,responseBody: null == responseBody ? _self.responseBody : responseBody // ignore: cast_nullable_to_non_nullable
as bool,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as bool,logPrint: freezed == logPrint ? _self.logPrint : logPrint // ignore: cast_nullable_to_non_nullable
as void Function(Object? object)?,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
