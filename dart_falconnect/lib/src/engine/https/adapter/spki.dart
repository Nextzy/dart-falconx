import 'dart:convert';

import 'package:dart_faltool/dart_faltool.dart' show sha256;

/// The pin of the DER certificate [der]: `sha256/` and the base64
/// SHA-256 of its SubjectPublicKeyInfo element, tag and length included.
///
/// Throws [FormatException] when [der] is not an X.509 certificate this
/// reader understands.
String spkiPin(List<int> der) {
  final certificate = _Element.at(der, 0, 'Certificate');
  final tbs = _Element.at(der, certificate.contentStart, 'tbsCertificate');
  var field = _Element.at(der, tbs.contentStart, 'serialNumber');
  if (field.tag == _versionTag) {
    field = _Element.at(der, field.end, 'serialNumber');
  }
  // serialNumber, signature, issuer, validity, subject.
  for (var skipped = 0; skipped < 5; skipped++) {
    field = _Element.at(der, field.end, 'subjectPublicKeyInfo');
  }
  if (field.tag != _sequenceTag || field.end > tbs.end) {
    throw const FormatException('No subjectPublicKeyInfo in certificate');
  }
  final digest = sha256.convert(der.sublist(field.start, field.end)).bytes;
  return '$_pinPrefix${base64Encode(digest)}';
}

/// [pin] in the form [spkiPin] returns, `sha256/` and padded base64, or
/// null when it is not `sha256/` followed by base64 of 32 bytes.
String? canonicalPin(String pin) {
  if (!pin.startsWith(_pinPrefix)) return null;
  try {
    final digest = base64.normalize(pin.substring(_pinPrefix.length));
    return base64Decode(digest).length == 32 ? '$_pinPrefix$digest' : null;
  } on FormatException {
    return null;
  }
}

const _pinPrefix = 'sha256/';

const _sequenceTag = 0x30;
const _versionTag = 0xA0;

/// One DER element: its tag, and where its bytes start and end in the
/// certificate.
class _Element {
  const new(this.tag, this.start, this.contentStart, this.end);

  /// Reads the element at [start] of [der]. [name] names it in errors.
  ///
  /// Lengths are combined by multiplication, never a shift, so the result
  /// is the same on the web, where `int` shifts truncate to 32 bits.
  factory at(List<int> der, int start, String name) {
    if (start + 2 > der.length) {
      throw FormatException('Certificate ends before $name');
    }
    final tag = der[start];
    if (tag & 0x1F == 0x1F) {
      throw FormatException('Unsupported multi-byte tag at $name');
    }
    final first = der[start + 1];
    var length = first;
    var contentStart = start + 2;
    if (first >= 0x80) {
      final count = first & 0x7F;
      if (count == 0 || count > 3) {
        throw FormatException('Unsupported length form at $name');
      }
      if (contentStart + count > der.length) {
        throw FormatException('Certificate ends inside the length of $name');
      }
      length = 0;
      for (var i = 0; i < count; i++) {
        length = length * 256 + der[contentStart + i];
      }
      contentStart += count;
    }
    final end = contentStart + length;
    if (end > der.length) {
      throw FormatException('Certificate ends inside $name');
    }
    return _Element(tag, start, contentStart, end);
  }

  final int tag;
  final int start;
  final int contentStart;
  final int end;
}
