import 'package:dart_faltool/lib.dart';

final _hhmmssPattern = RegExp(r'^(\d{1,2}):(\d{2}):(\d{2})$');

Never _throwFormatException(dynamic value, String targetType) {
  throw FormatException(
    "Cannot convert '$value' (${value.runtimeType}) to $targetType",
  );
}

// ── Private coerce functions (null on failure, never throw) ────────────────

String? _coerceToString(dynamic value) => value?.toString();

int? _coerceToInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  if (value is bool) return value ? 1 : 0;
  if (value is BigInt) return value.toInt();
  return null;
}

double? _coerceToDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  if (value is bool) return value ? 1.0 : 0.0;
  if (value is BigDecimal) return value.toDouble();
  return null;
}

num? _coerceToNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  if (value is bool) return value ? 1 : 0;
  return null;
}

bool? _coerceToBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return null;
}

BigInt? _coerceToBigInt(dynamic value) {
  if (value is BigInt) return value;
  if (value is int) return BigInt.from(value);
  if (value is String) return BigInt.tryParse(value);
  return null;
}

BigDecimal? _coerceToBigDecimal(dynamic value) {
  if (value is BigDecimal) return value;
  if (value is num) return BigDecimal.tryParse(value.toString());
  if (value is String) return BigDecimal.tryParse(value);
  return null;
}

DateTime? _coerceToDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Duration? _coerceToDuration(dynamic value) {
  if (value is Duration) return value;
  if (value is int) return Duration(milliseconds: value);
  if (value is String) {
    final asInt = int.tryParse(value);
    if (asInt != null) return Duration(milliseconds: asInt);
    final match = _hhmmssPattern.firstMatch(value);
    if (match != null) {
      return Duration(
        hours: int.parse(match.group(1)!),
        minutes: int.parse(match.group(2)!),
        seconds: int.parse(match.group(3)!),
      );
    }
  }
  return null;
}

List<dynamic>? _coerceToList(dynamic value) {
  if (value is List) return List<dynamic>.from(value);
  if (value is String) {
    try {
      final decoded = json.decode(value);
      if (decoded is List) return List<dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
  }
  return null;
}

Map<String, dynamic>? _coerceToMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String) {
    try {
      final decoded = json.decode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
  }
  return null;
}

// ── Extension ──────────────────────────────────────────────────────────────

/// Extension methods for type-coercion on dynamic values.
///
/// Each target type offers three access patterns: a throwing getter (`asT`),
/// a nullable getter (`asTOrNull`), and a default-value method (`asTOr`).
extension FalconDynamicTypeCastExtension on dynamic {
  // ── String ──────────────────────────────────────────────

  /// Coerces to [String], throwing [FormatException] if not possible.
  String get asString =>
      _coerceToString(this) ?? _throwFormatException(this, 'String');

  /// Coerces to [String], returning `null` if not possible.
  String? get asStringOrNull => _coerceToString(this);

  /// Coerces to [String], returning [defaultValue] if not possible.
  String asStringOr(String defaultValue) =>
      _coerceToString(this) ?? defaultValue;

  // ── int ─────────────────────────────────────────────────

  /// Coerces to [int], throwing [FormatException] if not possible.
  int get asInt => _coerceToInt(this) ?? _throwFormatException(this, 'int');

  /// Coerces to [int], returning `null` if not possible.
  int? get asIntOrNull => _coerceToInt(this);

  /// Coerces to [int], returning [defaultValue] if not possible.
  int asIntOr(int defaultValue) => _coerceToInt(this) ?? defaultValue;

  // ── double ──────────────────────────────────────────────

  /// Coerces to [double], throwing [FormatException] if not possible.
  double get asDouble =>
      _coerceToDouble(this) ?? _throwFormatException(this, 'double');

  /// Coerces to [double], returning `null` if not possible.
  double? get asDoubleOrNull => _coerceToDouble(this);

  /// Coerces to [double], returning [defaultValue] if not possible.
  double asDoubleOr(double defaultValue) =>
      _coerceToDouble(this) ?? defaultValue;

  // ── num ─────────────────────────────────────────────────

  /// Coerces to [num], throwing [FormatException] if not possible.
  num get asNum => _coerceToNum(this) ?? _throwFormatException(this, 'num');

  /// Coerces to [num], returning `null` if not possible.
  num? get asNumOrNull => _coerceToNum(this);

