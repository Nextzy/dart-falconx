// Ignore because is not necessary
// ignore_for_file: only_throw_errors, omit_local_variable_types
// ignore_for_file: inference_failure_on_function_return_type
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_dynamic_calls

import 'package:dart_falconnect/lib.dart';

/// Abstract base class for JSON-RPC 2.0 services communicating over HTTP.
///
/// Subclass this to implement application-specific JSON-RPC endpoints.
/// Use [DefaultJsonRpcService] when no custom behaviour is needed.
abstract class JsonRpcService {
  /// Creates a [JsonRpcService] backed by [_dio].
  ///
  /// [baseUrl] is the root endpoint for all requests. [jsonrpc] is the
  /// protocol version string (e.g. `'2.0'`). [errorLogger] is optional.
  const JsonRpcService(
    this._dio, {
    required this.baseUrl,
    required this.jsonrpc,
    this.errorLogger,
  });

  final Dio _dio;

  /// Root URL prepended to every JSON-RPC request path.
  final String baseUrl;

  /// JSON-RPC protocol version string sent in every request body.
  final String jsonrpc;

  /// Optional logger invoked when request parsing or network errors occur.
  final ParseErrorLogger? errorLogger;

  /// Sends a JSON-RPC request and returns the typed response.
  ///
  /// [method] is the remote procedure name. [fromResultJson] deserializes the
  /// `result` field. Throws [JsonRpcErrorResponse] when the server returns an
  /// error object, and [StateError] when the `result` field is absent.
  Future<JsonRpcResponse<RESULT>> request<RESULT extends JsonRpcResult>({
    String? path,
    String? jsonrpc,
    required String method,
    Map<String, dynamic>? params,
    String? id,
    String? mockId,
    required RESULT Function(Map<String, dynamic> json) fromResultJson,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
  }) async {
    queryParameters?.removeWhere((k, v) => v == null);
    final Map<String, Object?> body = {
      'jsonrpc': jsonrpc ?? this.jsonrpc,
      'mock': mockId,
      'method': method,
      'params': params,
      'id': id ?? _randomRequestId(),
    };
    body.removeWhere((k, v) => v == null);
    final options = _setStreamType<JsonRpcResponse<RESULT>>(
      Options(
            method: 'POST',
            headers: headers,
            extra: extra,
          )
          .compose(
            _dio.options,
            path ?? '',
            queryParameters: queryParameters,
            data: body,
          )
          .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ),
          ),
    );
    final fetchResult = await _dio.fetch<Map<String, dynamic>>(
      options,
    );
    late JsonRpcResponse<RESULT> value;
    final Map<String, dynamic> data = fetchResult.data!;
    try {
      // Check for error response first
      final error = data['error'];
      if (error != null) {
        throw JsonRpcErrorResponse(
          jsonrpc: data['jsonrpc'] as String,
          id: data['id'] as int,
          errors: (error is List)
              ? error
                    .map(
                      (e) => JsonRpcError.fromJson(e as Map<String, dynamic>),
                    )
                    .toList()
              : [JsonRpcError.fromJson(error as Map<String, dynamic>)],
        );
      }

      final result = data['result'];
      if (result == null) {
        throw StateError(
          'JSON-RPC response has no "result" — '
          'use notify() for fire-and-forget calls',
        );
      }

      value = JsonRpcResponse(
        jsonrpc: data['jsonrpc'] as String,
        id: data['id'] as int,
        result: switch (result) {
          final Map<String, dynamic> map => fromResultJson(map),
          _ => throw StateError('Invalid result type'),
        },
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, options);
      rethrow;
    }
    return value;
  }

  /// Sends a fire-and-forget JSON-RPC notification synchronously.
  ///
  /// Delegates to [notify]. Returns a [FutureOr] so callers may choose to
  /// await it or discard the future.
  FutureOr<void> notifySync({
    String? path,
    String? jsonrpc,
    required String method,
    String? mockId,
    Map<String, dynamic>? params,
  }) async => await notify(
    path: path,
    jsonrpc: jsonrpc,
    method: method,
    mockId: mockId,
    params: params,
  );

  /// Sends a fire-and-forget JSON-RPC notification with no expected result.
  ///
  /// [method] is the remote procedure name. [params] are optional named
  /// parameters. The server response body is ignored.
  Future<void> notify({
    String? path,
    String? jsonrpc,
    required String method,
    String? mockId,
    Map<String, dynamic>? params,
  }) async {
    final extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final headers = <String, dynamic>{};
    final Map<String, Object?> data = {
      'jsonrpc': jsonrpc ?? this.jsonrpc,
      'mock': mockId,
      'method': method,
      'params': params,
    };
    data.removeWhere((k, v) => v == null);
    final options = _setStreamType<void>(
      Options(
            method: 'POST',
            headers: headers,
            extra: extra,
          )
          .compose(
            _dio.options,
            path ?? '',
            queryParameters: queryParameters,
            data: data,
          )
          .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ),
          ),
    );
    await _dio.fetch<Map<String, dynamic>>(options);
  }

  /// Sends multiple JSON-RPC calls in a single HTTP request.
  ///
  /// [path] is the batch endpoint path. [bodyList] contains each individual
  /// call body including its `fromResultJson` deserializer. Returns a
  /// [List<BatchJsonRpcItem>] with a success or failure item per request.
  Future<List<BatchJsonRpcItem<dynamic>>> batch(
    String path, {
    required List<BatchJsonRpcBody<dynamic>> bodyList,
  }) async {
    final extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = bodyList.map((e) => e.toJson()).toList();
    final options = _setStreamType<List<BatchJsonRpcItem<dynamic>>>(
      Options(
            method: 'POST',
            headers: headers,
            extra: extra,
          )
          .compose(
            _dio.options,
            path,
            queryParameters: queryParameters,
            data: data,
          )
          .copyWith(
            baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ),
          ),
    );
    final result = await _dio.fetch<List<dynamic>>(options);
    late List<BatchJsonRpcItem<dynamic>> value;
    try {
      result.data!.removeWhere((m) => m['id'] == null);
      value = result.data!.map(
        (dynamic i) {
          final iMap = i as Map<String, dynamic>;
          final id = iMap['id'];
          final result = iMap['result'];
          final error = iMap['error'];
          final jsonrpc = iMap['jsonrpc'] as String;
          final intId = id as int;

          if (error != null) {
            return BatchJsonRpcFailure(
              JsonRpcErrorResponse(
                jsonrpc: jsonrpc,
                id: intId,
                errors: (error is List)
                    ? error
                          .map(
                            (e) => JsonRpcError.fromJson(
                              e as Map<String, dynamic>,
                            ),
                          )
                          .toList()
                    : [
                        JsonRpcError.fromJson(
                          error as Map<String, dynamic>,
                        ),
                      ],
              ),
            );
          }

          final Function(Map<String, dynamic>? json)? fromResultJson = bodyList
              .firstOrNullWhere(
                (b) => b.id == id,
              )
              ?.fromResultJson;

          return BatchJsonRpcSuccess(
            JsonRpcResponse(
              jsonrpc: jsonrpc,
              id: intId,
              result: switch (result) {
                final Map<String, dynamic> map =>
                  fromResultJson!(map) as JsonRpcResult,
                _ => throw StateError('Invalid result type'),
              },
            ),
          );
        },
      ).toList();
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, options);
      rethrow;
    }
    return value;
  }

  String _randomRequestId() {
    final random = Random();
    final randomNumber = random.nextInt(9999999) + 1;
    return randomNumber.toString();
  }

  RequestOptions _setStreamType<T>(
    RequestOptions requestOptions,
  ) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(
    String dioBaseUrl,
    String? baseUrl,
  ) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}
