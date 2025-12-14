import 'package:dart_falmodel/lib.dart';

class NoInternetConnectException extends NetworkException {
  const NoInternetConnectException({
    super.statusCode = 0,
    super.type,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