  /// Coerces to [num], returning [defaultValue] if not possible.
  num asNumOr(num defaultValue) => _coerceToNum(this) ?? defaultValue;

  // ── bool ────────────────────────────────────────────────

  /// Coerces to [bool], throwing [FormatException] if not possible.
  bool get asBool => _coerceToBool(this) ?? _throwFormatException(this, 'bool');

  /// Coerces to [bool], returning `null` if not possible.
  bool? get asBoolOrNull => _coerceToBool(this);

  // The default value matches the return type — positional is idiomatic here.
  /// Coerces to [bool], returning [defaultValue] if not possible.
  // ignore: avoid_positional_boolean_parameters
  bool asBoolOr(bool defaultValue) => _coerceToBool(this) ?? defaultValue;

  // ── BigInt ──────────────────────────────────────────────

  /// Coerces to [BigInt], throwing [FormatException] if not possible.
  BigInt get asBigInt =>
      _coerceToBigInt(this) ?? _throwFormatException(this, 'BigInt');

  /// Coerces to [BigInt], returning `null` if not possible.
  BigInt? get asBigIntOrNull => _coerceToBigInt(this);

  /// Coerces to [BigInt], returning [defaultValue] if not possible.
  BigInt asBigIntOr(BigInt defaultValue) =>
      _coerceToBigInt(this) ?? defaultValue;

  // ── BigDecimal ──────────────────────────────────────────

  /// Coerces to [BigDecimal], throwing [FormatException] if not possible.
  BigDecimal get asBigDecimal =>
      _coerceToBigDecimal(this) ?? _throwFormatException(this, 'BigDecimal');

  /// Coerces to [BigDecimal], returning `null` if not possible.
  BigDecimal? get asBigDecimalOrNull => _coerceToBigDecimal(this);

  /// Coerces to [BigDecimal], returning [defaultValue] if not possible.
  BigDecimal asBigDecimalOr(BigDecimal defaultValue) =>
      _coerceToBigDecimal(this) ?? defaultValue;

  // ── DateTime ────────────────────────────────────────────

  /// Coerces to [DateTime], throwing [FormatException] if not possible.
  DateTime get asDateTime =>
      _coerceToDateTime(this) ?? _throwFormatException(this, 'DateTime');

  /// Coerces to [DateTime], returning `null` if not possible.
  DateTime? get asDateTimeOrNull => _coerceToDateTime(this);

  /// Coerces to [DateTime], returning [defaultValue] if not possible.
  DateTime asDateTimeOr(DateTime defaultValue) =>
      _coerceToDateTime(this) ?? defaultValue;

  // ── Duration ────────────────────────────────────────────

  /// Coerces to [Duration], throwing [FormatException] if not possible.
  Duration get asDuration =>
      _coerceToDuration(this) ?? _throwFormatException(this, 'Duration');

  /// Coerces to [Duration], returning `null` if not possible.
  Duration? get asDurationOrNull => _coerceToDuration(this);

  /// Coerces to [Duration], returning [defaultValue] if not possible.
  Duration asDurationOr(Duration defaultValue) =>
      _coerceToDuration(this) ?? defaultValue;

  // ── List ────────────────────────────────────────────────

  /// Coerces to `List<dynamic>`, throwing [FormatException] if not possible.
  List<dynamic> get asList =>
      _coerceToList(this) ?? _throwFormatException(this, 'List');

  /// Coerces to `List<dynamic>`, returning `null` if not possible.
  List<dynamic>? get asListOrNull => _coerceToList(this);

  /// Coerces to `List<dynamic>`, returning [defaultValue] if not possible.
  List<dynamic> asListOr(List<dynamic> defaultValue) =>
      _coerceToList(this) ?? defaultValue;

  // ── Map ─────────────────────────────────────────────────

  /// Coerces to `Map<String, dynamic>`, throwing [FormatException]
  /// if not possible.
  Map<String, dynamic> get asMap =>
      _coerceToMap(this) ?? _throwFormatException(this, 'Map');

  /// Coerces to `Map<String, dynamic>`, returning `null` if not possible.
  Map<String, dynamic>? get asMapOrNull => _coerceToMap(this);

  /// Coerces to `Map<String, dynamic>`, returning [defaultValue]
  /// if not possible.
  Map<String, dynamic> asMapOr(Map<String, dynamic> defaultValue) =>
      _coerceToMap(this) ?? defaultValue;
}
