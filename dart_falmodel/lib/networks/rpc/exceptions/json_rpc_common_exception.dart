import 'package:dart_falmodel/lib.dart';

class JsonRpcCommonException extends CommonException {
  const JsonRpcCommonException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}
