/// A collection of static helpers for common JSON serialization conversions.
class JsonSerializeUtil {
  /// Converts a [DateTime] to a Unix timestamp (seconds since epoch).
  static int dateTimeToUnix(DateTime dt) => dt.millisecondsSinceEpoch ~/ 1000;

  /// Converts a Unix timestamp (seconds) to a UTC [DateTime].
  static DateTime unixToDateTime(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

  /// Converts a [DateTime] to an ISO 8601 UTC string.
  static String dateTimeToIso(DateTime dt) => dt.toUtc().toIso8601String();

  /// Parses an ISO 8601 string and returns a UTC [DateTime].
  static DateTime isoToDateTime(String iso) => DateTime.parse(iso).toUtc();

  /// Converts a [BigInt] to its decimal string representation.
  static String bigIntToString(BigInt value) => value.toString();

  /// Parses a decimal string into a [BigInt].
  static BigInt stringToBigInt(String value) => BigInt.parse(value);
}
