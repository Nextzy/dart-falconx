import 'package:dart_faltool/dart_faltool.dart';
import 'package:test/test.dart';

void main() {
  const converter = DurationMillisecondsConverter();

  group('DurationMillisecondsConverter.toJson', () {
    test('returns the duration in milliseconds', () {
      expect(converter.toJson(const Duration(milliseconds: 5250)), 5250);
    });

    test('returns zero for Duration.zero', () {
      expect(converter.toJson(Duration.zero), 0);
    });

    test('truncates sub-millisecond precision', () {
      expect(
        converter.toJson(const Duration(milliseconds: 9, microseconds: 999)),
        9,
      );
    });

    test('keeps negative durations negative', () {
      expect(converter.toJson(const Duration(milliseconds: -40)), -40);
    });
  });

  group('DurationMillisecondsConverter.fromJson', () {
    test('builds a duration from milliseconds', () {
      expect(converter.fromJson(5250), const Duration(milliseconds: 5250));
    });

    test('zero maps to Duration.zero', () {
      expect(converter.fromJson(0), Duration.zero);
    });

    test('negative values map to negative durations', () {
      expect(converter.fromJson(-40), const Duration(milliseconds: -40));
    });
  });

  test('toJson and fromJson round-trip whole milliseconds', () {
    const original = Duration(milliseconds: 123456);
    expect(converter.fromJson(converter.toJson(original)), original);
  });
}
