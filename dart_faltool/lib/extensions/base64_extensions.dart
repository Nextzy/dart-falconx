import 'package:dart_falmodel/lib.dart';

extension FalconBase64StringExtension<K, V> on String {
  bool isBase64() {
    try {
      base64Decode(this);
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  /// Encodes the string to base64.
  ///
  /// Example:
  /// ```dart
  /// 'Hello'.toBase64(); // 'SGVsbG8='
  /// ```
  String toBase64() => base64Encode(utf8.encode(this));

  /// Decodes the string from base64.
  ///
  /// Throws [FormatException] if the string is not valid base64.
  ///
  /// Example:
  /// ```dart
  /// 'SGVsbG8='.fromBase64(); // 'Hello'
  /// ```
  String fromBase64ToString() =>
      utf8.decode(base64Decode(base64Url.normalize(this)));

  /// Decodes the string from base64 into raw bytes.
  ///
  /// Uses [base64Url.normalize] to handle both standard and URL-safe base64
  /// before decoding.
  ///
  /// Throws [FormatException] if the string is not valid base64.
  ///
  /// Example:
  /// ```dart
  /// 'SGVsbG8='.fromBase64ToBytes(); // [72, 101, 108, 108, 111]
  /// ```
  Uint8List fromBase64ToBytes() => base64Decode(base64Url.normalize(this));
}
