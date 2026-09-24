// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../http_client_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HttpClientConfig {

/// Base URL of every request.
 String get baseUrl;/// Timeout for opening a connection.
 Duration get connectTimeout;/// Timeout between two received chunks.
 Duration get receiveTimeout;/// Timeout for sending the body; null means no limit.
 Duration? get sendTimeout;/// Default `Content-Type`.
 String get contentType;/// Default headers the configuration owns.
 Map<String, String> get headers;/// `User-Agent` header; null leaves it unset.
 String? get userAgent;/// Whether dio follows redirects.
 bool get followRedirects;/// Most redirects followed.
 int get maxRedirects;/// Which statuses succeed; null keeps dio's default, 2xx only.
 ValidateStatus? get validateStatus;/// HTTP logging; null turns it off.
 LogConfig? get log;/// Performance monitoring; null turns it off.
 PerformanceConfig? get performance;/// Response cache; null turns it off.
 CacheConfig? get cache;/// Concurrency limit; null turns it off.
 ConcurrencyConfig? get concurrency;/// Rate limit and `Retry-After` pause.
 RateLimitConfig get rateLimit;/// Retry; null turns it off.
 RetryConfig? get retry;/// The app's own interceptors, placed first in the chain.
 List<Interceptor> get interceptors;/// Last interceptor of the chain; null means
/// `DefaultNetworkExceptionHandlerInterceptor`.
 NetworkExceptionHandlerInterceptor? get exceptionHandler;
/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HttpClientConfigCopyWith<HttpClientConfig> get copyWith => _$HttpClientConfigCopyWithImpl<HttpClientConfig>(this as HttpClientConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HttpClientConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HttpClientConfig&&(identical(other.baseUrl, _this.baseUrl) || other.baseUrl == _this.baseUrl)&&(identical(other.connectTimeout, _this.connectTimeout) || other.connectTimeout == _this.connectTimeout)&&(identical(other.receiveTimeout, _this.receiveTimeout) || other.receiveTimeout == _this.receiveTimeout)&&(identical(other.sendTimeout, _this.sendTimeout) || other.sendTimeout == _this.sendTimeout)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&const DeepCollectionEquality().equals(other.headers, _this.headers)&&(identical(other.userAgent, _this.userAgent) || other.userAgent == _this.userAgent)&&(identical(other.followRedirects, _this.followRedirects) || other.followRedirects == _this.followRedirects)&&(identical(other.maxRedirects, _this.maxRedirects) || other.maxRedirects == _this.maxRedirects)&&(identical(other.validateStatus, _this.validateStatus) || other.validateStatus == _this.validateStatus)&&(identical(other.log, _this.log) || other.log == _this.log)&&(identical(other.performance, _this.performance) || other.performance == _this.performance)&&(identical(other.cache, _this.cache) || other.cache == _this.cache)&&(identical(other.concurrency, _this.concurrency) || other.concurrency == _this.concurrency)&&(identical(other.rateLimit, _this.rateLimit) || other.rateLimit == _this.rateLimit)&&(identical(other.retry, _this.retry) || other.retry == _this.retry)&&const DeepCollectionEquality().equals(other.interceptors, _this.interceptors)&&(identical(other.exceptionHandler, _this.exceptionHandler) || other.exceptionHandler == _this.exceptionHandler));
}


@override
int get hashCode {
  final _this = this as HttpClientConfig;
  return Object.hash(runtimeType,_this.baseUrl,_this.connectTimeout,_this.receiveTimeout,_this.sendTimeout,_this.contentType,const DeepCollectionEquality().hash(_this.headers),_this.userAgent,_this.followRedirects,_this.maxRedirects,_this.validateStatus,_this.log,_this.performance,_this.cache,_this.concurrency,_this.rateLimit,_this.retry,const DeepCollectionEquality().hash(_this.interceptors),_this.exceptionHandler);
}

