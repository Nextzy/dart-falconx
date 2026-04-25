export 'batch_json_rpc_item.dart';
export 'batch_rpc_request.dart';
export 'exceptions/exceptions.dart';
export 'json_rpc_error.dart';
export 'json_rpc_request.dart';
export 'json_rpc_response.dart';
export 'json_rpc_result.dart';

/// Base class for all JSON-RPC 2.0 message types.
///
/// Holds the protocol version string and an optional request identifier.
abstract class JsonRpc {
  /// Creates a [JsonRpc] instance with the given [jsonrpc] version
  /// and optional [id].
  const JsonRpc({
    this.jsonrpc = '2.0',
    this.id,
  });

  /// The JSON-RPC protocol version; always `'2.0'`.
  final String jsonrpc;

  /// Optional request identifier used to correlate responses with requests.
  final int? id;
}
