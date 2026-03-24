
import 'package:dart_falconnect/lib.dart';

class DefaultJsonRpcService extends JsonRpcService {
  const DefaultJsonRpcService(
    super._dio, {
    required super.baseUrl,
    required super.jsonrpc,
    super.errorLogger,
  });
}
