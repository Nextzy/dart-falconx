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
}
