import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/web_adapter_config.freezed.dart';

/// Settings of the browser adapter that a `BaseHttpClient` builds; a
/// non-null box replaces the adapter on the web. dart:io platforms ignore
/// this box.
@freezed
abstract class WebAdapterConfig with _$WebAdapterConfig {
  /// Creates browser adapter settings.
  const factory({
    /// Whether cross-site requests send cookies and authorization headers.
    /// A request's `extra['withCredentials']` overrides it.
    @Default(false) bool withCredentials,
  }) = _WebAdapterConfig;
}
