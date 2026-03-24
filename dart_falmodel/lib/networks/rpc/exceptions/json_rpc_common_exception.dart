import 'package:dart_falmodel/lib.dart';

class JsonRpcCommonException extends CommonException {
  const JsonRpcCommonException({
    super.category,
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}
