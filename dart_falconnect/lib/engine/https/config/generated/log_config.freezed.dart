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

/// Logs the request body.
 bool get requestBody;/// Logs the response body.
 bool get responseBody;/// Headers printed as `REDACTED`, compared ignoring case.
 Set<String> get redactHeaders;/// Query parameters whose values print as `REDACTED`, compared ignoring
/// case.
 Set<String> get redactQueryParameters;/// Printer for HTTP logs and diagnostics; null prints to the console.
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogConfig&&(identical(other.requestBody, _this.requestBody) || other.requestBody == _this.requestBody)&&(identical(other.responseBody, _this.responseBody) || other.responseBody == _this.responseBody)&&const DeepCollectionEquality().equals(other.redactHeaders, _this.redactHeaders)&&const DeepCollectionEquality().equals(other.redactQueryParameters, _this.redactQueryParameters)&&(identical(other.logPrint, _this.logPrint) || other.logPrint == _this.logPrint)&&(identical(other.diagnostics, _this.diagnostics) || other.diagnostics == _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as LogConfig;
  return Object.hash(runtimeType,_this.requestBody,_this.responseBody,const DeepCollectionEquality().hash(_this.redactHeaders),const DeepCollectionEquality().hash(_this.redactQueryParameters),_this.logPrint,_this.diagnostics);
}

