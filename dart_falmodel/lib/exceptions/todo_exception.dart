import 'package:dart_falmodel/lib.dart';

class TodoException<T> extends CommonException<T> {
  const TodoException({
    required super.code,
    super.userMessage = 'Coming soon.',
    super.developerMessage = '[TODO] Not implement right now',
  });
}
