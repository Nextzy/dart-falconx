import 'package:ansicolor/ansicolor.dart';
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

/// An error whose text carries the request URI, as `dart:io`'s
/// `HttpException` does.
class _UriError {
  new(this.uri);

  final Uri uri;

  @override
  String toString() => 'Connection closed, uri = $uri';
}

/// Runs one request through a pretty log built by [log] and returns the
/// printed lines; [answer] settles the gated request after [elapsed].
List<String> _run(
  HttpLogInterceptor Function(void Function(Object?) print) log, {
  String path = '/x',
  Options? options,
  void Function(GatedRequest request)? answer,
  Duration elapsed = Duration.zero,
}) {
  final lines = <String>[];
  fakeAsync((async) {
    final adapter = GatedAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
      ..httpClientAdapter = adapter
      ..transformer = FoldingTransformer()
      ..interceptors.add(log((line) => lines.add('$line')));
    dio.get<dynamic>(path, options: options).ignore();
    async.elapse(elapsed);
    (answer ?? (request) => request.respond(200))(adapter.requests.single);
    async.elapse(Duration.zero);
  });
  return lines;
}

void main() {
  late bool colorDisabled;

  setUp(() {
    colorDisabled = ansiColorDisabled;
    ansiColorDisabled = true;
  });

  tearDown(() => ansiColorDisabled = colorDisabled);

  group('colour', () {
    for (final (enabled, global) in [(true, true), (false, false)]) {
      test('the constructor leaves ansiColorDisabled at $global '
          '(enabled: $enabled)', () {
        ansiColorDisabled = global;

        HttpLogInterceptor(enabled: enabled);

        expect(ansiColorDisabled, global);
      });
    }

    test('a disabled instance prints nothing', () {
      final lines = _run(
        (print) => HttpLogInterceptor(enabled: false, logPrint: print),
      );

      expect(lines, isEmpty);
    });
  });

  group('redaction', () {
    test('a listed request header prints REDACTED whatever its case', () {
      final lines = _run(
        (print) => HttpLogInterceptor(logPrint: print),
        options: Options(
          headers: {'AUTHORIZATION': 'Bearer secret', 'X-Tenant': 'acme'},
        ),
      );

      expect(lines, contains(' AUTHORIZATION: REDACTED'));
      expect(lines, contains(' X-Tenant: acme'));
      expect(lines.join('\n'), isNot(contains('secret')));
    });

    test('an empty set prints every header as is', () {
      final lines = _run(
        (print) => HttpLogInterceptor(redactHeaders: const {}, logPrint: print),
        options: Options(headers: {'Authorization': 'Bearer secret'}),
      );

      expect(lines, contains(' Authorization: Bearer secret'));
    });

    test('a listed response header prints REDACTED', () {
      final lines = _run(
        (print) => HttpLogInterceptor(responseHeader: true, logPrint: print),
        answer: (request) =>
            request.respond(200, headers: {'set-cookie': 'session=secret'}),
      );

      expect(lines, contains(' set-cookie: REDACTED'));
      expect(lines.join('\n'), isNot(contains('session=secret')));
    });

    test('every URL line redacts user info and listed query values', () {
      final lines = _run(
        (print) => HttpLogInterceptor(logPrint: print),
        path: 'https://me:pw@a.test/x?page=2&token=abc',
      );

      const url =
          'URL: https://REDACTED:REDACTED@a.test/x?page=2&token=REDACTED';
      expect(lines.where((line) => line.startsWith('URL:')), [url, url]);
      expect(lines.join('\n'), isNot(contains('abc')));
    });

    test('an exception text prints the URL redacted', () {
      final lines = <String>[];
      fakeAsync((async) {
        final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
          ..httpClientAdapter = ScriptedAdapter([
            (options) => throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              error: _UriError(options.uri),
            ),
          ])
          ..transformer = FoldingTransformer()
          ..interceptors.add(
            HttpLogInterceptor(logPrint: (l) => lines.add('$l')),
          );
        dio.get<dynamic>('/x?token=secret').ignore();
        async.elapse(Duration.zero);
      });

      final printed = lines.join('\n');
      expect(printed, contains('uri = https://a.test/x?token=REDACTED'));
      expect(printed, isNot(contains('secret')));
    });

    test('custom query parameter names replace the defaults', () {
      final lines = _run(
        (print) => HttpLogInterceptor(
          redactQueryParameters: const {'tenant'},
          logPrint: print,
        ),
        path: '/x?tenant=acme&token=abc',
      );

      expect(
        lines,
        contains('URL: https://a.test/x?tenant=REDACTED&token=abc'),
      );
    });
  });

  group('request block', () {
    test('the printed extra hides the log start stamp and keeps app keys', () {
      final lines = _run(
        (print) => HttpLogInterceptor(logPrint: print),
        options: Options(extra: {'id': 1}),
      );

      expect(lines, contains('extra: {id: 1}'));
      expect(lines.join('\n'), isNot(contains('dart_falconnect.log.start')));
    });
  });

  group('status and duration', () {
    test('a response prints its status and duration with responseHeader '
        'off', () {
      final lines = _run(
        (print) => HttpLogInterceptor(logPrint: print),
        elapsed: const Duration(milliseconds: 250),
      );

      expect(lines, contains('statusCode: 200'));
      expect(lines, contains('duration: 250ms'));
    });

    test('an error response prints its status and duration', () {
      final lines = _run(
        (print) => HttpLogInterceptor(logPrint: print),
        elapsed: const Duration(milliseconds: 40),
        answer: (request) => request.respond(404),
      );

      expect(lines, contains('statusCode: 404'));
      expect(lines, contains('duration: 40ms'));
    });

    test('an error without a response prints its duration', () {
      final lines = <String>[];
      fakeAsync((async) {
        final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
          ..httpClientAdapter = ScriptedAdapter([
            failWith(DioExceptionType.connectionError),
          ])
          ..transformer = FoldingTransformer()
          ..interceptors.add(
            HttpLogInterceptor(logPrint: (l) => lines.add('$l')),
          );
        dio.get<dynamic>('/x').ignore();
        async.elapse(Duration.zero);
      });

      expect(lines, contains('duration: 0ms'));
      expect(lines.where((line) => line.startsWith('statusCode')), isEmpty);
    });
  });
}
