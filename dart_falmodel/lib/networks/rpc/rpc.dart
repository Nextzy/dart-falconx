export 'batch_json_rpc_item.dart';
export 'batch_rpc_request.dart';
export 'exceptions/exceptions.dart';
export 'json_rpc_error.dart';
export 'json_rpc_request.dart';
export 'json_rpc_response.dart';
export 'json_rpc_result.dart';

abstract class JsonRpc {
  const JsonRpc({
    this.jsonrpc = '2.0',
    this.id,
  });

  final String? jsonrpc;
  final int? id;
}
