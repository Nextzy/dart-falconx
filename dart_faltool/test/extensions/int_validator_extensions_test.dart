import 'package:dart_faltool/src/src.dart';
import 'package:test/test.dart';

void main() {
  group('FalconToolIntValidatorExtension', () {
    group('isValidDayOfMonth', () {
      test('returns true for day 1 (lower bound)', () {
        expect(1.isValidDayOfMonth, true);
      });

      test('returns true for day 31 (upper bound)', () {
        expect(31.isValidDayOfMonth, true);
      });

      test('returns false for day 0', () {
        expect(0.isValidDayOfMonth, false);
      });

      test('returns false for day 32', () {
        expect(32.isValidDayOfMonth, false);
      });

      test('returns false for negative days', () {
        expect((-1).isValidDayOfMonth, false);
        expect((-31).isValidDayOfMonth, false);
      });
    });
  });
}
