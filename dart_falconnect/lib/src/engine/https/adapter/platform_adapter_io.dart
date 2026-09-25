import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_falconnect/engine/https/certificate_pinning_exception.dart';
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/config/io_adapter_config.dart';
import 'package:dart_falconnect/src/engine/https/adapter/spki.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// The box dart:io reads from [config].
Object? platformAdapterBox(HttpClientConfig config) => config.ioAdapter;

/// An adapter built from [box], an [IoAdapterConfig].
HttpClientAdapter buildPlatformAdapter(Object box) => PinningIoAdapter(
  box as IoAdapterConfig,
  trustAny: trustsAnyCertificate(box, assertionsEnabled: _assertionsEnabled),
);

/// Diagnostics about [config]'s `ioAdapter` box. All of them when
/// [adapterBuilt], else only the connection-limit one.
List<String> adapterDiagnostics(
  HttpClientConfig config, {
  required bool adapterBuilt,
}) {
  final box = config.ioAdapter;
  if (box == null) return const [];
  final messages = <String>[];
  final max = box.maxConnectionsPerHost;
  final concurrency = config.concurrency;
  if (max != null && concurrency != null) {
    final limits = [
      concurrency.perHost,
      ...concurrency.hosts.values,
    ].whereType<int>().where((limit) => limit > max);
    if (limits.isNotEmpty) {
      final highest = limits.reduce((a, b) => a > b ? a : b);
      messages.add(
        '[ioAdapter] maxConnectionsPerHost $max is below the concurrency '
        'limit $highest: requests past $max wait inside HttpClient and '
        'count toward connectTimeout',
      );
    }
  }
  if (!adapterBuilt) return messages;
  if (trustsAnyCertificate(box, assertionsEnabled: _assertionsEnabled)) {
    messages.add(
      '[ioAdapter] debugTrustAnyCertificate is in effect: every '
      'certificate chain is trusted',
    );
  }
  for (final MapEntry(key: host, value: pins) in box.pins.entries) {
    if (pins.length == 1) {
      messages.add('[ioAdapter] $host has one pin: add a backup pin');
    }
  }
  return messages;
}

/// Whether [box] trusts every certificate chain: only when its switch is
/// on and [assertionsEnabled], so a release build never does.
bool trustsAnyCertificate(
  IoAdapterConfig box, {
  required bool assertionsEnabled,
}) => box.debugTrustAnyCertificate && assertionsEnabled;

bool get _assertionsEnabled {
  var enabled = false;
  assert(enabled = true, 'assert runs only when assertions are enabled');
  return enabled;
}

/// A new `HttpClient` configured by [box].
HttpClient createIoHttpClient(IoAdapterConfig box, {required bool trustAny}) {
  final pins = _canonicalPins(box.pins);
  final client = HttpClient()
    ..idleTimeout = box.idleTimeout
    ..maxConnectionsPerHost = box.maxConnectionsPerHost;
  final proxy = box.proxy;
  if (proxy != null) {
    // A pinned host gets no DIRECT entry, so it fails instead of going
    // around the proxy unseen.
    client.findProxy = (uri) => pins.containsKey(uri.host.toLowerCase())
        ? 'PROXY $proxy'
        : 'PROXY $proxy; DIRECT';
  }
  if (trustAny) {
    client.badCertificateCallback = (certificate, host, port) => true;
  }
  if (pins.isNotEmpty) {
    client.connectionFactory = _PinningConnector(
      pins,
      trustAny: trustAny,
    ).connect;
  }
  return client;
}

/// [pins] with lowercase hosts and canonical pins; hosts that differ only
/// in case share one set.
Map<String, Set<String>> _canonicalPins(Map<String, Set<String>> pins) {
  final canonical = <String, Set<String>>{};
  for (final MapEntry(key: host, value: hostPins) in pins.entries) {
    canonical
        .putIfAbsent(host.toLowerCase(), () => {})
        .addAll(hostPins.map((pin) => canonicalPin(pin) ?? pin));
  }
  return canonical;
}

/// Opens every connection of a pinned `HttpClient`, and checks the leaf
/// certificate of a pinned host before `HttpClient` writes the request.
class _PinningConnector {
  new(this.pins, {required this.trustAny});

  final Map<String, Set<String>> pins;
  final bool trustAny;

  bool Function(X509Certificate certificate)? get _onBadCertificate =>
      trustAny ? (certificate) => true : null;

  Future<ConnectionTask<Socket>> connect(
    Uri uri,
    String? proxyHost,
    int? proxyPort,
  ) async {
    final host = uri.host.toLowerCase();
    final expected = pins[host];
    final secure = uri.isScheme('https');
    if (expected == null) {
      if (proxyHost != null) {
        // HttpClient runs the CONNECT tunnel and its TLS itself.
        return Socket.startConnect(proxyHost, proxyPort!);
      }
      return secure
          ? SecureSocket.startConnect(
              uri.host,
              uri.port,
              onBadCertificate: _onBadCertificate,
            )
          : Socket.startConnect(uri.host, uri.port);
    }
    if (proxyHost != null || !secure) {
      throw CertificatePinningException(
        host: host,
        failure: proxyHost != null ? PinFailure.proxied : PinFailure.plainHttp,
        expected: expected,
      );
    }
    final task = await SecureSocket.startConnect(
      uri.host,
      uri.port,
      onBadCertificate: _onBadCertificate,
    );
    return ConnectionTask.fromSocket(
      task.socket.then((socket) => _check(socket, host, expected)),
      task.cancel,
    );
  }

  /// [socket] when its leaf certificate matches one of [expected];
  /// otherwise destroys it, before any request byte is written, and
  /// throws [CertificatePinningException].
  SecureSocket _check(SecureSocket socket, String host, Set<String> expected) {
    final certificate = socket.peerCertificate;
    String? presented;
    if (certificate != null) {
      try {
        presented = spkiPin(certificate.der);
      } on FormatException {
        presented = null;
      }
    }
    if (presented != null && expected.contains(presented)) return socket;
    socket.destroy();
    throw CertificatePinningException(
      host: host,
      failure: presented == null
          ? PinFailure.unreadableCertificate
          : PinFailure.mismatch,
      expected: expected,
      presented: presented,
    );
  }
}

/// dio's `IOHttpClientAdapter` on an `HttpClient` from
/// [createIoHttpClient], reporting a pin failure as a `badCertificate`
/// `DioException`, which `RetryInterceptor` never retries.
class PinningIoAdapter implements HttpClientAdapter {
  /// Creates an adapter configured by [box].
  new(IoAdapterConfig box, {required bool trustAny})
    : _inner = IOHttpClientAdapter(
        createHttpClient: () => createIoHttpClient(box, trustAny: trustAny),
      );

  final IOHttpClientAdapter _inner;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    try {
      return await _inner.fetch(options, requestStream, cancelFuture);
    } on CertificatePinningException catch (error, stackTrace) {
      throw DioException.badCertificate(
        requestOptions: options,
        error: error,
      ).copyWith(stackTrace: stackTrace);
    }
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}
