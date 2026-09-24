import 'dart:async';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/config/request_id_config.dart';
import 'package:dart_falconnect/engine/https/extensions/use_token_extensions.dart';
import 'package:dart_falconnect/engine/https/interceptors/auth_session.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/auth_extra.dart';
import 'package:dart_faltool/dart_faltool.dart' show uuid;
import 'package:dio/dio.dart';

const String _requestIdKey = 'dart_falconnect.requestId';
const String _providedKey = 'dart_falconnect.headers.provided';

/// The request ID on [RequestOptions].
extension FalconRequestIdExtensions on RequestOptions {
  /// The ID `RequestStampInterceptor` gave this request; null when it has
  /// none.
  String? get requestId => switch (extra[_requestIdKey]) {
    final String id => id,
    _ => null,
  };
}

/// Stamps the request ID, the provider's headers, and the access token on
/// every attempt, in that order.
///
/// `BaseHttpClient` places it first, so the log prints the stamped
/// headers, `CacheInterceptor` keys entries by the token, and the app's own
/// interceptors see every stamped header. It runs again on each retry
/// attempt and re-send, which then carry the current token and fresh
/// provider values while keeping the first attempt's ID.
///
/// A callback that throws fails the request with a `DioException` of type
/// `unknown` whose `error` is the thrown object.
class RequestStampInterceptor extends Interceptor {
  /// Creates a stamp. [dio] supplies the configured headers, which the
  /// provider's headers override.
  new({this.requestId, this.headerProvider, this.auth, required this.dio});

  /// Request ID settings; null stamps no ID.
  final RequestIdConfig? requestId;

  /// Headers computed per request; null stamps none.
  final HeaderProvider? headerProvider;

  /// The token session; null stamps no token.
  final AuthSession? auth;

  /// The client's Dio, whose `options.headers` are the configured headers.
  final Dio dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var step = 'RequestIdConfig.generate';
    try {
      _stampId(options);
      step = 'HttpClientConfig.headerProvider';
      await _stampProvided(options);
      step = 'AuthConfig.accessToken';
      await _stampToken(options);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
          message: '$step threw: $error',
        ),
        true,
      );
      return;
    }
    handler.next(options);
  }

  void _stampId(RequestOptions options) {
    final box = requestId;
    if (box == null) return;
    final id =
        options.requestId ??
        options.headers[box.headerName]?.toString() ??
        (box.generate ?? uuid.v7)();
    options
      ..extra = {...options.extra, _requestIdKey: id}
      ..headers[box.headerName] = id;
  }

  Future<void> _stampProvided(RequestOptions options) async {
    final provider = headerProvider;
    if (provider == null) return;
    final values = await provider(options);
    final earlier = switch (options.extra[_providedKey]) {
      final Set<String> keys => keys,
      _ => const <String>{},
    };
    final configured = dio.options.headers;
    final written = <String>{};
    for (final MapEntry(:key, :value) in values.entries) {
      final name = key.toLowerCase();
      final current = options.headers[key];
      final setByRequest =
          current != null &&
          current != configured[key] &&
          !earlier.contains(name);
      if (setByRequest) continue;
      options.headers[key] = value;
      written.add(name);
    }
    options.extra = {...options.extra, _providedKey: written};
  }

  Future<void> _stampToken(RequestOptions options) async {
    final session = auth;
    if (session == null || !options.useToken) return;
    await session.waitForRefresh();
    final token = await session.config.accessToken();
    final name = session.config.headerName;
    if (token == null) {
      options
        ..headers.remove(name)
        ..stampedToken = null;
      return;
    }
    final scheme = session.config.scheme;
    options
      ..headers[name] = scheme.isEmpty ? token : '$scheme $token'
      ..stampedToken = token;
  }
}
