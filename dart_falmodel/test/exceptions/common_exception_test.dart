import 'package:dart_falmodel/src/src.dart';
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
      const ex = CommonException(type: 'TEST', data: {'foo': 'bar'});
      final copy = ex.copyWith(userMessage: 'updated');
      expect(copy.data, {'foo': 'bar'});
    });

    test('copyWith replaces data when explicitly passed', () {
      const ex = CommonException(type: 'TEST', data: {'foo': 'bar'});
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

  group('CommonException.toJsonRpcError category', () {
    test('maps a JsonRpcApiErrorTypeEnum type to API_ERROR', () {
      const ex = CommonException(
        type: JsonRpcApiErrorTypeEnum.INTERNAL_SERVER_ERROR,
      );
      expect(ex.toJsonRpcError().category, JsonRpcErrorCategory.API_ERROR);
    });

    test(
      'maps a JsonRpcExternalApiErrorTypeEnum type to EXTERNAL_API_ERROR',
      () {
        const ex = CommonException(
          type: JsonRpcExternalApiErrorTypeEnum.BAD_REQUEST,
        );
        expect(
          ex.toJsonRpcError().category,
          JsonRpcErrorCategory.EXTERNAL_API_ERROR,
        );
      },
    );

    test(
      'maps a JsonRpcRequestErrorTypeEnum type to INVALID_REQUEST_ERROR',
      () {
        const ex = CommonException(
          type: JsonRpcRequestErrorTypeEnum.BAD_REQUEST,
        );
        expect(
          ex.toJsonRpcError().category,
          JsonRpcErrorCategory.INVALID_REQUEST_ERROR,
        );
      },
    );
  });
}
