import 'package:dart_faltool/lib.dart';

/// Extension methods for String manipulation and validation.
///
/// Provides comprehensive string utilities including conversions, validations,
/// formatting, and transformations.
extension FalconToolStringExtension on String {
  // Conversion Methods

  // toInt() and toIntOrNull() are now provided by dartx package.
  // Use: string.toInt() and string.toIntOrNull()

  /// Converts the string to an integer, returning 0 if parsing fails.
  ///
  /// Removes whitespace before parsing.
  ///
  /// Example:
  /// ```dart
  /// ' 123 '.toIntOrZero(); // 123
  /// 'abc'.toIntOrZero(); // 0
  /// ```
  int toIntOrZero() {
    final cleaned = removeWhiteSpace;
    if (cleaned.isEmpty) return 0;
    return int.tryParse(cleaned) ?? 0;
  }

  String hashSha256({int? length}) {
    // Generate hash using hashlib's SHA-256 implementation.
    final hash = sha256.string(this).hex();

    // Adjust length if specified
    if (length != null && length > 0) {
      if (length > hash.length) {
        // Pad with zeros if requested length is longer
        return hash.padRight(length, '0');
      }
      return hash.substring(0, length);
    }

    return hash;
  }

  /// Converts the string to a double, returning 0.0 if parsing fails.
  double toDoubleOrZero() => double.tryParse(this) ?? 0.0;

  /// Converts the string to a boolean value.
  ///
  /// Returns true for 'true' or '1', false for 'false' or '0'.
  /// Throws [UnsupportedError] for other values.
  ///
  /// Example:
  /// ```dart
  /// 'true'.toBoolean(); // true
  /// '1'.toBoolean(); // true
  /// 'false'.toBoolean(); // false
  /// 'maybe'.toBoolean(); // throws UnsupportedError
  /// ```
  bool toBoolean() {
    final lower = toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
    throw UnsupportedError('Cannot convert "$this" to boolean');
  }

  /// Converts the string to a boolean, returning null if conversion fails.
  ///
  /// Example:
  /// ```dart
  /// 'true'.toBooleanOrNull(); // true
  /// 'maybe'.toBooleanOrNull(); // null
  /// ```
  bool? toBooleanOrNull() {
    final lower = toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
    return null;
  }

  /// Parses the string as JSON and returns a Map.
  ///
  /// Throws [FormatException] if the string is not valid JSON.
  ///
  /// Example:
  /// ```dart
  /// '{"key": "value"}'.toMap(); // {'key': 'value'}
  /// ```
  Map<String, dynamic> toMap() {
    try {
      final decoded = json.decode(this);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw FormatException('JSON is not a Map: $this');
    } catch (e) {
      throw FormatException('Invalid JSON: $e');
    }
  }

  /// Parses the string as JSON and returns a Map, or null if parsing fails.
  Map<String, dynamic>? toMapOrNull() {
    try {
      final decoded = json.decode(this);
      return decoded is Map<String, dynamic> ? decoded : null;
      // Generic catch needed to return null on any parse failure.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  /// Parses the string as JSON and returns a Map,
  /// or empty map if parsing fails.
  Map<String, dynamic> toMapOrEmpty() => toMapOrNull() ?? {};



  /// Converts the string to bytes using UTF-8 encoding.
  Uint8List toBytes() => Uint8List.fromList(utf8.encode(this));

  // String Manipulation

  /// Reverses the string.
  ///
  /// This method is now provided by dartx package.
  /// Use: string.reversed
  ///
  /// Example:
  /// ```dart
  /// 'hello'.reversed; // 'olleh'
  /// ```

  /// Removes the protocol (http:// or https://) from the URL.
  ///
  /// Example:
  /// ```dart
  /// 'https://example.com'.removeHttp; // 'example.com'
  /// 'http://example.com'.removeHttp; // 'example.com'
  /// ```
  String get removeHttp => replaceFirst(RegExp('^https?://'), '');

  /// Returns true if the string contains the pattern (case-insensitive).
  ///
  /// Example:
  /// ```dart
  /// 'Hello World'.containsIgnoreCase('WORLD'); // true
  /// ```
  bool containsIgnoreCase(String pattern) {
    return toLowerCase().contains(pattern.toLowerCase());
  }

  /// Counts occurrences of a pattern in the string.
  ///
  /// Example:
  /// ```dart
  /// 'hello hello world'.countOccurrences('hello'); // 2
  /// ```
  int countOccurrences(String pattern) {
    if (pattern.isEmpty) return 0;
    return split(pattern).length - 1;
  }

  /// Escapes HTML special characters.
  ///
  /// Example:
  /// ```dart
  /// '<div>Hello</div>'.escapeHtml(); // '&lt;div&gt;Hello&lt;/div&gt;'
  /// ```
  String escapeHtml() {
    return replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Unescapes HTML special characters.
  ///
  /// Example:
  /// ```dart
  /// '&lt;div&gt;'.unescapeHtml(); // '<div>'
  /// ```
  String unescapeHtml() {
    return replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

}

/// Extension methods for nullable String manipulation and validation.
extension FalconStringNullExtension on String? {
  /// Returns the string or the provided default value if null.
  String or(String defaultValue) => this ?? defaultValue;

  /// Safely converts to integer with null safety.
  int? toIntOrNull() => this == null ? null : int.tryParse(this!);

  /// Safely converts to integer, returning 0 for null or invalid values.
  int toIntOrZero() => this?.toIntOrZero() ?? 0;

  /// Safely converts to double with null safety.
  double? toDoubleOrNull() => this == null ? null : double.tryParse(this!);

  /// Safely converts to double, returning 0.0 for null or invalid values.
  double toDoubleOrZero() => this?.toDoubleOrZero() ?? 0.0;

  /// Safely checks if the string is a valid URL.
  bool get isUrl => this?.isUrl ?? false;

  /// Safely checks if the string is a valid email.
  bool get isEmail => this?.isEmail ?? false;

  /// Safely checks if the string is valid JSON.
  bool get isJson => this?.isJson ?? false;

  /// Safely converts to boolean with null safety.
  bool? toBooleanOrNull() => this?.toBooleanOrNull();

  /// Safely converts to Map with null safety.
  Map<String, dynamic>? toMapOrNull() => this?.toMapOrNull();

  /// Safely converts to Map, returning empty map for null or invalid values.
  Map<String, dynamic> toMapOrEmpty() => this?.toMapOrEmpty() ?? {};

  /// Safely removes whitespace.
  String? get removeWhiteSpace => this?.removeWhiteSpace;

  /// Safely normalizes whitespace.
  String? get normalizeWhitespace => this?.normalizeWhitespace;

}
