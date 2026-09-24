import 'dart:convert';

/// Value printed in place of a redacted header, query value, or user info.
const String redactedValue = 'REDACTED';

/// Whether [name] is in [names], ignoring case on both sides.
bool matchesName(String name, Set<String> names) {
  final lower = name.toLowerCase();
  return names.any((listed) => listed.toLowerCase() == lower);
}

/// Returns [uri] as a string with its user info and the values of the query
/// parameters named in [queryParameters] replaced by [redactedValue].
///
/// Other parameters keep their order and their encoding.
String redactUrl(Uri uri, Set<String> queryParameters) {
  if (uri.userInfo.isEmpty && (!uri.hasQuery || queryParameters.isEmpty)) {
    return uri.toString();
  }
  return uri
      .replace(
        userInfo: uri.userInfo.isEmpty ? null : '$redactedValue:$redactedValue',
        query: uri.hasQuery ? _redactQuery(uri.query, queryParameters) : null,
      )
      .toString();
}

/// A header value as the list of strings the semantic conventions require;
/// null has no value.
List<String> headerValues(Object? value) => switch (value) {
  null => const [],
  Iterable<Object?>() => [for (final item in value) '$item'],
  _ => ['$value'],
};

/// The logged value of header [name]: `["REDACTED"]` when [name] is in
/// [redactHeaders], else [headerValues] of [value].
List<String> logHeader(String name, Object? value, Set<String> redactHeaders) =>
    matchesName(name, redactHeaders)
    ? const [redactedValue]
    : headerValues(value);

/// Cuts [text] to at most [maxBytes] UTF-8 bytes at the last whole
/// character, and reports whether anything was cut.
({String text, bool truncated}) truncateUtf8(String text, int maxBytes) {
  final bytes = utf8.encode(text);
  if (bytes.length <= maxBytes) {
    return (text: text, truncated: false);
  }
  var end = maxBytes;
  // A byte of the form 10xxxxxx continues the character before it.
  while (end > 0 && bytes[end] & 0xC0 == 0x80) {
    end--;
  }
  return (text: utf8.decode(bytes.sublist(0, end)), truncated: true);
}

String _redactQuery(String query, Set<String> names) => query
    .split('&')
    .map((pair) {
      final equals = pair.indexOf('=');
      final rawName = equals < 0 ? pair : pair.substring(0, equals);
      return matchesName(Uri.decodeQueryComponent(rawName), names)
          ? '$rawName=$redactedValue'
          : pair;
    })
    .join('&');
