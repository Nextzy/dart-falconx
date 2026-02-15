import 'package:dart_falmodel/lib.dart';

part 'generated/feedback.freezed.dart';

part 'generated/feedback.g.dart';

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

/// Sealed class hierarchy for user feedback using Freezed.
///
/// This provides a type-safe way to handle different types of feedback
/// with exhaustive pattern matching and immutability.
///
/// Example:
/// ```dart
/// UserFeedback processFeedback(UserFeedback feedback) {
///   return feedback.when(
///     success: (message, data, level) => print('Success: $message'),
///     warning: (message, data, level) => print('Warning: $message'),
///     failure: (message, data, level) => print('Error: $message'),
///     information: (message, data, level) => print('Info: $message'),
///   );
/// }
/// ```
@freezed
sealed class UserFeedback with _$UserFeedback {
  const UserFeedback._();

  /// Represents a successful operation.
  const factory UserFeedback.success({
    String? message,
    @Default(FeedbackLevel.medium) FeedbackLevel level,
  }) = Success;

  /// Represents a warning that doesn't prevent operation completion.
  const factory UserFeedback.warning({
    String? message,
    @Default(FeedbackLevel.medium) FeedbackLevel level,
  }) = Warning;

  /// Represents a failure or error condition.
  const factory UserFeedback.failure({
    String? message,
    @Default(FeedbackLevel.medium) FeedbackLevel level,
  }) = Failure;

  /// Represents an informational message.
  const factory UserFeedback.information({
    String? message,
    @Default(FeedbackLevel.medium) FeedbackLevel level,
  }) = Information;

  factory UserFeedback.fromJson(
    Map<String, dynamic> json,
  ) => _$UserFeedbackFromJson(json);

  /// Creates a Warning from an Exception object.
  static UserFeedback warningFromException(
    CommonException? exception, {
    FeedbackLevel level = FeedbackLevel.medium,
  }) => UserFeedback.warning(
    message: exception?.userMessage,
    level: level,
  );

  /// Creates a Failure from an Exception object.
  static UserFeedback failureFromException(
    CommonException? exception, {
    FeedbackLevel level = FeedbackLevel.medium,
  }) => UserFeedback.failure(
    message: exception?.userMessage,
    level: level,
  );

  /// Gets the message if this is a Success feedback.
  String? get successMessage => maybeWhen(
    success: (message, level) => message,
    orElse: () => null,
  );

  /// Gets the message if this is a Failure feedback.
  String? get errorMessage => maybeWhen(
    failure: (message, level) => message,
    orElse: () => null,
  );

  /// Gets the message if this is a Warning feedback.
  String? get warningMessage => maybeWhen(
    warning: (message, level) => message,
    orElse: () => null,
  );

  /// Gets the message if this is an Information feedback.
  String? get informationMessage => maybeWhen(
    information: (message, level) => message,
    orElse: () => null,
  );

  /// Pattern matching using switch expression (Dart 3 style).
  /// This is available in addition to Freezed's when/maybeWhen methods.
  R match<R>({
    required R Function(Success success) onSuccess,
    required R Function(Warning warning) onWarning,
    required R Function(Failure failure) onFailure,
    required R Function(Information information) onInformation,
  }) {
    return switch (this) {
      Success() => onSuccess(this as Success),
      Warning() => onWarning(this as Warning),
      Failure() => onFailure(this as Failure),
      Information() => onInformation(this as Information),
    };
  }
}

