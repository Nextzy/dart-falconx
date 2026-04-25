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
    super.originalException,
    super.stackTrace,
  });
}
