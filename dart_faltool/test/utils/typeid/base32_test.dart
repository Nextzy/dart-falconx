import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

void main() {
  group('Base32', () {
    group('encode', () {
      test('encodes 16-byte UUID to 26-char base32 string', () {
        // All zeros
        final zeros = Uint8List(16);
        expect(Base32.encode(zeros), '00000000000000000000000000');

        // All 0xFF (max value)
        final maxBytes = Uint8List.fromList(List.filled(16, 0xFF));
        expect(Base32.encode(maxBytes).length, 26);
      });

      test('throws ArgumentError for non-16-byte input', () {
        expect(() => Base32.encode(Uint8List(0)), throwsArgumentError);
        expect(() => Base32.encode(Uint8List(15)), throwsArgumentError);
        expect(() => Base32.encode(Uint8List(17)), throwsArgumentError);
      });

      test('encode and decode are inverse operations', () {
        final original = Uint8List.fromList([
          0x01, 0x89, 0x6b, 0x3a, 0x56, 0x80, //
          0x72, 0x1c, 0x10, 0x2e, 0x31, 0x5e,
          0x6f, 0xab, 0xc3, 0x40,
        ]);
        final encoded = Base32.encode(original);
        final decoded = Base32.decode(encoded);
        expect(decoded, original);
      });
    });

    group('decode', () {
      test('decodes 26-char base32 string to 16 bytes', () {
        final result = Base32.decode('00000000000000000000000000');
        expect(result, Uint8List(16));
      });

      test('throws FormatException for wrong length', () {
        expect(() => Base32.decode('short'), throwsFormatException);
        expect(
          () => Base32.decode('000000000000000000000000000'),
          throwsFormatException,
        );
      });

      test('throws FormatException for overflow (exceeds 128 bits)', () {
        expect(
          () => Base32.decode('80000000000000000000000000'),
          throwsFormatException,
        );
      });

      test('throws FormatException for invalid characters', () {
        expect(
          () => Base32.decode('l0000000000000000000000000'),
          throwsFormatException,
        );
      });
    });
  });
}
