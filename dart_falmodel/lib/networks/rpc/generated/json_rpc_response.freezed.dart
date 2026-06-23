// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../json_rpc_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JsonRpcResponse<RESULT extends JsonRpcResult> {

@JsonKey(includeFromJson: true, includeToJson: true) String get jsonrpc;@JsonKey(includeFromJson: true, includeToJson: true) int get id;@JsonKey(includeFromJson: true, includeToJson: true) RESULT get result;
/// Create a copy of JsonRpcResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JsonRpcResponseCopyWith<RESULT, JsonRpcResponse<RESULT>> get copyWith => _$JsonRpcResponseCopyWithImpl<RESULT, JsonRpcResponse<RESULT>>(this as JsonRpcResponse<RESULT>, _$identity);

  /// Serializes this JsonRpcResponse to a JSON map.
  Map<String, dynamic> toJson(Object? Function(RESULT) toJsonRESULT);


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JsonRpcResponse<RESULT>&&(identical(other.jsonrpc, jsonrpc) || other.jsonrpc == jsonrpc)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.result, result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jsonrpc,id,const DeepCollectionEquality().hash(result));

@override
String toString() {
  return 'JsonRpcResponse<$RESULT>(jsonrpc: $jsonrpc, id: $id, result: $result)';
}


}

/// @nodoc
abstract mixin class $JsonRpcResponseCopyWith<RESULT extends JsonRpcResult,$Res>  {
  factory $JsonRpcResponseCopyWith(JsonRpcResponse<RESULT> value, $Res Function(JsonRpcResponse<RESULT>) _then) = _$JsonRpcResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeFromJson: true, includeToJson: true) String jsonrpc,@JsonKey(includeFromJson: true, includeToJson: true) int id,@JsonKey(includeFromJson: true, includeToJson: true) RESULT result
});




}
/// @nodoc
class _$JsonRpcResponseCopyWithImpl<RESULT extends JsonRpcResult,$Res>
    implements $JsonRpcResponseCopyWith<RESULT, $Res> {
  _$JsonRpcResponseCopyWithImpl(this._self, this._then);

  final JsonRpcResponse<RESULT> _self;
  final $Res Function(JsonRpcResponse<RESULT>) _then;

/// Create a copy of JsonRpcResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jsonrpc = null,Object? id = null,Object? result = null,}) {
  return _then(_self.copyWith(
jsonrpc: null == jsonrpc ? _self.jsonrpc : jsonrpc // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as RESULT,
  ));
}

}


