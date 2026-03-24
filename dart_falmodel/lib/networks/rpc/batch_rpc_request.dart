import 'package:dart_falmodel/lib.dart';

class BatchJsonRpcBody<RESULT> extends JsonRpc {
  const BatchJsonRpcBody({
    super.jsonrpc,
    super.id,
    required this.method,
    this.params,
    this.fromResultJson,
  }) : super();

  final String? method;
  final Map<String, dynamic>? params;
  final RESULT Function(Map<String, dynamic>? json)? fromResultJson;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['method'] = method;
    json['params'] = params;
    json.removeWhere((k, v) => v == null);
    return json;
  }
}