@override
String toString() {
  final _this = this as HttpClientConfig;
  return 'HttpClientConfig(baseUrl: ${_this.baseUrl}, connectTimeout: ${_this.connectTimeout}, receiveTimeout: ${_this.receiveTimeout}, sendTimeout: ${_this.sendTimeout}, contentType: ${_this.contentType}, headers: ${_this.headers}, userAgent: ${_this.userAgent}, followRedirects: ${_this.followRedirects}, maxRedirects: ${_this.maxRedirects}, validateStatus: ${_this.validateStatus}, log: ${_this.log}, performance: ${_this.performance}, cache: ${_this.cache}, concurrency: ${_this.concurrency}, rateLimit: ${_this.rateLimit}, retry: ${_this.retry}, interceptors: ${_this.interceptors}, exceptionHandler: ${_this.exceptionHandler})';
}


}

/// @nodoc
abstract mixin class $HttpClientConfigCopyWith<$Res>  {
  factory $HttpClientConfigCopyWith(HttpClientConfig value, $Res Function(HttpClientConfig) _then) = _$HttpClientConfigCopyWithImpl;
@useResult
$Res call({
 String baseUrl, Duration connectTimeout, Duration receiveTimeout, Duration? sendTimeout, String contentType, Map<String, String> headers, String? userAgent, bool followRedirects, int maxRedirects, ValidateStatus? validateStatus, LogConfig? log, PerformanceConfig? performance, CacheConfig? cache, ConcurrencyConfig? concurrency, RateLimitConfig rateLimit, RetryConfig? retry, List<Interceptor> interceptors, NetworkExceptionHandlerInterceptor? exceptionHandler
});


$LogConfigCopyWith<$Res>? get log;$PerformanceConfigCopyWith<$Res>? get performance;$CacheConfigCopyWith<$Res>? get cache;$ConcurrencyConfigCopyWith<$Res>? get concurrency;$RateLimitConfigCopyWith<$Res> get rateLimit;$RetryConfigCopyWith<$Res>? get retry;

}
/// @nodoc
class _$HttpClientConfigCopyWithImpl<$Res>
    implements $HttpClientConfigCopyWith<$Res> {
  _$HttpClientConfigCopyWithImpl(this._self, this._then);

  final HttpClientConfig _self;
  final $Res Function(HttpClientConfig) _then;

/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baseUrl = null,Object? connectTimeout = null,Object? receiveTimeout = null,Object? sendTimeout = freezed,Object? contentType = null,Object? headers = null,Object? userAgent = freezed,Object? followRedirects = null,Object? maxRedirects = null,Object? validateStatus = freezed,Object? log = freezed,Object? performance = freezed,Object? cache = freezed,Object? concurrency = freezed,Object? rateLimit = null,Object? retry = freezed,Object? interceptors = null,Object? exceptionHandler = freezed,}) {
  return _then(HttpClientConfig(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,connectTimeout: null == connectTimeout ? _self.connectTimeout : connectTimeout // ignore: cast_nullable_to_non_nullable
as Duration,receiveTimeout: null == receiveTimeout ? _self.receiveTimeout : receiveTimeout // ignore: cast_nullable_to_non_nullable
as Duration,sendTimeout: freezed == sendTimeout ? _self.sendTimeout : sendTimeout // ignore: cast_nullable_to_non_nullable
as Duration?,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,userAgent: freezed == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String?,followRedirects: null == followRedirects ? _self.followRedirects : followRedirects // ignore: cast_nullable_to_non_nullable
as bool,maxRedirects: null == maxRedirects ? _self.maxRedirects : maxRedirects // ignore: cast_nullable_to_non_nullable
as int,validateStatus: freezed == validateStatus ? _self.validateStatus : validateStatus // ignore: cast_nullable_to_non_nullable
as ValidateStatus?,log: freezed == log ? _self.log : log // ignore: cast_nullable_to_non_nullable
as LogConfig?,performance: freezed == performance ? _self.performance : performance // ignore: cast_nullable_to_non_nullable
as PerformanceConfig?,cache: freezed == cache ? _self.cache : cache // ignore: cast_nullable_to_non_nullable
as CacheConfig?,concurrency: freezed == concurrency ? _self.concurrency : concurrency // ignore: cast_nullable_to_non_nullable
as ConcurrencyConfig?,rateLimit: null == rateLimit ? _self.rateLimit : rateLimit // ignore: cast_nullable_to_non_nullable
as RateLimitConfig,retry: freezed == retry ? _self.retry : retry // ignore: cast_nullable_to_non_nullable
as RetryConfig?,interceptors: null == interceptors ? _self.interceptors : interceptors // ignore: cast_nullable_to_non_nullable
as List<Interceptor>,exceptionHandler: freezed == exceptionHandler ? _self.exceptionHandler : exceptionHandler // ignore: cast_nullable_to_non_nullable
as NetworkExceptionHandlerInterceptor?,
  ));
}
/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LogConfigCopyWith<$Res>? get log {
    if (_self.log == null) {
    return null;
  }

  return $LogConfigCopyWith<$Res>(_self.log!, (value) {
    return _then(_self.copyWith(log: value));
  });
}/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PerformanceConfigCopyWith<$Res>? get performance {
    if (_self.performance == null) {
    return null;
  }

  return $PerformanceConfigCopyWith<$Res>(_self.performance!, (value) {
    return _then(_self.copyWith(performance: value));
  });
}/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CacheConfigCopyWith<$Res>? get cache {
    if (_self.cache == null) {
    return null;
  }

  return $CacheConfigCopyWith<$Res>(_self.cache!, (value) {
    return _then(_self.copyWith(cache: value));
  });
}/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConcurrencyConfigCopyWith<$Res>? get concurrency {
    if (_self.concurrency == null) {
    return null;
  }

  return $ConcurrencyConfigCopyWith<$Res>(_self.concurrency!, (value) {
    return _then(_self.copyWith(concurrency: value));
  });
}/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RateLimitConfigCopyWith<$Res> get rateLimit {
  
  return $RateLimitConfigCopyWith<$Res>(_self.rateLimit, (value) {
    return _then(_self.copyWith(rateLimit: value));
  });
}/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RetryConfigCopyWith<$Res>? get retry {
    if (_self.retry == null) {
    return null;
  }

  return $RetryConfigCopyWith<$Res>(_self.retry!, (value) {
    return _then(_self.copyWith(retry: value));
  });
}
}


