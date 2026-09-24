import 'dart:convert';

import 'package:dart_falconnect/engine/https/config/log_config.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/log_redaction.dart';
import 'package:test/test.dart';

String _redact(
  String url, [
  Set<String> names = defaultRedactedQueryParameters,
]) => redactUrl(Uri.parse(url), names);

void main() {
  group('default redaction sets', () {
    test('list the sensitive headers', () {
      expect(defaultRedactedHeaders, {
        'authorization',
        'cookie',
        'proxy-authorization',
        'set-cookie',
        'x-api-key',
      });
    });

    test('list the sensitive query parameters, OpenTelemetry defaults '
        'included', () {
      expect(defaultRedactedQueryParameters, {
        'access_token',
        'api_key',
        'apikey',
        'awsaccesskeyid',
        'key',
        'password',
        'secret',
        'sig',
        'signature',
        'token',
        'x-amz-signature',
        'x-goog-signature',
      });
    });
  });

  group('matchesName', () {
    test('matches a listed name whatever its case', () {
      expect(matchesName('Authorization', defaultRedactedHeaders), isTrue);
      expect(matchesName('X-API-KEY', defaultRedactedHeaders), isTrue);
    });

    test('matches a listed name the app wrote in mixed case', () {
      expect(matchesName('x-tenant-secret', {'X-Tenant-Secret'}), isTrue);
    });

    test('does not match an unlisted name', () {
      expect(matchesName('accept', defaultRedactedHeaders), isFalse);
    });

    test('matches nothing in an empty set', () {
      expect(matchesName('authorization', const {}), isFalse);
    });
  });

  group('redactUrl', () {
    test('replaces the value of a listed parameter and keeps the rest in '
        'order', () {
      expect(
        _redact('https://a.test/x?page=2&token=abc&sort=name'),
        'https://a.test/x?page=2&token=REDACTED&sort=name',
      );
    });

    test('redacts a repeated and case-variant key every time', () {
      expect(
        _redact('https://a.test/x?token=a&TOKEN=b'),
        'https://a.test/x?token=REDACTED&TOKEN=REDACTED',
      );
    });

    test('redacts user info', () {
      expect(
        _redact('https://user:pass@a.test/x'),
        'https://REDACTED:REDACTED@a.test/x',
      );
    });

    test('redacts user info with no password', () {
      expect(
        _redact('https://user@a.test/x'),
        'https://REDACTED:REDACTED@a.test/x',
      );
    });

    test('matches a parameter name by its decoded form', () {
      expect(
        _redact('https://a.test/x?my%20secret=abc&my+secret=def', {
          'my secret',
        }),
        'https://a.test/x?my%20secret=REDACTED&my+secret=REDACTED',
      );
    });

    test('redacts a listed parameter that has no value', () {
      expect(
        _redact('https://a.test/x?token'),
        'https://a.test/x?token=REDACTED',
      );
    });

    test('keeps the encoding of unlisted parameters, the port, and the '
        'fragment', () {
      expect(
        _redact('https://a.test:8443/x?q=a%20b&key=k#top'),
        'https://a.test:8443/x?q=a%20b&key=REDACTED#top',
      );
    });

    test('leaves a URL with no query or user info unchanged', () {
      expect(_redact('https://a.test/x'), 'https://a.test/x');
    });

    test('redacts nothing with an empty set', () {
      expect(
        _redact('https://a.test/x?token=abc', const {}),
        'https://a.test/x?token=abc',
      );
    });
  });

  group('headerValues', () {
    test('wraps a single value in a list of strings', () {
      expect(headerValues('application/json'), ['application/json']);
      expect(headerValues(42), ['42']);
    });

    test('converts every item of a list', () {
      expect(headerValues(['a', 1]), ['a', '1']);
    });

    test('reads null as no value', () {
      expect(headerValues(null), isEmpty);
    });
  });

  group('logHeader', () {
    test('reads a listed header as REDACTED whatever its case', () {
      expect(logHeader('Authorization', 'Bearer t', defaultRedactedHeaders), [
        'REDACTED',
      ]);
    });

    test('keeps an unlisted header value', () {
      expect(logHeader('accept', ['a', 'b'], defaultRedactedHeaders), [
        'a',
        'b',
      ]);
    });
  });

  group('truncateUtf8', () {
    test('keeps a text within the limit', () {
      final result = truncateUtf8('hello', 5);

      expect(result.text, 'hello');
      expect(result.truncated, isFalse);
    });

    test('cuts ASCII text at the limit', () {
      final result = truncateUtf8('hello world', 5);

      expect(result.text, 'hello');
      expect(result.truncated, isTrue);
    });

    test('cuts Thai text at a character boundary within the limit', () {
      // Every Thai character is 3 UTF-8 bytes, so 10 bytes hold 3 of them.
      const thai = 'สวัสดีครับ';

      for (var limit = 1; limit < utf8.encode(thai).length; limit++) {
        final result = truncateUtf8(thai, limit);
        final bytes = utf8.encode(result.text);

        expect(bytes.length, lessThanOrEqualTo(limit), reason: 'limit $limit');
        expect(utf8.decode(bytes), result.text);
        expect(thai, startsWith(result.text));
        expect(result.truncated, isTrue);
      }
      expect(truncateUtf8(thai, 10).text, 'สวั');
    });

    test('cuts a four-byte character whole', () {
      final result = truncateUtf8('a😀b', 4);

      expect(result.text, 'a');
      expect(result.truncated, isTrue);
    });

    test('a limit of 0 keeps nothing', () {
      final result = truncateUtf8('a', 0);

      expect(result.text, isEmpty);
      expect(result.truncated, isTrue);
    });
  });
}
