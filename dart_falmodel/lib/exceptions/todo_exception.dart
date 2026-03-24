import 'package:dart_falmodel/lib.dart';

class TodoException<T> extends CommonException {
  const TodoException({
    required super.type,
    super.userMessage = 'Coming soon.',
    super.developerMessage = '[TODO] Not implement right now',
    super.originalException,
    super.stackTrace,
  });
}
