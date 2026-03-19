import 'package:dart_falmodel/lib.dart';

/// A single item in a batch JSON-RPC response — either a success or a failure.
sealed class BatchJsonRpcItem<RESULT extends JsonRpcResult> {
  const BatchJsonRpcItem();

  bool get isSuccess => this is BatchJsonRpcSuccess;

  bool get isFailure => this is BatchJsonRpcFailure;

  JsonRpcResponse<RESULT>? get responseOrNull => switch (this) {
    BatchJsonRpcSuccess(:final response) => response,
    BatchJsonRpcFailure() => null,
  };

  JsonRpcErrorResponse? get errorOrNull => switch (this) {
    BatchJsonRpcSuccess() => null,
    BatchJsonRpcFailure(:final error) => error,
  };

  /// Folds this item into a single value.
  R resolve<R>({
    required R Function(JsonRpcResponse<RESULT> response) success,
    required R Function(JsonRpcErrorResponse error) failure,
  }) => switch (this) {
    BatchJsonRpcSuccess(:final response) => success(response),
    BatchJsonRpcFailure(:final error) => failure(error),
  };

  /// Transforms the success response if present.
  BatchJsonRpcItem<R> map<R extends JsonRpcResult>(
    JsonRpcResponse<R> Function(JsonRpcResponse<RESULT> response) transform,
  ) => switch (this) {
    BatchJsonRpcSuccess(:final response) =>
      BatchJsonRpcSuccess(transform(response)),
    final BatchJsonRpcFailure<RESULT> f => BatchJsonRpcFailure(f.error),
  };
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
