import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:test/test.dart';

void main() {
  group('runCatching', () {
    test('returns a success Result from execute unchanged', () async {
      final result = await runCatching(() async => Result.success(42));

      expect(result.isSuccess, isTrue);
      expect(result.value, 42);
    });

    test('returns a failure Result from execute unchanged', () async {
      const exception = CommonException(type: 'TEST');

      final result = await runCatching<int>(
        () async => Result.failure(exception),
      );

      expect(result.isFailure, isTrue);
      expect(result.exception, same(exception));
    });

    test('wraps a thrown CommonException as is', () async {
      const exception = CommonException(type: 'TEST');

      final result = await runCatching<int>(() async => throw exception);

      expect(result.isFailure, isTrue);
      expect(result.exception, same(exception));
    });

    test('converts any other throw through toException()', () async {
      final result = await runCatching<int>(
        () async => throw const FormatException('bad input'),
      );

      expect(result.isFailure, isTrue);
      expect(result.exception.type, InputErrorType.invalidFormat);
    });
  });
}
