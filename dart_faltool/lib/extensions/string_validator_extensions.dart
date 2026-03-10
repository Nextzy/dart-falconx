import 'package:dart_faltool/lib.dart';

/// Extension methods for String manipulation and validation.
///
/// Provides comprehensive string utilities including conversions, validations,
/// formatting, and transformations.
extension FalconToolStringValidatorExtension on String {
  /// URL validation pattern that matches http and https URLs.
  static final _urlRegex = RegExp(
    r'^https?://[-A-Z0-9.]+(\:[0-9]+)?(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:,.;]*)?$',
    caseSensitive: false,
  );

  /// Email validation pattern (RFC 5322 simplified).
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _htmlTags = RegExp(
    '<[^>]*>',
    multiLine: true,
    caseSensitive: false,
  );

  static final RegExp _htmlEntities = RegExp(
    '&[^;]+;',
    multiLine: true,
  );

  static final _e164Regex = RegExp(r'^\+[1-9]\d{6,14}$');

  // Whitespace and Formatting

  /// Removes all whitespace characters from the string.
  ///
  /// Example:
  /// ```dart
  /// 'hello world'.removeWhiteSpace; // 'helloworld'
  /// '  tab\tspace\n '.removeWhiteSpace; // 'tabspace'
  /// ```
  String get removeWhiteSpace => replaceAll(RegExp(r'\s+'), '');

  String get removeHtmlTags => replaceAll(
    _htmlTags,
    '',
  ).replaceAll(_htmlEntities, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Removes leading and trailing whitespace and collapses internal whitespace.
  ///
  /// Example:
  /// ```dart
  /// '  hello   world  '.normalizeWhitespace; // 'hello world'
  /// ```
  String get normalizeWhitespace => trim().replaceAll(RegExp(r'\s+'), ' ');

  // isBlank and isNotBlank are now provided by dartx package.
  // Use: string.isBlank and string.isNotBlank

  // Validation Methods

  /// Returns true if the string is a valid URL.
  ///
  /// Validates against http and https protocols.
  ///
  /// Example:
  /// ```dart
  /// 'https://example.com'.isUrl; // true
  /// 'not a url'.isUrl; // false
  /// ```
  bool get isUrl => _urlRegex.hasMatch(this);

  /// Returns true if the string is not a valid URL.
  bool get isNotUrl => !isUrl;

  /// Returns true if the string is a valid email address.
  ///
  /// Example:
  /// ```dart
  /// 'user@example.com'.isEmail; // true
  /// 'invalid.email'.isEmail; // false
  /// ```
  bool get isEmail => _emailRegex.hasMatch(this);

  /// Returns true if the string is not a valid email address.
  bool get isNotEmail => !isEmail;

  /// Returns true if the string contains only numeric characters.
  ///
  /// Allows optional leading minus sign and decimal point.
  ///
  /// Example:
  /// ```dart
  /// '123'.isNumeric; // true
  /// '-45.67'.isNumeric; // true
  /// 'abc123'.isNumeric; // false
  /// ```
  bool get isNumeric => RegExp(r'^-?\d*\.?\d+$').hasMatch(this);

  /// Returns true if the string is valid JSON.
  ///
  /// Example:
  /// ```dart
  /// '{"key": "value"}'.isJson; // true
  /// 'not json'.isJson; // false
  /// ```
  bool get isJson {
    try {
      json.decode(this);
      return true;
      // Generic catch needed to return false on any JSON parse failure.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the string is not valid JSON.
  bool get isNotJson => !isJson;

  bool get isPhoneNumber => _e164Regex.hasMatch(this);

  bool get isNotPhoneNumber => !isPhoneNumber;
}