/// Adds pattern-matching-related methods to [HttpClientConfig].
extension HttpClientConfigPatterns on HttpClientConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HttpClientConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HttpClientConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HttpClientConfig value)  $default,){
final _that = this;
switch (_that) {
case _HttpClientConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HttpClientConfig value)?  $default,){
final _that = this;
switch (_that) {
case _HttpClientConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String baseUrl,  Duration connectTimeout,  Duration receiveTimeout,  Duration? sendTimeout,  String contentType,  Map<String, String> headers,  String? userAgent,  bool followRedirects,  int maxRedirects,  ValidateStatus? validateStatus,  LogConfig? log,  PerformanceConfig? performance,  CacheConfig? cache,  ConcurrencyConfig? concurrency,  RateLimitConfig rateLimit,  RetryConfig? retry,  List<Interceptor> interceptors,  NetworkExceptionHandlerInterceptor? exceptionHandler)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HttpClientConfig() when $default != null:
return $default(_that.baseUrl,_that.connectTimeout,_that.receiveTimeout,_that.sendTimeout,_that.contentType,_that.headers,_that.userAgent,_that.followRedirects,_that.maxRedirects,_that.validateStatus,_that.log,_that.performance,_that.cache,_that.concurrency,_that.rateLimit,_that.retry,_that.interceptors,_that.exceptionHandler);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String baseUrl,  Duration connectTimeout,  Duration receiveTimeout,  Duration? sendTimeout,  String contentType,  Map<String, String> headers,  String? userAgent,  bool followRedirects,  int maxRedirects,  ValidateStatus? validateStatus,  LogConfig? log,  PerformanceConfig? performance,  CacheConfig? cache,  ConcurrencyConfig? concurrency,  RateLimitConfig rateLimit,  RetryConfig? retry,  List<Interceptor> interceptors,  NetworkExceptionHandlerInterceptor? exceptionHandler)  $default,) {final _that = this;
switch (_that) {
case _HttpClientConfig():
return $default(_that.baseUrl,_that.connectTimeout,_that.receiveTimeout,_that.sendTimeout,_that.contentType,_that.headers,_that.userAgent,_that.followRedirects,_that.maxRedirects,_that.validateStatus,_that.log,_that.performance,_that.cache,_that.concurrency,_that.rateLimit,_that.retry,_that.interceptors,_that.exceptionHandler);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String baseUrl,  Duration connectTimeout,  Duration receiveTimeout,  Duration? sendTimeout,  String contentType,  Map<String, String> headers,  String? userAgent,  bool followRedirects,  int maxRedirects,  ValidateStatus? validateStatus,  LogConfig? log,  PerformanceConfig? performance,  CacheConfig? cache,  ConcurrencyConfig? concurrency,  RateLimitConfig rateLimit,  RetryConfig? retry,  List<Interceptor> interceptors,  NetworkExceptionHandlerInterceptor? exceptionHandler)?  $default,) {final _that = this;
switch (_that) {
case _HttpClientConfig() when $default != null:
return $default(_that.baseUrl,_that.connectTimeout,_that.receiveTimeout,_that.sendTimeout,_that.contentType,_that.headers,_that.userAgent,_that.followRedirects,_that.maxRedirects,_that.validateStatus,_that.log,_that.performance,_that.cache,_that.concurrency,_that.rateLimit,_that.retry,_that.interceptors,_that.exceptionHandler);case _:
  return null;

}
}

}

