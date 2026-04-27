import 'package:dart_falmodel/lib.dart';

/// General-purpose JSON-RPC exception not tied to a specific application layer.
///
/// Prefer the more specific [JsonRpcDataLayerException] or
/// [JsonRpcDomainLayerException] when the failure site is known.
class JsonRpcCommonException extends CommonException {
  /// Creates a [JsonRpcCommonException].
  const JsonRpcCommonException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });

  @override
  JsonRpcCommonException copyWith({
    Object? type,
    String? userMessage,
    String? developerMessage,
    Exception? originalException,
    StackTrace? stackTrace,
  }) => JsonRpcCommonException(
    type: type ?? this.type,
    userMessage: userMessage ?? this.userMessage,
    developerMessage: developerMessage ?? this.developerMessage,
    originalException: originalException ?? this.originalException,
    stackTrace: stackTrace ?? this.stackTrace,
  );
}
