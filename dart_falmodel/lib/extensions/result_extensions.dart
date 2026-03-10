import 'package:dart_falmodel/lib.dart';

extension FalconFutureResultDataExtensions<DATA> on Future<DATA> {
  /// Converts a `Future<DATA>` to `Future<Result<DATA>>`.
  ///
  /// Catches any errors and wraps them in a `Result.failure`.
  /// Optionally transforms caught exceptions using [mapException].
  Future<Result<DATA>> toResult([
    CommonException<Object> Function(CommonException<Object> exception)?
        mapException,
  ]) {
    return then(Result<DATA>.success).catchError(
      (Object e, StackTrace stackTrace) {
        final exception = e.toException(stackTrace: stackTrace);
        return Result<DATA>.failure(
          mapException != null ? mapException(exception) : exception,
        );
      },
    );
  }
}

extension FalconFutureResultExtensions<DATA> on Future<Result<DATA>> {
  /// Transforms the data inside the Result if successful.
  ///
  /// Optionally transforms the exception if the Result is a failure.
  Future<Result<R>> mapResult<R>(
    R Function(DATA data) transform, [
    CommonException<Object> Function(CommonException<Object> exception)?
        mapException,
  ]) {
    return then((result) {
      final mapped = result.map(transform);
      if (mapException != null && mapped.isFailure) {
        return mapped.mapException(mapException);
      }
      return mapped;
    }).catchError((Object error, StackTrace stackTrace) {
      final exception = error.toException(stackTrace: stackTrace);
      return Result<R>.failure(
        mapException != null ? mapException(exception) : exception,
      );
    });
  }

  /// Chains Result operations (flatMap).
  ///
  /// If the current Result is successful, applies the transform function
  /// which returns a new `Future<Result>`.
  Future<Result<R>> flatMapResult<R>(
    Future<Result<R>> Function(DATA data) transform,
  ) {
    return then((result) {
      if (result.isSuccess) {
        return transform(result.value);
      }
      return Future.value(Result<R>.failure(result.exception));
    });
  }

  /// Transforms the exception if the Result is a failure.
  Future<Result<DATA>> mapResultException(
    CommonException<Object> Function(CommonException<Object> exception)
        transform,
  ) {
    return then((result) => result.mapException(transform));
  }

  /// Executes a callback if the Result is successful.
  ///
  /// Returns the original `Future<Result>` for chaining.
  Future<Result<DATA>> onSuccess(void Function(DATA data) callback) {
    return then((result) {
      if (result.isSuccess) {
        callback(result.value);
      }
      return result;
    });
  }

  /// Executes a callback if the Result is a failure.
  ///
  /// Returns the original `Future<Result>` for chaining.
  Future<Result<DATA>> onFailure(
    void Function(CommonException<Object> exception) callback,
  ) {
    return then((result) {
      if (result.isFailure) {
        callback(result.exception);
      }
      return result;
    });
  }

  /// Unwraps the Result, returning the value if successful
  /// or the default value if failed.
  Future<DATA> getOrElse(DATA defaultValue) {
    return then((result) => result.valueOr(defaultValue));
  }

  /// Unwraps the Result, returning the value if successful
  /// or computing a default value if failed.
  Future<DATA> getOrElseAsync(Future<DATA> Function() defaultValue) {
    return then((result) {
      if (result.isSuccess) {
        return Future.value(result.value);
      }
      return defaultValue();
    });
  }

  /// Recovers from a failure by providing a fallback value.
  Future<Result<DATA>> recover(
    DATA Function(CommonException<Object> exception) fallback,
  ) {
    return then((result) {
      if (result.isFailure) {
        return Result.success(fallback(result.exception));
      }
      return result;
    });
  }

  /// Recovers from a failure by providing a fallback `Future<Result>`.
  Future<Result<DATA>> recoverWith(
    Future<Result<DATA>> Function(CommonException<Object> exception) fallback,
  ) {
    return then((result) {
      if (result.isFailure) {
        return fallback(result.exception);
      }
      return Future.value(result);
    });
  }

  /// Executes callbacks based on whether the Result is successful or failed.
  Future<void> whenAsync(
    Future<void> Function(DATA data) onSuccess,
    Future<void> Function(CommonException<Object> exception) onFailure,
  ) {
    return then((result) {
      if (result.isSuccess) {
        return onSuccess(result.value);
      }
      return onFailure(result.exception);
    });
  }

  /// Converts `Future<Result<DATA>>` to `Future<DATA>`, throwing if failed.
  Future<DATA> unwrap() {
    return then((result) {
      if (result.isSuccess) {
        return result.value;
      }
      throw result.exception;
    });
  }
}

extension FalconStreamResultDataExtensions<DATA> on Stream<DATA> {
  /// Converts a `Stream<DATA>` to `Stream<Result<DATA>>`.
  ///
  /// Each emitted value becomes a success Result.
  /// Errors are caught and converted to failure Results.
  /// Optionally transforms caught exceptions using [mapException].
  Stream<Result<DATA>> toResult([
    CommonException<Object> Function(CommonException<Object> exception)?
        mapException,
  ]) {
    return map(Result<DATA>.success).handleError(
      (Object error, StackTrace stackTrace) {
        final exception = error.toException(stackTrace: stackTrace);
        return Result<DATA>.failure(
          mapException != null ? mapException(exception) : exception,
        );
      },
    );
  }
}

