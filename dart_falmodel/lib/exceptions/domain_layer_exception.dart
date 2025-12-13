import 'package:dart_falmodel/lib.dart';

class DomainLayerException<T> extends CommonException<T> {
  const DomainLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
  });
}
