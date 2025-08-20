// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../rpc_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JsonRpcRequest {

 String? get jsonrpc; String? get method; Map<String, dynamic>? get params; String? get id;
/// Create a copy of JsonRpcRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JsonRpcRequestCopyWith<JsonRpcRequest> get copyWith => _$JsonRpcRequestCopyWithImpl<JsonRpcRequest>(this as JsonRpcRequest, _$identity);

  /// Serializes this JsonRpcRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JsonRpcRequest&&(identical(other.jsonrpc, jsonrpc) || other.jsonrpc == jsonrpc)&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other.params, params)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jsonrpc,method,const DeepCollectionEquality().hash(params),id);

@override
String toString() {
  return 'JsonRpcRequest(jsonrpc: $jsonrpc, method: $method, params: $params, id: $id)';
}


}

/// @nodoc
abstract mixin class $JsonRpcRequestCopyWith<$Res>  {
  factory $JsonRpcRequestCopyWith(JsonRpcRequest value, $Res Function(JsonRpcRequest) _then) = _$JsonRpcRequestCopyWithImpl;
@useResult
$Res call({
 String? jsonrpc, String? method, Map<String, dynamic>? params, String? id
});




}
/// @nodoc
class _$JsonRpcRequestCopyWithImpl<$Res>
    implements $JsonRpcRequestCopyWith<$Res> {
  _$JsonRpcRequestCopyWithImpl(this._self, this._then);

  final JsonRpcRequest _self;
  final $Res Function(JsonRpcRequest) _then;

/// Create a copy of JsonRpcRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jsonrpc = freezed,Object? method = freezed,Object? params = freezed,Object? id = freezed,}) {
  return _then(_self.copyWith(
jsonrpc: freezed == jsonrpc ? _self.jsonrpc : jsonrpc // ignore: cast_nullable_to_non_nullable
as String?,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,params: freezed == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JsonRpcRequest].
extension JsonRpcRequestPatterns on JsonRpcRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JsonRpcRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JsonRpcRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JsonRpcRequest value)  $default,){
final _that = this;
switch (_that) {
case _JsonRpcRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JsonRpcRequest value)?  $default,){
final _that = this;
switch (_that) {
case _JsonRpcRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? jsonrpc,  String? method,  Map<String, dynamic>? params,  String? id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JsonRpcRequest() when $default != null:
return $default(_that.jsonrpc,_that.method,_that.params,_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? jsonrpc,  String? method,  Map<String, dynamic>? params,  String? id)  $default,) {final _that = this;
switch (_that) {
case _JsonRpcRequest():
return $default(_that.jsonrpc,_that.method,_that.params,_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? jsonrpc,  String? method,  Map<String, dynamic>? params,  String? id)?  $default,) {final _that = this;
switch (_that) {
case _JsonRpcRequest() when $default != null:
return $default(_that.jsonrpc,_that.method,_that.params,_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JsonRpcRequest extends JsonRpcRequest {
  const _JsonRpcRequest({required final  String? jsonrpc, required this.method, final  Map<String, dynamic>? params, final  String? id}): _params = params,super._(jsonrpc: jsonrpc, id: id);
  factory _JsonRpcRequest.fromJson(Map<String, dynamic> json) => _$JsonRpcRequestFromJson(json);

@override final  String? method;
 final  Map<String, dynamic>? _params;
@override Map<String, dynamic>? get params {
  final value = _params;
  if (value == null) return null;
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of JsonRpcRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JsonRpcRequestCopyWith<_JsonRpcRequest> get copyWith => __$JsonRpcRequestCopyWithImpl<_JsonRpcRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JsonRpcRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JsonRpcRequest&&(identical(other.jsonrpc, jsonrpc) || other.jsonrpc == jsonrpc)&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other._params, _params)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jsonrpc,method,const DeepCollectionEquality().hash(_params),id);

@override
String toString() {
  return 'JsonRpcRequest(jsonrpc: $jsonrpc, method: $method, params: $params, id: $id)';
}


}

/// @nodoc
abstract mixin class _$JsonRpcRequestCopyWith<$Res> implements $JsonRpcRequestCopyWith<$Res> {
  factory _$JsonRpcRequestCopyWith(_JsonRpcRequest value, $Res Function(_JsonRpcRequest) _then) = __$JsonRpcRequestCopyWithImpl;
@override @useResult
$Res call({
 String? jsonrpc, String? method, Map<String, dynamic>? params, String? id
});




}
/// @nodoc
class __$JsonRpcRequestCopyWithImpl<$Res>
    implements _$JsonRpcRequestCopyWith<$Res> {
  __$JsonRpcRequestCopyWithImpl(this._self, this._then);

  final _JsonRpcRequest _self;
  final $Res Function(_JsonRpcRequest) _then;

/// Create a copy of JsonRpcRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jsonrpc = freezed,Object? method = freezed,Object? params = freezed,Object? id = freezed,}) {
  return _then(_JsonRpcRequest(
jsonrpc: freezed == jsonrpc ? _self.jsonrpc : jsonrpc // ignore: cast_nullable_to_non_nullable
as String?,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,params: freezed == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
