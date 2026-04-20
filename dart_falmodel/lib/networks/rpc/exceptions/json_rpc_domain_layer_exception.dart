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

class JsonRpcInternalApiDomainLayerException
    extends JsonRpcDomainLayerException {
  const JsonRpcInternalApiDomainLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}

class JsonRpcExternalApiDomainLayerException
    extends JsonRpcDomainLayerException {
  const JsonRpcExternalApiDomainLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}

class JsonRpcInvalidRequestDomainLayerException
    extends JsonRpcDomainLayerException {
  const JsonRpcInvalidRequestDomainLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}

class JsonRpcBadRequestDomainLayerException
    extends JsonRpcDomainLayerException {
  const JsonRpcBadRequestDomainLayerException({
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  }) : super(type: JsonRpcRequestErrorTypeEnum.BAD_REQUEST);
}
