import 'package:dart_faltool/lib.dart';

Future<Result<T>> runCatching<T>(
  Future<Result<T>> Function() execute,
) async {
  try {
    return await execute();
  } on CommonException catch (e) {
    return Result.failure(e);
  } on Object catch (e) {
    return Result.failure(e.toException());
  }
}
