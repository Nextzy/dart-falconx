import 'package:dart_faltool/lib.dart';

Future<Result<T>> runCatching<T>(
  Future<Result<T>> Function() execute,
) async {
  try {
    return await execute();
  } on CommonException<Object> catch (e) {
    return Result.failure(e);
  } on Exception catch (e, st) {
    return Result.failure(
      CommonException<Object>(
        type: ErrorType.unexpected,
        developerMessage: e.toString(),
        originalException: e,
        stackTrace: st,
      ),
    );
  } on Object catch (e, st) {
    return Result.failure(
      CommonException<Object>(
        type: ErrorType.unexpected,
        developerMessage: e.toString(),
        originalException: e,
        stackTrace: st,
      ),
    );
  }
}

Future<Result<T>> runDomainCatching<T>(
  Future<Result<T>> Function() execute,
) async {
  try {
    return await execute();
  } on CommonException<Object> catch (e) {
    return Result.failure(e);
  } on Exception catch (e, st) {
    return Result.failure(
      DomainLayerException<Object>(
        type: ErrorType.unexpected,
        developerMessage: e.toString(),
        originalException: e,
        stackTrace: st,
      ),
    );
  } on Object catch (e, st) {
    return Result.failure(
      DomainLayerException<Object>(
        type: ErrorType.unexpected,
        developerMessage: e.toString(),
        originalException: e,
        stackTrace: st,
      ),
    );
  }
}

Future<Result<T>> runDataCatching<T>(
  Future<Result<T>> Function() execute,
) async {
  try {
    return await execute();
  } on DataLayerException<Object> catch (e) {
    return Result.failure(e);
  } on CommonException<Object> catch (e) {
    return Result.failure(
      DataLayerException<Object>(
        type: e.type,
        userMessage: e.userMessage,
        developerMessage: e.developerMessage,
        originalException: e.originalException,
        stackTrace: e.stackTrace,
      ),
    );
  } on Exception catch (e, st) {
    return Result.failure(
      DataLayerException<Object>(
        type: ErrorType.unexpected,
        developerMessage: e.toString(),
        originalException: e,
        stackTrace: st,
      ),
    );
  } on Object catch (e, st) {
    return Result.failure(
      DataLayerException<Object>(
        type: ErrorType.unexpected,
        developerMessage: e.toString(),
        originalException: e,
        stackTrace: st,
      ),
    );
  }
}
