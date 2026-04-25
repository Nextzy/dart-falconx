import 'package:dart_faltool/lib.dart';

/// Executes [execute] and wraps any thrown exception into a [Result.failure].
///
/// [CommonException] instances are wrapped directly; all other exceptions are
/// converted via `toException()` before wrapping.
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
