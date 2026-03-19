import 'package:dart_falmodel/lib.dart';

/// A single item in a batch JSON-RPC response — either a success or a failure.
sealed class BatchJsonRpcItem<RESULT extends JsonRpcResult> {
  const BatchJsonRpcItem();

  bool get isSuccess => this is BatchJsonRpcSuccess;

  bool get isFailure => this is BatchJsonRpcFailure;

  JsonRpcResponse<RESULT>? get dataOrNull {
    if (isSuccess) {
      return (this as BatchJsonRpcSuccess<RESULT>).response;
    }
    return null;
  }

  JsonRpcResponse<RESULT> get data {
    if (isSuccess) {
      return (this as BatchJsonRpcSuccess<RESULT>).response;
    }
    throw StateError('Batch item is not a success');
  }

  JsonRpcErrorResponse? get errorOrNull {
    if (isFailure) {
      return (this as BatchJsonRpcFailure).error;
    }
    return null;
  }

  JsonRpcErrorResponse get error {
    if (isFailure) {
      return (this as BatchJsonRpcFailure).error;
    }
    throw StateError('Batch item is not a failure');
  }
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

  @override
  final JsonRpcErrorResponse error;
}
