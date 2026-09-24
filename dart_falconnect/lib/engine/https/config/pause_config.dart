import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/pause_config.freezed.dart';

/// Settings of the 429 and 503 `Retry-After` pause.
@freezed
abstract class PauseConfig with _$PauseConfig {
  /// Creates pause settings.
  const factory({
    /// Longest remaining pause a request waits out instead of failing.
    @Default(Duration(seconds: 10)) Duration maxPauseWait,

    /// Longest pause any response can start.
    @Default(Duration(minutes: 10)) Duration maxPause,

    /// Pause for a 429 without a readable `Retry-After`; null means none.
    @Default(Duration(seconds: 5)) Duration? defaultPause,
  }) = _PauseConfig;
}
