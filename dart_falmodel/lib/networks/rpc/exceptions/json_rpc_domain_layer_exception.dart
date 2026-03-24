import 'package:dart_falmodel/lib.dart';

class JsonRpcDomainLayerException extends CommonException {
  const JsonRpcDomainLayerException({
    super.category,
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });

  factory JsonRpcDomainLayerException.api({
    required Object type,
    String? userMessage,
    String? developerMessage,
    Object? originalException,
    StackTrace? stackTrace,
  }) {
    return JsonRpcDomainLayerException(
      category: JsonRpcErrorCategory.API_ERROR,
      type: type,
      userMessage: userMessage,
      developerMessage: developerMessage,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  factory JsonRpcDomainLayerException.externalApi({
    required Object type,
    String? userMessage,
    String? developerMessage,
    Object? originalException,
    StackTrace? stackTrace,
  }) {
    return JsonRpcDomainLayerException(
      category: JsonRpcErrorCategory.EXTERNAL_API_ERROR,
      type: type,
      userMessage: userMessage,
      developerMessage: developerMessage,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  factory JsonRpcDomainLayerException.invalidRequest({
    required Object type,
    String? userMessage,
    String? developerMessage,
    Object? originalException,
    StackTrace? stackTrace,
  }) {
    return JsonRpcDomainLayerException(
      category: JsonRpcErrorCategory.INVALID_REQUEST_ERROR,
      type: type,
      userMessage: userMessage,
      developerMessage: developerMessage,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }
}
