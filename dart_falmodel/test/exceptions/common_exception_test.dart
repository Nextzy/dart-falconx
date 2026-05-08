import 'package:dart_falmodel/lib.dart';
import 'package:test/test.dart';

void main() {
  group('CommonException.data', () {
    test('defaults to null when omitted', () {
      const ex = CommonException(type: 'TEST');
      expect(ex.data, isNull);
    });

    test('stores Map<String, dynamic> payload verbatim', () {
      const payload = {
        'providers': ['GOOGLE', 'APPLE'],
        'count': 2,
      };
      const ex = CommonException(type: 'TEST', data: payload);
      expect(ex.data, payload);
    });

    test('copyWith preserves existing data when not overridden', () {
      const ex = CommonException(
        type: 'TEST',
        data: {'foo': 'bar'},
      );
      final copy = ex.copyWith(userMessage: 'updated');
      expect(copy.data, {'foo': 'bar'});
    });

    test('copyWith replaces data when explicitly passed', () {
      const ex = CommonException(
        type: 'TEST',
        data: {'foo': 'bar'},
      );
      final copy = ex.copyWith(data: const {'baz': 1});
      expect(copy.data, {'baz': 1});
    });

    test('toString appends Data line when non-null', () {
      const ex = CommonException(type: 'TEST', data: {'k': 'v'});
      expect(ex.toString(), contains('Data: {k: v}'));
    });

    test('toString omits Data line when null', () {
      const ex = CommonException(type: 'TEST');
      expect(ex.toString(), isNot(contains('Data:')));
    });

    test('toJsonRpcError forwards data', () {
      const ex = JsonRpcDomainLayerException(
        type: JsonRpcRequestErrorTypeEnum.BAD_REQUEST,
        data: {
          'providers': ['GOOGLE'],
        },
      );
      final err = ex.toJsonRpcError();
      expect(err.data, {
        'providers': ['GOOGLE'],
      });
    });
  });
}
