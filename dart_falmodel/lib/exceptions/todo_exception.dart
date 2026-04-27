import 'package:dart_falmodel/lib.dart';

/// Placeholder exception for features that are not yet implemented.
///
/// Defaults [userMessage] to `"Coming soon."` so it is safe to surface
/// directly to end users during development or staged rollouts.
class TodoException<T> extends CommonException {
  /// Creates a [TodoException].
  ///
  /// [type] identifies the unimplemented feature; defaults signal that the
  /// feature is pending implementation.
  const TodoException({
    required super.type,
    super.userMessage = 'Coming soon.',
    super.developerMessage = '[TODO] Not implement right now',
    super.originalException,
    super.stackTrace,
  });

  @override
  TodoException<T> copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => TodoException<T>(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}
