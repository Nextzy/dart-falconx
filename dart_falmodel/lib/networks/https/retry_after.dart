import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:dio/dio.dart' show Headers;
import 'package:http_parser/http_parser.dart' show parseHttpDate;

/// The longest delay [parseRetryAfter] returns, about 68 years. Clamping
/// to it keeps a huge delay-seconds value from overflowing [Duration].
const Duration _maxRetryAfter = Duration(seconds: 1 << 31);

final RegExp _delaySeconds = RegExp(r'^\d+$');

/// Converts a `Retry-After` header value into a delay.
///
/// Accepts delay-seconds (`120`) and the three HTTP-date formats RFC 9110
/// requires a recipient to accept. A date is measured from [serverDate],
/// the response's `Date` header, when given, otherwise from `clock.now()`;
/// a date in the past gives [Duration.zero]. Delay-seconds above 2^31
/// (about 68 years) are clamped to 2^31 seconds.
///
/// Returns null for a missing, empty, negative, decimal, or unreadable
/// value.
Duration? parseRetryAfter(String? value, {DateTime? serverDate}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  if (_delaySeconds.hasMatch(text)) {
    final seconds = int.tryParse(text);
    if (seconds == null || seconds > _maxRetryAfter.inSeconds) {
      return _maxRetryAfter;
    }
    return Duration(seconds: seconds);
  }
  final DateTime date;
  try {
    date = parseHttpDate(text);
  } on FormatException {
    return null;
  }
  final delay = date.difference(serverDate ?? clock.now());
  return delay.isNegative ? Duration.zero : delay;
}

/// Reads `Retry-After` from response headers.
extension FalconRetryAfterHeadersExtensions on Headers {
  /// The `Retry-After` delay of this response, or null when the header is
  /// missing or unreadable. A duplicated header uses its first value.
  ///
  /// An HTTP-date is measured from the response's `Date` header when it is
  /// readable, so a wrong client clock does not change the delay.
  Duration? get retryAfter {
    final values = this['retry-after'];
    if (values == null || values.isEmpty) {
      return null;
    }
    final value = values.first;
    if (!_delaySeconds.hasMatch(value.trim())) {
      // An HTTP-date needs the response's Date header as the reference
      // time; delay-seconds never does.
      DateTime? serverDate;
      final dates = this['date'];
      if (dates != null && dates.isNotEmpty) {
        try {
          serverDate = parseHttpDate(dates.first);
        } on FormatException {
          serverDate = null;
        }
      }
      return parseRetryAfter(value, serverDate: serverDate);
    }
    return parseRetryAfter(value);
  }
}
