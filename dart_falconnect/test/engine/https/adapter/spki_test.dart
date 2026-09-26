import 'dart:convert';

import 'package:dart_falconnect/src/engine/https/adapter/spki.dart';
import 'package:dart_faltool/dart_faltool.dart' show sha256;
import 'package:test/test.dart';

import '../../../fixtures/localhost_certificate.dart';

/// One DER element with a short-form length.
List<int> _tlv(int tag, List<int> content) => [tag, content.length, ...content];

void main() {
  test('the fixture pin matches the openssl value', () {
    expect(spkiPin(base64Decode(localhostCertificateDer)), localhostPin);
  });

  test('reads a certificate without the version element', () {
    final spki = _tlv(0x30, _tlv(0x03, [0, 1, 2, 3]));
    final der = _tlv(0x30, [
      ..._tlv(0x30, [
        ..._tlv(0x02, [1]), // serialNumber
        ..._tlv(0x30, []), // signature
        ..._tlv(0x30, []), // issuer
        ..._tlv(0x30, []), // validity
        ..._tlv(0x30, []), // subject
        ...spki,
      ]),
    ]);

    expect(spkiPin(der), 'sha256/${base64Encode(sha256.convert(spki).bytes)}');
  });

  test('rejects a truncated certificate', () {
    final der = base64Decode(localhostCertificateDer);

    expect(() => spkiPin(der.sublist(0, 100)), throwsFormatException);
  });

  test('rejects a length of 4 bytes', () {
    expect(() => spkiPin([0x30, 0x84, 0, 0, 0, 1, 0]), throwsFormatException);
  });

  test('canonicalPin pads a bare pin and rejects a short one', () {
    expect(canonicalPin(localhostPin.replaceAll('=', '')), localhostPin);
    expect(canonicalPin(localhostPin), localhostPin);
    expect(canonicalPin('sha256/AAAA'), isNull);
    expect(canonicalPin('sha1/${localhostPin.substring(7)}'), isNull);
  });

  test('rejects empty input', () {
    expect(() => spkiPin(const []), throwsFormatException);
  });

  test('rejects a certificate whose fields end before the key', () {
    final der = _tlv(0x30, [
      ..._tlv(0x30, [
        ..._tlv(0x02, [1]),
      ]),
    ]);

    expect(() => spkiPin(der), throwsFormatException);
  });
}
