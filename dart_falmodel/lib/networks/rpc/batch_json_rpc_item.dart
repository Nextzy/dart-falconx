import 'package:dart_falmodel/lib.dart';

/// A single item in a batch JSON-RPC response — either a success or a failure.
sealed class BatchJsonRpcItem<RESULT extends JsonRpcResult> {
  const BatchJsonRpcItem();

  /// Returns `true` if this item represents a successful response.
  bool get isSuccess => this is BatchJsonRpcSuccess;

  /// Returns `true` if this item represents a failed response.
  bool get isFailure => this is BatchJsonRpcFailure;

  /// Returns the [JsonRpcResponse] if this is a success, or `null` otherwise.
  JsonRpcResponse<RESULT>? get responseOrNull => switch (this) {
    BatchJsonRpcSuccess(:final response) => response,
    BatchJsonRpcFailure() => null,
  };

  /// Returns the [JsonRpcErrorResponse] if this is a failure,
  /// or `null` otherwise.
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
    BatchJsonRpcSuccess(:final response) => BatchJsonRpcSuccess(
      transform(response),
    ),
    final BatchJsonRpcFailure<RESULT> f => BatchJsonRpcFailure(f.error),
  };
}

/// A successful batch item wrapping a [JsonRpcResponse].
class BatchJsonRpcSuccess<RESULT extends JsonRpcResult>
    extends BatchJsonRpcItem<RESULT> {
  /// Creates a [BatchJsonRpcSuccess] wrapping [response].
  const BatchJsonRpcSuccess(this.response);

  /// The successful JSON-RPC response.
  final JsonRpcResponse<RESULT> response;
}

/// A failed batch item wrapping a [JsonRpcErrorResponse].
class BatchJsonRpcFailure<RESULT extends JsonRpcResult>
    extends BatchJsonRpcItem<RESULT> {
  /// Creates a [BatchJsonRpcFailure] wrapping [error].
  const BatchJsonRpcFailure(this.error);

  /// The JSON-RPC error response.
  final JsonRpcErrorResponse error;
}
