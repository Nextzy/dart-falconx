import 'package:dart_falconnect/lib.dart';

/// Extensions on `Future<Response<dynamic>>` for JSON mapping.
extension DartFalconnectHttpFutureDynamicExtensions
    on Future<Response<dynamic>> {
  /// Maps the response body through [f], which receives the decoded JSON map
  /// and returns an instance of [T].
  ///
  /// If the response data is a plain [String], it is wrapped under a `result`
  /// key before being passed to [f].
  ///
  /// Returns a `Future<Response<T>>` with the converted data payload.
  Future<Response<T>> mapJson<T>(
    FutureOr<T> Function(Map<String, Object?> response) f,
  ) {
    return then((response) async {
      T data;
      if (response.data is String) {
        final map = <String, dynamic>{};
        map['result'] = response.data;
        data = await f(map);
      } else {
        data = await f(
          response.data as Map<String, Object?>,
        );
      }

      return response.copyWith(data: data);
    });
  }
}

/// Extensions on `Future<Response<T>>` for unwrapping and error recovery.
extension DartFalconnectFutureResponseExtensions<T> on Future<Response<T>> {
  /// Unwraps the response and returns only the data payload.
  ///
  /// Returns a `Future<T>` containing the value of [Response.data].
  Future<T> unwrapResponse() {
    return then<T>((response) {
      return Future.value(response.data);
    });
  }

  /// Recovers from a [DioException] by invoking [f] to produce a fallback
  /// value.
  ///
  /// If [f] returns a non-null value the resolved response carries that value
  /// as its data; otherwise the original error is rethrown.
  Future<Response<T>> catchWhenError(
    T? Function(
      DioException exception,
      StackTrace? stackTrace,
    )?
    f,
  ) {
    return then(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) {
        if (f != null && error is DioException) {
          final resolve = f(error, error.stackTrace);
          final response = error.response.transformData(data: resolve);
          return Future.value(response);
        }
        // Error is rethrown as-is to preserve the original type.
        // ignore: only_throw_errors
        throw error;
      },
    );
  }
}

/// Extensions on `Future<JsonRpcResponse<RESULT>>` for unwrapping and error
/// recovery.
extension DartFalconnectHttpFutureRpcResponseExtensions<
  RESULT extends JsonRpcResult
>
    on Future<JsonRpcResponse<RESULT>> {
  /// Unwraps the JSON-RPC response and returns only the result payload.
  ///
  /// Returns a `Future<RESULT>` containing the value of
  /// [JsonRpcResponse.result].
  Future<RESULT> unwrapResponse() {
    return then<RESULT>((response) {
      return Future.value(response.result);
    });
  }

  /// Recovers from a [DioException] by invoking [f] to produce a fallback
  /// result.
  ///
  /// If [f] returns a non-null value the resolved response carries that value
  /// as its result; otherwise the original error is rethrown.
  Future<JsonRpcResponse<RESULT>> catchWhenError(
    RESULT? Function(
      DioException exception,
      StackTrace? stackTrace,
    )?
    f,
  ) {
    return then(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) {
        if (f != null && error is DioException) {
          final resolve = f(error, error.stackTrace);
          final response = error.response.transformData(data: resolve);
          return Future.value(response);
        }
        // Error is rethrown as-is to preserve the original type.
        // ignore: only_throw_errors
        throw error;
      },
    );
  }
}

/// Extensions on `Future<HttpResponse<T>>` for unwrapping and error recovery.
extension DartFalconnectHttpFutureResponseExtensions<T>
    on Future<HttpResponse<T>> {
  /// Unwraps the HTTP response and returns only the data payload.
  ///
  /// Returns a `Future<T>` containing the value of [HttpResponse.data].
  Future<T> unwrapResponse() {
    return then<T>((response) {
      return Future.value(response.data);
    });
  }

  /// Recovers from a [DioException] by invoking [f] to produce a fallback
  /// value.
  ///
  /// If [f] returns a non-null value the resolved response carries that value
  /// as its data; otherwise the original error is rethrown.
  Future<HttpResponse<T>> catchWhenError(
    T? Function(
      DioException exception,
      StackTrace? stackTrace,
    )?
    f,
  ) {
    return then(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) {
        if (f != null && error is DioException) {
          final resolve = f(error, error.stackTrace);
          final response = error.response.transformData(data: resolve);
          return Future.value(response);
        }
        // Error is rethrown as-is to preserve the original type.
        // ignore: only_throw_errors
        throw error;
      },
    );
  }
}

/// Extensions on a nullable [Response] for creating modified copies.
extension DartFalconnectResponseExtensions on Response<dynamic>? {
  /// Creates a copy of this response with the given fields replaced.
  ///
  /// All parameters are optional; unspecified fields are carried over from the
  /// original response. Returns a new `Response<T>` with [data] typed to [T].
  Response<T> copyWith<T>({
    T? data,
    Headers? headers,
    RequestOptions? requestOptions,
    bool? isRedirect,
    int? statusCode,
    String? statusMessage,
    List<RedirectRecord>? redirects,
    Map<String, dynamic>? extra,
  }) {
    return Response<T>(
      data: (data ?? this?.data) as T?,
      headers: headers ?? this?.headers,
      requestOptions: requestOptions ?? this!.requestOptions,
      isRedirect: isRedirect ?? this?.isRedirect ?? false,
      statusCode: statusCode ?? this?.statusCode,
      statusMessage: statusMessage ?? this?.statusMessage,
      redirects: redirects ?? this?.redirects ?? [],
      extra: extra ?? this?.extra ?? {},
    );
  }

  /// Creates a copy of this response replacing [data] with [data] typed as
  /// [T].
  ///
  /// Unlike [copyWith], the [data] parameter is required and the return type is
  /// always `Response<T>`. If this response is `null`, the data is applied in
  /// place before the cast.
  Response<T> transformData<T>({
    required T? data,
    Headers? headers,
    RequestOptions? requestOptions,
    bool? isRedirect,
    int? statusCode,
    String? statusMessage,
    List<RedirectRecord>? redirects,
    Map<String, dynamic>? extra,
  }) {
    if (this == null) {
      this?.data = data;
      return this! as Response<T>;
    }
    return Response<T>(
      data: data,
      headers: headers ?? this?.headers,
      requestOptions: requestOptions ?? this!.requestOptions,
      isRedirect: isRedirect ?? this?.isRedirect ?? false,
      statusCode: statusCode ?? this?.statusCode,
      statusMessage: statusMessage ?? this?.statusMessage,
      redirects: redirects ?? this?.redirects ?? [],
      extra: extra ?? this?.extra ?? {},
    );
  }
}
