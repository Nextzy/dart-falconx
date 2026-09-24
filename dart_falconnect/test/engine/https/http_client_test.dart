import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:test/test.dart';

import 'interceptors/_scripted_adapter.dart';

class _Client extends BaseHttpClient {
  new(HttpClientAdapter adapter)
    : super(
        dio: Dio()..httpClientAdapter = adapter,
        config: const HttpClientConfig(baseUrl: 'https://a.test'),
      );
}

class _Body extends BaseRequestBody {
  const new();

  @override
  List<Object?> get props => [];

  @override
  Map<String, Object?> toJson() => {'name': 'falcon'};
}

/// Records whether each request asked for a token.
class _TokenSpy extends Interceptor {
  final List<bool> useToken = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    useToken.add(options.useToken);
    handler.next(options);
  }
}

Reply _body(String json) =>
    (_) => ResponseBody.fromString(
      json,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _echo(Map<String, dynamic> json) => json;

Matcher _invalidFormat() => throwsA(
  isA<DioException>().having(
    (e) => e.error,
    'error',
    isA<CommonException>().having(
      (c) => c.type,
      'type',
      InputErrorType.invalidFormat,
    ),
  ),
);

void main() {
  group('request methods', () {
    test('each method sends its verb, path, query, and body', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(adapter);

      await client.get('/g', queryParameters: {'q': 1}, converter: _echo);
      await client.post('/p', data: const _Body(), converter: _echo);
      await client.postFormData(
        '/pf',
        data: FormData.fromMap({'a': 'b'}),
        converter: _echo,
      );
      await client.patch('/pa', data: const _Body(), converter: _echo);
      await client.put('/pu', data: const _Body(), converter: _echo);
      await client.putFormData(
        '/puf',
        data: FormData.fromMap({'a': 'b'}),
        converter: _echo,
      );
      await client.delete('/d', data: const _Body(), converter: _echo);

      expect(adapter.requests.map((r) => '${r.method} ${r.uri.path}'), [
        'GET /g',
        'POST /p',
        'POST /pf',
        'PATCH /pa',
        'PUT /pu',
        'PUT /puf',
        'DELETE /d',
      ]);
      expect(adapter.requests[0].uri.queryParameters, {'q': '1'});
      expect(adapter.requests[1].data, {'name': 'falcon'});
      expect(adapter.requests[2].data, isA<FormData>());
      expect(adapter.requests[6].data, {'name': 'falcon'});
    });

    test('every method accepts an async converter', () async {
      final client = _Client(ScriptedAdapter([reply(200)]));

      final response = await client.post<int>(
        '/p',
        converter: (json) async => json['status']! as int,
      );

      expect(response.data, 200);
    });

    test('a null query value is accepted', () async {
      final adapter = ScriptedAdapter([reply(200)]);
      final client = _Client(adapter);

      await client.get(
        '/g',
        queryParameters: {'a': 1, 'b': null},
        converter: _echo,
      );

      expect(adapter.requests.single.uri.path, '/g');
    });

    test('isUseToken reaches interceptors as useToken', () async {
      final spy = _TokenSpy();
      final client = _Client(ScriptedAdapter([reply(200)]))
        ..addInterceptors([spy]);

      await client.get('/a', converter: _echo);
      await client.get('/b', isUseToken: false, converter: _echo);
      await client.dio.get<dynamic>('/raw');

      expect(spy.useToken, [true, false, true]);
    });

    test('the caller options are not changed', () async {
      final client = _Client(ScriptedAdapter([reply(200)]));
      final options = Options(headers: {'X-A': '1'});

      await client.get(
        '/a',
        options: options,
        isUseToken: false,
        converter: _echo,
      );

      expect(options.method, isNull);
      expect(options.extra, isNull);
    });
  });

  group('mapJson', () {
    test('a JSON array body fails with invalidFormat', () {
      final client = _Client(ScriptedAdapter([_body('[1, 2]')]));

      expect(client.get('/a', converter: _echo), _invalidFormat());
    });

    test('an empty JSON body fails with invalidFormat', () {
      final client = _Client(ScriptedAdapter([_body('')]));

      expect(client.get('/a', converter: _echo), _invalidFormat());
    });

    test('a throwing converter fails with invalidFormat and keeps the '
        'original exception', () async {
      final client = _Client(ScriptedAdapter([reply(200)]));

      await expectLater(
        client.get<int>(
          '/a',
          converter: (json) => throw const FormatException('bad'),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => (e.error! as CommonException).originalException,
            'originalException',
            isA<FormatException>(),
          ),
        ),
      );
    });

    test('catchError sees a parse failure', () async {
      final client = _Client(ScriptedAdapter([_body('[1]')]));

      final response = await client.get<String>(
        '/a',
        converter: (json) => 'parsed',
        catchError: (e, st) => 'fallback',
      );

      expect(response.data, 'fallback');
    });

    test('a String body still arrives under result', () async {
      final client = _Client(
        ScriptedAdapter([(_) => ResponseBody.fromString('plain', 200)]),
      );

      final response = await client.get('/a', converter: _echo);

      expect(response.data, {'result': 'plain'});
    });
  });
}
