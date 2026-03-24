import 'package:dart_falmodel/lib.dart';

class DomainLayerException extends CommonException {
  const DomainLayerException({
    super.category,
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}
