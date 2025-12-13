import 'package:dart_falmodel/lib.dart';

class DataLayerException<T> extends CommonException<T> {
  const DataLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
  });
}
