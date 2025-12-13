import 'package:dart_falmodel/lib.dart';

extension FalconEitherStreamDataAndFailureExtensions<F extends Failure, DATA>
    on Stream<Either<F, DATA>> {
  Stream<Either<F, S>> mapEither<S>(
    S Function(DATA data) mapData, [
    F Function(F failue)? mapFailure,
  ]) => map(
    (event) => event.resolve(
      (data) => Right(mapData(data)),
      (fail) => Left(mapFailure?.call(fail) ?? fail),
    ),
  );

  Stream<Either<F, DATA>> mapEitherFailure<S>(
    F Function(F failue) mapFailure,
  ) => map(
    (event) => event.resolve(
      Right.new,
      (fail) => Left(mapFailure(fail)),
    ),
  );
}

extension FalconResultStreamExtensions<DATA> on Stream<Result<DATA>> {
  Stream<Result<S>> mapResult<S>(
    S Function(DATA data) mapData, [
    Object Function(Object failue)? mapFailure,
  ]) => map(
    (event) => event.resolve(
      (data) => Result.success(mapData(data)),
      (fail, stacktrace) => Result.failure(
        (mapFailure?.call(fail) ?? fail).toException(
          stackTrace: stacktrace,
        ),
      ),
    ),
  );

  Stream<Result<DATA>> mapResultFailure<S>(
    Object Function(Object failue) mapFailure,
  ) => map(
    (event) => event.resolve(
      Result.success,
      (fail, stacktrace) => Result.failure(
        mapFailure(fail).toException(
          stackTrace: stacktrace,
        ),
      ),
    ),
  );
}

extension FalconStreamDataAndExceptionExtensions<E extends Exception, DATA>
    on Stream<Either<E, DATA>> {
  Stream<Either<E, S>> mapEitherData<S>(
    S Function(DATA data) mapData,
  ) => map(
    (event) => event.resolve(
      (data) => Right(mapData(data)),
      Left.new,
    ),
  );

  Stream<Either<Failure, DATA>> mapEitherFailure(
    Failure Function(E exception) mapException,
  ) => map(
    (event) => event.resolve(
      Right.new,
      (exception) => Left(mapException(exception)),
    ),
  );

  Stream<Either<Failure, DATA>> mapEitherExceptionToFailure() => map(
    (event) => event.resolve(
      Right.new,
      (exception) => Left(
        Failure.fromException(
          exception.toException(),
        ),
      ),
    ),
  );

  Stream<Either<Failure, S>> mapEitherWithFailure<S>(
    S Function(DATA data) mapData, [
    Failure Function(E exception)? mapException,
  ]) => map(
    (event) => event.resolve(
      (data) => Right(mapData(data)),
      (exception) => Left(
        mapException?.call(exception) ??
            Failure.fromException(exception.toException()),
      ),
    ),
  );
}
