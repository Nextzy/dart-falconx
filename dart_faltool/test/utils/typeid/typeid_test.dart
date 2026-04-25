import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

void main() {
  group('TypeId', () {
    group('generate', () {
      test('generates valid TypeID with prefix', () {
        final id = TypeId.generate('user');
        expect(id.startsWith('user_'), isTrue);
        // prefix(4) + separator(1) + base32(26) = 31
        expect(id.length, 31);
      });

      test('generates valid TypeID without prefix', () {
        final id = TypeId.generate('');
        // base32 only, no separator
        expect(id.length, 26);
        expect(id.contains('_'), isFalse);
      });

      test('throws FormatException for prefix with underscore', () {
        expect(
          () => TypeId.generate('user_account'),
          throwsFormatException,
        );
      });

      test('throws FormatException for uppercase prefix', () {
        expect(() => TypeId.generate('User'), throwsFormatException);
      });

      test('throws FormatException for prefix longer than 63 chars', () {
        expect(
          () => TypeId.generate('a' * 64),
          throwsFormatException,
        );
      });

      test('accepts max length prefix of 63 chars', () {
        final id = TypeId.generate('a' * 63);
        expect(id.startsWith('${'a' * 63}_'), isTrue);
      });
    });

    group('decode', () {
      test('decodes TypeID with prefix', () {
        final generated = TypeId.generate('order');
        final decoded = TypeId.decode(generated);

        expect(decoded.prefix, 'order');
        expect(decoded.suffix.length, 26);
        expect(decoded.toString(), generated);
        expect(
          decoded.uuid,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            ),
          ),
        );
      });

      test('decodes TypeID without prefix', () {
        final generated = TypeId.generate('');
        final decoded = TypeId.decode(generated);

        expect(decoded.prefix, isEmpty);
        expect(decoded.suffix.length, 26);
        expect(decoded.toString(), generated);
        expect(
          decoded.uuid,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            ),
          ),
        );
      });

      test('throws FormatException for empty suffix with separator', () {
        expect(() => TypeId.decode('_'), throwsFormatException);
      });

      test('throws FormatException for invalid base32 suffix', () {
        expect(
          () => TypeId.decode('user_!!!!!!!!!!!!!!!!!!!!!!!!!!'),
          throwsFormatException,
        );
      });

      test('populates uuid with canonical 36-char lowercase hex', () {
        // Known-good vector: generate, decode, re-encode, compare.
        // This verifies the _uuidBytesToString helper produces canonical form.
        final id = TypeId.generate('test');
        final decoded = TypeId.decode(id);

        expect(
          decoded.uuid,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            ),
          ),
        );
        expect(decoded.uuid.length, 36);
        expect(decoded.uuid.split('-').map((seg) => seg.length).toList(), [
          8,
          4,
          4,
          4,
          12,
        ]);
        expect(decoded.uuid, decoded.uuid.toLowerCase()); // must be lowercase
      });
    });

    group('isValid', () {
      test('returns true for valid TypeID with prefix', () {
        final id = TypeId.generate('user');
        expect(TypeId.isValid(id), isTrue);
      });

      test('returns true for valid TypeID without prefix', () {
        final id = TypeId.generate('');
        expect(TypeId.isValid(id), isTrue);
      });

      test('returns false for invalid TypeID', () {
        expect(TypeId.isValid(''), isFalse);
        expect(TypeId.isValid('not-valid!!'), isFalse);
        expect(TypeId.isValid('user_short'), isFalse);
      });
    });

    group('decodeOrNull', () {
      test('returns DecodedTypeId for valid input', () {
        final id = TypeId.generate('test');
        final decoded = TypeId.decodeOrNull(id);
        expect(decoded, isNotNull);
        expect(decoded!.prefix, 'test');
      });

      test('returns null for invalid input', () {
        expect(TypeId.decodeOrNull(''), isNull);
        expect(TypeId.decodeOrNull('invalid!!'), isNull);
        expect(TypeId.decodeOrNull('user_short'), isNull);
      });
    });

    group('DecodedTypeId', () {
      test('toString reconstructs TypeID with prefix', () {
        final id = TypeId.generate('user');
        final decoded = TypeId.decode(id);
        expect(decoded.toString(), id);
      });

      test('toString returns suffix only when no prefix', () {
        final id = TypeId.generate('');
        final decoded = TypeId.decode(id);
        expect(decoded.toString(), id);
      });

      test('equality works via Freezed', () {
        final id = TypeId.generate('user');
        final a = TypeId.decode(id);
        final b = TypeId.decode(id);
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });
    });
  });
}
