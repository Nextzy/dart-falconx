import 'package:dart_falmodel/lib.dart';

class UnauthorizedException extends NetworkClientException {
  const UnauthorizedException({
    super.statusCode = 401,
    super.type,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
