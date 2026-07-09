import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

void main() {
  group('nowUtc', () {
    test('returns a UTC DateTime', () {
      expect(nowUtc.isUtc, isTrue);
    });

    test('is close to DateTime.now()', () {
      final diff = nowUtc.difference(DateTime.now().toUtc()).abs();
      expect(diff.inSeconds, lessThan(2));
    });
  });

  group('constantTimeEquals', () {
    test('returns true for identical strings', () {
      expect(constantTimeEquals('secret', 'secret'), isTrue);
      expect(constantTimeEquals('', ''), isTrue);
    });

    test('returns false for different content of same length', () {
      expect(constantTimeEquals('secret', 'secreT'), isFalse);
      expect(constantTimeEquals('abc', 'xyz'), isFalse);
    });

    test('returns false for different length', () {
      expect(constantTimeEquals('secret', 'secret1'), isFalse);
      expect(constantTimeEquals('a', ''), isFalse);
    });

    test('handles unicode code units', () {
      expect(constantTimeEquals('café', 'café'), isTrue);
      expect(constantTimeEquals('café', 'cafe'), isFalse);
    });
  });

  group('randomDelay', () {
    test('waits at least minMs', () async {
      final sw = Stopwatch()..start();
      await randomDelay(minMs: 20, maxMs: 40);
      sw.stop();
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(20));
    });

    test('asserts maxMs greater than minMs', () {
      expect(
        () => randomDelay(minMs: 100, maxMs: 100),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts non-negative minMs', () {
      expect(
        () => randomDelay(minMs: -1, maxMs: 10),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
