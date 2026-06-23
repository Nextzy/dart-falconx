import 'package:dart_falconnect/lib.dart';

/// Contract for a WebSocket channel that supports request/response streaming.
///
/// Implementations manage connection lifecycle, outbound requests, and
/// typed inbound response streams.
abstract class RequestSocketService {
  /// Opens a new WebSocket channel, replacing any existing one.
  void createChannel();

  /// Sends [body] as a text frame over the current WebSocket channel.
  void request(String body);

  /// Closes the active WebSocket channel and cancels stream subscriptions.
  Future<void> closeChannel();

  /// Returns a typed stream of responses matching [filter], converted by
  /// [converter].
  ///
  /// [filter] selects which [SocketResponse] values to forward. [converter]
  /// maps each accepted response to the desired type [T].
  Stream<T> getResponseStream<T>({
    required bool Function(SocketResponse response) filter,
    required T Function(SocketResponse response) converter,
  });

  /// Returns a raw [SocketResponse] stream, optionally narrowed by [filter].
  ///
  /// When [filter] is omitted, all responses are forwarded.
  Stream<SocketResponse> getRawStream({
    bool Function(SocketResponse response)? filter,
  });
}
