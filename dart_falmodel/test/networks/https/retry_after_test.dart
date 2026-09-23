import 'package:dart_falmodel/lib.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 9, 23, 12);

Headers _headers(Map<String, String> values) => Headers.fromMap({
  for (final entry in values.entries) entry.key: [entry.value],
});

Response<dynamic> _response(int status, Map<String, String> headers) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: 'https://a.test/x'),
      statusCode: status,
      headers: _headers(headers),
    );

void main() {
  group('parseRetryAfter', () {
    test('reads delay-seconds', () {
      expect(parseRetryAfter('120'), const Duration(seconds: 120));
      expect(parseRetryAfter(' 0 '), Duration.zero);
    });

    test('clamps a huge delay-seconds value instead of overflowing', () {
      const clamp = Duration(seconds: 1 << 31);
      expect(parseRetryAfter('9000000000000000000'), clamp);
      expect(parseRetryAfter('99999999999999999999999'), clamp);
    });

    test('reads every HTTP-date format against serverDate', () {
      final server = DateTime.utc(1994, 11, 6, 8, 49, 7);
      for (final value in [
        'Sun, 06 Nov 1994 08:49:37 GMT',
        'Sunday, 06-Nov-94 08:49:37 GMT',
        'Sun Nov  6 08:49:37 1994',
      ]) {
        expect(
          parseRetryAfter(value, serverDate: server),
          const Duration(seconds: 30),
          reason: value,
        );
      }
    });

    test('measures a date from clock.now() without serverDate', () {
      withClock(Clock.fixed(_now), () {
        expect(
          parseRetryAfter('Wed, 23 Sep 2026 12:00:45 GMT'),
          const Duration(seconds: 45),
        );
      });
    });

    test('gives zero for a date in the past', () {
      withClock(Clock.fixed(_now), () {
        expect(parseRetryAfter('Wed, 23 Sep 2026 11:00:00 GMT'), Duration.zero);
      });
    });

    test('gives null for missing and unreadable values', () {
      for (final value in [null, '', '  ', '-5', '1.5', 'soon', '12s']) {
        expect(parseRetryAfter(value), isNull, reason: '$value');
      }
    });
  });

  group('Headers.retryAfter', () {
    test('uses the Date header as the reference time', () {
      // The client clock is an hour ahead of the server.
      withClock(Clock.fixed(_now.add(const Duration(hours: 1))), () {
        final headers = _headers({
          'retry-after': 'Wed, 23 Sep 2026 12:00:10 GMT',
          'date': 'Wed, 23 Sep 2026 12:00:00 GMT',
        });
        expect(headers.retryAfter, const Duration(seconds: 10));
      });
    });

    test('ignores an unreadable Date header', () {
      withClock(Clock.fixed(_now), () {
        final headers = _headers({
          'retry-after': 'Wed, 23 Sep 2026 12:00:10 GMT',
          'date': 'yesterday',
        });
        expect(headers.retryAfter, const Duration(seconds: 10));
      });
    });

    test('is null without a Retry-After header', () {
      expect(_headers({}).retryAfter, isNull);
    });

    test('uses the first value of a duplicated Retry-After header', () {
      final headers = Headers.fromMap({
        'retry-after': ['5', '9'],
      });
      expect(headers.retryAfter, const Duration(seconds: 5));
    });

    test('uses the first value of a duplicated Date header', () {
      final headers = Headers.fromMap({
        'retry-after': ['Wed, 23 Sep 2026 12:00:10 GMT'],
        'date': [
          'Wed, 23 Sep 2026 12:00:00 GMT',
          'Wed, 23 Sep 2026 13:00:00 GMT',
        ],
      });
      expect(headers.retryAfter, const Duration(seconds: 10));
    });

    test('is null for an empty Retry-After value list', () {
      final headers = Headers.fromMap({'retry-after': <String>[]});
      expect(headers.retryAfter, isNull);
    });
  });

  group('recommendedRetryDelay', () {
    test('429 reads an HTTP-date Retry-After', () {
      withClock(Clock.fixed(_now), () {
        final exception = NetworkLimitExceededException(
          response: _response(429, {
            'retry-after': 'Wed, 23 Sep 2026 12:00:20 GMT',
          }),
        );
        expect(exception.recommendedRetryDelay, const Duration(seconds: 20));
      });
    });

    test('429 without Retry-After falls back to one minute', () {
      final exception = NetworkLimitExceededException(
        response: _response(429, {}),
      );
      expect(exception.recommendedRetryDelay, const Duration(minutes: 1));
    });

    test('429 with a duplicated Date header reads delay-seconds', () {
      final exception = NetworkLimitExceededException(
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: 'https://a.test/x'),
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['7'],
            'date': [
              'Wed, 23 Sep 2026 12:00:00 GMT',
              'Wed, 23 Sep 2026 13:00:00 GMT',
            ],
          }),
        ),
      );
      expect(exception.recommendedRetryDelay, const Duration(seconds: 7));
    });

    test('503 reads Retry-After and falls back to 30 seconds', () {
      final withHeader = NetworkServerException(
        statusCode: 503,
        response: _response(503, {'retry-after': '7'}),
      );
      final without = NetworkServerException(
        statusCode: 503,
        response: _response(503, {}),
      );
      expect(withHeader.recommendedRetryDelay, const Duration(seconds: 7));
      expect(without.recommendedRetryDelay, const Duration(seconds: 30));
    });
  });
}
