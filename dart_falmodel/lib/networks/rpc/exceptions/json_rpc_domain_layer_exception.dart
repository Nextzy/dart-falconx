import 'package:dart_falmodel/lib.dart';

class JsonRpcDomainLayerException extends CommonException {
  const JsonRpcDomainLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}

class JsonRpcDomainLayerInternalApiException
    extends JsonRpcDomainLayerException {
  const JsonRpcDomainLayerInternalApiException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}

class JsonRpcDomainLayerExternalApiException
    extends JsonRpcDomainLayerException {
  const JsonRpcDomainLayerExternalApiException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}

class JsonRpcDomainLayerInvalidRequestException
    extends JsonRpcDomainLayerException {
  const JsonRpcDomainLayerInvalidRequestException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}
