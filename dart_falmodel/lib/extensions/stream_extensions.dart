import 'package:dart_falmodel/lib.dart';

extension FalconResultStreamExtensions<DATA> on Stream<Result<DATA>> {
  Stream<Result<S>> mapResult<S>(
    S Function(DATA data) mapData, [
    CommonException Function(CommonException exception)? mapException,
  ]) => map(
    (event) => event.resolve(
      (data) => Result.success(mapData(data)),
      (exception, stacktrace) => Result.failure(
        mapException?.call(exception) ?? exception,
      ),
    ),
  );

  Stream<Result<DATA>> mapResultException(
    CommonException Function(CommonException exception) mapException,
  ) => map(
    (event) => event.resolve(
      Result<DATA>.success,
      (exception, stacktrace) => Result.failure(
        mapException(exception),
      ),
    ),
  );
}
