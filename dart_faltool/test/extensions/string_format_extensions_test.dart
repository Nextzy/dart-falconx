import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

void main() {
  group('FalconToolStringFormatExtension', () {
    group('Case Conversions', () {
      test('toCamelCase converts to camelCase', () {
        expect('hello_world'.toCamelCase(), 'helloWorld');
        expect('HELLO-WORLD'.toCamelCase(), 'helloWorld');
        expect('hello world'.toCamelCase(), 'helloWorld');
        expect('Hello_World'.toCamelCase(), 'helloWorld');
        expect('helloWorld'.toCamelCase(), 'helloWorld');
        expect(''.toCamelCase(), '');
      });

      test('toSnakeCase converts to snake_case', () {
        expect('helloWorld'.toSnakeCase(), 'hello_world');
        expect('HelloWorld'.toSnakeCase(), 'hello_world');
        expect('hello-world'.toSnakeCase(), 'hello_world');
        expect('hello world'.toSnakeCase(), 'hello_world');
        expect('hello_world'.toSnakeCase(), 'hello_world');
        expect(''.toSnakeCase(), '');
      });

      test('toPascalCase converts to PascalCase', () {
        expect('hello_world'.toPascalCase(), 'HelloWorld');
        expect('hello-world'.toPascalCase(), 'HelloWorld');
        expect('hello world'.toPascalCase(), 'HelloWorld');
        expect('helloWorld'.toPascalCase(), 'HelloWorld');
        expect(''.toPascalCase(), '');
      });

      test('toKebabCase converts to kebab-case', () {
        expect('helloWorld'.toKebabCase(), 'hello-world');
        expect('HelloWorld'.toKebabCase(), 'hello-world');
        expect('hello_world'.toKebabCase(), 'hello-world');
        expect('hello world'.toKebabCase(), 'hello-world');
        expect(''.toKebabCase(), '');
      });
    });

    group('String Formatting', () {
      test(
        'capitalizeWords capitalizes first letter of each word',
        () {
          expect(
            'hello world'.capitalizeWords(),
            'Hello World',
          );
          expect(
            'HELLO WORLD'.capitalizeWords(),
            'HELLO WORLD',
          );
          expect(
            'hello   world'.capitalizeWords(),
            'Hello   World',
          );
          expect(''.capitalizeWords(), '');
          expect('a'.capitalizeWords(), 'A');
        },
      );

      test('truncate truncates string to specified length', () {
        expect('Hello World'.truncate(8), 'Hello...');
        expect(
          'Hello World'.truncate(8, ellipsis: '~'),
          'Hello W~',
        );
        expect('Hello'.truncate(10), 'Hello');
        expect('Hello World'.truncate(3), '...');
        expect(
          'Hello World'.truncate(null),
          'Hello World',
        );
      });

      test('capitalize uppercases first letter', () {
        expect('abcd'.capitalize, 'Abcd');
        expect('Abcd'.capitalize, 'Abcd');
        expect(''.capitalize, '');
        expect('a'.capitalize, 'A');
      });
    });

    group('Masking', () {
      test('maskPhoneNumber masks middle digits', () {
        expect('0891234567'.maskPhoneNumber(), '08******67');
        expect(
          '+66891234567'.maskPhoneNumber(),
          '+66********67',
        );
        expect(
          '089-123-4567'.maskPhoneNumber(),
          '08******67',
        );
      });

      test('maskPhoneNumber with custom lengths', () {
        expect(
          '0891234567'.maskPhoneNumber(
            prefixLength: 3,
            suffixLength: 4,
          ),
          '089***4567',
        );
        expect(
          '0891234567'.maskPhoneNumber(
            prefixLength: 4,
            suffixLength: 4,
          ),
          '0891**4567',
        );
      });

      test('maskPhoneNumber with custom mask char', () {
        expect(
          '0891234567'.maskPhoneNumber(maskChar: '#'),
          '08######67',
        );
      });

      test('maskPhoneNumber returns original if too short', () {
        expect(
          '1234'.maskPhoneNumber(),
          '1234',
        );
        expect(
          '12345'.maskPhoneNumber(
            prefixLength: 3,
            suffixLength: 3,
          ),
          '12345',
        );
      });

      test('maskEmail masks local part', () {
        expect(
          'user@example.com'.maskEmail(),
          'us**@example.com',
        );
        expect(
          'john.doe@gmail.com'.maskEmail(),
          'jo******@gmail.com',
        );
      });

      test('maskEmail with short local part', () {
        expect(
          'a@example.com'.maskEmail(),
          '*@example.com',
        );
        expect(
          'ab@example.com'.maskEmail(),
          '**@example.com',
        );
      });

      test('maskEmail with custom visible chars', () {
        expect(
          'user@example.com'.maskEmail(visibleChars: 3),
          'use*@example.com',
        );
        expect(
          'john.doe@gmail.com'.maskEmail(visibleChars: 4),
          'john****@gmail.com',
        );
      });

      test('maskEmail with custom mask char', () {
        expect(
          'user@example.com'.maskEmail(maskChar: '#'),
          'us##@example.com',
        );
      });

      test('maskEmail returns original if no @ sign', () {
        expect('no-at-sign'.maskEmail(), 'no-at-sign');
      });
    });
  });

  group('FalconStringNullFormatExtension', () {
    test('capitalize safely capitalizes string', () {
      String? nullString;
      const emptyString = '';
      const lowerString = 'hello';
      const upperString = 'HELLO';

      expect(nullString.capitalize, null);
      expect(emptyString.capitalize, '');
      expect(lowerString.capitalize, 'Hello');
      expect(upperString.capitalize, 'HELLO');
    });

    test('truncate safely truncates string', () {
      String? nullString;
      const longString = 'Hello World';

      expect(nullString.truncate(5), null);
      expect(longString.truncate(5), 'He...');
    });

    test('maskPhoneNumber safely masks phone number', () {
      String? nullString;
      const phone = '0891234567';

      expect(nullString.maskPhoneNumber(), null);
      expect(phone.maskPhoneNumber(), '08******67');
    });

    test('maskEmail safely masks email', () {
      String? nullString;
      const email = 'user@example.com';

      expect(nullString.maskEmail(), null);
      expect(email.maskEmail(), 'us**@example.com');
    });
  });
}
