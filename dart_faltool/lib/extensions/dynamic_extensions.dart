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
}
