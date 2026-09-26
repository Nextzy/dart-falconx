import 'package:dart_falconnect/src/src.dart';

/// Converts a decoded JSON object into `T`.
typedef JsonResponseConverter<T> = FutureOr<T> Function(
  Map<String, dynamic> json,
);

/// Returns a fallback value for a failed request, or null to rethrow.
typedef RequestErrorCallback<T> = T? Function(
  DioException exception,
  StackTrace? stackTrace,
);

/// Abstract interface for type-safe HTTP operations.
///
/// Every method requires a `converter` that turns the decoded JSON object
/// into `T`. A body that is not a JSON object, or a converter that throws,
/// fails with a [DioException] holding a `CommonException` of
/// `InputErrorType.invalidFormat`. An optional `catchError` returns a
/// fallback value; returning null rethrows the error.
abstract class RequestApiService {
  /// Sends a `GET` request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `POST` request with a JSON body.
  Future<Response<T>> post<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `POST` request with a multipart body.
  Future<Response<T>> postFormData<T>(
    String path, {
    FormData? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `PATCH` request with a JSON body.
  Future<Response<T>> patch<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `PUT` request with a JSON body.
  Future<Response<T>> put<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `PUT` request with a multipart body.
  Future<Response<T>> putFormData<T>(
    String path, {
    FormData? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });

  /// Sends a `DELETE` request with an optional JSON body.
  Future<Response<T>> delete<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  });
}