/// @nodoc


class _HttpClientConfig extends HttpClientConfig {
  const _HttpClientConfig({this.baseUrl = '', this.connectTimeout = const Duration(seconds: 20), this.receiveTimeout = const Duration(seconds: 20), this.sendTimeout, this.contentType = Headers.jsonContentType,  Map<String, String> headers = const <String, String>{}, this.userAgent, this.followRedirects = true, this.maxRedirects = 5, this.validateStatus, this.log, this.performance, this.cache, this.concurrency, this.rateLimit = const RateLimitConfig.none(), this.retry,  List<Interceptor> interceptors = const <Interceptor>[], this.exceptionHandler}): _headers = headers,_interceptors = interceptors,super._();
  

/// Base URL of every request.
@override@JsonKey() final  String baseUrl;
/// Timeout for opening a connection.
@override@JsonKey() final  Duration connectTimeout;
/// Timeout between two received chunks.
@override@JsonKey() final  Duration receiveTimeout;
/// Timeout for sending the body; null means no limit.
@override final  Duration? sendTimeout;
/// Default `Content-Type`.
@override@JsonKey() final  String contentType;
/// Default headers the configuration owns.
 final  Map<String, String> _headers;
/// Default headers the configuration owns.
@override@JsonKey() Map<String, String> get headers {
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headers);
}

/// `User-Agent` header; null leaves it unset.
@override final  String? userAgent;
/// Whether dio follows redirects.
@override@JsonKey() final  bool followRedirects;
/// Most redirects followed.
@override@JsonKey() final  int maxRedirects;
/// Which statuses succeed; null keeps dio's default, 2xx only.
@override final  ValidateStatus? validateStatus;
/// HTTP logging; null turns it off.
@override final  LogConfig? log;
/// Performance monitoring; null turns it off.
@override final  PerformanceConfig? performance;
/// Response cache; null turns it off.
@override final  CacheConfig? cache;
/// Concurrency limit; null turns it off.
@override final  ConcurrencyConfig? concurrency;
/// Rate limit and `Retry-After` pause.
@override@JsonKey() final  RateLimitConfig rateLimit;
/// Retry; null turns it off.
@override final  RetryConfig? retry;
/// The app's own interceptors, placed first in the chain.
 final  List<Interceptor> _interceptors;
/// The app's own interceptors, placed first in the chain.
@override@JsonKey() List<Interceptor> get interceptors {
  if (_interceptors is EqualUnmodifiableListView) return _interceptors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_interceptors);
}

/// Last interceptor of the chain; null means
/// `DefaultNetworkExceptionHandlerInterceptor`.
@override final  NetworkExceptionHandlerInterceptor? exceptionHandler;

