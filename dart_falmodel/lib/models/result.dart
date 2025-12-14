import 'package:dart_falmodel/lib.dart';

class Result<T> {
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

  CommonException? get exceptionOrNull => !_isSuccess ? _exception : null;

  /// Gets the stack trace if failed.
  StackTrace? get stackTrace => exception.stackTrace;

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
    return onError(_exception!, stackTrace);
  }

  /// Executes a callback based on the result.
  void when(
    void Function(T value) onSuccess,
    void Function(CommonException exception, StackTrace? stackTrace) onError,
  ) {
    if (_isSuccess) {
      onSuccess(_value as T);
    } else {
      onError(_exception!, stackTrace);
    }
  }
}
