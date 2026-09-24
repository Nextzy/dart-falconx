import 'package:dio/dio.dart';

const String _tokenKey = 'dart_falconnect.auth.token';
const String _resentKey = 'dart_falconnect.auth.resent';

/// The token a request carried. `toString` hides it, because the pretty
/// log prints `extra`.
final class _StampedToken {
  const new(this.value);

  final String value;

  @override
  String toString() => 'REDACTED';
}

/// Auth bookkeeping the stamp and the refresh interceptor keep in
/// `RequestOptions.extra`. Retry attempts and re-sends copy it.
extension AuthExtra on RequestOptions {
  /// The token `RequestStampInterceptor` stamped; null when it stamped none.
  String? get stampedToken => switch (extra[_tokenKey]) {
    final _StampedToken token => token.value,
    _ => null,
  };

  set stampedToken(String? token) => extra = token == null
      ? ({...extra}..remove(_tokenKey))
      : {...extra, _tokenKey: _StampedToken(token)};

  /// Whether `TokenRefreshInterceptor` sent this request again after a
  /// refresh.
  bool get isAuthResend => extra[_resentKey] == true;

  /// A copy of these options marked as a re-send, with a `FormData` body
  /// cloned so it can be sent again.
  RequestOptions authResend() {
    final body = data;
    return copyWith(
      data: body is FormData ? body.clone() : body,
      extra: {...extra, _resentKey: true},
    );
  }
}
