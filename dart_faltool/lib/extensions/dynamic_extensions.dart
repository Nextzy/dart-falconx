import 'package:dart_faltool/lib.dart';

final _hhmmssPattern = RegExp(r'^(\d{1,2}):(\d{2}):(\d{2})$');

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

  // ── int ─────────────────────────────────────────────────

  int get asInt {
    final v = this;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      return int.tryParse(v) ?? _throwFormatException(v, 'int');
    }
    if (v is bool) return v ? 1 : 0;
    if (v is BigInt) return v.toInt();
    _throwFormatException(v, 'int');
  }

  int? get asIntOrNull {
    try {
      return asInt;
    } on FormatException {
      return null;
    }
  }

  int asIntOr(int defaultValue) {
    try {
      return asInt;
    } on FormatException {
      return defaultValue;
    }
  }

  // ── double ──────────────────────────────────────────────

  double get asDouble {
    final v = this;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v) ?? _throwFormatException(v, 'double');
    }
    if (v is bool) return v ? 1.0 : 0.0;
    if (v is BigDecimal) return v.toDouble();
    _throwFormatException(v, 'double');
  }

  double? get asDoubleOrNull {
    try {
      return asDouble;
    } on FormatException {
      return null;
    }
  }

  double asDoubleOr(double defaultValue) {
    try {
      return asDouble;
    } on FormatException {
      return defaultValue;
    }
  }

  // ── num ─────────────────────────────────────────────────

  num get asNum {
    final v = this;
    if (v is num) return v;
    if (v is String) {
      return num.tryParse(v) ?? _throwFormatException(v, 'num');
    }
    if (v is bool) return v ? 1 : 0;
    _throwFormatException(v, 'num');
  }

  num? get asNumOrNull {
    try {
      return asNum;
    } on FormatException {
      return null;
    }
  }

  num asNumOr(num defaultValue) {
    try {
      return asNum;
    } on FormatException {
      return defaultValue;
    }
  }

  // ── bool ────────────────────────────────────────────────

  bool get asBool {
    final v = this;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final lower = v.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
      _throwFormatException(v, 'bool');
    }
    _throwFormatException(v, 'bool');
  }

  bool? get asBoolOrNull {
    try {
      return asBool;
    } on FormatException {
      return null;
    }
  }

  // The default value matches the return type — positional is idiomatic here.
  // ignore: avoid_positional_boolean_parameters
  bool asBoolOr(bool defaultValue) {
    try {
      return asBool;
    } on FormatException {
      return defaultValue;
    }
  }

  // ── BigInt ──────────────────────────────────────────────

  BigInt get asBigInt {
    final v = this;
    if (v is BigInt) return v;
    if (v is int) return BigInt.from(v);
    if (v is String) {
      return BigInt.tryParse(v) ?? _throwFormatException(v, 'BigInt');
    }
    _throwFormatException(v, 'BigInt');
  }

  BigInt? get asBigIntOrNull {
    try {
      return asBigInt;
    } on FormatException {
      return null;
    }
  }

  BigInt asBigIntOr(BigInt defaultValue) {
    try {
      return asBigInt;
    } on FormatException {
      return defaultValue;
    }
  }

  // ── BigDecimal ──────────────────────────────────────────

  BigDecimal get asBigDecimal {
    final v = this;
    if (v is BigDecimal) return v;
    if (v is num) {
      return BigDecimal.tryParse(v.toString()) ??
          _throwFormatException(v, 'BigDecimal');
    }
    if (v is String) {
      return BigDecimal.tryParse(v) ?? _throwFormatException(v, 'BigDecimal');
    }
    _throwFormatException(v, 'BigDecimal');
  }

  BigDecimal? get asBigDecimalOrNull {
    try {
      return asBigDecimal;
    } on FormatException {
      return null;
    }
  }

  BigDecimal asBigDecimalOr(BigDecimal defaultValue) {
    try {
      return asBigDecimal;
    } on FormatException {
      return defaultValue;
    }
  }

  // ── DateTime ────────────────────────────────────────────

  DateTime get asDateTime {
    final v = this;
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      return DateTime.tryParse(v) ?? _throwFormatException(v, 'DateTime');
    }
    _throwFormatException(v, 'DateTime');
  }

  DateTime? get asDateTimeOrNull {
    try {
      return asDateTime;
    } on FormatException {
      return null;
    }
  }

  DateTime asDateTimeOr(DateTime defaultValue) {
    try {
      return asDateTime;
    } on FormatException {
      return defaultValue;
    }
  }

  // ── Duration ────────────────────────────────────────────

  Duration get asDuration {
    final v = this;
    if (v is Duration) return v;
    if (v is int) return Duration(milliseconds: v);
    if (v is String) {
      final asInt = int.tryParse(v);
      if (asInt != null) return Duration(milliseconds: asInt);
      final match = _hhmmssPattern.firstMatch(v);
      if (match != null) {
        return Duration(
          hours: int.parse(match.group(1)!),
          minutes: int.parse(match.group(2)!),
          seconds: int.parse(match.group(3)!),
        );
      }
      _throwFormatException(v, 'Duration');
    }
    _throwFormatException(v, 'Duration');
  }

  Duration? get asDurationOrNull {
    try {
      return asDuration;
    } on FormatException {
      return null;
    }
  }

  Duration asDurationOr(Duration defaultValue) {
    try {
      return asDuration;
    } on FormatException {
      return defaultValue;
    }
  }

  // ── List ────────────────────────────────────────────────

  List<dynamic> get asList {
    final v = this;
    if (v is List) return List<dynamic>.from(v);
    if (v is String) {
      final decoded = json.decode(v);
      if (decoded is List) return List<dynamic>.from(decoded);
    }
    _throwFormatException(v, 'List');
  }

  List<dynamic>? get asListOrNull {
    try {
      return asList;
    } on FormatException {
      return null;
    }
  }

  List<dynamic> asListOr(List<dynamic> defaultValue) {
    try {
      return asList;
    } on FormatException {
      return defaultValue;
    }
  }

  // ── Map ─────────────────────────────────────────────────

  Map<String, dynamic> get asMap {
    final v = this;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String) {
      final decoded = json.decode(v);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    _throwFormatException(v, 'Map');
  }

  Map<String, dynamic>? get asMapOrNull {
    try {
      return asMap;
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> asMapOr(Map<String, dynamic> defaultValue) {
    try {
      return asMap;
    } on FormatException {
      return defaultValue;
    }
  }
}