/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HttpClientConfigCopyWith<_HttpClientConfig> get copyWith => __$HttpClientConfigCopyWithImpl<_HttpClientConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HttpClientConfig&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.connectTimeout, connectTimeout) || other.connectTimeout == connectTimeout)&&(identical(other.receiveTimeout, receiveTimeout) || other.receiveTimeout == receiveTimeout)&&(identical(other.sendTimeout, sendTimeout) || other.sendTimeout == sendTimeout)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&const DeepCollectionEquality().equals(other.headers, _headers)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&(identical(other.followRedirects, followRedirects) || other.followRedirects == followRedirects)&&(identical(other.maxRedirects, maxRedirects) || other.maxRedirects == maxRedirects)&&(identical(other.validateStatus, validateStatus) || other.validateStatus == validateStatus)&&(identical(other.log, log) || other.log == log)&&(identical(other.performance, performance) || other.performance == performance)&&(identical(other.cache, cache) || other.cache == cache)&&(identical(other.concurrency, concurrency) || other.concurrency == concurrency)&&(identical(other.rateLimit, rateLimit) || other.rateLimit == rateLimit)&&(identical(other.retry, retry) || other.retry == retry)&&const DeepCollectionEquality().equals(other.interceptors, _interceptors)&&(identical(other.exceptionHandler, exceptionHandler) || other.exceptionHandler == exceptionHandler));
}


@override
int get hashCode {
    return Object.hash(runtimeType,baseUrl,connectTimeout,receiveTimeout,sendTimeout,contentType,const DeepCollectionEquality().hash(_headers),userAgent,followRedirects,maxRedirects,validateStatus,log,performance,cache,concurrency,rateLimit,retry,const DeepCollectionEquality().hash(_interceptors),exceptionHandler);
}

@override
String toString() {
    return 'HttpClientConfig(baseUrl: $baseUrl, connectTimeout: $connectTimeout, receiveTimeout: $receiveTimeout, sendTimeout: $sendTimeout, contentType: $contentType, headers: $headers, userAgent: $userAgent, followRedirects: $followRedirects, maxRedirects: $maxRedirects, validateStatus: $validateStatus, log: $log, performance: $performance, cache: $cache, concurrency: $concurrency, rateLimit: $rateLimit, retry: $retry, interceptors: $interceptors, exceptionHandler: $exceptionHandler)';
}


}

