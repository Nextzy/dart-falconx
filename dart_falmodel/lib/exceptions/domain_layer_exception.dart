import 'package:dart_falmodel/lib.dart';

/// Exception that originates in the domain layer (use cases, business logic).
///
/// Use this instead of [CommonException] when the failure site is a use case
/// or domain service, giving callers a way to distinguish domain-layer errors
/// from data-layer errors via `is` checks.
class DomainLayerException extends CommonException {
  /// Creates a [DomainLayerException].
  const DomainLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.data,
    super.originalException,
    super.stackTrace,
  });

  @override
  DomainLayerException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Map<String, dynamic>? data,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => DomainLayerException(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    data: data ?? this.data,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}
