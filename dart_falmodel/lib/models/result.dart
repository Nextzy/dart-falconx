import 'package:dart_falmodel/lib.dart';

/// A type representing either a successful value or an exception.
///
/// Result is useful for error handling without throwing exceptions,
/// making error cases explicit in the type system.
class Result<T> extends Equatable {
  /// Creates a successful result.
  factory Result.success(T value) => Result._success(value);

  /// Creates a failed result.
  factory Result.failure(CommonException exception) =>
      Result._failure(exception);

  const Result._success(T value)
    : _value = value,
      _exception = null,
      _isSuccess = true;

  const Result._failure(CommonException exception)
    : _value = null,
      _exception = exception,
      _isSuccess = false;
  final T? _value;
  final CommonException? _exception;
  final bool _isSuccess;

  /// True if the result is successful.
  bool get isSuccess => _isSuccess;

  /// True if the result is a failure.
  bool get isFailure => !_isSuccess;

  /// Gets the value if successful, throws if failure.
  T get value {
    if (_isSuccess) return _value as T;
    throw StateError('Cannot get value from failed Result');
  }

  /// Gets the value or null if failed.
  T? get valueOrNull => _isSuccess ? _value : null;

  /// Gets the value or the provided default if failed.
  T valueOr(T defaultValue) => _isSuccess ? _value as T : defaultValue;

  /// Gets the error if failed, throws if successful.
  CommonException get exception {
    if (!_isSuccess) return _exception!;
    throw StateError('Cannot get error from successful Result');
  }

  /// Gets the exception or null if successful.
  CommonException? get exceptionOrNull => !_isSuccess ? _exception : null;

  /// Gets the stack trace if failed, null otherwise.
  StackTrace? get stackTraceOrNull => exceptionOrNull?.stackTrace;

  /// Transforms the value if successful.
  Result<R> map<R>(R Function(T value) transform) {
    if (_isSuccess) {
      try {
        return Result.success(transform(_value as T));
      } catch (error, stackTrace) {
        return Result.failure(
          error.toException(stackTrace: stackTrace),
        );
      }
    }
    return Result.failure(_exception!);
  }

  /// Transforms the error if failed.
  Result<T> mapException(
    CommonException Function(CommonException error) transform,
  ) {
    if (!_isSuccess) {
      return Result.failure(transform(_exception!));
    }
    return this;
  }

  /// Folds the result into a single value.
  R resolve<R>(
    R Function(T value) onSuccess,
    R Function(CommonException exception, StackTrace? stackTrace) onError,
  ) {
    if (_isSuccess) {
      return onSuccess(_value as T);
    }
    return onError(_exception!, stackTraceOrNull);
  }

  /// Executes a callback based on the result.
  void when(
    void Function(T value) onSuccess,
    void Function(CommonException exception, StackTrace? stackTrace) onError,
  ) {
    if (_isSuccess) {
      onSuccess(_value as T);
    } else {
      onError(_exception!, stackTraceOrNull);
    }
  }

  /// Chains Result operations (flatMap/bind).
  ///
  /// If successful, applies transform which returns a new Result.
  /// If failed, returns the failure.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    if (_isSuccess) {
      try {
        return transform(_value as T);
      } catch (error, stackTrace) {
        return Result.failure(
          error.toException(stackTrace: stackTrace),
        );
      }
    }
    return Result.failure(_exception!);
  }

  /// Recovers from a failure by providing a fallback value.
  Result<T> recover(T Function(CommonException exception) fallback) {
    if (!_isSuccess) {
      try {
        return Result.success(fallback(_exception!));
      } catch (error, stackTrace) {
        return Result.failure(
          error.toException(stackTrace: stackTrace),
        );
      }
    }
    return this;
  }

  /// Recovers from a failure by providing a fallback Result.
  Result<T> recoverWith(
    Result<T> Function(CommonException exception) fallback,
  ) {
    if (!_isSuccess) {
      try {
        return fallback(_exception!);
      } catch (error, stackTrace) {
        return Result.failure(
          error.toException(stackTrace: stackTrace),
        );
      }
    }
    return this;
  }

  /// Executes a side-effect callback if successful.
  void doOnSuccess(void Function(T value) callback) {
    if (_isSuccess) {
      callback(_value as T);
    }
  }

  /// Executes a side-effect callback if failed.
  void doOnFailure(void Function(CommonException exception) callback) {
    if (!_isSuccess) {
      callback(_exception!);
    }
  }

  /// Converts this Result to a UserFeedback.
  UserFeedback<T> toUserFeedback({
    FeedbackLevel level = FeedbackLevel.medium,
  }) {
    if (_isSuccess) {
      return Success<T>(
        data: _value as T,
        level: level,
      );
    }
    return Failure<T>.fromException(
      _exception as CommonException<T>?,
      level: level,
    );
  }

  /// Swaps success and failure.
  ///
  /// Success becomes Failure with a new exception,
  /// Failure becomes Success with the exception.
  Result<CommonException> swap({String? message}) {
    if (_isSuccess) {
      return Result.failure(
        CommonException(
          code: ErrorType.unexpected,
          userMessage: message ?? 'Unexpected success',
        ),
      );
    }
    return Result.success(_exception!);
  }

  @override
  List<Object?> get props => [_value, _exception, _isSuccess];

  @override
  String toString() {
    if (_isSuccess) {
      return 'Result.success($_value)';
    }
    return 'Result.failure($_exception)';
  }
}


