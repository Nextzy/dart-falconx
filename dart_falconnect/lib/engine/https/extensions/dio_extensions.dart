import 'package:dart_falconnect/lib.dart';

/// Extensions on [RequestOptions] for common authorization header operations.
extension DartFalconnectRequestOptionExtensions on RequestOptions {
  /// Sets the `Authorization` header to `Bearer [token]`.
  void setHeaderTokenBearer(String token) {
    headers[HttpHeader.AUTHORIZE] = 'Bearer $token';
  }

  /// Removes the `Authorization` header from this request.
  Future<void> removeHeaderToken() async {
    headers.remove(HttpHeader.AUTHORIZE);
  }
}
