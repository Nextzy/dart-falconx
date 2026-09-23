import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart'
    show localRateLimitKey;
import 'package:dio/dio.dart';

/// Tells a 429 produced on the client apart from one the server sent.
extension FalconLocalRateLimitResponseExtensions on Response<dynamic> {
  /// Whether this response is a 429 built by a rate-limit interceptor, with
  /// no request sent to the server.
  bool get isLocalRateLimit => extra[localRateLimitKey] == true;
}
