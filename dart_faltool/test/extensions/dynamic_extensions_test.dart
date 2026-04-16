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

    // ── asBigInt ──────────────────────────────────────────

    group('asBigInt', () {
      test('returns BigInt directly', () {
        expect((BigInt.from(42) as Object?).asBigInt, BigInt.from(42));
      });

      test('converts int to BigInt', () {
        expect((100 as Object?).asBigInt, BigInt.from(100));
      });

      test('parses BigInt string', () {
        expect(
          ('12345678901234567890' as Object?).asBigInt,
          BigInt.parse('12345678901234567890'),
        );
      });

      test('throws FormatException for null', () {
        expect(() => (null as Object?).asBigInt, throwsFormatException);
      });

      test('throws FormatException for invalid string', () {
        expect(() => ('abc' as Object?).asBigInt, throwsFormatException);
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (3.14 as Object?).asBigInt, throwsFormatException);
      });
    });

    group('asBigIntOrNull', () {
      test('returns value for valid input', () {
        expect((BigInt.from(7) as Object?).asBigIntOrNull, BigInt.from(7));
      });

      test('returns null for null', () {
        expect((null as Object?).asBigIntOrNull, isNull);
      });

      test('returns null for invalid input', () {
        expect(('xyz' as Object?).asBigIntOrNull, isNull);
      });
    });

    group('asBigIntOr', () {
      test('returns value for valid input', () {
        expect((5 as Object?).asBigIntOr(BigInt.zero), BigInt.from(5));
      });

      test('returns default for null', () {
        expect((null as Object?).asBigIntOr(BigInt.from(99)), BigInt.from(99));
      });

      test('returns default for invalid input', () {
        expect(('bad' as Object?).asBigIntOr(BigInt.from(99)), BigInt.from(99));
      });
    });

    // ── asBigDecimal ──────────────────────────────────────

    group('asBigDecimal', () {
      test('returns BigDecimal directly', () {
        final bd = BigDecimal.parse('1.5');
        expect((bd as Object?).asBigDecimal, bd);
      });

      test('converts int to BigDecimal', () {
        expect((10 as Object?).asBigDecimal, BigDecimal.parse('10'));
      });

      test('converts double to BigDecimal', () {
        expect((2.5 as Object?).asBigDecimal, BigDecimal.parse('2.5'));
      });

      test('parses BigDecimal string', () {
        expect(
          ('3.14159' as Object?).asBigDecimal,
          BigDecimal.parse('3.14159'),
        );
      });

      test('throws FormatException for null', () {
        expect(() => (null as Object?).asBigDecimal, throwsFormatException);
      });

      test('throws FormatException for invalid string', () {
        expect(() => ('abc' as Object?).asBigDecimal, throwsFormatException);
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (true as Object?).asBigDecimal, throwsFormatException);
      });
    });

    group('asBigDecimalOrNull', () {
      test('returns value for valid input', () {
        expect(
          (BigDecimal.parse('1.1') as Object?).asBigDecimalOrNull,
          BigDecimal.parse('1.1'),
        );
      });

      test('returns null for null', () {
        expect((null as Object?).asBigDecimalOrNull, isNull);
      });

      test('returns null for invalid input', () {
        expect(('xyz' as Object?).asBigDecimalOrNull, isNull);
      });
    });

    group('asBigDecimalOr', () {
      test('returns value for valid input', () {
        expect(
          ('9.99' as Object?).asBigDecimalOr(BigDecimal.zero),
          BigDecimal.parse('9.99'),
        );
      });

      test('returns default for null', () {
        final fallback = BigDecimal.parse('0.0');
        expect((null as Object?).asBigDecimalOr(fallback), fallback);
      });

      test('returns default for invalid input', () {
        final fallback = BigDecimal.parse('0.0');
        expect(('bad' as Object?).asBigDecimalOr(fallback), fallback);
      });
    });

    // ── asDateTime ────────────────────────────────────────

    group('asDateTime', () {
      test('returns DateTime directly', () {
        final dt = DateTime(2024, 1, 15);
        expect((dt as Object?).asDateTime, dt);
      });

      test('converts int (epoch ms) to DateTime', () {
        final dt = DateTime.fromMillisecondsSinceEpoch(1000000);
        expect((1000000 as Object?).asDateTime, dt);
      });

      test('parses ISO 8601 string', () {
        expect(
          ('2024-06-01T12:00:00.000Z' as Object?).asDateTime,
          DateTime.parse('2024-06-01T12:00:00.000Z'),
        );
      });

      test('parses date-only string', () {
        expect(('2024-01-15' as Object?).asDateTime, DateTime(2024, 1, 15));
      });

      test('throws FormatException for null', () {
        expect(() => (null as Object?).asDateTime, throwsFormatException);
      });

      test('throws FormatException for invalid string', () {
        expect(
          () => ('not-a-date' as Object?).asDateTime,
          throwsFormatException,
        );
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (true as Object?).asDateTime, throwsFormatException);
      });
    });

    group('asDateTimeOrNull', () {
      test('returns value for valid input', () {
        expect(
          ('2024-01-01' as Object?).asDateTimeOrNull,
          DateTime(2024, 1, 1),
        );
      });

      test('returns null for null', () {
        expect((null as Object?).asDateTimeOrNull, isNull);
      });

      test('returns null for invalid input', () {
        expect(('not-a-date' as Object?).asDateTimeOrNull, isNull);
      });
    });

    group('asDateTimeOr', () {
      test('returns value for valid input', () {
        final fallback = DateTime(2000);
        expect(
          ('2024-01-01' as Object?).asDateTimeOr(fallback),
          DateTime(2024, 1, 1),
        );
      });

      test('returns default for null', () {
        final fallback = DateTime(2000);
        expect((null as Object?).asDateTimeOr(fallback), fallback);
      });

      test('returns default for invalid input', () {
        final fallback = DateTime(2000);
        expect(('bad' as Object?).asDateTimeOr(fallback), fallback);
      });
    });

    // ── asDuration ────────────────────────────────────────

    group('asDuration', () {
      test('returns Duration directly', () {
        const dur = Duration(seconds: 30);
        expect((dur as Object?).asDuration, dur);
      });

      test('converts int to Duration (milliseconds)', () {
        expect(
          (5000 as Object?).asDuration,
          const Duration(milliseconds: 5000),
        );
      });

      test('parses numeric string as milliseconds', () {
        expect(
          ('3000' as Object?).asDuration,
          const Duration(milliseconds: 3000),
        );
      });

      test('parses HH:MM:SS string', () {
        expect(
          ('1:30:45' as Object?).asDuration,
          const Duration(hours: 1, minutes: 30, seconds: 45),
        );
      });

      test('parses HH:MM:SS with zero-padded hours', () {
        expect(
          ('00:02:30' as Object?).asDuration,
          const Duration(minutes: 2, seconds: 30),
        );
      });

      test('throws FormatException for null', () {
        expect(() => (null as Object?).asDuration, throwsFormatException);
      });

      test('throws FormatException for invalid string', () {
        expect(
          () => ('not-a-duration' as Object?).asDuration,
          throwsFormatException,
        );
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (true as Object?).asDuration, throwsFormatException);
      });
    });

    group('asDurationOrNull', () {
      test('returns value for valid input', () {
        expect(
          ('1:00:00' as Object?).asDurationOrNull,
          const Duration(hours: 1),
        );
      });

      test('returns null for null', () {
        expect((null as Object?).asDurationOrNull, isNull);
      });

      test('returns null for invalid input', () {
        expect(('bad-duration' as Object?).asDurationOrNull, isNull);
      });
    });

    group('asDurationOr', () {
      test('returns value for valid input', () {
        const fallback = Duration(seconds: 1);
        expect(
          (1000 as Object?).asDurationOr(fallback),
          const Duration(milliseconds: 1000),
        );
      });

      test('returns default for null', () {
        const fallback = Duration(seconds: 5);
        expect((null as Object?).asDurationOr(fallback), fallback);
      });

      test('returns default for invalid input', () {
        const fallback = Duration(seconds: 5);
        expect(('bad' as Object?).asDurationOr(fallback), fallback);
      });
    });

    // ── asList ────────────────────────────────────────────

    group('asList', () {
      test('returns List<dynamic> from a List', () {
        expect((([1, 2, 3]) as Object?).asList, [1, 2, 3]);
      });

      test('parses JSON array string', () {
        expect(('[1, "two", 3]' as Object?).asList, [1, 'two', 3]);
      });

      test('throws FormatException for null', () {
        expect(() => (null as Object?).asList, throwsFormatException);
      });

      test('throws FormatException for JSON string that is not a list', () {
        expect(() => ('{"a":1}' as Object?).asList, throwsFormatException);
      });

      test('throws FormatException for non-JSON string', () {
        expect(() => ('not-json' as Object?).asList, throwsA(anything));
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (42 as Object?).asList, throwsFormatException);
      });
    });

    group('asListOrNull', () {
      test('returns value for valid input', () {
        expect(([1, 2] as Object?).asListOrNull, [1, 2]);
      });

      test('returns null for null', () {
        expect((null as Object?).asListOrNull, isNull);
      });

      test('returns null for invalid input', () {
        expect((99 as Object?).asListOrNull, isNull);
      });
    });

    group('asListOr', () {
      test('returns value for valid input', () {
        expect(([1, 2] as Object?).asListOr([]), [1, 2]);
      });

      test('returns default for null', () {
        expect((null as Object?).asListOr([0]), [0]);
      });

      test('returns default for invalid input', () {
        expect((99 as Object?).asListOr([0]), [0]);
      });
    });

    // ── asMap ─────────────────────────────────────────────

    group('asMap', () {
      test('returns Map<String, dynamic> from a Map', () {
        expect(({'a': 1, 'b': 2} as Object?).asMap, {'a': 1, 'b': 2});
      });

      test('parses JSON object string', () {
        expect(('{"x": 1, "y": "hello"}' as Object?).asMap, {
          'x': 1,
          'y': 'hello',
        });
      });

      test('throws FormatException for null', () {
        expect(() => (null as Object?).asMap, throwsFormatException);
      });

      test('throws FormatException for JSON string that is not a map', () {
        expect(() => ('[1,2,3]' as Object?).asMap, throwsFormatException);
      });

      test('throws FormatException for non-JSON string', () {
        expect(() => ('not-json' as Object?).asMap, throwsA(anything));
      });

      test('throws FormatException for unsupported type', () {
        expect(() => (42 as Object?).asMap, throwsFormatException);
      });
    });

    group('asMapOrNull', () {
      test('returns value for valid input', () {
        expect(({'key': 'val'} as Object?).asMapOrNull, {'key': 'val'});
      });

      test('returns null for null', () {
        expect((null as Object?).asMapOrNull, isNull);
      });

      test('returns null for invalid input', () {
        expect((99 as Object?).asMapOrNull, isNull);
      });
    });

    group('asMapOr', () {
      test('returns value for valid input', () {
        expect(({'a': 1} as Object?).asMapOr({}), {'a': 1});
      });

      test('returns default for null', () {
        expect((null as Object?).asMapOr({'default': true}), {'default': true});
      });

      test('returns default for invalid input', () {
        expect((99 as Object?).asMapOr({'default': true}), {'default': true});
      });
    });
  });
}
