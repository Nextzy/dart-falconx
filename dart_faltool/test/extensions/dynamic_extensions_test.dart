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
  });
}
