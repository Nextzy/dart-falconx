import 'package:dart_falmodel/lib.dart';
import 'package:test/test.dart';

void main() {
  group('JsonRpcError.data', () {
    test('defaults to null when omitted', () {
      const err = JsonRpcError(
        category: JsonRpcErrorCategory.API_ERROR,
        code: 'TEST',
      );
      expect(err.data, isNull);
    });

    test('stores structured payload', () {
      const err = JsonRpcError(
        category: JsonRpcErrorCategory.API_ERROR,
        code: 'TEST',
        data: {
          'providers': ['GOOGLE', 'APPLE'],
        },
      );
      expect(err.data?['providers'], ['GOOGLE', 'APPLE']);
    });

    test('toJson omits data when null (includeIfNull=false)', () {
      const err = JsonRpcError(
        category: JsonRpcErrorCategory.API_ERROR,
        code: 'TEST',
      );
      expect(err.toJson().containsKey('data'), isFalse);
    });

    test('toJson includes data when non-null', () {
      const err = JsonRpcError(
        category: JsonRpcErrorCategory.API_ERROR,
        code: 'TEST',
        data: {'foo': 'bar'},
      );
      expect(err.toJson()['data'], {'foo': 'bar'});
    });

    test('fromJson round-trips data', () {
      final json = {
        'category': 'API_ERROR',
        'code': 'TEST',
        'userMessage': 'oops',
        'data': {
          'providers': ['GOOGLE'],
        },
      };
      final err = JsonRpcError.fromJson(json);
      expect(err.data, {
        'providers': ['GOOGLE'],
      });
    });

    test('invalidRequest factory forwards data', () {
      final err = JsonRpcError.invalidRequest(
        code: 'X',
        data: const {'k': 1},
      );
      expect(err.data, {'k': 1});
    });
  });
}
