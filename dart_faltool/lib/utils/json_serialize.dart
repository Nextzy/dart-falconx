
class JsonSerializeUtil {
  static int dateTimeToUnix(DateTime dt) => dt.millisecondsSinceEpoch ~/ 1000;

  static DateTime unixToDateTime(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

  static String dateTimeToIso(DateTime dt) => dt.toUtc().toIso8601String();

  static DateTime isoToDateTime(String iso) => DateTime.parse(iso).toUtc();

  static String bigIntToString(BigInt value) => value.toString();

  static BigInt stringToBigInt(String value) => BigInt.parse(value);
}
