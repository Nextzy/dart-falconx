import 'package:dart_falconnect/lib.dart';

/// Concrete [JsonRpcService] with no additional configuration.
///
/// Use [DefaultJsonRpcService.fromHttpClient] to create an instance from an
/// existing [BaseHttpClient] so the base URL and Dio instance are shared.
class DefaultJsonRpcService extends JsonRpcService {
  /// Creates a [DefaultJsonRpcService] with the given [_dio] instance.
  ///
  /// [baseUrl] sets the JSON-RPC endpoint root. [jsonrpc] is the protocol
  /// version string (e.g. `'2.0'`). [errorLogger] is optional.
  const DefaultJsonRpcService(
    super._dio, {
    required super.baseUrl,
    required super.jsonrpc,
    super.errorLogger,
  });

  /// Creates a [DefaultJsonRpcService] from an existing [BaseHttpClient].
  ///
  /// Reuses [client]'s Dio instance and base URL unless [baseUrl] overrides
  /// it. [jsonrpc] sets the protocol version string (e.g. `'2.0'`).
  factory DefaultJsonRpcService.fromHttpClient(
    BaseHttpClient client, {
    required String jsonrpc,
    String? baseUrl,
    ParseErrorLogger? errorLogger,
  }) {
    return DefaultJsonRpcService(
      client.dio,
      baseUrl: baseUrl ?? client.baseUrl,
      jsonrpc: jsonrpc,
      errorLogger: errorLogger,
    );
  }
}
