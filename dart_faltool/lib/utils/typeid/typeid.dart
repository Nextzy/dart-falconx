import 'package:dart_faltool/lib.dart';
import 'package:hashlib/random.dart' as hl;

export 'base32.dart';
export 'decoded_typeid.dart';

/// A class to generate and decode TypeIDs per the [specification](https://github.com/jetify-com/typeid/tree/main/spec)
class TypeId {
  static const _separator = '_';

  /// Generates a TypeID with the given prefix. Provide an empty string for
  /// no prefix. Prefixes must be lowercase letters [a-z] and less than 64
  /// characters.
  static String generate(String prefix) {
    _checkPrefix(prefix);

    final v7String = hl.uuid.v7();
    final bytes = _uuidStringToBytes(v7String);
    final base32Encoded = Base32.encode(bytes);

    if (prefix.isEmpty) {
      return base32Encoded;
    } else {
      return '$prefix$_separator$base32Encoded';
    }
  }

  /// Decodes a TypeID into a [DecodedTypeId]. Throws [FormatException] if
  /// the provided TypeID is invalid.
  static DecodedTypeId decode(String typeid) {
    final parts = _splitLast(typeid, _separator);

    if (parts.length == 1) {
      parts.insert(0, '');
    } else if (parts.length == 2) {
      if (parts[0].isEmpty) {
        throw const FormatException(
          'Invalid typeid. separator cannot be present if prefix is empty',
        );
      }
    } else {
      throw const FormatException(
        'Invalid typeid. prefix cannot contain _',
      );
    }

    final prefix = parts[0];
    final suffix = parts[1];

    _checkPrefix(prefix);

    try {
      final base32Decoded = Base32.decode(suffix);
      final uuidString = _uuidBytesToString(base32Decoded);

      return DecodedTypeId(prefix: prefix, suffix: suffix, uuid: uuidString);
    } on FormatException {
      rethrow;
    }
  }

  /// Returns `true` if the given string is a valid TypeID.
  static bool isValid(String typeid) {
    try {
      decode(typeid);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// Decodes a TypeID, returning `null` if the input is invalid
  /// instead of throwing.
  static DecodedTypeId? decodeOrNull(String typeid) {
    try {
      return decode(typeid);
    } on FormatException {
      return null;
    }
  }

  static void _checkPrefix(String prefix) {
    if (prefix.length > 63) {
      throw const FormatException('Prefix too long');
    }

    if (prefix.startsWith(_separator) || prefix.endsWith(_separator)) {
      throw const FormatException('Prefix cannot start or end with _');
    }

    // ensure all characters fall within [a-z]
    final isValidChars = prefix.runes.every(
      (code) => code > 96 && code < 123,
    );

    if (!isValidChars) {
      throw const FormatException(
        'Prefix must only contain lowercase letters [a-z]',
      );
    }
  }

  static List<String> _splitLast(String input, String delimiter) {
    final lastIndex = input.lastIndexOf(delimiter);
    if (lastIndex == -1) {
      return [input];
    }
    final beforeLast = input.substring(0, lastIndex);
    final afterLast = input.substring(lastIndex + delimiter.length);
    return [beforeLast, afterLast];
  }
}

/// Parses a canonical 36-character UUID string (with dashes) into the
/// 16-byte representation expected by [Base32.encode].
Uint8List _uuidStringToBytes(String uuidString) {
  final hex = uuidString.replaceAll('-', '');
  if (hex.length != 32) {
    throw FormatException('Invalid UUID string: $uuidString');
  }
  final bytes = Uint8List(16);
  for (var i = 0; i < 16; i++) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}

/// Formats a 16-byte UUID into the canonical 8-4-4-4-12 lowercase hex string.
String _uuidBytesToString(Uint8List bytes) {
  if (bytes.length != 16) {
    throw FormatException(
      'UUID bytes must be exactly 16, got ${bytes.length}',
    );
  }
  final hex = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}
