import 'package:dart_falmodel/lib.dart';

class DomainLayerException<T> extends CommonException<T> {
  const DomainLayerException({
    required super.code,
    super.userMessage,
    super.developerMessage,
  });
}