@override
String toString() {
  final _this = this as LogConfig;
  return 'LogConfig(requestBody: ${_this.requestBody}, responseBody: ${_this.responseBody}, redactHeaders: ${_this.redactHeaders}, redactQueryParameters: ${_this.redactQueryParameters}, logPrint: ${_this.logPrint}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $LogConfigCopyWith<$Res>  {
  factory $LogConfigCopyWith(LogConfig value, $Res Function(LogConfig) _then) = _$LogConfigCopyWithImpl;
@useResult
$Res call({
 bool requestBody, bool responseBody, Set<String> redactHeaders, Set<String> redactQueryParameters, void Function(Object? object)? logPrint, bool diagnostics
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
@pragma('vm:prefer-inline') @override $Res call({Object? requestBody = null,Object? responseBody = null,Object? redactHeaders = null,Object? redactQueryParameters = null,Object? logPrint = freezed,Object? diagnostics = null,}) {
  return _then(_self.copyWith(
requestBody: null == requestBody ? _self.requestBody : requestBody // ignore: cast_nullable_to_non_nullable
as bool,responseBody: null == responseBody ? _self.responseBody : responseBody // ignore: cast_nullable_to_non_nullable
as bool,redactHeaders: null == redactHeaders ? _self.redactHeaders : redactHeaders // ignore: cast_nullable_to_non_nullable
as Set<String>,redactQueryParameters: null == redactQueryParameters ? _self.redactQueryParameters : redactQueryParameters // ignore: cast_nullable_to_non_nullable
as Set<String>,logPrint: freezed == logPrint ? _self.logPrint : logPrint // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( PrettyLogConfig value)?  $default,{TResult Function( JsonLogConfig value)?  json,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PrettyLogConfig() when $default != null:
return $default(_that);case JsonLogConfig() when json != null:
return json(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( PrettyLogConfig value)  $default,{required TResult Function( JsonLogConfig value)  json,}){
final _that = this;
switch (_that) {
case PrettyLogConfig():
return $default(_that);case JsonLogConfig():
return json(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( PrettyLogConfig value)?  $default,{TResult? Function( JsonLogConfig value)?  json,}){
final _that = this;
switch (_that) {
case PrettyLogConfig() when $default != null:
return $default(_that);case JsonLogConfig() when json != null:
return json(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool request,  bool requestHeader,  bool requestBody,  bool responseHeader,  bool responseBody,  bool error,  Set<String> redactHeaders,  Set<String> redactQueryParameters,  void Function(Object? object)? logPrint,  bool diagnostics)?  $default,{TResult Function( bool requestHeaders,  bool responseHeaders,  bool requestBody,  bool responseBody,  int maxBodyBytes,  Set<String> redactHeaders,  Set<String> redactQueryParameters,  void Function(Object? object)? logPrint,  bool diagnostics)?  json,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PrettyLogConfig() when $default != null:
return $default(_that.request,_that.requestHeader,_that.requestBody,_that.responseHeader,_that.responseBody,_that.error,_that.redactHeaders,_that.redactQueryParameters,_that.logPrint,_that.diagnostics);case JsonLogConfig() when json != null:
return json(_that.requestHeaders,_that.responseHeaders,_that.requestBody,_that.responseBody,_that.maxBodyBytes,_that.redactHeaders,_that.redactQueryParameters,_that.logPrint,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool request,  bool requestHeader,  bool requestBody,  bool responseHeader,  bool responseBody,  bool error,  Set<String> redactHeaders,  Set<String> redactQueryParameters,  void Function(Object? object)? logPrint,  bool diagnostics)  $default,{required TResult Function( bool requestHeaders,  bool responseHeaders,  bool requestBody,  bool responseBody,  int maxBodyBytes,  Set<String> redactHeaders,  Set<String> redactQueryParameters,  void Function(Object? object)? logPrint,  bool diagnostics)  json,}) {final _that = this;
switch (_that) {
case PrettyLogConfig():
return $default(_that.request,_that.requestHeader,_that.requestBody,_that.responseHeader,_that.responseBody,_that.error,_that.redactHeaders,_that.redactQueryParameters,_that.logPrint,_that.diagnostics);case JsonLogConfig():
return json(_that.requestHeaders,_that.responseHeaders,_that.requestBody,_that.responseBody,_that.maxBodyBytes,_that.redactHeaders,_that.redactQueryParameters,_that.logPrint,_that.diagnostics);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool request,  bool requestHeader,  bool requestBody,  bool responseHeader,  bool responseBody,  bool error,  Set<String> redactHeaders,  Set<String> redactQueryParameters,  void Function(Object? object)? logPrint,  bool diagnostics)?  $default,{TResult? Function( bool requestHeaders,  bool responseHeaders,  bool requestBody,  bool responseBody,  int maxBodyBytes,  Set<String> redactHeaders,  Set<String> redactQueryParameters,  void Function(Object? object)? logPrint,  bool diagnostics)?  json,}) {final _that = this;
switch (_that) {
case PrettyLogConfig() when $default != null:
return $default(_that.request,_that.requestHeader,_that.requestBody,_that.responseHeader,_that.responseBody,_that.error,_that.redactHeaders,_that.redactQueryParameters,_that.logPrint,_that.diagnostics);case JsonLogConfig() when json != null:
return json(_that.requestHeaders,_that.responseHeaders,_that.requestBody,_that.responseBody,_that.maxBodyBytes,_that.redactHeaders,_that.redactQueryParameters,_that.logPrint,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class PrettyLogConfig implements LogConfig {
  const PrettyLogConfig({this.request = true, this.requestHeader = true, this.requestBody = true, this.responseHeader = false, this.responseBody = true, this.error = true,  Set<String> redactHeaders = defaultRedactedHeaders,  Set<String> redactQueryParameters = defaultRedactedQueryParameters, this.logPrint, this.diagnostics = true}): _redactHeaders = redactHeaders,_redactQueryParameters = redactQueryParameters;
  

/// Logs the request line and options.
@JsonKey() final  bool request;
/// Logs request headers.
@JsonKey() final  bool requestHeader;
/// Logs the request body.
@override@JsonKey() final  bool requestBody;
/// Logs response headers.
@JsonKey() final  bool responseHeader;
/// Logs the response body.
@override@JsonKey() final  bool responseBody;
/// Logs errors.
@JsonKey() final  bool error;
/// Headers printed as `REDACTED`, compared ignoring case.
 final  Set<String> _redactHeaders;
/// Headers printed as `REDACTED`, compared ignoring case.
@override@JsonKey() Set<String> get redactHeaders {
  if (_redactHeaders is EqualUnmodifiableSetView) return _redactHeaders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_redactHeaders);
}

/// Query parameters whose values print as `REDACTED`, compared ignoring
/// case.
 final  Set<String> _redactQueryParameters;
/// Query parameters whose values print as `REDACTED`, compared ignoring
/// case.
@override@JsonKey() Set<String> get redactQueryParameters {
  if (_redactQueryParameters is EqualUnmodifiableSetView) return _redactQueryParameters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_redactQueryParameters);
}

/// Printer for HTTP logs and diagnostics; null prints to the console.
@override final  void Function(Object? object)? logPrint;
/// Whether interceptors print their diagnostics through [logPrint].
@override@JsonKey() final  bool diagnostics;

/// Create a copy of LogConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrettyLogConfigCopyWith<PrettyLogConfig> get copyWith => _$PrettyLogConfigCopyWithImpl<PrettyLogConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PrettyLogConfig&&(identical(other.request, request) || other.request == request)&&(identical(other.requestHeader, requestHeader) || other.requestHeader == requestHeader)&&(identical(other.requestBody, requestBody) || other.requestBody == requestBody)&&(identical(other.responseHeader, responseHeader) || other.responseHeader == responseHeader)&&(identical(other.responseBody, responseBody) || other.responseBody == responseBody)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.redactHeaders, _redactHeaders)&&const DeepCollectionEquality().equals(other.redactQueryParameters, _redactQueryParameters)&&(identical(other.logPrint, logPrint) || other.logPrint == logPrint)&&(identical(other.diagnostics, diagnostics) || other.diagnostics == diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,request,requestHeader,requestBody,responseHeader,responseBody,error,const DeepCollectionEquality().hash(_redactHeaders),const DeepCollectionEquality().hash(_redactQueryParameters),logPrint,diagnostics);
}

@override
String toString() {
    return 'LogConfig(request: $request, requestHeader: $requestHeader, requestBody: $requestBody, responseHeader: $responseHeader, responseBody: $responseBody, error: $error, redactHeaders: $redactHeaders, redactQueryParameters: $redactQueryParameters, logPrint: $logPrint, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $PrettyLogConfigCopyWith<$Res> implements $LogConfigCopyWith<$Res> {
  factory $PrettyLogConfigCopyWith(PrettyLogConfig value, $Res Function(PrettyLogConfig) _then) = _$PrettyLogConfigCopyWithImpl;
@override @useResult
$Res call({
 bool request, bool requestHeader, bool requestBody, bool responseHeader, bool responseBody, bool error, Set<String> redactHeaders, Set<String> redactQueryParameters, void Function(Object? object)? logPrint, bool diagnostics
});




}
/// @nodoc
class _$PrettyLogConfigCopyWithImpl<$Res>
    implements $PrettyLogConfigCopyWith<$Res> {
  _$PrettyLogConfigCopyWithImpl(this._self, this._then);

  final PrettyLogConfig _self;
  final $Res Function(PrettyLogConfig) _then;

/// Create a copy of LogConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? request = null,Object? requestHeader = null,Object? requestBody = null,Object? responseHeader = null,Object? responseBody = null,Object? error = null,Object? redactHeaders = null,Object? redactQueryParameters = null,Object? logPrint = freezed,Object? diagnostics = null,}) {
  return _then(PrettyLogConfig(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as bool,requestHeader: null == requestHeader ? _self.requestHeader : requestHeader // ignore: cast_nullable_to_non_nullable
as bool,requestBody: null == requestBody ? _self.requestBody : requestBody // ignore: cast_nullable_to_non_nullable
as bool,responseHeader: null == responseHeader ? _self.responseHeader : responseHeader // ignore: cast_nullable_to_non_nullable
as bool,responseBody: null == responseBody ? _self.responseBody : responseBody // ignore: cast_nullable_to_non_nullable
as bool,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as bool,redactHeaders: null == redactHeaders ? _self._redactHeaders : redactHeaders // ignore: cast_nullable_to_non_nullable
as Set<String>,redactQueryParameters: null == redactQueryParameters ? _self._redactQueryParameters : redactQueryParameters // ignore: cast_nullable_to_non_nullable
as Set<String>,logPrint: freezed == logPrint ? _self.logPrint : logPrint // ignore: cast_nullable_to_non_nullable
as void Function(Object? object)?,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class JsonLogConfig implements LogConfig {
  const JsonLogConfig({this.requestHeaders = false, this.responseHeaders = false, this.requestBody = false, this.responseBody = false, this.maxBodyBytes = 4096,  Set<String> redactHeaders = defaultRedactedHeaders,  Set<String> redactQueryParameters = defaultRedactedQueryParameters, this.logPrint, this.diagnostics = true}): _redactHeaders = redactHeaders,_redactQueryParameters = redactQueryParameters;
  

/// Adds each request header as `http.request.header.<name>`.
@JsonKey() final  bool requestHeaders;
/// Adds each response header as `http.response.header.<name>`.
@JsonKey() final  bool responseHeaders;
/// Adds the request body as `falconx.request.body`.
@override@JsonKey() final  bool requestBody;
/// Adds the response body as `falconx.response.body`.
@override@JsonKey() final  bool responseBody;
/// Most UTF-8 bytes of a logged body; a longer body is cut and flagged.
@JsonKey() final  int maxBodyBytes;
/// Headers logged as `["REDACTED"]`, compared ignoring case. Bodies are
/// never redacted.
 final  Set<String> _redactHeaders;
/// Headers logged as `["REDACTED"]`, compared ignoring case. Bodies are
/// never redacted.
@override@JsonKey() Set<String> get redactHeaders {
  if (_redactHeaders is EqualUnmodifiableSetView) return _redactHeaders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_redactHeaders);
}

/// Query parameters whose values log as `REDACTED`, compared ignoring
/// case.
 final  Set<String> _redactQueryParameters;
/// Query parameters whose values log as `REDACTED`, compared ignoring
/// case.
@override@JsonKey() Set<String> get redactQueryParameters {
  if (_redactQueryParameters is EqualUnmodifiableSetView) return _redactQueryParameters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_redactQueryParameters);
}

/// Printer for HTTP logs and diagnostics; null prints to stdout.
@override final  void Function(Object? object)? logPrint;
/// Whether interceptors print their diagnostics through [logPrint], as
/// JSON lines inside a `BaseHttpClient`.
@override@JsonKey() final  bool diagnostics;

/// Create a copy of LogConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JsonLogConfigCopyWith<JsonLogConfig> get copyWith => _$JsonLogConfigCopyWithImpl<JsonLogConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is JsonLogConfig&&(identical(other.requestHeaders, requestHeaders) || other.requestHeaders == requestHeaders)&&(identical(other.responseHeaders, responseHeaders) || other.responseHeaders == responseHeaders)&&(identical(other.requestBody, requestBody) || other.requestBody == requestBody)&&(identical(other.responseBody, responseBody) || other.responseBody == responseBody)&&(identical(other.maxBodyBytes, maxBodyBytes) || other.maxBodyBytes == maxBodyBytes)&&const DeepCollectionEquality().equals(other.redactHeaders, _redactHeaders)&&const DeepCollectionEquality().equals(other.redactQueryParameters, _redactQueryParameters)&&(identical(other.logPrint, logPrint) || other.logPrint == logPrint)&&(identical(other.diagnostics, diagnostics) || other.diagnostics == diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,requestHeaders,responseHeaders,requestBody,responseBody,maxBodyBytes,const DeepCollectionEquality().hash(_redactHeaders),const DeepCollectionEquality().hash(_redactQueryParameters),logPrint,diagnostics);
}

@override
String toString() {
    return 'LogConfig.json(requestHeaders: $requestHeaders, responseHeaders: $responseHeaders, requestBody: $requestBody, responseBody: $responseBody, maxBodyBytes: $maxBodyBytes, redactHeaders: $redactHeaders, redactQueryParameters: $redactQueryParameters, logPrint: $logPrint, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $JsonLogConfigCopyWith<$Res> implements $LogConfigCopyWith<$Res> {
  factory $JsonLogConfigCopyWith(JsonLogConfig value, $Res Function(JsonLogConfig) _then) = _$JsonLogConfigCopyWithImpl;
@override @useResult
$Res call({
 bool requestHeaders, bool responseHeaders, bool requestBody, bool responseBody, int maxBodyBytes, Set<String> redactHeaders, Set<String> redactQueryParameters, void Function(Object? object)? logPrint, bool diagnostics
});




}
/// @nodoc
class _$JsonLogConfigCopyWithImpl<$Res>
    implements $JsonLogConfigCopyWith<$Res> {
  _$JsonLogConfigCopyWithImpl(this._self, this._then);

  final JsonLogConfig _self;
  final $Res Function(JsonLogConfig) _then;

/// Create a copy of LogConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestHeaders = null,Object? responseHeaders = null,Object? requestBody = null,Object? responseBody = null,Object? maxBodyBytes = null,Object? redactHeaders = null,Object? redactQueryParameters = null,Object? logPrint = freezed,Object? diagnostics = null,}) {
  return _then(JsonLogConfig(
requestHeaders: null == requestHeaders ? _self.requestHeaders : requestHeaders // ignore: cast_nullable_to_non_nullable
as bool,responseHeaders: null == responseHeaders ? _self.responseHeaders : responseHeaders // ignore: cast_nullable_to_non_nullable
as bool,requestBody: null == requestBody ? _self.requestBody : requestBody // ignore: cast_nullable_to_non_nullable
as bool,responseBody: null == responseBody ? _self.responseBody : responseBody // ignore: cast_nullable_to_non_nullable
as bool,maxBodyBytes: null == maxBodyBytes ? _self.maxBodyBytes : maxBodyBytes // ignore: cast_nullable_to_non_nullable
as int,redactHeaders: null == redactHeaders ? _self._redactHeaders : redactHeaders // ignore: cast_nullable_to_non_nullable
as Set<String>,redactQueryParameters: null == redactQueryParameters ? _self._redactQueryParameters : redactQueryParameters // ignore: cast_nullable_to_non_nullable
as Set<String>,logPrint: freezed == logPrint ? _self.logPrint : logPrint // ignore: cast_nullable_to_non_nullable
as void Function(Object? object)?,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
