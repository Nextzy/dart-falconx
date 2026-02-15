import 'package:dart_falmodel/lib.dart';

class DataLayerException<T> extends CommonException<T> {
  const DataLayerException({
    required super.code,
    super.userMessage,
    super.developerMessage,
  });
}
