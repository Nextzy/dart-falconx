import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart';
import 'package:dio/dio.dart';

/// Pauses requests to a host after it answers 429, or 503 with
/// `Retry-After`, without limiting the request rate.
///
/// `TokenBucketRateLimitInterceptor` already contains this pause. A chain
/// that uses it must not add `RetryAfterPauseInterceptor`: the two would
/// hold requests twice under two sets of limits.
///
/// A 429 pauses its host for its `Retry-After`, else for `defaultPause`;
/// a 503 pauses only for its `Retry-After`. Every pause is clamped to
/// `maxPause`. While a host is paused, a request waits when the remaining
/// pause is at most `maxPauseWait` and fewer than `maxQueueSize` requests
/// already wait; otherwise it fails with a local 429 that carries
/// `Retry-After` and goes through every error interceptor, so callers get
/// the same `NetworkLimitExceededException` as for a server 429.
///
/// Place it before `RetryInterceptor`, so a server 429 starts the pause
/// before the retry is sent, and before the network exception handler,
/// which stops the error chain.
class RetryAfterPauseInterceptor extends Interceptor {
  /// Creates a pause-only interceptor.
  new({
    required this.config,
    Duration maxPauseWait = const Duration(seconds: 10),
    Duration maxPause = const Duration(minutes: 10),
    Duration? defaultPause = const Duration(seconds: 5),
    int maxQueueSize = 50,
  }) : _pause = _buildPause(
         maxPauseWait: maxPauseWait,
         maxPause: maxPause,
         defaultPause: defaultPause,
         maxQueueSize: maxQueueSize,
       );

  /// Builds the pause core, reporting a negative queue size under its
  /// public name before the core's own check can.
  static RetryAfterPause _buildPause({
    required Duration maxPauseWait,
    required Duration maxPause,
    required Duration? defaultPause,
    required int maxQueueSize,
  }) {
    if (maxQueueSize < 0) {
      throw ArgumentError.value(
        maxQueueSize,
        'maxQueueSize',
        'must not be negative',
      );
    }
    return RetryAfterPause(
      maxPauseWait: maxPauseWait,
      maxPause: maxPause,
      defaultPause: defaultPause,
      maxHeld: maxQueueSize,
      holdRequests: true,
    );
  }

  /// Configuration; `enableLogging` gates diagnostic prints.
  final HttpClientConfig config;

  final RetryAfterPause _pause;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final host = options.uri.host;
    while (true) {
      final admission = _pause.admit(host);
      if (admission is PauseReject) {
        _log('Paused host $host rejected a request');
        handler.reject(
          localRateLimitRejection(options, retryAfter: admission.remaining),
          true,
        );
        return;
      }
      if (admission is PausePass) {
        handler.next(options);
        return;
      }
      try {
        await _pause.wait(host, options.cancelToken);
      } on Object catch (error) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: error,
            message: 'Request cancelled while its host was paused',
          ),
        );
        return;
      }
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _pause.observe(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      _pause.observe(response);
    }
    handler.next(err);
  }

  /// Fails held requests and forgets every pause. Afterwards requests pass
  /// without a pause. Calling it again has no effect.
  void dispose() => _pause.dispose();

  void _log(String message) {
    if (config.enableLogging) {
      // Intentional logging for pause diagnostics.
      // ignore: avoid_print
      print('[RetryAfterPauseInterceptor] $message');
    }
  }
}
