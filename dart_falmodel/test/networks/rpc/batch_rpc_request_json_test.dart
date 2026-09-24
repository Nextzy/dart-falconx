import 'package:dart_falmodel/lib.dart';
import 'package:test/test.dart';

void main() {
  group('BatchJsonRpcBody.toJson characterization', () {
    test('emits method and params only, no envelope keys', () {
      const body = BatchJsonRpcBody<int>(
        id: 1,
        method: 'wallet.balance',
        params: {'address': '0x1'},
        fromResultJson: null,
      );

      expect(body.toJson(), {
        'method': 'wallet.balance',
        'params': {'address': '0x1'},
      });
      expect(body.toJson().containsKey('jsonrpc'), isFalse);
      expect(body.toJson().containsKey('id'), isFalse);
    });

    test('null method and null params are omitted entirely', () {
      const body = BatchJsonRpcBody<int>(method: null, params: null);

      expect(body.toJson(), isEmpty);
    });

    test('null method with non-null params keeps params', () {
      const body = BatchJsonRpcBody<int>(method: null, params: {'k': 1});

      expect(body.toJson(), {
        'params': {'k': 1},
      });
    });

    test('empty params map is kept (not null)', () {
      const body = BatchJsonRpcBody<int>(method: 'ping', params: {});

      expect(body.toJson(), {'method': 'ping', 'params': {}});
    });

    test('fromResultJson never appears in the output', () {
      final body = BatchJsonRpcBody<Map<String, dynamic>>(
        method: 'm',
        fromResultJson: _identity,
      );

      expect(body.toJson().containsKey('fromResultJson'), isFalse);
    });
  });
}

Map<String, dynamic> _identity(Map<String, dynamic>? json) => json ?? {};
