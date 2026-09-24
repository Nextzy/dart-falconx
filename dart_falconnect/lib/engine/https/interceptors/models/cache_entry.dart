import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/cache_entry.freezed.dart';

/// Response cache entry.
///
/// Store and read the [timestamp] in the same clock zone: the age is
/// computed from `clock.now()` at read time, so mixing zones yields a
/// negative age (the entry never expires) or an inflated one.
@freezed
abstract class CacheEntry with _$CacheEntry {
  /// Creates a cache entry with the given [response], creation
  /// [timestamp], and cache [maxAge].
  const factory({
    /// The cached HTTP response.
    required Response<dynamic> response,

    /// The time at which this entry was stored.
    required DateTime timestamp,

    /// The maximum duration this entry remains valid.
    required Duration maxAge,
  }) = _CacheEntry;

  const new _();

  /// Returns `true` if the entry has exceeded its [maxAge].
  bool get isExpired => clock.now().difference(timestamp) > maxAge;
}
