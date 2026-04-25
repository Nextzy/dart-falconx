import 'dart:collection';
import 'package:dart_falconnect/lib.dart';

/// Ordered, mutable list of [SocketInterceptor] instances for a socket client.
///
/// Behaves as a standard [List] and is iterated in insertion order during
/// each socket lifecycle event.
class SocketInterceptors extends ListMixin<SocketInterceptor> {
  final _list = <SocketInterceptor>[];

  @override
  int length = 0;

  @override
  SocketInterceptor operator [](int index) {
    return _list[index];
  }

  @override
  void operator []=(int index, SocketInterceptor value) {
    if (_list.length == index) {
      _list.add(value);
    } else {
      _list[index] = value;
    }
  }
}

/// Abstract middleware for intercepting WebSocket request and response events.
///
/// Implement [onRequest], [onResponse], and [onError] to add cross-cutting
/// behaviour such as logging or metrics collection.
abstract class SocketInterceptor {
  // TODO(username): Implement interceptor followed dio concept

  /// Called before a socket request is sent.
  ///
  /// [options] contains the URI, protocol, and payload for the outgoing frame.
  void onRequest(SocketOptions options);

  /// Called when a socket response frame is received.
  ///
  /// [response] wraps the raw data and the originating [SocketOptions].
  void onResponse(SocketResponse response);

  /// Called when a socket error occurs.
  ///
  /// [err] carries the exception detail and [options] reflects the request
  /// state at the time of the failure.
  void onError(SocketException err, SocketOptions options);
}
