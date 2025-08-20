// Ignore because is not necessary
// ignore_for_file: omit_local_variable_types
// ignore_for_file: inference_failure_on_function_return_type
// ignore_for_file: cascade_invocations
// ignore_for_file:  avoid_dynamic_calls

import 'dart:math';

import 'package:dart_falconnect/lib.dart';

abstract class RpcService {
  const RpcService(
    this._dio, {
    required this.baseUrl,
    required this.jsonrpc,
    this.errorLogger,
  });

  final Dio _dio;
  final String baseUrl;
  final String jsonrpc;
  final ParseErrorLogger? errorLogger;

  Future<JsonRpcResponse<DATA, ERROR>> request<DATA, ERROR>(
    String path, {
    String? jsonrpc,
    required String method,
    Map<String, dynamic>? params,
    String? id,
    String? mockId,
    DATA Function(Map<String, dynamic> json)? fromResponseJson,
    ERROR Function(Map<String, dynamic> json)? fromErrorJson,
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
    final options = _setStreamType<JsonRpcResponse<DATA, ErrorResponse>>(
      Options(method: 'POST', headers: headers, extra: extra)
          .compose(
            _dio.options,
            path,
            queryParameters: queryParameters,
            data: body,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final fetchResult = await _dio.fetch<Map<String, dynamic>>(options);
    late JsonRpcResponse<DATA, ERROR> value;
    final Map<String, dynamic>? data = fetchResult.data;
    final result = data?['result'];
    final error = data?['error'];
    try {
      value = JsonRpcResponse(
        jsonrpc: data?['jsonrpc'] as String?,
        id: data?['id'] as String?,
        result: result is Map<String, dynamic>
            ? fromResponseJson!(result)
            : result != null
            ? fromResponseJson!({
                'result': result,
              })
            : null,
        error:
            (error != null
                    ? fromErrorJson != null
                          ? fromErrorJson(error as Map<String, dynamic>)
                          : error
                    : null)
                as ERROR?,
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, options);
      rethrow;
    }
    return value;
  }

  void notifySync(
    String path, {
    String? jsonrpc,
    required String method,
    String? mockId,
    Map<String, dynamic>? params,
  }) => notify(
    path,
    jsonrpc: jsonrpc,
    method: method,
    mockId: mockId,
    params: params,
  );

  Future<void> notify(
    String path, {
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
    final options = _setStreamType(
      Options(method: 'POST', headers: headers, extra: extra)
          .compose(
            _dio.options,
            path,
            queryParameters: queryParameters,
            data: data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    await _dio.fetch<Map<String, dynamic>>(options);
  }

  // TODO(username): Need research
  Future<List<JsonRpcResponse>> batch(
    String path, {
    required List<BatchJsonRpcBody> bodyList,
  }) async {
    final extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = bodyList.map((e) => e.toJson()).toList();
    final options = _setStreamType<List<JsonRpcResponse<dynamic, dynamic>>>(
      Options(method: 'POST', headers: headers, extra: extra)
          .compose(
            _dio.options,
            path,
            queryParameters: queryParameters,
            data: data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final result = await _dio.fetch<List<dynamic>>(options);
    late List<JsonRpcResponse<dynamic, dynamic>> value;
    try {
      result.data!.removeWhere((m) => m['id'] == null);
      value = result.data!.map(
        (dynamic i) {
          final iMap = i as Map<String, dynamic>;
          final id = iMap['id'];
          final result = iMap['result'];
          final error = iMap['error'];
          final Function(Map<String, dynamic>? json)? fromResponseJson =
              bodyList.firstOrNullWhere((b) => b.id == id)?.fromResponseJson;
          final Function(Map<String, dynamic>? json)? fromErrorJson = bodyList
              .firstOrNullWhere((b) => b.id == id)
              ?.fromErrorJson;

          return JsonRpcResponse(
            jsonrpc: iMap['jsonrpc'] as String?,
            id: id as String?,
            result: result is Map<String, dynamic>
                ? fromResponseJson!(result)
                : result != null
                ? fromResponseJson!({
                    'result': result,
                  })
                : null,
            error: error != null
                ? fromErrorJson != null
                      ? fromErrorJson(error as Map<String, dynamic>)
                      : error
                : null,
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
    final randomNumber = random.nextInt(999999) + 1;
    return randomNumber.toString();
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
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

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
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