extension FalconStreamResultExtensions<DATA> on Stream<Result<DATA>> {
  /// Transforms the data inside each Result if successful.
  ///
  /// Optionally transforms the exception if the Result is a failure.
  Stream<Result<R>> mapResult<R>(
    R Function(DATA data) transform, [
    CommonException<Object> Function(CommonException<Object> exception)?
        mapException,
  ]) {
    return map((result) {
      final mapped = result.map(transform);
      if (mapException != null && mapped.isFailure) {
        return mapped.mapException(mapException);
      }
      return mapped;
    }).handleError((Object error, StackTrace stackTrace) {
      final exception = error.toException(stackTrace: stackTrace);
      return Result<R>.failure(
        mapException != null ? mapException(exception) : exception,
      );
    });
  }

  /// Chains Result operations (flatMap).
  ///
  /// If a Result is successful, applies transform which returns a new Result.
  Stream<Result<R>> flatMapResult<R>(
    Result<R> Function(DATA data) transform,
  ) {
    return map((result) => result.flatMap(transform));
  }

  /// Transforms exceptions in failed Results.
  Stream<Result<DATA>> mapResultException(
    CommonException<Object> Function(CommonException<Object> exception)
        transform,
  ) {
    return map((result) => result.mapException(transform));
  }

  /// Filters to only successful Results.
  Stream<Result<DATA>> whereSuccess() {
    return where((result) => result.isSuccess);
  }

  /// Filters to only failed Results.
  Stream<Result<DATA>> whereFailure() {
    return where((result) => result.isFailure);
  }

  /// Maps to a stream of successful values only, discarding failures.
  Stream<DATA> successOnly() {
    return where((result) => result.isSuccess)
        .map((result) => result.value);
  }

  /// Maps to a stream of exceptions only, discarding successes.
  Stream<CommonException<Object>> failureOnly() {
    return where((result) => result.isFailure)
        .map((result) => result.exception);
  }

  /// Executes a callback for each successful Result.
  Stream<Result<DATA>> doOnSuccess(void Function(DATA data) callback) {
    return map((result) {
      result.doOnSuccess(callback);
      return result;
    });
  }

  /// Executes a callback for each failed Result.
  Stream<Result<DATA>> doOnFailure(
    void Function(CommonException<Object> exception) callback,
  ) {
    return map((result) {
      result.doOnFailure(callback);
      return result;
    });
  }

  /// Recovers from failures by providing a fallback value.
  Stream<Result<DATA>> recover(
    DATA Function(CommonException<Object> exception) fallback,
  ) {
    return map((result) => result.recover(fallback));
  }

  /// Recovers from failures by providing a fallback Result.
  Stream<Result<DATA>> recoverWith(
    Result<DATA> Function(CommonException<Object> exception) fallback,
  ) {
    return map((result) => result.recoverWith(fallback));
  }

  /// Unwraps Results, emitting only values and throwing on first failure.
  Stream<DATA> unwrap() {
    return map((result) {
      if (result.isSuccess) {
        return result.value;
      }
      throw result.exception;
    });
  }

  /// Unwraps Results with a default value for failures.
  Stream<DATA> getOrElse(DATA defaultValue) {
    return map((result) => result.valueOr(defaultValue));
  }

  /// Unwraps Results, computing default values for failures.
  Stream<DATA> getOrElseCompute(
    DATA Function(CommonException<Object> exception) defaultValue,
  ) {
    return map((result) {
      if (result.isSuccess) {
        return result.value;
      }
      return defaultValue(result.exception);
    });
  }


  /// Partitions the stream into successes and failures.
  ///
  /// Returns a record with two streams: (successes, failures).
  (Stream<DATA>, Stream<CommonException<Object>>) partition() {
    final broadcast = asBroadcastStream();
    return (
      broadcast.successOnly(),
      broadcast.failureOnly(),
    );
  }

  /// Collects all Results into a single Result containing a list.
  ///
  /// Returns success with all values if all Results are successful,
  /// otherwise returns the first failure encountered.
  Future<Result<List<DATA>>> collect() async {
    final results = <DATA>[];

    await for (final result in this) {
      if (result.isFailure) {
        return Result.failure(result.exception);
      }
      results.add(result.value);
    }

    return Result.success(results);
  }

  /// Collects all successful Results, ignoring failures.
  Future<List<DATA>> collectSuccesses() async {
    final results = <DATA>[];

    await for (final result in this) {
      if (result.isSuccess) {
        results.add(result.value);
      }
    }

    return results;
  }

  /// Collects all failures, ignoring successes.
  Future<List<CommonException<Object>>> collectFailures() async {
    final failures = <CommonException<Object>>[];

    await for (final result in this) {
      if (result.isFailure) {
        failures.add(result.exception);
      }
    }

    return failures;
  }
}
