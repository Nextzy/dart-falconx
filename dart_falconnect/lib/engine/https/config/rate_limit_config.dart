import 'package:dart_falconnect/engine/https/config/pause_config.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/rate_limit_config.freezed.dart';

/// Rate limit settings: none, the `Retry-After` pause alone, or token
/// buckets with the pause built in. The two limiters never share a chain.
@freezed
sealed class RateLimitConfig with _$RateLimitConfig {
  /// No rate limit and no pause.
  const factory none() = NoRateLimitConfig;

  /// The `Retry-After` pause alone; builds `RetryAfterPauseInterceptor`.
  const factory pauseOnly({
    /// Pause settings.
    @Default(PauseConfig()) PauseConfig pause,

    /// Most requests held per paused host.
    @Default(50) int maxQueueSize,
  }) = PauseOnlyRateLimitConfig;

  /// Token buckets with the pause built in; builds
  /// `TokenBucketRateLimitInterceptor`.
  const factory tokenBucket({
    /// Tiers every request passes.
    @Default(<TokenBucketPolicy>[]) List<TokenBucketPolicy> global,

    /// Tiers of a host missing from `hosts`.
    @Default(<TokenBucketPolicy>[]) List<TokenBucketPolicy> perHost,

    /// Tiers keyed by bare lowercase host; an empty list opts the host out
    /// of `perHost`.
    @Default(<String, List<TokenBucketPolicy>>{})
    Map<String, List<TokenBucketPolicy>> hosts,

    /// Whether a request with no token, or to a briefly paused host, waits.
    @Default(true) bool queueRequests,

    /// Wait-queue capacity of each host tier, and of each host's pause.
    @Default(50) int maxQueueSize,

    /// Wait-queue capacity of each global tier.
    @Default(500) int maxGlobalQueueSize,

    /// Pause settings.
    @Default(PauseConfig()) PauseConfig pause,
  }) = TokenBucketRateLimitConfig;
}
