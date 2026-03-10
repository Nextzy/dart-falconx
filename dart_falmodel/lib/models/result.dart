import 'package:dart_falmodel/lib.dart';

/// A type representing either a successful value or an exception.
///
/// Result is useful for exception handling without throwing exceptions,
/// making exception cases explicit in the type system.
class Result<T> extends Equatable {
  /// Creates a successful result.
  factory Result.success(T value) => Result._success(value);

  /// Creates a failed result.
  factory Result.failure(CommonException<Object> exception) =>
      Result._failure(exception);

  factory Result.dataFailure({
    required Object code,
    String? userMessage,
    String? developerMessage,
    Object? originalException,
    StackTrace? stackTrace,
  }) => Result._failure(
    DataLayerException<Object>(
      type: code,
      userMessage: userMessage,
      developerMessage: developerMessage,
      originalException: originalException,
      stackTrace: stackTrace,
    ),
  );

  factory Result.domainFailure({
    required Object code,
    String? userMessage,
    String? developerMessage,
    Object? originalException,
    StackTrace? stackTrace,
  }) => Result._failure(
    DomainLayerException<Object>(
      type: code,
      userMessage: userMessage,
      developerMessage: developerMessage,
      originalException: originalException,
      stackTrace: stackTrace,
    ),
  );

  const Result._success(T value)
    : _value = value,
      _exception = null,
      _isSuccess = true;

  const Result._failure(CommonException<Object> exception)
    : _value = null,
      _exception = exception,
      _isSuccess = false;
  final T? _value;
  final CommonException<Object>? _exception;
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
  T valueOr(T defaultValue) =>
      _isSuccess ? _value ?? defaultValue : defaultValue;

  /// Gets the exception if failed, throws if successful.
  CommonException<Object> get exception {
    if (!_isSuccess) return _exception!;
    throw StateError('Cannot get exception from successful Result');
  }

  /// Gets the exception or null if successful.
  CommonException<Object>? get exceptionOrNull =>
      !_isSuccess ? _exception : null;

  /// Gets the stack trace if failed, null otherwise.
  StackTrace? get stackTraceOrNull => exceptionOrNull?.stackTrace;

  /// Transforms the value if successful.
  Result<R> map<R>(R Function(T value) transform) {
    if (_isSuccess) {
      try {
        return Result.success(transform(_value as T));
        // Need to catch all errors from user-provided transform
        // ignore: avoid_catches_without_on_clauses
      } catch (error, stackTrace) {
        return Result.failure(
          exception.toException(stackTrace: stackTrace),
        );
      }
    }
    return Result.failure(_exception!);
  }

  /// Transforms the exception if failed.
  Result<T> mapException(
    CommonException<Object> Function(
      CommonException<Object> exception,
    ) transform,
  ) {
    if (!_isSuccess) {
      return Result.failure(transform(_exception!));
    }
    return this;
  }

  /// Folds the result into a single value.
  R resolve<R>(
    R Function(T value) onSuccess,
    R Function(CommonException<Object> exception, StackTrace? stackTrace)
        onError,
  ) {
    if (_isSuccess) {
      return onSuccess(_value as T);
    }
    return onError(_exception!, stackTraceOrNull);
  }

  /// Executes a callback based on the result.
  void when(
    void Function(T value) onSuccess,
    void Function(CommonException<Object> exception, StackTrace? stackTrace)
        onError,
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
        // Need to catch all errors from user-provided transform
        // ignore: avoid_catches_without_on_clauses
      } catch (error, stackTrace) {
        return Result.failure(
          exception.toException(stackTrace: stackTrace),
        );
      }
    }
    return Result.failure(_exception!);
  }

  /// Recovers from a failure by providing a fallback value.
  Result<T> recover(
    T Function(CommonException<Object> exception) fallback,
  ) {
    if (!_isSuccess) {
      try {
        return Result.success(fallback(_exception!));
        // Need to catch all errors from user-provided transform
        // ignore: avoid_catches_without_on_clauses
      } catch (error, stackTrace) {
        return Result.failure(
          exception.toException(stackTrace: stackTrace),
        );
      }
    }
    return this;
  }

  /// Recovers from a failure by providing a fallback Result.
  Result<T> recoverWith(
    Result<T> Function(CommonException<Object> exception) fallback,
  ) {
    if (!_isSuccess) {
      try {
        return fallback(_exception!);
        // Need to catch all errors from user-provided transform
        // ignore: avoid_catches_without_on_clauses
      } catch (error, stackTrace) {
        return Result.failure(
          exception.toException(stackTrace: stackTrace),
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
  void doOnFailure(
    void Function(CommonException<Object> exception) callback,
  ) {
    if (!_isSuccess) {
      callback(_exception!);
    }
  }

  Result<T> updateFailMessage({
    String? userMessage,
    String? developerMessage,
  }) {
    if (!_isSuccess) {
      return Result._failure(
        exception.copyWith(
          userMessage: userMessage,
          developerMessage: developerMessage,
        ),
      );
    }
    return this;
  }

  /// Swaps success and failure.
  ///
  /// Success becomes Failure with a new exception,
  /// Failure becomes Success with the exception.
  Result<CommonException<Object>> swap({String? message}) {
    if (_isSuccess) {
      return Result.failure(
        CommonException(
          type: ErrorType.unexpected,
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
