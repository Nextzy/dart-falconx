import 'package:dart_faltool/lib.dart';

Future<Result<T>> runCatching<T>(
  Future<Result<T>> Function() execute,
) async {
  try {
    return await execute();
  } on CommonException catch (e) {
    return Result.failure(e);
  } on Exception catch (e, st) {
    return Result.failure(
      CommonException(
        type: DefaultErrorType.unexpected,
        developerMessage: e.toString(),
        originalException: e,
        stackTrace: st,
      ),
    );
  } on Object catch (e, st) {
    return Result.failure(
      CommonException(
        type: DefaultErrorType.unexpected,
        developerMessage: e.toString(),
        originalException: e,
        stackTrace: st,
      ),
    );
  }
}

