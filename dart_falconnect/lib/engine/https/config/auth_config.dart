import 'dart:async';

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/auth_config.freezed.dart';

/// Returns the current access token; null sends the request without one.
typedef AccessTokenCallback = FutureOr<String?> Function();

/// Refreshes the access token; returns true on success.
typedef RefreshCallback = Future<bool> Function();

/// Called when the app must sign in again.
typedef AuthFailedCallback = FutureOr<void> Function(DioException error);

/// Access token settings; a non-null box stamps the token and refreshes it
/// on a 401.
///
/// The app owns the token: [accessToken] reads it and [refresh] renews it.
/// After a refresh, the client reads the new token through [accessToken].
@freezed
abstract class AuthConfig with _$AuthConfig {
  /// Creates access token settings.
  const factory({
    /// Returns the current access token; null sends the request without
    /// one. An app that refreshes before expiry does it here.
    required AccessTokenCallback accessToken,

    /// Refreshes the token and returns true on success; false or a throw
    /// fails the refresh. A request sent from inside it never waits for
    /// the refresh and never refreshes.
    required RefreshCallback refresh,

    /// Called once per failed refresh, and when a re-sent request gets a
    /// 401 again. Not awaited; an error it throws goes to the diagnostics.
    AuthFailedCallback? onAuthFailed,

    /// Header that carries the token. A `BaseHttpClient` redacts it in both
    /// logs and keys the cache by it wherever it does so for `authorization`.
    @Default('Authorization') String headerName,

    /// Word placed before the token; an empty string sends the bare token.
    @Default('Bearer') String scheme,
  }) = _AuthConfig;
}
