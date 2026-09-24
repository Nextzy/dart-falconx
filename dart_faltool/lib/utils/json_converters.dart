import 'package:dart_faltool/lib.dart';

/// Converts a [Duration] to and from its whole milliseconds as an `int`.
///
/// Sub-millisecond precision truncates on the way out, matching
/// `Duration.inMilliseconds`.
class DurationMillisecondsConverter implements JsonConverter<Duration, int> {
  /// Creates the converter.
  const new();

  @override
  Duration fromJson(int json) => Duration(milliseconds: json);

  @override
  int toJson(Duration object) => object.inMilliseconds;
}
