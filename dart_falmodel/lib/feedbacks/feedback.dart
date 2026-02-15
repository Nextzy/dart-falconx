import 'package:dart_falmodel/lib.dart';

/// Severity levels for warnings.
enum FeedbackLevel {
  low,
  medium,
  high,
  critical;

  /// Whether this warning should be prominently displayed.
  bool get isProminent => this == high || this == critical;
}

/// Type alias for void callback that receives a Failure.
typedef VoidFailureCallback = void Function(Failure failure);

/// Sealed class hierarchy for user feedback using Dart 3 features.
///
/// This provides a type-safe way to handle different types of feedback
/// with exhaustive pattern matching.
///
/// Example:
/// ```dart
/// UserFeedback processFeedback(UserFeedback feedback) {
///   return switch (feedback) {
///     Success(:final message) => print('Success: $message'),
///     Warning(:final message) => print('Warning: $message'),
///     Failure(:final exception) => print('Error: $exception'),
///     Information() => print('Info'),
///   };
/// }
/// ```
sealed class UserFeedback<T> extends Equatable {
  const UserFeedback({
    this.message,
    this.data,
    this.level = FeedbackLevel.medium,
  });

  /// A human-readable message describing the feedback.
  final String? message;

  /// Optional data associated with the feedback.
  final T? data;

  /// The severity level of the feedback.
  final FeedbackLevel level;

  @override
  List<Object?> get props => [message, data, level];
}

/// Represents a successful operation.
class Success<T> extends UserFeedback<T> {
  const Success({
    super.message,
    super.data,
    super.level,
  });

  /// Creates a copy of this Success with the given fields replaced.
  Success<T> copyWith({
    String? message,
    T? data,
    FeedbackLevel? level,
  }) => Success(
    message: message ?? this.message,
    data: data ?? this.data,
    level: level ?? this.level,
  );
}

/// Represents an informational message.
class Information<T> extends UserFeedback<T> {
  const Information({
    super.message,
    super.data,
    super.level,
  });

  /// Creates a copy of this Information with the given fields replaced.
  Information<T> copyWith({
    String? message,
    T? data,
    FeedbackLevel? level,
  }) => Information(
    message: message ?? this.message,
    data: data ?? this.data,
    level: level ?? this.level,
  );
}

/// Represents a warning that doesn't prevent operation completion.
class Warning<T> extends UserFeedback<T> {
  const Warning({
    super.message,
    super.data,
    super.level,
  });

  /// Creates a Warning from an Error object.
  factory Warning.fromException(
    CommonException<T>? exception, {
    T? data,
    FeedbackLevel level = FeedbackLevel.medium,
  }) => Warning<T>(
    message: exception?.userMessage,
    data: data ?? exception?.code,
    level: level,
  );

  /// Creates a copy of this Warning with the given fields replaced.
  Warning<T> copyWith({
    String? message,
    T? data,
    FeedbackLevel? level,
  }) => Warning(
    message: message ?? this.message,
    data: data ?? this.data,
    level: level ?? this.level,
  );

  @override
  List<Object?> get props => [
    ...super.props,
  ];
}

/// Represents a failure or error condition.
class Failure<T> extends UserFeedback<T> {
  const Failure({
    super.message,
    super.data,
    super.level,
  });

  /// Creates a Failure from an Exception object.
  factory Failure.fromException(
    CommonException<T>? exception, {
    T? data,
    FeedbackLevel level = FeedbackLevel.medium,
  }) => Failure<T>(
    message: exception?.userMessage,
    data: data ?? exception?.code,
    level: level,
  );

  /// Creates a copy of this Failure with the given fields replaced.
  Failure<T> copyWith({
    String? message,
    T? data,
    FeedbackLevel? level,
  }) => Failure(
    message: message ?? this.message,
    data: data ?? this.data,
    level: level ?? this.level,
  );

  @override
  List<Object?> get props => [
    ...super.props,
  ];
}

/// Extension methods for pattern matching on feedback types.
extension UserFeedbackExtension<T> on UserFeedback<T> {
  /// Gets the message if this is a Success feedback.
  String? get successMessage => this is Success ? message : null;

  /// Gets the message if this is a Failure feedback.
  String? get errorMessage => this is Failure ? message : null;

  /// Gets the message if this is a Warning feedback.
  String? get warningMessage => this is Warning ? message : null;

  /// Gets the message if this is an Information feedback.
  String? get informationMessage => this is Information ? message : null;

  /// Executes the appropriate callback based on the feedback type.
  R when<R>({
    required R Function(Success<T> success) success,
    required R Function(Warning<T> warning) warning,
    required R Function(Failure<T> failure) failure,
    required R Function(Information<T> information) information,
  }) {
    return switch (this) {
      Success() => success(this as Success<T>),
      Warning() => warning(this as Warning<T>),
      Failure() => failure(this as Failure<T>),
      Information() => information(this as Information<T>),
    };
  }

  /// Maps the data contained in the feedback to a new type.
  UserFeedback<R> mapData<R>(R Function(T? data) mapper) {
    return switch (this) {
      Success(message: final message, level: final level) => Success<R>(
        message: message,
        data: mapper(data),
        level: level,
      ),
      Warning(message: final message, level: final level) => Warning<R>(
        message: message,
        data: mapper(data),
        level: level,
      ),
      Failure(message: final message, level: final level) =>
        Failure<R>(
          message: message,
          data: mapper(data),
          level: level,
        ),
      Information(message: final message, level: final level) => Information<R>(
        message: message,
        data: mapper(data),
        level: level,
      ),
    };
  }
}