/// @nodoc
abstract mixin class _$HttpClientConfigCopyWith<$Res> implements $HttpClientConfigCopyWith<$Res> {
  factory _$HttpClientConfigCopyWith(_HttpClientConfig value, $Res Function(_HttpClientConfig) _then) = __$HttpClientConfigCopyWithImpl;
@override @useResult
$Res call({
 String baseUrl, Duration connectTimeout, Duration receiveTimeout, Duration? sendTimeout, String contentType, Map<String, String> headers, String? userAgent, bool followRedirects, int maxRedirects, ValidateStatus? validateStatus, LogConfig? log, PerformanceConfig? performance, CacheConfig? cache, ConcurrencyConfig? concurrency, RateLimitConfig rateLimit, RetryConfig? retry, List<Interceptor> interceptors, NetworkExceptionHandlerInterceptor? exceptionHandler
});


@override $LogConfigCopyWith<$Res>? get log;@override $PerformanceConfigCopyWith<$Res>? get performance;@override $CacheConfigCopyWith<$Res>? get cache;@override $ConcurrencyConfigCopyWith<$Res>? get concurrency;@override $RateLimitConfigCopyWith<$Res> get rateLimit;@override $RetryConfigCopyWith<$Res>? get retry;

}
/// @nodoc
class __$HttpClientConfigCopyWithImpl<$Res>
    implements _$HttpClientConfigCopyWith<$Res> {
  __$HttpClientConfigCopyWithImpl(this._self, this._then);

  final _HttpClientConfig _self;
  final $Res Function(_HttpClientConfig) _then;

/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baseUrl = null,Object? connectTimeout = null,Object? receiveTimeout = null,Object? sendTimeout = freezed,Object? contentType = null,Object? headers = null,Object? userAgent = freezed,Object? followRedirects = null,Object? maxRedirects = null,Object? validateStatus = freezed,Object? log = freezed,Object? performance = freezed,Object? cache = freezed,Object? concurrency = freezed,Object? rateLimit = null,Object? retry = freezed,Object? interceptors = null,Object? exceptionHandler = freezed,}) {
  return _then(_HttpClientConfig(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,connectTimeout: null == connectTimeout ? _self.connectTimeout : connectTimeout // ignore: cast_nullable_to_non_nullable
as Duration,receiveTimeout: null == receiveTimeout ? _self.receiveTimeout : receiveTimeout // ignore: cast_nullable_to_non_nullable
as Duration,sendTimeout: freezed == sendTimeout ? _self.sendTimeout : sendTimeout // ignore: cast_nullable_to_non_nullable
as Duration?,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,userAgent: freezed == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String?,followRedirects: null == followRedirects ? _self.followRedirects : followRedirects // ignore: cast_nullable_to_non_nullable
as bool,maxRedirects: null == maxRedirects ? _self.maxRedirects : maxRedirects // ignore: cast_nullable_to_non_nullable
as int,validateStatus: freezed == validateStatus ? _self.validateStatus : validateStatus // ignore: cast_nullable_to_non_nullable
as ValidateStatus?,log: freezed == log ? _self.log : log // ignore: cast_nullable_to_non_nullable
as LogConfig?,performance: freezed == performance ? _self.performance : performance // ignore: cast_nullable_to_non_nullable
as PerformanceConfig?,cache: freezed == cache ? _self.cache : cache // ignore: cast_nullable_to_non_nullable
as CacheConfig?,concurrency: freezed == concurrency ? _self.concurrency : concurrency // ignore: cast_nullable_to_non_nullable
as ConcurrencyConfig?,rateLimit: null == rateLimit ? _self.rateLimit : rateLimit // ignore: cast_nullable_to_non_nullable
as RateLimitConfig,retry: freezed == retry ? _self.retry : retry // ignore: cast_nullable_to_non_nullable
as RetryConfig?,interceptors: null == interceptors ? _self._interceptors : interceptors // ignore: cast_nullable_to_non_nullable
as List<Interceptor>,exceptionHandler: freezed == exceptionHandler ? _self.exceptionHandler : exceptionHandler // ignore: cast_nullable_to_non_nullable
as NetworkExceptionHandlerInterceptor?,
  ));
}

/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LogConfigCopyWith<$Res>? get log {
    if (_self.log == null) {
    return null;
  }

  return $LogConfigCopyWith<$Res>(_self.log!, (value) {
    return _then(_self.copyWith(log: value));
  });
}/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PerformanceConfigCopyWith<$Res>? get performance {
    if (_self.performance == null) {
    return null;
  }

  return $PerformanceConfigCopyWith<$Res>(_self.performance!, (value) {
    return _then(_self.copyWith(performance: value));
  });
}/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CacheConfigCopyWith<$Res>? get cache {
    if (_self.cache == null) {
    return null;
  }

  return $CacheConfigCopyWith<$Res>(_self.cache!, (value) {
    return _then(_self.copyWith(cache: value));
  });
}/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConcurrencyConfigCopyWith<$Res>? get concurrency {
    if (_self.concurrency == null) {
    return null;
  }

  return $ConcurrencyConfigCopyWith<$Res>(_self.concurrency!, (value) {
    return _then(_self.copyWith(concurrency: value));
  });
}/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RateLimitConfigCopyWith<$Res> get rateLimit {
  
  return $RateLimitConfigCopyWith<$Res>(_self.rateLimit, (value) {
    return _then(_self.copyWith(rateLimit: value));
  });
}/// Create a copy of HttpClientConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RetryConfigCopyWith<$Res>? get retry {
    if (_self.retry == null) {
    return null;
  }

  return $RetryConfigCopyWith<$Res>(_self.retry!, (value) {
    return _then(_self.copyWith(retry: value));
  });
}
}

// dart format on
