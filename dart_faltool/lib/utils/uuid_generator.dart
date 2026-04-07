import 'package:uuid/uuid.dart';

const uuid = Uuid();

class UuidGenerator {
  static String getV4() => uuid.v4();
}
