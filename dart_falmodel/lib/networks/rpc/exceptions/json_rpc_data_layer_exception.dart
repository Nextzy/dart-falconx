import 'package:dart_falmodel/lib.dart';

class JsonRpcDataLayerException extends CommonException {
  const JsonRpcDataLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}

class JsonRpcDatabaseException extends JsonRpcDataLayerException {
  const JsonRpcDatabaseException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}

class JsonRpcExternalApiDataLayerException extends JsonRpcDataLayerException {
  const JsonRpcExternalApiDataLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}
