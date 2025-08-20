import 'package:dart_falconnect/lib.dart';

extension DartFalconnectRequestOptionExtensions on RequestOptions {
  void setHeaderTokenBearer(String token) {
    headers[HttpHeader.AUTHORIZE] = 'Bearer $token';
  }

  void removeHeaderToken() async {
    headers.remove(HttpHeader.AUTHORIZE);
  }
}
