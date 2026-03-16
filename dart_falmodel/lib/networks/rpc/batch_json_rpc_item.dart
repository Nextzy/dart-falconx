import 'package:dart_falmodel/lib.dart';

/// A single item in a batch JSON-RPC response — either a success or a failure.
sealed class BatchJsonRpcItem<RESULT extends JsonRpcResult> {
  const BatchJsonRpcItem();
}

/// A successful batch item wrapping a [JsonRpcResponse].
class BatchJsonRpcSuccess<RESULT extends JsonRpcResult>
    extends BatchJsonRpcItem<RESULT> {
  const BatchJsonRpcSuccess(this.response);
  final JsonRpcResponse<RESULT> response;
}

/// A failed batch item wrapping a [JsonRpcErrorResponse].
class BatchJsonRpcFailure<RESULT extends JsonRpcResult>
    extends BatchJsonRpcItem<RESULT> {
  const BatchJsonRpcFailure(this.error);
  final JsonRpcErrorResponse error;
}
