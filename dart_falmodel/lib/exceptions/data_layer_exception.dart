import 'package:dart_falmodel/lib.dart';

/// Exception that originates in the data layer (repositories, data sources).
///
/// Use this instead of [CommonException] when the failure site is a repository
/// or remote/local data source, giving callers a way to distinguish data-layer
/// errors from domain-layer errors via `is` checks.
class DataLayerException extends CommonException {
  /// Creates a [DataLayerException].
  const DataLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.data,
    super.originalException,
    super.stackTrace,
  });

  @override
  DataLayerException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Map<String, dynamic>? data,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => DataLayerException(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    data: data ?? this.data,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}
