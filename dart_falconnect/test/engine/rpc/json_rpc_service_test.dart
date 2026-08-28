import 'dart:io';

import 'package:dart_falconnect/lib.dart';
import 'package:test/test.dart';

/// Minimal result model for the loopback round trips below.
class _EchoResult extends JsonRpcModelResult {
  _EchoResult(this.value);

  factory _EchoResult.fromJson(Map<String, dynamic> json) =>
      _EchoResult(json['value'] as String);

  final String value;

  @override
  Map<String, dynamic> toJson() => {'value': value};
}

void main() {
  late HttpServer server;
  late Object nextBody;
  late DefaultJsonRpcService service;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen((request) async {
        await request.drain<void>();
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(nextBody));
        await request.response.close();
      });
    service = DefaultJsonRpcService(
      Dio(),
      baseUrl: 'http://${server.address.address}:${server.port}',
      jsonrpc: '2.0',
    );
  });

  tearDown(() => server.close(force: true));

  Future<JsonRpcResponse<_EchoResult>> call() => service.request(
    path: '/rpc',
    method: 'echo',
    params: const {'value': 'x'},
    fromResultJson: _EchoResult.fromJson,
  );

  group('JsonRpcService.request error decoding', () {
    test('a result answer decodes through fromResultJson', () async {
      nextBody = {
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'value': 'ok'},
      };
      final response = await call();
      expect(response.result.value, 'ok');
    });

    test('a singular `error` object becomes a JsonRpcErrorResponse', () async {
      nextBody = {
        'jsonrpc': '2.0',
        'id': 1,
        'error': {
          'category': 'INVALID_REQUEST_ERROR',
          'code': 'BAD_REQUEST',
          'userMessage': 'bad',
        },
      };
      await expectLater(
        call(),
        throwsA(
          isA<JsonRpcErrorResponse>().having(
            (e) => e.errors.map((x) => x.code).toList(),
            'codes',
            ['BAD_REQUEST'],
          ),
        ),
      );
    });

    test(
      'a plural `errors` list becomes the same JsonRpcErrorResponse',
      () async {
        nextBody = {
          'jsonrpc': '2.0',
          'id': 1,
          'errors': [
            {
              'category': 'API_ERROR',
              'code': 'INVALID_STATE',
              'userMessage': 'settled',
              'developerMessage': 'generation already CANCELLED',
            },
            {'category': 'API_ERROR', 'code': 'RATE_LIMITED'},
          ],
        };
        await expectLater(
          call(),
          throwsA(
            isA<JsonRpcErrorResponse>()
                .having(
                  (e) => e.errors.map((x) => x.code).toList(),
                  'codes',
                  ['INVALID_STATE', 'RATE_LIMITED'],
                )
                .having(
                  (e) => e.errors.first.developerMessage,
                  'developerMessage',
                  'generation already CANCELLED',
                ),
          ),
        );
      },
    );

    test('a body with neither result nor error is a StateError', () async {
      nextBody = {'jsonrpc': '2.0', 'id': 1};
      await expectLater(call(), throwsA(isA<StateError>()));
    });
  });

  group('JsonRpcService.batch error decoding', () {
    test(
      'items answered with `error` or `errors` both become failures',
      () async {
        nextBody = [
          {
            'jsonrpc': '2.0',
            'id': 1,
            'result': {'value': 'one'},
          },
          {
            'jsonrpc': '2.0',
            'id': 2,
            'error': {'category': 'API_ERROR', 'code': 'SINGULAR'},
          },
          {
            'jsonrpc': '2.0',
            'id': 3,
            'errors': [
              {'category': 'API_ERROR', 'code': 'PLURAL_A'},
              {'category': 'API_ERROR', 'code': 'PLURAL_B'},
            ],
          },
        ];
        final items = await service.batch(
          '/rpc',
          bodyList: [
            for (final id in [1, 2, 3])
              BatchJsonRpcBody(
                id: id,
                method: 'echo',
                fromResultJson: (json) => _EchoResult.fromJson(json!),
              ),
          ],
        );
        expect(items, hasLength(3));
        expect(
          (items[0] as BatchJsonRpcSuccess).response.result,
          isA<_EchoResult>().having((r) => r.value, 'value', 'one'),
        );
        expect(
          (items[1] as BatchJsonRpcFailure).error.errors.single.code,
          'SINGULAR',
        );
        expect(
          (items[2] as BatchJsonRpcFailure).error.errors.map((e) => e.code),
          ['PLURAL_A', 'PLURAL_B'],
        );
      },
    );
  });
}
