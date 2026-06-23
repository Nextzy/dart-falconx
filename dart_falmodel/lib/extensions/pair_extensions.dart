import 'package:dart_falmodel/lib.dart';

/// Extensions on `Pair<Failure?, DATA>` for convenient failure/data access.
extension FalconPairDataAndFailureExtensions<F extends Failure?, DATA>
    on Pair<F, DATA> {
  /// Returns `true` when both the failure and the data are `null`.
  bool get isEmpty => first == null && second == null;

  /// Returns `true` when at least one of failure or data is non-`null`.
  bool get isNotEmpty => !isEmpty;

  /// Returns `true` when the failure slot is non-`null`.
  bool get hasFailure => first != null;

  /// Returns `true` when the data slot is non-`null`.
  bool get hasData => second != null;

  /// The data value held in the second slot of this pair.
  DATA get data => second;

  /// The failure held in the first slot of this pair, or `null`.
  Failure? get failure => first;
}

/// Extensions on `Pair<Exception?, DATA>` for convenient exception/data access.
extension FalconPairDataAndExceptionExtensions<E extends Exception?, DATA>
    on Pair<E, DATA> {
  /// Returns `true` when both the exception and the data are `null`.
  bool get isEmpty => first == null && second == null;

  /// Returns `true` when at least one of exception or data is non-`null`.
  bool get isNotEmpty => !isEmpty;

  /// Returns `true` when the exception slot is non-`null`.
  bool get hasException => first != null;

  /// Returns `true` when the data slot is non-`null`.
  bool get hasData => second != null;

  /// The data value held in the second slot of this pair.
  DATA get data => second;

  /// The exception held in the first slot of this pair, or `null`.
  Exception? get exception => first;
}
