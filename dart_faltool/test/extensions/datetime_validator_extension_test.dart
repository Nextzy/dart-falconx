import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

void main() {
  group('FalconDateTimeValidatorExtension', () {
    group('isValidDateRange', () {
      final start = DateTime(2026, 9, 24);
      final sameInstant = DateTime(2026, 9, 24);
      final later = DateTime(2026, 9, 25);

      test('returns true when this is strictly before to', () {
        expect(start.isValidDateRange(later), true);
      });

      test('returns false when this equals to', () {
        // Doc says "strictly before", so equal instants are not a valid range.
        expect(start.isValidDateRange(sameInstant), false);
      });

      test('returns false when this is after to', () {
        expect(later.isValidDateRange(start), false);
      });
    });
  });
}