/// Adds pattern-matching-related methods to [JsonRpcResponse].
extension JsonRpcResponsePatterns<RESULT extends JsonRpcResult> on JsonRpcResponse<RESULT> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JsonRpcResponse<RESULT> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JsonRpcResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JsonRpcResponse<RESULT> value)  $default,){
final _that = this;
switch (_that) {
case _JsonRpcResponse():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JsonRpcResponse<RESULT> value)?  $default,){
final _that = this;
switch (_that) {
case _JsonRpcResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeFromJson: true, includeToJson: true)  String jsonrpc, @JsonKey(includeFromJson: true, includeToJson: true)  int id, @JsonKey(includeFromJson: true, includeToJson: true)  RESULT result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JsonRpcResponse() when $default != null:
return $default(_that.jsonrpc,_that.id,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeFromJson: true, includeToJson: true)  String jsonrpc, @JsonKey(includeFromJson: true, includeToJson: true)  int id, @JsonKey(includeFromJson: true, includeToJson: true)  RESULT result)  $default,) {final _that = this;
switch (_that) {
case _JsonRpcResponse():
return $default(_that.jsonrpc,_that.id,_that.result);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeFromJson: true, includeToJson: true)  String jsonrpc, @JsonKey(includeFromJson: true, includeToJson: true)  int id, @JsonKey(includeFromJson: true, includeToJson: true)  RESULT result)?  $default,) {final _that = this;
switch (_that) {
case _JsonRpcResponse() when $default != null:
return $default(_that.jsonrpc,_that.id,_that.result);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class _JsonRpcResponse<RESULT extends JsonRpcResult> implements JsonRpcResponse<RESULT> {
  const _JsonRpcResponse({@JsonKey(includeFromJson: true, includeToJson: true) required this.jsonrpc, @JsonKey(includeFromJson: true, includeToJson: true) required this.id, @JsonKey(includeFromJson: true, includeToJson: true) required this.result});
  factory _JsonRpcResponse.fromJson(Map<String, dynamic> json,RESULT Function(Object?) fromJsonRESULT) => _$JsonRpcResponseFromJson(json,fromJsonRESULT);

@override@JsonKey(includeFromJson: true, includeToJson: true) final  String jsonrpc;
@override@JsonKey(includeFromJson: true, includeToJson: true) final  int id;
@override@JsonKey(includeFromJson: true, includeToJson: true) final  RESULT result;

/// Create a copy of JsonRpcResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JsonRpcResponseCopyWith<RESULT, _JsonRpcResponse<RESULT>> get copyWith => __$JsonRpcResponseCopyWithImpl<RESULT, _JsonRpcResponse<RESULT>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(RESULT) toJsonRESULT) {
  return _$JsonRpcResponseToJson<RESULT>(this, toJsonRESULT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JsonRpcResponse<RESULT>&&(identical(other.jsonrpc, jsonrpc) || other.jsonrpc == jsonrpc)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.result, result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jsonrpc,id,const DeepCollectionEquality().hash(result));

@override
String toString() {
  return 'JsonRpcResponse<$RESULT>(jsonrpc: $jsonrpc, id: $id, result: $result)';
}


}

/// @nodoc
abstract mixin class _$JsonRpcResponseCopyWith<RESULT extends JsonRpcResult,$Res> implements $JsonRpcResponseCopyWith<RESULT, $Res> {
  factory _$JsonRpcResponseCopyWith(_JsonRpcResponse<RESULT> value, $Res Function(_JsonRpcResponse<RESULT>) _then) = __$JsonRpcResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeFromJson: true, includeToJson: true) String jsonrpc,@JsonKey(includeFromJson: true, includeToJson: true) int id,@JsonKey(includeFromJson: true, includeToJson: true) RESULT result
});




}
/// @nodoc
class __$JsonRpcResponseCopyWithImpl<RESULT extends JsonRpcResult,$Res>
    implements _$JsonRpcResponseCopyWith<RESULT, $Res> {
  __$JsonRpcResponseCopyWithImpl(this._self, this._then);

  final _JsonRpcResponse<RESULT> _self;
  final $Res Function(_JsonRpcResponse<RESULT>) _then;

/// Create a copy of JsonRpcResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jsonrpc = null,Object? id = null,Object? result = null,}) {
  return _then(_JsonRpcResponse<RESULT>(
jsonrpc: null == jsonrpc ? _self.jsonrpc : jsonrpc // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as RESULT,
  ));
}


}


/// @nodoc
mixin _$JsonRpcErrorResponse {

@JsonKey(includeFromJson: true, includeToJson: true) String get jsonrpc;@JsonKey(includeFromJson: true, includeToJson: true) int get id;@JsonKey(includeFromJson: true, includeToJson: true) List<JsonRpcError> get errors;
/// Create a copy of JsonRpcErrorResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JsonRpcErrorResponseCopyWith<JsonRpcErrorResponse> get copyWith => _$JsonRpcErrorResponseCopyWithImpl<JsonRpcErrorResponse>(this as JsonRpcErrorResponse, _$identity);

  /// Serializes this JsonRpcErrorResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JsonRpcErrorResponse&&(identical(other.jsonrpc, jsonrpc) || other.jsonrpc == jsonrpc)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.errors, errors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jsonrpc,id,const DeepCollectionEquality().hash(errors));

@override
String toString() {
  return 'JsonRpcErrorResponse(jsonrpc: $jsonrpc, id: $id, errors: $errors)';
}


}

/// @nodoc
abstract mixin class $JsonRpcErrorResponseCopyWith<$Res>  {
  factory $JsonRpcErrorResponseCopyWith(JsonRpcErrorResponse value, $Res Function(JsonRpcErrorResponse) _then) = _$JsonRpcErrorResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeFromJson: true, includeToJson: true) String jsonrpc,@JsonKey(includeFromJson: true, includeToJson: true) int id,@JsonKey(includeFromJson: true, includeToJson: true) List<JsonRpcError> errors
});




}
/// @nodoc
class _$JsonRpcErrorResponseCopyWithImpl<$Res>
    implements $JsonRpcErrorResponseCopyWith<$Res> {
  _$JsonRpcErrorResponseCopyWithImpl(this._self, this._then);

  final JsonRpcErrorResponse _self;
  final $Res Function(JsonRpcErrorResponse) _then;

/// Create a copy of JsonRpcErrorResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jsonrpc = null,Object? id = null,Object? errors = null,}) {
  return _then(_self.copyWith(
jsonrpc: null == jsonrpc ? _self.jsonrpc : jsonrpc // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as List<JsonRpcError>,
  ));
}

}


