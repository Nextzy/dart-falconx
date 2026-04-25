import 'package:dart_faltool/lib.dart';

/// Extension methods for String formatting and case conversions.
///
/// Provides case conversion utilities (camelCase, snake_case, PascalCase,
/// kebab-case), capitalization, and truncation.
extension FalconToolStringFormatExtension on String {
  // Case Conversions

  /// Converts the string to camelCase.
  ///
  /// Example:
  /// ```dart
  /// 'hello_world'.toCamelCase(); // 'helloWorld'
  /// 'HELLO-WORLD'.toCamelCase(); // 'helloWorld'
  /// ```
  String toCamelCase() {
    // Handle camelCase strings by inserting underscores before capitals
    final normalized = replaceAllMapped(
      RegExp('([a-z])([A-Z])'),
      (match) => '${match[1]}_${match[2]}',
    );

    final words = normalized.split(RegExp(r'[_\-\s]+'));
    if (words.isEmpty) return toLowerCase();

    return words.first.toLowerCase() +
        words.skip(1).map((w) => w.toLowerCase().capitalize).join();
  }

  /// Converts the string to snake_case.
  ///
  /// Example:
  /// ```dart
  /// 'helloWorld'.toSnakeCase(); // 'hello_world'
  /// 'HelloWorld'.toSnakeCase(); // 'hello_world'
  /// ```
  String toSnakeCase() {
    return replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceAll(RegExp('^_'), '').replaceAll(RegExp(r'[\s\-]+'), '_');
  }

  /// Converts the string to PascalCase.
  ///
  /// Example:
  /// ```dart
  /// 'hello_world'.toPascalCase(); // 'HelloWorld'
  /// 'hello-world'.toPascalCase(); // 'HelloWorld'
  /// ```
  String toPascalCase() {
    // Handle camelCase strings by inserting underscores before capitals
    final normalized = replaceAllMapped(
      RegExp('([a-z])([A-Z])'),
      (match) => '${match[1]}_${match[2]}',
    );

    final words = normalized.split(RegExp(r'[_\-\s]+'));
    return words.map((w) => w.toLowerCase().capitalize).join();
  }

  /// Converts the string to kebab-case.
  ///
  /// Example:
  /// ```dart
  /// 'helloWorld'.toKebabCase(); // 'hello-world'
  /// 'HelloWorld'.toKebabCase(); // 'hello-world'
  /// ```
  String toKebabCase() => toSnakeCase().replaceAll('_', '-');

  // String Formatting

  /// Capitalizes the first letter of each word.
  ///
  /// Example:
  /// ```dart
  /// 'hello world'.capitalizeWords(); // 'Hello World'
  /// ```
  String capitalizeWords() {
    return split(' ')
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  /// Truncates the string to the specified length.
  ///
  /// [length] - Maximum length of the result
  /// [ellipsis] - String to append if truncated (default: '...')
  ///
  /// Example:
  /// ```dart
  /// 'Hello World'.truncate(8); // 'Hello...'
  /// 'Hello World'.truncate(8, ellipsis: '~'); // 'Hello W~'
  /// ```
  String truncate(int? length, {String ellipsis = '...'}) {
    if (length == null) return this;
    if (this.length <= length) return this;
    if (length <= ellipsis.length) return ellipsis.substring(0, length);
    return substring(0, length - ellipsis.length) + ellipsis;
  }

  /// Masks a phone number, showing only the first [prefixLength] and
  /// last [suffixLength] digits.
  ///
  /// Strips non-digit characters before masking, then reconstructs
  /// with the mask applied.
  ///
  /// [prefixLength] - Number of leading digits to show (default: 2)
  /// [suffixLength] - Number of trailing digits to show (default: 2)
  /// [maskChar] - Character used for masking (default: '*')
  ///
  /// Example:
  /// ```dart
  /// '0891234567'.maskPhoneNumber(); // '08******67'
  /// '+66891234567'.maskPhoneNumber(); // '+66********67'
  /// '089-123-4567'.maskPhoneNumber(); // '08******67'
  /// '0891234567'.maskPhoneNumber(prefixLength: 3, suffixLength: 4); // '089***4567'
  /// ```
  String maskPhoneNumber({
    int prefixLength = 2,
    int suffixLength = 2,
    String maskChar = '*',
  }) {
    final digits = replaceAll(RegExp(r'\D'), '');
    final visible = prefixLength + suffixLength;
    if (digits.length <= visible) return this;

    final prefix = digits.substring(0, prefixLength);
    final suffix = digits.substring(digits.length - suffixLength);
    final masked = maskChar * (digits.length - visible);

    // Preserve leading '+' if present
    final plusPrefix = startsWith('+') ? '+' : '';
    return '$plusPrefix$prefix$masked$suffix';
  }

  /// Masks an email address, showing only the first [visibleChars]
  /// characters of the local part and the full domain.
  ///
  /// [visibleChars] - Number of leading characters to show (default: 2)
  /// [maskChar] - Character used for masking (default: '*')
  ///
  /// Example:
  /// ```dart
  /// 'user@example.com'.maskEmail(); // 'us**@example.com'
  /// 'john.doe@gmail.com'.maskEmail(); // 'jo******@gmail.com'
  /// 'a@example.com'.maskEmail(); // '*@example.com'
  /// 'ab@example.com'.maskEmail(visibleChars: 3); // 'ab@example.com'
  /// ```
  String maskEmail({
    int visibleChars = 2,
    String maskChar = '*',
  }) {
    final atIndex = indexOf('@');
    if (atIndex < 0) return this;

    final local = substring(0, atIndex);
    final domain = substring(atIndex);

    if (local.length <= visibleChars) {
      return '${maskChar * local.length}$domain';
    }

    final visible = local.substring(0, visibleChars);
    final masked = maskChar * (local.length - visibleChars);
    return '$visible$masked$domain';
  }

  /// Returns a copy of this string having its first letter uppercased, or the
  /// original string, if it's empty or already starts with an upper case
  /// letter.
  ///
  /// ```dart
  /// print('abcd'.capitalize()) // Abcd
  /// print('Abcd'.capitalize()) // Abcd
  /// ```
  String get capitalize {
    switch (length) {
      case 0:
        return this;
      case 1:
        return toUpperCase();
      default:
        return substring(0, 1).toUpperCase() + substring(1);
    }
  }
}

/// Extension methods for nullable String formatting.
extension FalconStringNullFormatExtension on String? {
  /// Safely capitalizes the string.
  String? get capitalize => this == null || this!.isEmpty
      ? this
      : this![0].toUpperCase() + this!.substring(1);

  /// Safely truncates the string.
  String? truncate(int? length, {String ellipsis = '...'}) =>
      this?.truncate(length, ellipsis: ellipsis);

  /// Safely masks a phone number.
  String? maskPhoneNumber({
    int prefixLength = 2,
    int suffixLength = 2,
    String maskChar = '*',
  }) => this?.maskPhoneNumber(
    prefixLength: prefixLength,
    suffixLength: suffixLength,
    maskChar: maskChar,
  );

  /// Safely masks an email address.
  String? maskEmail({
    int visibleChars = 2,
    String maskChar = '*',
  }) => this?.maskEmail(visibleChars: visibleChars, maskChar: maskChar);
}
