import 'package:hashlib/random.dart';

/// Utility class for generating universally unique identifiers (UUIDs).
class UuidGenerator {
  /// Generates a random UUID version 4 string.
  static String getV4() => uuid.v4();
}
