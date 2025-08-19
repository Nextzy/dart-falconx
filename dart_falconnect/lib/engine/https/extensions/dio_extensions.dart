import 'package:dart_falconnect/lib.dart';

extension dart_falconnectRequestOptionExtensions on RequestOptions {
  void setHeaderTokenBearer(String token) {
    headers[HttpHeader.AUTHORIZE] = 'Bearer $token';
  }

  void removeHeaderToken() async {
    headers.remove(HttpHeader.AUTHORIZE);
  }
}
