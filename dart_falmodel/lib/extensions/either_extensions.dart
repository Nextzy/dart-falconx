import 'package:dart_falmodel/lib.dart';

/// Extensions on `Either<Failure, DATA>` for ergonomic failure/data access.
extension FalconEitherDataAndFailueExtensions<F extends Failure, DATA>
    on Either<F, DATA> {
  /// Folds the [Either] into a single value [B] by applying [data] on
  /// [Right] or [fail] on [Left].
  B resolve<B>(B Function(DATA data) data, B Function(F fail) fail) =>
      fold(fail, data);

  /// Returns `true` when this is a [Left] (failure) value.
  bool get isFailure => this is Left;

  /// Returns `true` when this is a [Right] (data) value.
  bool get hasData => this is Right;

  /// Returns the [Right] value, throwing if this is a [Left].
  DATA get data => fold(
    (l) {
      throw Exception('Either is fail.');
    },
    (r) => r,
  );

  /// Returns the [Right] value, or `null` if this is a [Left].
  DATA? get dataOrNull => fold(
    (l) => null,
    (r) => r,
  );

  /// Returns the [Left] failure, throwing if this is a [Right].
  F get failure => fold(
    (l) => l,
    (r) {
      throw Exception('Either has data not fail.');
    },
  );

  /// Returns the [Left] failure, or `null` if this is a [Right].
  F? get failureOrNull => fold(
    (l) => l,
    (r) => null,
  );
}

/// Extensions on `Either<Exception, DATA>` for ergonomic exception/data access.
extension FalconEitherDataAndExceptionExtensions<E extends Exception, DATA>
    on Either<E, DATA> {
  /// Folds the [Either] into a single value [B] by applying [data] on
  /// [Right] or [exception] on [Left].
  B resolve<B>(B Function(DATA data) data, B Function(E exception) exception) =>
      fold(exception, data);

  /// Returns `true` when this is a [Left] (exception) value.
  bool get isException => this is Left;

  /// Returns `true` when this is a [Right] (data) value.
  bool get hasData => this is Right;

  /// Returns the [Right] value, throwing if this is a [Left].
  DATA get data => fold(
    (l) {
      throw Exception('Either is fail.');
    },
    (r) => r,
  );

  /// Returns the [Right] value, or `null` if this is a [Left].
  DATA? get dataOrNull => fold(
    (l) => null,
    (r) => r,
  );

  /// Returns the [Left] exception, throwing if this is a [Right].
  E get exception => fold(
    (l) => l,
    (r) {
      throw Exception('Either has data not exception.');
    },
  );

  /// Returns the [Left] exception, or `null` if this is a [Right].
  E? get exceptionOrNull => fold(
    (l) => l,
    (r) => null,
  );
}

/// Extensions on `Future<Either<Failure, DATA>>` for asynchronous folding.
extension FalconEitherDataAndFailurFutureExtensions<F extends Failure, DATA>
    on Future<Either<F, DATA>> {
  /// Awaits the future and folds the [Either] into [B] using [data] or [fail].
  Future<B> resolve<B>(
    B Function(DATA data) data,
    B Function(F fail) fail,
  ) async => (await this).fold(fail, data);
}

/// Extensions on `Future<Either<Exception, DATA>>` for asynchronous folding.
extension FalconEitherDataAndExceptionFutureExtensions<
  E extends Exception,
  DATA
>
    on Future<Either<E, DATA>> {
  /// Awaits the future and folds the [Either] into [B]
  /// using [data] or [exception].
  Future<B> resolve<B>(
    B Function(DATA data) data,
    B Function(E exception) exception,
  ) async => (await this).fold(exception, data);
}
