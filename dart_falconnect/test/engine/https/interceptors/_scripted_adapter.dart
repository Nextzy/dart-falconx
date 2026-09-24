import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_faltool/dart_faltool.dart' show clock;
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

/// Fails the request with the given [error], as an interceptor-produced
/// rejection would.
Reply failLocal(DioException error) =>
    (_) => throw error;

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

/// One request held by a [GatedAdapter] until the test answers it.
class GatedRequest {
  new(this.options) : sentAt = clock.now();

  final RequestOptions options;

  /// When the request reached the adapter, read from `clock`, which
  /// `fakeAsync` controls.
  final DateTime sentAt;
  final Completer<ResponseBody> _answer = Completer<ResponseBody>();
  bool _cancelled = false;

  /// Whether the request was answered or cancelled.
  bool get isDone => _answer.isCompleted || _cancelled;

  /// Answers with [status], optional headers, and a JSON body.
  void respond(int status, {Map<String, String> headers = const {}}) =>
      _answer.complete(reply(status, headers: headers)(options));
}

/// A fake transport that holds every request until the test answers it,
/// so a test can see how many requests are in flight at once.
class GatedAdapter implements HttpClientAdapter {
  final List<GatedRequest> requests = [];

  /// Requests neither answered nor cancelled.
  List<GatedRequest> get inFlight =>
      requests.where((request) => !request.isDone).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    final request = GatedRequest(options);
    requests.add(request);
    unawaited(cancelFuture?.then((_) => request._cancelled = true));
    return request._answer.future;
  }

  @override
  void close({bool force = false}) {}
}
