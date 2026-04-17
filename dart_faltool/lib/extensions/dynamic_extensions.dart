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

extension FalconDynamicTypeCastExtension on dynamic {
  // ── String ──────────────────────────────────────────────

  String get asString =>
      _coerceToString(this) ?? _throwFormatException(this, 'String');

  String? get asStringOrNull => _coerceToString(this);

  String asStringOr(String defaultValue) =>
      _coerceToString(this) ?? defaultValue;

  // ── int ─────────────────────────────────────────────────

  int get asInt => _coerceToInt(this) ?? _throwFormatException(this, 'int');

  int? get asIntOrNull => _coerceToInt(this);

  int asIntOr(int defaultValue) => _coerceToInt(this) ?? defaultValue;

  // ── double ──────────────────────────────────────────────

  double get asDouble =>
      _coerceToDouble(this) ?? _throwFormatException(this, 'double');

  double? get asDoubleOrNull => _coerceToDouble(this);

  double asDoubleOr(double defaultValue) =>
      _coerceToDouble(this) ?? defaultValue;

  // ── num ─────────────────────────────────────────────────

  num get asNum => _coerceToNum(this) ?? _throwFormatException(this, 'num');

  num? get asNumOrNull => _coerceToNum(this);

  num asNumOr(num defaultValue) => _coerceToNum(this) ?? defaultValue;

  // ── bool ────────────────────────────────────────────────

  bool get asBool => _coerceToBool(this) ?? _throwFormatException(this, 'bool');

  bool? get asBoolOrNull => _coerceToBool(this);

  // The default value matches the return type — positional is idiomatic here.
  // ignore: avoid_positional_boolean_parameters
  bool asBoolOr(bool defaultValue) => _coerceToBool(this) ?? defaultValue;

  // ── BigInt ──────────────────────────────────────────────

  BigInt get asBigInt =>
      _coerceToBigInt(this) ?? _throwFormatException(this, 'BigInt');

  BigInt? get asBigIntOrNull => _coerceToBigInt(this);

  BigInt asBigIntOr(BigInt defaultValue) =>
      _coerceToBigInt(this) ?? defaultValue;

  // ── BigDecimal ──────────────────────────────────────────

  BigDecimal get asBigDecimal =>
      _coerceToBigDecimal(this) ?? _throwFormatException(this, 'BigDecimal');

  BigDecimal? get asBigDecimalOrNull => _coerceToBigDecimal(this);

  BigDecimal asBigDecimalOr(BigDecimal defaultValue) =>
      _coerceToBigDecimal(this) ?? defaultValue;

  // ── DateTime ────────────────────────────────────────────

  DateTime get asDateTime =>
      _coerceToDateTime(this) ?? _throwFormatException(this, 'DateTime');

  DateTime? get asDateTimeOrNull => _coerceToDateTime(this);

  DateTime asDateTimeOr(DateTime defaultValue) =>
      _coerceToDateTime(this) ?? defaultValue;

  // ── Duration ────────────────────────────────────────────

  Duration get asDuration =>
      _coerceToDuration(this) ?? _throwFormatException(this, 'Duration');

  Duration? get asDurationOrNull => _coerceToDuration(this);

  Duration asDurationOr(Duration defaultValue) =>
      _coerceToDuration(this) ?? defaultValue;

  // ── List ────────────────────────────────────────────────

  List<dynamic> get asList =>
      _coerceToList(this) ?? _throwFormatException(this, 'List');

  List<dynamic>? get asListOrNull => _coerceToList(this);

  List<dynamic> asListOr(List<dynamic> defaultValue) =>
      _coerceToList(this) ?? defaultValue;

  // ── Map ─────────────────────────────────────────────────

  Map<String, dynamic> get asMap =>
      _coerceToMap(this) ?? _throwFormatException(this, 'Map');

  Map<String, dynamic>? get asMapOrNull => _coerceToMap(this);

  Map<String, dynamic> asMapOr(Map<String, dynamic> defaultValue) =>
      _coerceToMap(this) ?? defaultValue;
}