/// Adds pattern-matching-related methods to [JsonRpcErrorResponse].
extension JsonRpcErrorResponsePatterns on JsonRpcErrorResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JsonRpcErrorResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JsonRpcErrorResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JsonRpcErrorResponse value)  $default,){
final _that = this;
switch (_that) {
case _JsonRpcErrorResponse():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JsonRpcErrorResponse value)?  $default,){
final _that = this;
switch (_that) {
case _JsonRpcErrorResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeFromJson: true, includeToJson: true)  String jsonrpc, @JsonKey(includeFromJson: true, includeToJson: true)  int id, @JsonKey(includeFromJson: true, includeToJson: true)  List<JsonRpcError> errors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JsonRpcErrorResponse() when $default != null:
return $default(_that.jsonrpc,_that.id,_that.errors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeFromJson: true, includeToJson: true)  String jsonrpc, @JsonKey(includeFromJson: true, includeToJson: true)  int id, @JsonKey(includeFromJson: true, includeToJson: true)  List<JsonRpcError> errors)  $default,) {final _that = this;
switch (_that) {
case _JsonRpcErrorResponse():
return $default(_that.jsonrpc,_that.id,_that.errors);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeFromJson: true, includeToJson: true)  String jsonrpc, @JsonKey(includeFromJson: true, includeToJson: true)  int id, @JsonKey(includeFromJson: true, includeToJson: true)  List<JsonRpcError> errors)?  $default,) {final _that = this;
switch (_that) {
case _JsonRpcErrorResponse() when $default != null:
return $default(_that.jsonrpc,_that.id,_that.errors);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JsonRpcErrorResponse implements JsonRpcErrorResponse {
  const _JsonRpcErrorResponse({@JsonKey(includeFromJson: true, includeToJson: true) required this.jsonrpc, @JsonKey(includeFromJson: true, includeToJson: true) required this.id, @JsonKey(includeFromJson: true, includeToJson: true) required final  List<JsonRpcError> errors}): _errors = errors;
  factory _JsonRpcErrorResponse.fromJson(Map<String, dynamic> json) => _$JsonRpcErrorResponseFromJson(json);

@override@JsonKey(includeFromJson: true, includeToJson: true) final  String jsonrpc;
@override@JsonKey(includeFromJson: true, includeToJson: true) final  int id;
 final  List<JsonRpcError> _errors;
@override@JsonKey(includeFromJson: true, includeToJson: true) List<JsonRpcError> get errors {
  if (_errors is EqualUnmodifiableListView) return _errors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_errors);
}


/// Create a copy of JsonRpcErrorResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JsonRpcErrorResponseCopyWith<_JsonRpcErrorResponse> get copyWith => __$JsonRpcErrorResponseCopyWithImpl<_JsonRpcErrorResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JsonRpcErrorResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JsonRpcErrorResponse&&(identical(other.jsonrpc, jsonrpc) || other.jsonrpc == jsonrpc)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._errors, _errors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jsonrpc,id,const DeepCollectionEquality().hash(_errors));

@override
String toString() {
  return 'JsonRpcErrorResponse(jsonrpc: $jsonrpc, id: $id, errors: $errors)';
}


}

/// @nodoc
abstract mixin class _$JsonRpcErrorResponseCopyWith<$Res> implements $JsonRpcErrorResponseCopyWith<$Res> {
  factory _$JsonRpcErrorResponseCopyWith(_JsonRpcErrorResponse value, $Res Function(_JsonRpcErrorResponse) _then) = __$JsonRpcErrorResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeFromJson: true, includeToJson: true) String jsonrpc,@JsonKey(includeFromJson: true, includeToJson: true) int id,@JsonKey(includeFromJson: true, includeToJson: true) List<JsonRpcError> errors
});




}
/// @nodoc
class __$JsonRpcErrorResponseCopyWithImpl<$Res>
    implements _$JsonRpcErrorResponseCopyWith<$Res> {
  __$JsonRpcErrorResponseCopyWithImpl(this._self, this._then);

  final _JsonRpcErrorResponse _self;
  final $Res Function(_JsonRpcErrorResponse) _then;

/// Create a copy of JsonRpcErrorResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jsonrpc = null,Object? id = null,Object? errors = null,}) {
  return _then(_JsonRpcErrorResponse(
jsonrpc: null == jsonrpc ? _self.jsonrpc : jsonrpc // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,errors: null == errors ? _self._errors : errors // ignore: cast_nullable_to_non_nullable
as List<JsonRpcError>,
  ));
}


}

// dart format on
