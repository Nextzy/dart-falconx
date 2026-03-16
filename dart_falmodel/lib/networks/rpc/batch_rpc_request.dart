import 'package:dart_falmodel/lib.dart';

class BatchJsonRpcBody<RESPONSE> extends JsonRpc {
  const BatchJsonRpcBody({
    super.jsonrpc,
    super.id,
    required this.method,
    this.params,
    this.fromResponseJson,
  }) : super();

  final String? method;
  final Map<String, dynamic>? params;
  final RESPONSE Function(Map<String, dynamic>? json)? fromResponseJson;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['method'] = method;
    json['params'] = params;
    json.removeWhere((k, v) => v == null);
    return json;
  }
}
