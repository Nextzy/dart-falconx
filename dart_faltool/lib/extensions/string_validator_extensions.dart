import 'package:dart_faltool/lib.dart';

/// A collection of pre-compiled regular expressions used for string validation.
class FormatRegex {
  /// URL validation pattern that matches http and https URLs.
  static final url = RegExp(
    r'^https?://[-A-Z0-9.]+(\:[0-9]+)?(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:,.;]*)?$',
    caseSensitive: false,
  );

  /// Email validation pattern (RFC 5322 simplified).
  static final email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// HTML tag pattern that matches any `<tag>` element.
  static final RegExp html = RegExp(
    '<[^>]*>',
    multiLine: true,
    caseSensitive: false,
  );

  /// HTML entity pattern that matches encoded entities such as `&amp;`.
  static final RegExp htmlEntities = RegExp(
    '&[^;]+;',
    multiLine: true,
  );

  /// E.164 international phone number validation pattern.
  static final e164 = RegExp(r'^\+[1-9]\d{6,14}$');

  /// HH:mm format (24-hour UTC).
  static final timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
}

/// Extension methods for String manipulation and validation.
///
/// Provides comprehensive string utilities including conversions, validations,
/// formatting, and transformations.
extension FalconToolStringValidatorExtension on String {
  // Whitespace and Formatting

  /// Removes all whitespace characters from the string.
  ///
  /// Example:
  /// ```dart
  /// 'hello world'.removeWhiteSpace; // 'helloworld'
  /// '  tab\tspace\n '.removeWhiteSpace; // 'tabspace'
  /// ```
  String get removeWhiteSpace => replaceAll(RegExp(r'\s+'), '');

  /// Strips all HTML tags and entities from the string, collapsing
  /// extra whitespace.
  String get removeHtmlTags =>
      replaceAll(
            FormatRegex.html,
            '',
          )
          .replaceAll(FormatRegex.htmlEntities, ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

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
  bool get isUrl => FormatRegex.url.hasMatch(this);

  /// Returns true if the string is not a valid URL.
  bool get isNotUrl => !isUrl;

  /// Returns true if the string is a valid email address.
  ///
  /// Example:
  /// ```dart
  /// 'user@example.com'.isEmail; // true
  /// 'invalid.email'.isEmail; // false
  /// ```
  bool get isEmail => FormatRegex.email.hasMatch(this);

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

  /// Returns `true` if the string is a valid E.164 phone number.
  bool get isPhoneNumber => FormatRegex.e164.hasMatch(this);

  /// Returns `true` if the string is not a valid E.164 phone number.
  bool get isNotPhoneNumber => !isPhoneNumber;

  /// Returns `true` if the string is a valid 24-hour time in `HH:mm` format.
  ///
  /// Example:
  /// ```dart
  /// '14:30'.isTime; // true
  /// '23:59'.isTime; // true
  /// '24:00'.isTime; // false
  /// '9:05'.isTime; // false (hour must be zero-padded)
  /// ```
  bool get isTime => FormatRegex.timePattern.hasMatch(this);

  /// Returns `true` if the string is not a valid 24-hour `HH:mm` time.
  bool get isNotTime => !isTime;
}
