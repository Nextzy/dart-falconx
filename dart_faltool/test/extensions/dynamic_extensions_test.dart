import 'package:big_decimal/big_decimal.dart';
import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

void main() {
  group('FalconDynamicTypeCastExtension', () {
    // ── asString ──────────────────────────────────────────

    group('asString', () {
      test('converts non-null values to String via toString()', () {
        expect((42 as Object?).asString, '42');
        expect((3.14 as Object?).asString, '3.14');
        expect((true as Object?).asString, 'true');
        expect(('hello' as Object?).asString, 'hello');
      });

      test('throws FormatException for null', () {
        expect(() => (null as Object?).asString, throwsFormatException);
      });
    });

    group('asStringOrNull', () {
      test('converts non-null values to String', () {
        expect((42 as Object?).asStringOrNull, '42');
      });

      test('returns null for null', () {
        expect((null as Object?).asStringOrNull, isNull);
      });
    });

    group('asStringOr', () {
      test('converts non-null values to String', () {
        expect((42 as Object?).asStringOr('fallback'), '42');
      });

      test('returns default for null', () {
        expect((null as Object?).asStringOr('fallback'), 'fallback');
      });
    });

    // ── asInt ─────────────────────────────────────────────

    group('asInt', () {
      test('returns int directly', () {
        expect((42 as Object?).asInt, 42);
      });

      test('truncates double to int', () {
        expect((3.9 as Object?).asInt, 3);
      });

      test('parses int string', () {
        expect(('123' as Object?).asInt, 123);
      });

      test('converts bool to int', () {
        expect((true as Object?).asInt, 1);
        expect((false as Object?).asInt, 0);
      });

      test('converts BigInt to int', () {
        expect((BigInt.from(99) as Object?).asInt, 99);
      });

      test('throws FormatException for null', () {
        expect(() => (null as Object?).asInt, throwsFormatException);
      });

      test('throws FormatException for invalid string', () {
        expect(() => ('abc' as Object?).asInt, throwsFormatException);
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (Object() as Object?).asInt, throwsFormatException);
      });
    });

    group('asIntOrNull', () {
      test('returns value for valid input', () {
        expect((10 as Object?).asIntOrNull, 10);
      });

      test('returns null for null', () {
        expect((null as Object?).asIntOrNull, isNull);
      });

      test('returns null for invalid input', () {
        expect(('xyz' as Object?).asIntOrNull, isNull);
      });
    });

    group('asIntOr', () {
      test('returns value for valid input', () {
        expect((7 as Object?).asIntOr(0), 7);
      });

      test('returns default for null', () {
        expect((null as Object?).asIntOr(99), 99);
      });

      test('returns default for invalid input', () {
        expect(('bad' as Object?).asIntOr(99), 99);
      });
    });

    // ── asDouble ──────────────────────────────────────────

    group('asDouble', () {
      test('returns double directly', () {
        expect((3.14 as Object?).asDouble, 3.14);
      });

      test('converts int to double', () {
        expect((5 as Object?).asDouble, 5.0);
      });

      test('parses double string', () {
        expect(('2.5' as Object?).asDouble, 2.5);
      });

      test('converts bool to double', () {
        expect((true as Object?).asDouble, 1.0);
        expect((false as Object?).asDouble, 0.0);
      });

      test('converts BigDecimal to double', () {
        expect(
          (BigDecimal.parse('1.5') as Object?).asDouble,
          closeTo(1.5, 0.0001),
        );
      });

      test('throws FormatException for null', () {
        expect(() => (null as Object?).asDouble, throwsFormatException);
      });

      test('throws FormatException for invalid string', () {
        expect(() => ('abc' as Object?).asDouble, throwsFormatException);
      });
    });

    group('asDoubleOrNull', () {
      test('returns value for valid input', () {
        expect((1.1 as Object?).asDoubleOrNull, 1.1);
      });

      test('returns null for null', () {
        expect((null as Object?).asDoubleOrNull, isNull);
      });

      test('returns null for invalid input', () {
        expect(('xyz' as Object?).asDoubleOrNull, isNull);
      });
    });

    group('asDoubleOr', () {
      test('returns value for valid input', () {
        expect((2.2 as Object?).asDoubleOr(0.0), 2.2);
      });

      test('returns default for null', () {
        expect((null as Object?).asDoubleOr(9.9), 9.9);
      });

      test('returns default for invalid input', () {
        expect(('bad' as Object?).asDoubleOr(9.9), 9.9);
      });
    });

    // ── asNum ─────────────────────────────────────────────

    group('asNum', () {
      test('returns num directly', () {
        expect((42 as Object?).asNum, 42);
        expect((3.14 as Object?).asNum, 3.14);
      });

      test('parses num string', () {
        expect(('100' as Object?).asNum, 100);
        expect(('1.5' as Object?).asNum, 1.5);
      });

      test('converts bool to num', () {
        expect((true as Object?).asNum, 1);
        expect((false as Object?).asNum, 0);
      });

      test('throws FormatException for null', () {
        expect(() => (null as Object?).asNum, throwsFormatException);
      });

      test('throws FormatException for invalid string', () {
        expect(() => ('abc' as Object?).asNum, throwsFormatException);
      });
    });

    group('asNumOrNull', () {
      test('returns value for valid input', () {
        expect((5 as Object?).asNumOrNull, 5);
      });

      test('returns null for null', () {
        expect((null as Object?).asNumOrNull, isNull);
      });

      test('returns null for invalid input', () {
        expect(('xyz' as Object?).asNumOrNull, isNull);
      });
    });

    group('asNumOr', () {
      test('returns value for valid input', () {
        expect((3 as Object?).asNumOr(0), 3);
      });

      test('returns default for null', () {
        expect((null as Object?).asNumOr(42), 42);
      });

      test('returns default for invalid input', () {
        expect(('bad' as Object?).asNumOr(42), 42);
      });
    });

    // ── asBool ────────────────────────────────────────────

    group('asBool', () {
      test('returns bool directly', () {
        expect((true as Object?).asBool, isTrue);
        expect((false as Object?).asBool, isFalse);
      });

      test('converts string to bool (case-insensitive)', () {
        expect(('true' as Object?).asBool, isTrue);
        expect(('True' as Object?).asBool, isTrue);
        expect(('TRUE' as Object?).asBool, isTrue);
        expect(('1' as Object?).asBool, isTrue);
        expect(('false' as Object?).asBool, isFalse);
        expect(('False' as Object?).asBool, isFalse);
        expect(('FALSE' as Object?).asBool, isFalse);
        expect(('0' as Object?).asBool, isFalse);
      });

      test('converts num to bool', () {
        expect((1 as Object?).asBool, isTrue);
        expect((0 as Object?).asBool, isFalse);
        expect((3.14 as Object?).asBool, isTrue);
        expect((0.0 as Object?).asBool, isFalse);
      });

      test('throws FormatException for null', () {
        expect(() => (null as Object?).asBool, throwsFormatException);
      });

      test('throws FormatException for invalid string', () {
        expect(() => ('yes' as Object?).asBool, throwsFormatException);
        expect(() => ('no' as Object?).asBool, throwsFormatException);
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (Object() as Object?).asBool, throwsFormatException);
      });
    });

    group('asBoolOrNull', () {
      test('returns value for valid input', () {
        expect((true as Object?).asBoolOrNull, isTrue);
        expect(('false' as Object?).asBoolOrNull, isFalse);
      });

      test('returns null for null', () {
        expect((null as Object?).asBoolOrNull, isNull);
      });

      test('returns null for invalid input', () {
        expect(('maybe' as Object?).asBoolOrNull, isNull);
      });
    });

    group('asBoolOr', () {
      test('returns value for valid input', () {
        expect((true as Object?).asBoolOr(false), isTrue);
      });

      test('returns default for null', () {
        expect((null as Object?).asBoolOr(true), isTrue);
      });

      test('returns default for invalid input', () {
        expect(('bad' as Object?).asBoolOr(true), isTrue);
      });
    });
  });
}
