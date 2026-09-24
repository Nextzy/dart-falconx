import 'dart:async';

import 'package:dart_falconnect/engine/https/config/auth_config.dart';
import 'package:dio/dio.dart';

/// State the two auth interceptors share: the running refresh, the token
/// whose refresh failed last, and the zone that marks code running inside
/// a refresh.
///
/// `BaseHttpClient` builds one session per `AuthConfig` and passes it to
/// `RequestStampInterceptor` and `TokenRefreshInterceptor`. A chain built
/// by hand passes one session to both.
class AuthSession {
  /// Creates a session for [config].
  new(this.config, {this.logPrint});

  /// The token callbacks and header settings.
  final AuthConfig config;

  /// Prints diagnostics; null prints nothing.
  final void Function(String message)? logPrint;

  /// Zone key that marks code running inside `config.refresh()`.
  final Object _zoneKey = Object();

  Future<bool>? _refreshing;
  String? _failedToken;

  /// Whether the caller runs inside this session's `config.refresh()`.
  bool get isInsideRefresh => Zone.current[_zoneKey] == true;

  /// Completes when no refresh is running, and at once inside a refresh.
  Future<void> waitForRefresh() async {
    final running = _refreshing;
    if (running == null || isInsideRefresh) return;
    await running;
  }

  /// Whether [token] is the token whose refresh failed last.
  bool isFailedToken(String token) => token == _failedToken;

  /// Refreshes once for every caller that arrives while a refresh runs.
  ///
  /// Returns true when the refresh succeeded. On failure, records
  /// [staleToken] as the last failed token and calls `onAuthFailed` with
  /// [error] once; callers that joined the refresh do not call it again.
  Future<bool> refreshFor(String staleToken, DioException error) {
    final running = _refreshing;
    if (running != null) return running;
    final refresh = _refresh(staleToken, error);
    _refreshing = refresh;
    unawaited(
      refresh.whenComplete(() {
        if (identical(_refreshing, refresh)) _refreshing = null;
      }),
    );
    return refresh;
  }

  /// Records [token] as the last failed token and calls `onAuthFailed`
  /// with [error], without awaiting it.
  void fail(String token, DioException error) {
    _failedToken = token;
    final onAuthFailed = config.onAuthFailed;
    if (onAuthFailed == null) return;
    unawaited(
      Future<void>.sync(() => onAuthFailed(error)).then<void>(
        (_) {},
        onError: (Object failure) => _log('onAuthFailed threw: $failure'),
      ),
    );
  }

  Future<bool> _refresh(String staleToken, DioException error) async {
    _log('Refreshing the access token');
    var refreshed = false;
    try {
      refreshed = await runZoned(config.refresh, zoneValues: {_zoneKey: true});
    } on Object catch (failure) {
      _log('Refresh threw: $failure');
    }
    if (refreshed) {
      _log('Refresh succeeded');
      return true;
    }
    _log('Refresh failed');
    fail(staleToken, error);
    return false;
  }

  void _log(String message) => logPrint?.call('[AuthSession] $message');
}
