import 'package:dart_falconnect/src/src.dart';

/// Extensions on `Future<Response<dynamic>>` for JSON mapping.
extension DartFalconnectHttpFutureDynamicExtensions
    on Future<Response<dynamic>> {
  /// Maps the response body through [f], which receives the decoded JSON
  /// object and returns an instance of [T].
  ///
  /// A plain [String] body is wrapped under a `result` key. Any other body
  /// that is not a JSON object, and any exception from [f], fails with a
  /// [DioException] whose `error` is a [CommonException] of
  /// [InputErrorType.invalidFormat].
  Future<Response<T>> mapJson<T>(
    FutureOr<T> Function(Map<String, Object?> response) f,
  ) {
    return then((response) async {
      final body = response.data;
      final Map<String, Object?> json;
      if (body is Map<String, Object?>) {
        json = body;
      } else if (body is String) {
        json = {'result': body};
      } else {
        throw _invalidFormat(
          response,
          'Expected a JSON object, got ${body.runtimeType}.',
        );
      }
      final T data;
      try {
        data = await f(json);
      } on Object catch (error, stackTrace) {
        throw _invalidFormat(
          response,
          'The converter failed: $error',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return response.transformData<T>(data: data);
    });
  }
}

DioException _invalidFormat(
  Response<dynamic> response,
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) => DioException(
  requestOptions: response.requestOptions,
  response: response,
  message: message,
  stackTrace: stackTrace,
  error: CommonException(
    type: InputErrorType.invalidFormat,
    developerMessage: message,
    originalException: error,
    stackTrace: stackTrace,
  ),
);

/// Runs [fallback] for a [DioException]; rethrows every other error, and
/// the original error when [fallback] is null or returns null.
FutureOr<R> _recover<T, R>(
  Object error,
  StackTrace stackTrace,
  T? Function(DioException exception, StackTrace? stackTrace)? fallback,
  R Function(DioException exception, T value) wrap,
) {
  if (fallback == null || error is! DioException) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  final value = fallback(error, error.stackTrace);
  if (value == null) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  return wrap(error, value);
}

/// The response a recovered request resolves with: the error's response
/// carrying [value], or a new one when the error has no response.
Response<T> _fallbackResponse<T>(DioException error, T value) {
  final response = error.response;
  return response == null
      ? Response<T>(requestOptions: error.requestOptions, data: value)
      : response.transformData<T>(data: value);
}

/// Extensions on `Future<Response<T>>` for unwrapping and error recovery.
extension DartFalconnectFutureResponseExtensions<T> on Future<Response<T>> {
  /// Unwraps the response and returns only the data payload.
  Future<T> unwrapResponse() => then((response) => response.data as T);

  /// Recovers from a [DioException] with the value [f] returns.
  ///
  /// A null [f], a null result, or an error that is not a [DioException]
  /// rethrows the original error.
  Future<Response<T>> catchWhenError(
    T? Function(DioException exception, StackTrace? stackTrace)? f,
  ) {
    return then(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) =>
          _recover<T, Response<T>>(error, stackTrace, f, _fallbackResponse),
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
  Future<RESULT> unwrapResponse() => then((response) => response.result);

  /// Recovers from a [DioException] with the result [f] returns.
  ///
  /// The recovered response carries the request's id, or 0 when the
  /// request body holds none. A null [f], a null result, or an error that
  /// is not a [DioException] rethrows the original error.
  Future<JsonRpcResponse<RESULT>> catchWhenError(
    RESULT? Function(DioException exception, StackTrace? stackTrace)? f,
  ) {
    return then(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) =>
          _recover<RESULT, JsonRpcResponse<RESULT>>(
            error,
            stackTrace,
            f,
            (exception, result) => JsonRpcResponse<RESULT>(
              jsonrpc: '2.0',
              id: _requestId(exception.requestOptions),
              result: result,
            ),
          ),
    );
  }
}

int _requestId(RequestOptions options) {
  final body = options.data;
  if (body is Map && body['id'] is int) return body['id'] as int;
  return 0;
}

/// Extensions on `Future<HttpResponse<T>>` for unwrapping and error recovery.
extension DartFalconnectHttpFutureResponseExtensions<T>
    on Future<HttpResponse<T>> {
  /// Unwraps the HTTP response and returns only the data payload.
  Future<T> unwrapResponse() => then((response) => response.data);

  /// Recovers from a [DioException] with the value [f] returns.
  ///
  /// A null [f], a null result, or an error that is not a [DioException]
  /// rethrows the original error.
  Future<HttpResponse<T>> catchWhenError(
    T? Function(DioException exception, StackTrace? stackTrace)? f,
  ) {
    return then(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) =>
          _recover<T, HttpResponse<T>>(
            error,
            stackTrace,
            f,
            (exception, value) =>
                HttpResponse<T>(value, _fallbackResponse(exception, value)),
          ),
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
    final options = requestOptions ?? this?.requestOptions;
    if (options == null) {
      throw StateError('copyWith on a null Response needs requestOptions.');
    }
    return Response<T>(
      data: (data ?? this?.data) as T?,
      headers: headers ?? this?.headers,
      requestOptions: options,
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
    final options = requestOptions ?? this?.requestOptions;
    if (options == null) {
      throw StateError(
        'transformData on a null Response needs requestOptions.',
      );
    }
    return Response<T>(
      data: data,
      headers: headers ?? this?.headers,
      requestOptions: options,
      isRedirect: isRedirect ?? this?.isRedirect ?? false,
      statusCode: statusCode ?? this?.statusCode,
      statusMessage: statusMessage ?? this?.statusMessage,
      redirects: redirects ?? this?.redirects ?? [],
      extra: extra ?? this?.extra ?? {},
    );
  }
}
