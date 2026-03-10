import 'package:dart_falmodel/lib.dart';

class NetworkFailedDependencyException extends NetworkClientException {
  const NetworkFailedDependencyException({
    super.statusCode = 424,
    super.type = NetworkErrorType.failedDependency,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
