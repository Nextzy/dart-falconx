import 'package:dart_falconnect/lib.dart';

class DefaultJsonRpcService extends JsonRpcService {
  const DefaultJsonRpcService(
    super._dio, {
    required super.baseUrl,
    required super.jsonrpc,
    super.errorLogger,
  });

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
