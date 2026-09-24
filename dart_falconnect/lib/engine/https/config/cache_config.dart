import 'package:dio_cache_interceptor/dio_cache_interceptor.dart'
    show CachePolicy, CacheStore;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/cache_config.freezed.dart';

/// Response cache settings; a non-null box adds `CacheInterceptor`.
@freezed
abstract class CacheConfig with _$CacheConfig {
  /// Creates cache settings. By default the cache follows the server's
  /// cache headers and keeps entries in memory.
  const factory({
    /// Default policy; [CachePolicy.request] follows the server's cache
    /// headers and stores nothing a response does not mark cacheable.
    @Default(CachePolicy.request) CachePolicy policy,

    /// Drops an entry this long after it was stored, whatever its headers
    /// say; null keeps an entry as long as its headers allow.
    Duration? maxStale,

    /// Byte budget of the default memory store, evicted least recently
    /// used; must be positive. A single response over 512,000 bytes, or
    /// over a fifth of this budget, is not stored.
    @Default(50 * 1024 * 1024) int maxSize,

    /// Where entries live; null builds a `MemCacheStore` of [maxSize]
    /// bytes. The client never closes a store passed here.
    CacheStore? store,

    /// Request headers that split one URL into separate entries, compared
    /// ignoring case. On a server that serves many users, keep
    /// `authorization` here, or one user reads another's cached responses.
    @Default({'authorization', 'accept', 'accept-language'})
    Set<String> keyHeaders,
  }) = _CacheConfig;
}
