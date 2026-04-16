// These imports will be used by numeric/BigDecimal conversion methods added in
// subsequent tasks; suppressed here to preserve the scaffold structure.
// ignore_for_file: unused_import
import 'package:big_decimal/big_decimal.dart';
import 'package:dart_faltool/lib.dart';

Never _throwFormatException(Object? value, String targetType) {
  throw FormatException(
    "Cannot convert '$value' (${value.runtimeType}) to $targetType",
  );
}

extension FalconDynamicTypeCastExtension on Object? {
  // ── String ──────────────────────────────────────────────

  String get asString {
    final v = this;
    if (v == null) _throwFormatException(v, 'String');
    return v.toString();
  }

  String? get asStringOrNull {
    final v = this;
    if (v == null) return null;
    return v.toString();
  }

  String asStringOr(String defaultValue) {
    final v = this;
    if (v == null) return defaultValue;
    return v.toString();
  }
}
