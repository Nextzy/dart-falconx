import 'package:dart_falmodel/lib.dart';

class NetworkInsufficientStorageException extends NetworkServerException {
  const NetworkInsufficientStorageException({
    super.statusCode = 507,
    super.type = NetworkErrorType.insufficientStorage,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
