import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/retry_config.freezed.dart';

/// Called before each retry waits.
///
/// [attempt] is 1 for the first retry. The stack trace of the failure is
/// `error.stackTrace`.
typedef RetryCallback = void Function(
  DioException error,
  int attempt,
  Duration delay,
);

/// Retry settings; a non-null box adds `RetryInterceptor`.
@freezed
abstract class RetryConfig with _$RetryConfig {
  /// Creates retry settings.
  const factory({
    /// Most retries of one request.
    @Default(3) int maxAttempts,

    /// Base delay of the exponential backoff.
    @Default(Duration(seconds: 1)) Duration delay,

    /// Longest wait before one retry, and the cap on `Retry-After`.
    @Default(Duration(seconds: 30)) Duration maxDelay,

    /// Most time spent retrying one request, from its first failure.
    @Default(Duration(seconds: 60)) Duration maxDuration,

    /// Called before each retry waits.
    RetryCallback? onRetry,
  }) = _RetryConfig;
}
