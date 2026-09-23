import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// One scripted server answer: a response body, or a thrown DioException.
typedef Reply = ResponseBody Function(RequestOptions options);

/// Answers with [status], optional headers, and a JSON body.
Reply reply(int status, {Map<String, String> headers = const {}}) =>
    (_) => ResponseBody.fromString(
      '{"status":$status}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final entry in headers.entries) entry.key: [entry.value],
      },
    );

/// Fails the request with a DioException of [type], as a network error.
Reply failWith(DioExceptionType type) =>
    (options) => throw DioException(requestOptions: options, type: type);

/// A fake transport that replays [script] in order and repeats its last
/// entry, recording every request it receives.
class ScriptedAdapter implements HttpClientAdapter {
  new(this.script);

  final List<Reply> script;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    requests.add(options);
    return script[min(requests.length, script.length) - 1](options);
  }

  @override
  void close({bool force = false}) {}
}
