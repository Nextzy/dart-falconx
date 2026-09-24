import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/cache_config.freezed.dart';

/// Response cache settings; a non-null box adds `CacheInterceptor`.
@freezed
abstract class CacheConfig with _$CacheConfig {
  /// Creates cache settings.
  const factory({
    /// How long a response stays valid when its headers set no lifetime.
    @Default(Duration(minutes: 15)) Duration duration,

    /// Largest total cache size in bytes.
    @Default(50 * 1024 * 1024) int maxSize,
  }) = _CacheConfig;
}
