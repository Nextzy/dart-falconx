import 'dart:async';
import 'dart:convert';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

/// Rejects every request before the log sees it, as a custom-slot
/// interceptor placed first in the chain would.
class _RejectFirst extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'refused',
      ),
      true,
    );
  }
}

/// Has no JSON form, so a body holding it falls back to `toString()`.
class _Opaque {
  @override
  String toString() => 'opaque-value';
}

/// Throws from `toString()`, so no log can turn it into text.
class _Unprintable {
  @override
  String toString() => throw StateError('unprintable');
}

/// A JSON log printing into [lines].
HttpJsonLogInterceptor _log(
  List<Object?> lines, {
  bool requestHeaders = false,
  bool responseHeaders = false,
  bool requestBody = false,
  bool responseBody = false,
  int maxBodyBytes = 4096,
}) => HttpJsonLogInterceptor(
  config: JsonLogConfig(
    requestHeaders: requestHeaders,
    responseHeaders: responseHeaders,
    requestBody: requestBody,
    responseBody: responseBody,
    maxBodyBytes: maxBodyBytes,
    logPrint: lines.add,
  ),
);

Dio _dio(
  HttpClientAdapter adapter,
  List<Interceptor> Function(Dio) chain, {
  String baseUrl = 'https://a.test',
}) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl))
    ..httpClientAdapter = adapter
    ..transformer = FoldingTransformer();
  dio.interceptors.addAll(chain(dio));
  return dio;
}

/// Sends one request, runs it to the end, and returns the decoded lines.
List<Map<String, Object?>> _run(
  List<Reply> script,
  HttpJsonLogInterceptor Function(List<Object?> lines) log, {
  String path = '/x',
  Options? options,
  Object? data,
  String method = 'GET',
}) {
  final lines = <Object?>[];
  fakeAsync((async) {
    final dio = _dio(ScriptedAdapter(script), (_) => [log(lines)]);
    dio
        .request<dynamic>(
          path,
          data: data,
          options: (options ?? Options()).copyWith(method: method),
        )
        .ignore();
    async.elapse(Duration.zero);
  });
  return _decode(lines);
}

List<Map<String, Object?>> _decode(List<Object?> lines) => [
  for (final line in lines) jsonDecode(line! as String) as Map<String, Object?>,
];

