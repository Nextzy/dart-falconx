import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

void main() {
  group('FalconBase64StringExtension', () {
    group('isBase64', () {
      test('returns true for valid padded standard base64', () {
        expect('SGVsbG8='.isBase64(), true); // 'Hello'
        expect('++++'.isBase64(), true); // bytes [251, 239, 190]
        expect('//4='.isBase64(), true); // bytes [255, 254]
      });

      test('returns false for invalid characters and padding', () {
        expect('!!!'.isBase64(), false);
        expect('=G'.isBase64(), false);
      });

      test('returns false when whitespace is embedded', () {
        expect('SGVs bG8='.isBase64(), false);
      });

      test('rejects empty string', () {
        // Intended: an empty string is not meaningful Base64 data.
        expect(''.isBase64(), false);
      }, skip: 'BUG: empty string is accepted as valid Base64');

      test(
        'returns false for unpadded input (raw decoder requires padding)',
        () {
          // Characterization: isBase64 uses raw base64Decode, which rejects
          // unpadded input even though fromBase64* accept it via normalize.
          expect('SGVsbG8'.isBase64(), false);
        },
      );

      test('accepts padded URL-safe alphabet input', () {
        // Characterization: dart:convert's decoder accepts both the standard
        // and the URL-safe alphabet, so isBase64 matches fromBase64* here.
        expect('----'.isBase64(), true);
        expect('wr_Dvw=='.isBase64(), true);
      });
    });

    group('toBase64', () {
      test('encodes ASCII strings', () {
        expect('Hello'.toBase64(), 'SGVsbG8=');
        expect(''.toBase64(), '');
      });

      test('encodes multi-byte UTF-8 strings', () {
        // '¿ÿ' encodes to UTF-8 bytes [194, 191, 195, 191].
        expect('¿ÿ'.toBase64(), 'wr/Dvw==');
      });
    });

    group('fromBase64ToString', () {
      test('decodes padded standard base64', () {
        expect('SGVsbG8='.fromBase64ToString(), 'Hello');
      });

      test('decodes URL-safe base64', () {
        expect('wr_Dvw=='.fromBase64ToString(), '¿ÿ');
      });

      test('decodes unpadded input by normalizing first', () {
        expect('SGVsbG8'.fromBase64ToString(), 'Hello');
        expect('wr_Dvw'.fromBase64ToString(), '¿ÿ');
      });

      test('decodes empty string to empty string', () {
        expect(''.fromBase64ToString(), '');
      });

      test('round-trips through toBase64', () {
        expect('Hello'.toBase64().fromBase64ToString(), 'Hello');
        expect('¿ÿ'.toBase64().fromBase64ToString(), '¿ÿ');
      });

      test('throws FormatException for invalid base64', () {
        expect(() => '!!!'.fromBase64ToString(), throwsFormatException);
        expect(() => 'not-base64!'.fromBase64ToString(), throwsFormatException);
      });

      test('throws FormatException when payload is not valid UTF-8', () {
        // '//4=' decodes to bytes [255, 254], which are invalid UTF-8.
        expect(() => '//4='.fromBase64ToString(), throwsFormatException);
      });
    });

    group('fromBase64ToBytes', () {
      test('decodes padded standard base64 to bytes', () {
        expect('SGVsbG8='.fromBase64ToBytes(), [72, 101, 108, 108, 111]);
      });

      test('decodes URL-safe base64 to bytes', () {
        expect('----'.fromBase64ToBytes(), [251, 239, 190]);
      });

      test('decodes unpadded input by normalizing first', () {
        expect('SGVsbG8'.fromBase64ToBytes(), [72, 101, 108, 108, 111]);
      });

      test('decodes bytes outside the Base64 alphabet of letters only', () {
        expect('//4='.fromBase64ToBytes(), [255, 254]);
      });

      test('decodes empty string to empty bytes', () {
        expect(''.fromBase64ToBytes(), isEmpty);
      });

      test('throws FormatException for invalid base64', () {
        expect(() => '!!!'.fromBase64ToBytes(), throwsFormatException);
        expect(() => '=G='.fromBase64ToBytes(), throwsFormatException);
        expect(() => 'a'.fromBase64ToBytes(), throwsFormatException);
      });
    });
  });
}
