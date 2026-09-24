import 'dart:async';

import 'package:dart_falconnect/engine/https/extensions/use_token_extensions.dart';
import 'package:dart_falconnect/engine/https/interceptors/auth_session.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/auth_extra.dart';
import 'package:dio/dio.dart';

/// Refreshes the access token on a 401 and sends the request again.
///
/// It acts only on a 401 to a request that carried a token stamped by
/// `RequestStampInterceptor` of the same [session], whose `useToken` is
/// true, that is not a re-send, not sent from inside the refresh, and whose
/// token did not already fail to refresh. Any other error passes on.
///
/// Many 401s at once share one refresh. A request whose token is already
/// older than the current one is sent again without a refresh. The re-send
/// passes the whole chain, taking a new concurrency slot and rate-limit
/// token; its response resolves the request, and its error rejects it
/// without the rest of this chain, which the re-send already passed.
///
/// `BaseHttpClient` places it after the rate limiter and before
/// `RetryInterceptor`, so a 401 attempt gives its slot back and reaches the
/// log like any failure, and never enters the retry loop.
class TokenRefreshInterceptor extends Interceptor {
  /// Creates a refresh interceptor. [dio] sends the re-sends.
  new({required this.session, required this.dio});

  /// The session shared with the stamp.
  final AuthSession session;

  /// The Dio that sends each re-send.
  final Dio dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final token = options.stampedToken;
    if (err.response?.statusCode != 401 ||
        !options.useToken ||
        token == null ||
        session.isInsideRefresh ||
        session.isFailedToken(token)) {
      handler.next(err);
      return;
    }
    if (options.isAuthResend) {
      session.fail(token, err);
      handler.next(err);
      return;
    }
    if (!await _hasNewerToken(token, err)) {
      handler.next(err);
      return;
    }
    if (options.data is Stream || (options.cancelToken?.isCancelled ?? false)) {
      handler.next(err);
      return;
    }
    final RequestOptions resend;
    try {
      resend = options.authResend();
    } on Object {
      // A FormData whose files cannot be read again.
      handler.next(err);
      return;
    }
    try {
      // dynamic keeps the caller's responseType; any other type argument
      // makes dio overwrite it.
      handler.resolve(await dio.fetch<dynamic>(resend));
    } on DioException catch (error) {
      handler.reject(error);
    }
  }

  /// Whether a token newer than [token] is ready: another request already
  /// refreshed, or this call's refresh succeeded.
  Future<bool> _hasNewerToken(String token, DioException err) async {
    final String? current;
    try {
      current = await session.config.accessToken();
    } on Object {
      return false;
    }
    // The app signed out while the request was in flight: pass the 401 on.
    if (current == null) return false;
    if (current != token) return true;
    return session.refreshFor(token, err);
  }
}
