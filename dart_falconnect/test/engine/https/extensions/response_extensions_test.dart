import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:test/test.dart';

final _options = RequestOptions(
  path: '/rpc',
  data: const {'jsonrpc': '2.0', 'method': 'm', 'id': 7},
);

DioException _withResponse() => DioException(
  requestOptions: _options,
  response: Response<dynamic>(requestOptions: _options, statusCode: 500),
  type: DioExceptionType.badResponse,
);

DioException _withoutResponse() => DioException(
  requestOptions: _options,
  type: DioExceptionType.connectionError,
);

class _Result extends JsonRpcResult {
  const new(this.value);

  final String value;
}

void main() {
  group('catchWhenError on Future<Response<T>>', () {
    test('rethrows when no fallback is given', () {
      final future = Future<Response<String>>.error(_withResponse());

      expect(future.catchWhenError(null), throwsA(isA<DioException>()));
    });

    test('rethrows when the fallback returns null', () {
      final future = Future<Response<String>>.error(_withResponse());

      expect(
        future.catchWhenError((e, st) => null),
        throwsA(isA<DioException>()),
      );
    });

    test('rethrows an error that is not a DioException', () {
      final future = Future<Response<String>>.error(StateError('x'));

      expect(
        future.catchWhenError((e, st) => 'fallback'),
        throwsA(isA<StateError>()),
      );
    });

    test('resolves with the error response carrying the fallback', () async {
      final future = Future<Response<String>>.error(_withResponse());

      final response = await future.catchWhenError((e, st) => 'fallback');

      expect(response.data, 'fallback');
      expect(response.statusCode, 500);
    });

    test('resolves without a response, as after a lost connection', () async {
      final future = Future<Response<String>>.error(_withoutResponse());

      final response = await future.catchWhenError((e, st) => 'offline');

      expect(response.data, 'offline');
      expect(response.requestOptions, same(_options));
    });
  });

  group('catchWhenError on Future<JsonRpcResponse<RESULT>>', () {
    test('resolves with a JsonRpcResponse carrying the request id', () async {
      final future = Future<JsonRpcResponse<_Result>>.error(_withoutResponse());

      final response = await future.catchWhenError(
        (e, st) => const _Result('fallback'),
      );

      expect(response.result.value, 'fallback');
      expect(response.id, 7);
    });

    test('rethrows when the fallback returns null', () {
      final future = Future<JsonRpcResponse<_Result>>.error(_withResponse());

      expect(
        future.catchWhenError((e, st) => null),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('catchWhenError on Future<HttpResponse<T>>', () {
    test('resolves with an HttpResponse carrying the fallback', () async {
      final future = Future<HttpResponse<String>>.error(_withoutResponse());

      final response = await future.catchWhenError((e, st) => 'offline');

      expect(response.data, 'offline');
      expect(response.response.data, 'offline');
    });
  });

  group('mapJson', () {
    Future<Response<dynamic>> body(Object? data) =>
        Future.value(Response<dynamic>(requestOptions: _options, data: data));

    Matcher invalidFormat() => throwsA(
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

    test('passes a JSON object to the converter', () async {
      final response = await body({'a': 1}).mapJson((json) => json['a']);

      expect(response.data, 1);
    });

    test('wraps a String body under result', () async {
      final response = await body('plain').mapJson((json) => json['result']);

      expect(response.data, 'plain');
    });

    test('fails with invalidFormat on a JSON array', () {
      expect(body([1, 2]).mapJson((json) => json), invalidFormat());
    });

    test('fails with invalidFormat on an empty body', () {
      expect(body(null).mapJson((json) => json), invalidFormat());
    });

    test('fails with invalidFormat when the converter throws', () {
      expect(
        body({'a': 1})
            .mapJson<int>((json) => throw const FormatException('bad')),
        invalidFormat(),
      );
    });

    test('a converter that returns null yields null data', () async {
      final response = await body({'a': 1}).mapJson<int?>((json) => null);

      expect(response.data, isNull);
    });
  });

  test('a fallback that throws surfaces its own error', () {
    final future = Future<Response<String>>.error(_withResponse());

    expect(
      future.catchWhenError((e, st) => throw StateError('fallback failed')),
      throwsA(isA<StateError>()),
    );
  });

  group('null Response', () {
    test('transformData throws a StateError', () {
      const Response<dynamic>? response = null;

      expect(() => response.transformData<String>(data: 'x'), throwsStateError);
    });

    test('copyWith throws a StateError', () {
      const Response<dynamic>? response = null;

      expect(() => response.copyWith<String>(data: 'x'), throwsStateError);
    });
  });
}
