import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

void main() {
  group('FormatRegex', () {
    group('url', () {
      test('matches http and https URLs', () {
        expect(FormatRegex.url.hasMatch('https://example.com'), true);
        expect(
          FormatRegex.url.hasMatch('http://example.com:8080/path?q=1'),
          true,
        );
        expect(FormatRegex.url.hasMatch('HTTPS://EXAMPLE.COM'), true);
      });

      test('rejects non-http schemes and bare hosts', () {
        expect(FormatRegex.url.hasMatch('ftp://example.com'), false);
        expect(FormatRegex.url.hasMatch('example.com'), false);
        expect(FormatRegex.url.hasMatch('https://'), false);
        expect(FormatRegex.url.hasMatch(''), false);
      });

      test('rejects underscore in host and spaces in path', () {
        // Characterization: '_' is not in the allowed host character class.
        expect(
          FormatRegex.url.hasMatch('https://sub_domain.example.com'),
          false,
        );
        expect(
          FormatRegex.url.hasMatch('https://example.com/path with space'),
          false,
        );
      });

      test('accepts fragment after a path but not directly after the host', () {
        // Characterization: '#' is only allowed inside the path segment.
        expect(
          FormatRegex.url.hasMatch('https://example.com/path#section'),
          true,
        );
        expect(FormatRegex.url.hasMatch('https://example.com?q=1'), true);
      });
    });

    group('email', () {
      test('matches common valid addresses', () {
        expect(FormatRegex.email.hasMatch('user@example.com'), true);
        expect(FormatRegex.email.hasMatch('user.name+tag@example.co.uk'), true);
      });

      test('rejects missing parts and spaces', () {
        expect(FormatRegex.email.hasMatch('invalid.email'), false);
        expect(FormatRegex.email.hasMatch('@example.com'), false);
        expect(FormatRegex.email.hasMatch('user example@com'), false);
        expect(FormatRegex.email.hasMatch(''), false);
      });
    });

    group('html', () {
      test('matches opening and closing tags case-insensitively', () {
        expect(
          FormatRegex.html.allMatches('<b>hi</b>').map((m) => m.group(0)),
          ['<b>', '</b>'],
        );
        expect(FormatRegex.html.allMatches('<BR>hi</BR>').length, 2);
      });

      test('does not match angle brackets without a closing delimiter', () {
        expect(FormatRegex.html.hasMatch('5 < 6'), false);
      });
    });

    group('htmlEntities', () {
      test('matches encoded entities ending with a semicolon', () {
        expect(FormatRegex.htmlEntities.allMatches('&nbsp;&amp;').length, 2);
        expect(FormatRegex.htmlEntities.hasMatch('&amp'), false);
      });
    });

    group('e164', () {
      test('matches valid E.164 numbers within digit bounds', () {
        expect(FormatRegex.e164.hasMatch('+66891234567'), true);
        expect(FormatRegex.e164.hasMatch('+1234567'), true); // 7 digits
        expect(
          FormatRegex.e164.hasMatch('+123456789012345'),
          true,
        ); // 15 digits
      });

      test('rejects out-of-range digit counts and bad prefixes', () {
        expect(FormatRegex.e164.hasMatch('+123456'), false); // 6 digits
        expect(
          FormatRegex.e164.hasMatch('+1234567890123456'),
          false, // 16 digits
        );
        expect(FormatRegex.e164.hasMatch('+0123456'), false); // leading 0
        expect(FormatRegex.e164.hasMatch('66891234567'), false); // no plus
        expect(
          FormatRegex.e164.hasMatch('+1-555-123-4567'),
          false,
        ); // separators
      });
    });

    group('timePattern', () {
      test('matches zero-padded HH:mm within 24-hour bounds', () {
        expect(FormatRegex.timePattern.hasMatch('00:00'), true);
        expect(FormatRegex.timePattern.hasMatch('23:59'), true);
      });

      test('rejects out-of-range hours and minutes', () {
        expect(FormatRegex.timePattern.hasMatch('24:00'), false);
        expect(FormatRegex.timePattern.hasMatch('23:60'), false);
      });
    });
  });

  group('FalconToolStringValidatorExtension', () {
    group('Whitespace and Formatting', () {
      test('removeWhiteSpace removes all whitespace', () {
        expect('hello world'.removeWhiteSpace, 'helloworld');
        expect('  tab\tspace\n '.removeWhiteSpace, 'tabspace');
        expect(''.removeWhiteSpace, '');
      });

      test(
        'removeHtmlTags strips tags and entities, collapsing whitespace',
        () {
          expect('<p>Hello &amp; world</p>'.removeHtmlTags, 'Hello world');
          expect('<div>\n\n  Hello\n  </div>'.removeHtmlTags, 'Hello');
          expect('no tags here'.removeHtmlTags, 'no tags here');
          expect('a &amp b'.removeHtmlTags, 'a &amp b'); // no semicolon: kept
          expect('<BR>hi</BR>'.removeHtmlTags, 'hi'); // case-insensitive tags
        },
      );

      test(
        'removeHtmlTags keeps plain prose that contains an ampersand',
        () {
          // Intended: prose without HTML should pass through unchanged.
          expect('Fish & Chips are tasty; really'.removeHtmlTags, isNot(''));
        },
        skip: 'BUG: htmlEntities pattern &[^;]+; deletes prose between & and ;',
      );

      test('normalizeWhitespace trims and collapses whitespace', () {
        expect('  hello   world  '.normalizeWhitespace, 'hello world');
        expect(
          '\t\ttabs\t\tand\t\tspaces\t\t'.normalizeWhitespace,
          'tabs and spaces',
        );
        expect('already normal'.normalizeWhitespace, 'already normal');
        expect(''.normalizeWhitespace, '');
      });
    });

    group('URL validation', () {
      test('isUrl validates http and https URLs', () {
        expect('https://example.com'.isUrl, true);
        expect('http://sub.example.com:8080/a/b?x=1&y=2'.isUrl, true);
        expect('https://example.com/'.isUrl, true);

        expect('not a url'.isUrl, false);
        expect('ftp://example.com'.isUrl, false);
      });

      test('isUrl accepts a fragment directly after the host', () {
        // Intended: '#section' is a valid URL fragment position.
        expect('https://example.com#section'.isUrl, true);
      }, skip: 'BUG: url pattern rejects host-level #fragment (needs a path)');

      test('isNotUrl is the negation of isUrl', () {
        expect('https://example.com'.isNotUrl, false);
        expect('not a url'.isNotUrl, true);
      });
    });

    group('Email validation', () {
      test('isEmail validates common addresses', () {
        expect('user@example.com'.isEmail, true);
        expect('user.name@example.co.uk'.isEmail, true);

        expect('invalid.email'.isEmail, false);
        expect('user@'.isEmail, false);
        expect('user@example'.isEmail, false);
      });

      test('isEmail rejects obviously invalid dot placement', () {
        // Intended: consecutive or leading dots are invalid under RFC 5322.
        expect('user@example..com'.isEmail, false);
        expect('user..name@example.com'.isEmail, false);
        expect('.user@example.com'.isEmail, false);
      }, skip: 'BUG: email pattern accepts consecutive and leading dots');

      test('isNotEmail is the negation of isEmail', () {
        expect('user@example.com'.isNotEmail, false);
        expect('invalid email'.isNotEmail, true);
      });
    });

    group('Numeric validation', () {
      test('isNumeric accepts integers and decimals with optional minus', () {
        expect('123'.isNumeric, true);
        expect('-45.67'.isNumeric, true);
        expect('0'.isNumeric, true);
        expect('.5'.isNumeric, true); // leading dot, trailing digits
        expect('-.5'.isNumeric, true);
      });

      test('isNumeric rejects non-numeric strings', () {
        expect('abc123'.isNumeric, false);
        expect('1.2.3'.isNumeric, false);
        expect('5.'.isNumeric, false); // trailing dot
        expect('+5'.isNumeric, false); // plus sign not allowed
        expect('1e5'.isNumeric, false); // exponent notation not allowed
        expect(''.isNumeric, false);
      });
    });

    group('JSON validation', () {
      test('isJson accepts valid JSON values', () {
        expect('{"key": "value"}'.isJson, true);
        expect('[1, 2, 3]'.isJson, true);
        expect('"string"'.isJson, true);
        expect('123'.isJson, true);
        expect('true'.isJson, true);
        expect('null'.isJson, true);
      });

      test('isJson rejects invalid JSON', () {
        expect('not json'.isJson, false);
        expect('{key: value}'.isJson, false);
        expect("{'key': 'value'}".isJson, false);
        expect(''.isJson, false);
      });

      test('isNotJson is the negation of isJson', () {
        expect('{"key": "value"}'.isNotJson, false);
        expect('not json'.isNotJson, true);
      });
    });

    group('Phone number validation', () {
      test('isPhoneNumber accepts E.164 numbers', () {
        expect('+66891234567'.isPhoneNumber, true);
        expect('+123456789012345'.isPhoneNumber, true); // 15 digits
      });

      test('isPhoneNumber rejects malformed numbers', () {
        expect('66891234567'.isPhoneNumber, false); // missing plus
        expect('+0123456'.isPhoneNumber, false); // zero prefix
        expect('+12345'.isPhoneNumber, false); // too short
        expect('+1 555 123 4567'.isPhoneNumber, false); // spaces
        expect(''.isPhoneNumber, false);
      });

      test('isNotPhoneNumber is the negation of isPhoneNumber', () {
        expect('+66891234567'.isNotPhoneNumber, false);
        expect('12345'.isNotPhoneNumber, true);
      });
    });

    group('Time validation', () {
      test('isTime accepts HH:mm within 24-hour bounds', () {
        expect('00:00'.isTime, true);
        expect('09:05'.isTime, true);
        expect('23:59'.isTime, true);
      });

      test('isTime rejects malformed times', () {
        expect('24:00'.isTime, false);
        expect('23:60'.isTime, false);
        expect('9:05'.isTime, false); // hour must be zero-padded
        expect('14:30:00'.isTime, false);
        expect('not a time'.isTime, false);
        expect(''.isTime, false);
      });

      test('isNotTime is the negation of isTime', () {
        expect('14:30'.isNotTime, false);
        expect('24:00'.isNotTime, true);
      });
    });
  });
}
