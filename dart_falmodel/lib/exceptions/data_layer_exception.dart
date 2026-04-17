import 'package:dart_falmodel/lib.dart';

class DataLayerException extends CommonException {
  const DataLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}
