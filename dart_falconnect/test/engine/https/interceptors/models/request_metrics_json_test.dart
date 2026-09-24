import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  group('RequestMetrics.toJson characterization', () {
    test('completed request emits every key in declaration order', () {
      final metrics = RequestMetrics(
        method: 'GET',
        url: 'https://a.test/x',
        startTime: DateTime(2026, 1, 1, 12, 0, 0),
        endTime: DateTime(2026, 1, 1, 12, 0, 5, 250),
        statusCode: 200,
        error: null,
        requestSize: 12,
        responseSize: 34,
      );

      expect(metrics.toJson(), {
        'method': 'GET',
        'url': 'https://a.test/x',
        'startTime': '2026-01-01T12:00:00.000',
        'endTime': '2026-01-01T12:00:05.250',
        // 5 s 250 ms.
        'statusCode': 200,
        'error': null,
        'totalDuration': 5250,
        'requestSize': 12,
        'responseSize': 34,
      });
    });

    test("emits exactly today's key set", () {
      final metrics = RequestMetrics(
        method: 'GET',
        url: 'u',
        startTime: DateTime(2026),
      );

      expect(
        metrics.toJson().keys,
        unorderedEquals([
          'method',
          'url',
          'startTime',
          'endTime',
          'statusCode',
          'error',
          'totalDuration',
          'requestSize',
          'responseSize',
        ]),
      );
    });

    test('null optional fields serialize as explicit nulls', () {
      final metrics = RequestMetrics(
        method: 'POST',
        url: 'https://a.test/y',
        startTime: DateTime(2026, 1, 1),
      );

      final json = metrics.toJson();
      expect(json['endTime'], isNull);
      expect(json.containsKey('endTime'), isTrue);
      expect(json['statusCode'], isNull);
      expect(json.containsKey('statusCode'), isTrue);
      expect(json['error'], isNull);
      expect(json.containsKey('error'), isTrue);
      expect(json['requestSize'], isNull);
      expect(json['responseSize'], isNull);
    });

    test('in-flight totalDuration reads the clock', () {
      fakeAsync((async) {
        final metrics = RequestMetrics(
          method: 'GET',
          url: 'u',
          startTime: clock.now(),
        );

        async.elapse(const Duration(milliseconds: 40));

        expect(metrics.toJson()['totalDuration'], 40);
      });
    });
  });
}