void main() {
  group('the line', () {
    test('prints one JSON line per attempt with the core fields in order', () {
      final lines = <Object?>[];
      _run([reply(200)], (_) => _log(lines));

      expect(lines, hasLength(1));
      expect(lines.single, isNot(contains('\n')));
      final line = _decode(lines).single;
      expect(line.keys, [
        'timestamp',
        'severity_text',
        'body',
        'http.request.method',
        'url.full',
        'server.address',
        'server.port',
        'http.response.status_code',
        'http.client.request.duration',
      ]);
      expect(line['http.request.method'], 'GET');
      expect(line['url.full'], 'https://a.test/x');
      expect(line['server.address'], 'a.test');
      expect(line['server.port'], 443);
      expect(line['http.response.status_code'], 200);
      expect(line['body'], 'GET https://a.test/x 200 0.000s');
      expect(DateTime.parse(line['timestamp']! as String).isUtc, isTrue);
    });

    test('upper-cases the method', () {
      final line = _run([reply(200)], _log, method: 'post').single;

      expect(line['http.request.method'], 'POST');
    });

    test('a request retried twice prints three lines with their resend '
        'count', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        final dio = _dio(
          ScriptedAdapter([reply(500), reply(500), reply(200)]),
          (dio) => [
            _log(lines),
            RetryInterceptor(
              config: const RetryConfig(
                maxAttempts: 2,
                delay: Duration(milliseconds: 1),
                maxDelay: Duration(milliseconds: 1),
              ),
              dio: dio,
            ),
          ],
        );
        dio.get<dynamic>('/x').ignore();
        async.elapse(const Duration(seconds: 1));
      });

      final decoded = _decode(lines);
      expect(decoded.map((l) => l['http.response.status_code']), [
        500,
        500,
        200,
      ]);
      expect(decoded.map((l) => l['http.request.resend_count']), [null, 1, 2]);
      expect(decoded.first.containsKey('http.request.resend_count'), isFalse);
    });

    test('the duration is the time the attempt took', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        final adapter = GatedAdapter();
        _dio(adapter, (_) => [_log(lines)]).get<dynamic>('/x').ignore();
        async.elapse(const Duration(milliseconds: 250));
        adapter.requests.single.respond(200);
        async.elapse(Duration.zero);
      });

      final line = _decode(lines).single;
      expect(line['http.client.request.duration'], 0.25);
      expect(line['body'], 'GET https://a.test/x 200 0.250s');
    });

    test('an error raised before the log saw the request still prints one '
        'line with a zero duration', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        _dio(
          ScriptedAdapter([reply(200)]),
          (_) => [_RejectFirst(), _log(lines)],
        ).get<dynamic>('/x').ignore();
        async.elapse(Duration.zero);
      });

      final line = _decode(lines).single;
      expect(line['http.client.request.duration'], 0.0);
      expect(line['error.type'], 'unknown');
    });

    test('a printer that throws never fails the request', () async {
      final dio = _dio(
        ScriptedAdapter([reply(200)]),
        (_) => [
          HttpJsonLogInterceptor(
            config: JsonLogConfig(logPrint: (_) => throw StateError('sink')),
          ),
        ],
      );

      final response = await dio.get<dynamic>('/x');

      expect(response.statusCode, 200);
    });

    test('a value that cannot become text prints a minimal line and never '
        'fails the request', () {
      final lines = <Object?>[];
      final outcomes = <Object>[];
      fakeAsync((async) {
        _dio(
              ScriptedAdapter([reply(200)]),
              (_) => [_log(lines, requestHeaders: true)],
            )
            .get<dynamic>(
              '/x',
              options: Options(headers: {'x-bad': _Unprintable()}),
            )
            .then(outcomes.add, onError: outcomes.add)
            .ignore();
        async.elapse(Duration.zero);
      });

      expect(outcomes.single, isA<Response<dynamic>>());
      final line = _decode(lines).single;
      expect(line.keys, ['timestamp', 'severity_text', 'body']);
      expect(line['severity_text'], 'WARN');
      expect(line['body'], 'GET a.test (log failed)');
    });

    test('a null printer prints to stdout', () async {
      final printed = <String>[];
      await runZoned(
        () => _dio(
          ScriptedAdapter([reply(200)]),
          (_) => [HttpJsonLogInterceptor()],
        ).get<dynamic>('/x'),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => printed.add(line),
        ),
      );

      expect(printed, hasLength(1));
      expect(jsonDecode(printed.single), containsPair('severity_text', 'INFO'));
    });

    test('a negative maxBodyBytes is rejected', () {
      expect(
        () => HttpJsonLogInterceptor(
          config: const JsonLogConfig(maxBodyBytes: -1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('severity and error.type', () {
    for (final (status, severity) in [
      (200, 'INFO'),
      (404, 'WARN'),
      (500, 'ERROR'),
    ]) {
      test('status $status is $severity', () {
        final line = _run([reply(status)], _log).single;

        expect(line['severity_text'], severity);
        expect(line['http.response.status_code'], status);
        if (status < 400) {
          expect(line.containsKey('error.type'), isFalse);
        } else {
          expect(line['error.type'], '$status');
          expect(line['body'], 'GET https://a.test/x $status 0.000s');
        }
      });
    }

    test('a 3xx that validateStatus rejects is WARN with its status', () {
      final line = _run(
        [reply(302)],
        _log,
        options: Options(followRedirects: false),
      ).single;

      expect(line['severity_text'], 'WARN');
      expect(line['error.type'], '302');
    });

    test('a 4xx that validateStatus accepts is still WARN', () {
      final line = _run(
        [reply(404)],
        _log,
        options: Options(validateStatus: (_) => true),
      ).single;

      expect(line['severity_text'], 'WARN');
      expect(line['error.type'], '404');
    });

    test('a connection error is ERROR with the exception type name', () {
      final line = _run([
        failWith(DioExceptionType.connectionError),
      ], _log).single;

      expect(line['severity_text'], 'ERROR');
      expect(line['error.type'], 'connectionError');
      expect(line.containsKey('http.response.status_code'), isFalse);
      expect(line['body'], 'GET https://a.test/x connectionError 0.000s');
    });

    test('a cancel is INFO', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        final token = CancelToken();
        _dio(
          GatedAdapter(),
          (_) => [_log(lines)],
        ).get<dynamic>('/x', cancelToken: token).ignore();
        async.elapse(Duration.zero);
        token.cancel();
        async.elapse(Duration.zero);
      });

      final line = _decode(lines).single;
      expect(line['severity_text'], 'INFO');
      expect(line['error.type'], 'cancel');
    });
  });

  group('URL redaction', () {
    test('redacts user info and a listed parameter, keeps the rest', () {
      final line = _run(
        [reply(200)],
        _log,
        path: 'https://me:pw@a.test/x?page=2&Token=abc',
      ).single;

      const url = 'https://REDACTED:REDACTED@a.test/x?page=2&Token=REDACTED';
      expect(line['url.full'], url);
      expect(line['body'], 'GET $url 200 0.000s');
    });
  });

  group('headers', () {
    test('opted-in headers appear lower case as lists, listed ones '
        'redacted', () {
      final line = _run(
        [
          reply(200, headers: {'Set-Cookie': 's=1', 'X-Trace': 't'}),
        ],
        (lines) => _log(lines, requestHeaders: true, responseHeaders: true),
        options: Options(
          headers: {'AUTHORIZATION': 'Bearer secret', 'X-Tenant': 'acme'},
        ),
      ).single;

      expect(line['http.request.header.authorization'], ['REDACTED']);
      expect(line['http.request.header.x-tenant'], ['acme']);
      expect(line['http.response.header.set-cookie'], ['REDACTED']);
      expect(line['http.response.header.x-trace'], ['t']);
      expect(jsonEncode(line), isNot(contains('secret')));
    });

    test('headers and bodies are absent by default', () {
      final line = _run(
        [reply(200)],
        _log,
        method: 'POST',
        data: {'a': 1},
        options: Options(headers: {'x-a': '1'}),
      ).single;

      expect(
        line.keys.where(
          (key) =>
              key.startsWith('http.request.header.') ||
              key.startsWith('http.response.header.') ||
              key.startsWith('falconx.request.body') ||
              key.startsWith('falconx.response.body'),
        ),
        isEmpty,
      );
    });
  });

  group('bodies', () {
    test('opted-in bodies appear as strings', () {
      final line = _run(
        [reply(200)],
        (lines) => _log(lines, requestBody: true, responseBody: true),
        method: 'POST',
        data: {'name': 'a'},
      ).single;

      expect(line['falconx.request.body'], '{"name":"a"}');
      expect(line['falconx.response.body'], '{"status":200}');
      expect(line.containsKey('falconx.request.body.truncated'), isFalse);
    });

    test('a long body is cut at a character boundary and flagged', () {
      final line = _run(
        [reply(200)],
        (lines) => _log(lines, requestBody: true, maxBodyBytes: 10),
        method: 'POST',
        data: 'สวัสดีครับ',
      ).single;

      expect(line['falconx.request.body'], 'สวั');
      expect(line['falconx.request.body.truncated'], isTrue);
    });

    test('a body jsonEncode rejects falls back to toString()', () {
      final line = _run(
        [reply(200)],
        (lines) => _log(lines, requestBody: true),
        method: 'POST',
        data: {'value': _Opaque()},
      ).single;

      expect(line['falconx.request.body'], '{value: opaque-value}');
    });

    test('a FormData body lists its field and file names', () {
      final line = _run(
        [reply(200)],
        (lines) => _log(lines, requestBody: true),
        method: 'POST',
        data: FormData.fromMap({
          'name': 'secret-value',
          'avatar': MultipartFile.fromString('x', filename: 'me.png'),
        }),
      ).single;

      expect(
        line['falconx.request.body'],
        '{"fields":["name"],"files":["me.png"]}',
      );
    });

    test('a stream response body is not read', () {
      final line = _run(
        [reply(200)],
        (lines) => _log(lines, responseBody: true),
        options: Options(responseType: ResponseType.stream),
      ).single;

      expect(line['falconx.response.body'], '<stream>');
    });
  });

  group('FalconX flags', () {
    test('a local 429 is flagged', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        final bucket = TokenBucketRateLimitInterceptor(
          config: const TokenBucketRateLimitConfig(
            perHost: [TokenBucketPolicy(permits: 1, per: Duration(minutes: 1))],
            queueRequests: false,
          ),
        );
        final dio = _dio(
          ScriptedAdapter([reply(200)]),
          (_) => [_log(lines), bucket],
        );
        dio.get<dynamic>('/1').ignore();
        async.elapse(Duration.zero);
        dio.get<dynamic>('/2').ignore();
        async.elapse(Duration.zero);
        bucket.dispose();
      });

      final decoded = _decode(lines);
      expect(decoded.first.containsKey('falconx.rate_limit.local'), isFalse);
      expect(decoded.last['falconx.rate_limit.local'], isTrue);
      expect(decoded.last['http.response.status_code'], 429);
      expect(decoded.last['severity_text'], 'WARN');
    });

    test('a cache hit is flagged', () {
      final lines = <Object?>[];
      fakeAsync((async) {
        final dio = _dio(
          ScriptedAdapter([reply(200)]),
          (_) => [_log(lines), CacheInterceptor()],
        );
        dio.get<dynamic>('/x').ignore();
        async.elapse(Duration.zero);
        dio.get<dynamic>('/x').ignore();
        async.elapse(Duration.zero);
      });

      final decoded = _decode(lines);
      expect(decoded.first.containsKey('falconx.cache.hit'), isFalse);
      expect(decoded.last['falconx.cache.hit'], isTrue);
      expect(decoded.last['body'], 'GET https://a.test/x 200 0.000s (cache)');
    });
  });
}
