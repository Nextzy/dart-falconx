import 'package:dart_falconnect/lib.dart';

/// Abstract interface for type-safe HTTP operations.
///
/// Every method requires a `converter` function that transforms the decoded
/// JSON map into the target type `T`, ensuring all responses are strongly
/// typed. An optional `catchError` callback allows callers to supply a
/// fallback value instead of propagating a [DioException].
abstract class RequestApiService {
  /// Performs an HTTP GET request to [endPoint] and converts the response
  /// with [converter].
  ///
  /// - [queryParameters]: Optional URL query parameters.
  /// - [options]: Additional Dio request options.
  /// - [isUseToken]: Whether to attach the auth token (handled by
  ///   interceptors).
  /// - [converter]: Required function mapping the JSON response to [T].
  /// - [catchError]: Optional fallback invoked on [DioException].
  Future<Response<T>> get<T>(
    String endPoint, {
    Map<String, Object>? queryParameters,
    Options? options,
    bool isUseToken = true,
    required T Function(Map<String, dynamic> json) converter,
    T? Function(DioException exception, StackTrace? stackTrace)? catchError,
  });

  /// Performs an HTTP POST request to [endPoint] with an optional JSON [data]
  /// body and converts the response with [converter].
  ///
  /// - [data]: Optional request body implementing [BaseRequestBody].
  /// - [options]: Additional Dio request options.
  /// - [isUseToken]: Whether to attach the auth token.
  /// - [queryParameters]: Optional URL query parameters.
  /// - [converter]: Required function mapping the JSON response to [T].
  /// - [catchError]: Optional fallback invoked on [DioException].
  Future<Response<T>> post<T>(
    String endPoint, {
    BaseRequestBody? data,
    Options? options,
    bool isUseToken = true,
    Map<String, Object>? queryParameters,
    required T Function(Map<String, dynamic> json) converter,
    T? Function(DioException exception, StackTrace? stackTrace)? catchError,
  });

  /// Performs an HTTP POST request to [endPoint] with a multipart [data] body
  /// and converts the response with [converter].
  ///
  /// Use this variant when uploading files or sending form-encoded fields.
  ///
  /// - [data]: Multipart form data.
  /// - [options]: Additional Dio request options.
  /// - [isUseToken]: Whether to attach the auth token.
  /// - [converter]: Required function mapping the JSON response to [T].
  /// - [catchError]: Optional fallback invoked on [DioException].
  Future<Response<T>> postFormData<T>(
    String endPoint, {
    FormData? data,
    Options? options,
    bool isUseToken = true,
    required T Function(Map<String, dynamic> json) converter,
    T? Function(DioException exception, StackTrace? stackTrace)? catchError,
  });

  /// Performs an HTTP PATCH request to [endPoint] with an optional JSON [data]
  /// body and converts the response with [converter].
  ///
  /// - [data]: Optional partial-update request body.
  /// - [options]: Additional Dio request options.
  /// - [isUseToken]: Whether to attach the auth token.
  /// - [queryParameters]: Optional URL query parameters.
  /// - [converter]: Required function mapping the JSON response to [T].
  /// - [catchError]: Optional fallback invoked on [DioException].
  Future<Response<T>> patch<T>(
    String endPoint, {
    BaseRequestBody? data,
    Options? options,
    bool isUseToken = true,
    Map<String, Object>? queryParameters,
    required T Function(Map<String, dynamic> json) converter,
    T? Function(DioException exception, StackTrace? stackTrace)? catchError,
  });

  /// Performs an HTTP PUT request to [endPoint] with an optional JSON [data]
  /// body and converts the response with [converter].
  ///
  /// - [data]: Optional full-update request body.
  /// - [options]: Additional Dio request options.
  /// - [isUseToken]: Whether to attach the auth token.
  /// - [converter]: Required function mapping the JSON response to [T].
  /// - [catchError]: Optional fallback invoked on [DioException].
  Future<Response<T>> put<T>(
    String endPoint, {
    BaseRequestBody? data,
    Options? options,
    bool isUseToken = true,
    required T Function(Map<String, dynamic> json) converter,
    T? Function(DioException exception, StackTrace? stackTrace)? catchError,
  });

  /// Performs an HTTP PUT request to [endPoint] with a multipart [data] body
  /// and converts the response with [converter].
  ///
  /// Use this variant when replacing a resource that includes file uploads.
  ///
  /// - [data]: Multipart form data.
  /// - [options]: Additional Dio request options.
  /// - [isUseToken]: Whether to attach the auth token.
  /// - [converter]: Required function mapping the JSON response to [T].
  /// - [catchError]: Optional fallback invoked on [DioException].
  Future<Response<T>> putFormData<T>(
    String endPoint, {
    FormData? data,
    Options? options,
    bool isUseToken = true,
    required T Function(Map<String, dynamic> json) converter,
    T? Function(DioException exception, StackTrace? stackTrace)? catchError,
  });

  /// Performs an HTTP DELETE request to [endPoint] and converts the response
  /// with [converter].
  ///
  /// - [data]: Optional request body (some APIs require a body on DELETE).
  /// - [queryParameters]: Optional URL query parameters.
  /// - [options]: Additional Dio request options.
  /// - [isUseToken]: Whether to attach the auth token.
  /// - [converter]: Required function mapping the JSON response to [T].
  /// - [catchError]: Optional fallback invoked on [DioException].
  Future<Response<T>> delete<T>(
    String endPoint, {
    BaseRequestBody? data,
    Map<String, Object>? queryParameters,
    Options? options,
    bool isUseToken = true,
    required T Function(Map<String, dynamic> json) converter,
    T? Function(DioException exception, StackTrace? stackTrace)? catchError,
  });
}
