import 'package:dart_falmodel/lib.dart';

/// JSON-RPC exception that originates in the data layer
/// (repositories, data sources).
class JsonRpcDataLayerException extends CommonException {
  /// Creates a [JsonRpcDataLayerException].
  const JsonRpcDataLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}

/// JSON-RPC exception caused by a database operation failure.
class JsonRpcDatabaseException extends JsonRpcDataLayerException {
  /// Creates a [JsonRpcDatabaseException].
  const JsonRpcDatabaseException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}

/// JSON-RPC exception caused by a failure in an external API data source.
class JsonRpcExternalApiDataLayerException extends JsonRpcDataLayerException {
  /// Creates a [JsonRpcExternalApiDataLayerException].
  const JsonRpcExternalApiDataLayerException({
    required super.type,
    super.userMessage,
    super.developerMessage,
    super.originalException,
    super.stackTrace,
  });
}
