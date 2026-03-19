import 'dart:math';

import 'package:dart_falconnect/lib.dart';

class DefaultRpcService extends RpcService {
  const DefaultRpcService(
    super._dio, {
    required super.baseUrl,
    required super.jsonrpc,
    super.errorLogger,
  });
}
