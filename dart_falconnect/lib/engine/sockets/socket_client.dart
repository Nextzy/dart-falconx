import 'package:dart_falconnect/lib.dart';

/// Abstract WebSocket client with automatic retry, interceptor support, and
/// reactive response streaming.
///
/// Subclasses must implement [setupConfig] to configure [SocketOptions].
/// Override [setupInterceptors] to add [SocketInterceptor] instances. The
/// channel is opened lazily on the first [request] call.
abstract class SocketClient implements RequestSocketService {
  /// Creates a [SocketClient] connected to [baseUrl].
  ///
  /// Initialises internal state, calls [setupConfig] with the default options,
  /// and calls [setupInterceptors] with the empty interceptor list.
  SocketClient(String baseUrl) {
    _tmpOptions = SocketOptions(uri: baseUrl);
    _replaySubject = PublishSubject<SocketResponse>();
    _retryLimitCounter = _tmpOptions.retryLimit;
    interceptors = SocketInterceptors();
    setupConfig(_tmpOptions);
    setupInterceptors(interceptors);
  }

  /// Diagnostic tag for this client.
  static const TAG = 'SocketChannel';
  late SocketOptions _tmpOptions;
  late PublishSubject<SocketResponse> _replaySubject;
  late int _retryLimitCounter;

  /// The ordered list of interceptors applied to every socket event.
  late final SocketInterceptors interceptors;

  WebSocketChannel? _channel;
  bool _isClose = true;
  StreamSubscription<dynamic>? _subscription;

  /// Whether the underlying WebSocket channel is currently closed.
  bool get isClose => _isClose;

  /// Directly sets the closed state of the channel.
  set setIsClose(bool isClose) => _isClose = isClose;

  /// Current [SocketOptions] reflecting the latest request configuration.
  SocketOptions get options => _tmpOptions;

  /// Configures [SocketOptions] for this client before the first connection.
  ///
  /// Override to set the URI, protocol, retry limit, and other options.
  void setupConfig(SocketOptions configs);

  /// Registers interceptors on [interceptors] before the first connection.
  ///
  /// The default implementation is a no-op; override to add interceptors.
  void setupInterceptors(
    SocketInterceptors interceptors,
  ) {}

  @override
  Future<void> createChannel() async {
    if (_channel != null || !_isClose) {
      await closeChannel();
      _isClose = true;
    }

    _channel = WebSocketChannel.connect(
      Uri.parse(_tmpOptions.uri),
    );
    _subscription = _channel?.stream.listen(
      _onResponse,
      onError: _onError,
      onDone: _onDone,
    );
    _isClose = false;
  }

  Future<void> _onDone() async {
    _logCloseReason();
    await closeChannel();
  }

  Future<void> _onError(
    Exception? error,
    StackTrace? stackTrace,
  ) async {
    if (_retryLimitCounter > 0) {
      _executeInterceptorOnError(
        exception: SocketRetryException(
          retryCount: _retryLimitCounter,
          exception: error,
          stackTrace: stackTrace,
        ),
        options: _tmpOptions.copyWith(),
      );
      _isClose = false;
      _retryLimitCounter--;
      if (_tmpOptions.data != null) {
        _channel?.sink.add(_tmpOptions.data);
      }
    } else {
      _executeInterceptorOnError(
        exception: SocketException(
          exception: error,
          stackTrace: stackTrace,
        ),
        options: _tmpOptions.copyWith(),
      );
      _isClose = true;
      _replaySubject.addError(
        error!,
        stackTrace,
      );
      await _subscription?.cancel();
    }
  }

  @override
  Future<void> closeChannel() async {
    if (!_isClose) {
      await _channel?.sink.close();
      await _subscription?.cancel();
      _isClose = true;
      _tmpOptions = _tmpOptions.copyWith(data: null);
    }
  }

  /// Create channel automatically when first call
  /// request.
  @override
  Future<void> request(String data) async {
    if (_channel == null || isClose) {
      await createChannel();
    }
    _tmpOptions = _tmpOptions.copyWith(
      protocol: _channel?.protocol,
      data: data,
    );
    _executeInterceptorOnRequest(
      options: _tmpOptions,
    );
    _channel?.sink.add(_tmpOptions.data);
  }

  @override
  Stream<T> getResponseStream<T>({
    bool Function(SocketResponse response)? filter,
    required T Function(SocketResponse response) converter,
  }) =>
      _replaySubject.stream.where(filter ?? (data) => true).asyncMap(converter);

  @override
  Stream<SocketResponse> getRawStream({
    bool Function(SocketResponse response)? filter,
  }) => _replaySubject.stream.where(filter ?? (data) => true);

  /// Sends a `ping` frame to verify the connection is still alive.
  ///
  /// Calls [createChannel] if the ping throws, re-establishing the connection.
  Future<void> checkConnection() async {
    try {
      _channel?.sink.add('ping');
    } on Exception catch (_) {
      await createChannel();
    }
  }

  void _onResponse(dynamic response) {
    _retryLimitCounter = _tmpOptions.retryLimit;
    final responseWrap = SocketResponse(
      data: response as String,
      requestOptions: _tmpOptions.copyWith(),
    );
    _executeInterceptorOnResponse(
      response: responseWrap,
    );
    _replaySubject.add(responseWrap);
  }

  void _executeInterceptorOnRequest({
    required SocketOptions options,
  }) {
    for (final interceptor in interceptors) {
      interceptor.onRequest(options);
    }
  }

  void _executeInterceptorOnResponse({
    required SocketResponse response,
  }) {
    for (final interceptor in interceptors) {
      interceptor.onResponse(response);
    }
  }

  void _executeInterceptorOnError({
    required SocketException exception,
    required SocketOptions options,
  }) {
    for (final interceptor in interceptors) {
      interceptor.onError(exception, options);
    }
  }

  void _logCloseReason() {
    // Close reason info available via:
    // _channel?.protocol
    // _channel?.closeCode
    // _channel?.closeReason
  }
}
