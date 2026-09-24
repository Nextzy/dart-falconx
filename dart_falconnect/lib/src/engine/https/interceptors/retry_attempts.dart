import 'package:dart_falconnect/engine/https/interceptors/retry_interceptor.dart';
import 'package:dio/dio.dart';

const String _finalKey = 'dart_falconnect.retry.final';

/// Marks [err] as the error `RetryInterceptor` passes on after its last
/// attempt, and returns it.
DioException finalRetryError(DioException err) {
  final options = err.requestOptions;
  options.extra = {...options.extra, _finalKey: true};
  return err;
}

/// Whether [options] belong to a retry attempt whose loop may still send
/// another: its error passes the rest of the chain inside the loop, before
/// `RetryInterceptor` decides.
bool isOpenRetryAttempt(RequestOptions options) =>
    options.retryAttempt > 0 && options.extra[_finalKey] != true;
