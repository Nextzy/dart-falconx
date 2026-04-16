import 'package:dart_faltool/lib.dart';

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

    final v7 = uuid.v7obj();
    final base32Encoded = Base32.encode(v7.toBytes());

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
      final uuidValue = UuidValue.fromByteList(base32Decoded);

      return DecodedTypeId(prefix: prefix, suffix: suffix, uuid: uuidValue);
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
