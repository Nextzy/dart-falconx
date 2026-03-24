import 'package:dart_falmodel/lib.dart';

class JsonRpcDataLayerException extends CommonException {
  const JsonRpcDataLayerException({
    super.category,
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });

  factory JsonRpcDataLayerException.database({
    required Object type,
    String? userMessage,
    String? developerMessage,
    Object? originalException,
    StackTrace? stackTrace,
  }) {
    return JsonRpcDataLayerException(
      category: JsonRpcErrorCategory.API_ERROR,
      type: type,
      userMessage: userMessage,
      developerMessage: developerMessage,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  factory JsonRpcDataLayerException.externalApi({
    required Object type,
    String? userMessage,
    String? developerMessage,
    Object? originalException,
    StackTrace? stackTrace,
  }) {
    return JsonRpcDataLayerException(
      category: JsonRpcErrorCategory.EXTERNAL_API_ERROR,
      type: type,
      userMessage: userMessage,
      developerMessage: developerMessage,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }
}
