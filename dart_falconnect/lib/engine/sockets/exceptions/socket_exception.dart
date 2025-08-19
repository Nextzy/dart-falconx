import 'package:dart_falconnect/lib.dart';
import 'package:dart_falmodel/dart_falmodel.dart';

class SocketException implements Exception {
  const SocketException({
    this.response,
    this.message,
    this.exception,
    this.stackTrace,
  });

  final String? message;
  final SocketResponse? response;
  final Exception? exception;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'SocketException{message: $message,\nresponse: $response,\nexception: $exception,\nstackTrace: $stackTrace}';
  }
}
