import 'package:dart_falconnect/src/engine/https/adapter/spki.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/host_key.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/io_adapter_config.freezed.dart';

/// Settings of the dart:io adapter that a `BaseHttpClient` builds; a
/// non-null box replaces the adapter on Android, iOS, macOS, Windows,
/// Linux, and servers. The web ignores this box.
@freezed
abstract class IoAdapterConfig with _$IoAdapterConfig {
  /// Creates dart:io adapter settings.
  const factory({
    /// Most open connections to one host; null means no limit. Requests
    /// past the limit wait inside `HttpClient`, and that wait counts
    /// toward `connectTimeout`: keep it at or above any per-host limit of
    /// `ConcurrencyConfig`.
    int? maxConnectionsPerHost,

    /// How long an idle connection stays open for reuse. The default is
    /// the value dio uses.
    @Default(Duration(seconds: 3)) Duration idleTimeout,

    /// Proxy for every request, as `host:port`; null keeps the dart:io
    /// default, which reads `https_proxy`, `http_proxy`, and `no_proxy`
    /// (either case) from the environment. A request that cannot reach
    /// the proxy goes direct, except to a pinned host.
    String? proxy,

    /// Certificate pins keyed by host. Each pin is `sha256/` followed by
    /// the base64 SHA-256 of the leaf certificate's SubjectPublicKeyInfo.
    /// A request to a listed host succeeds only when the leaf matches one
    /// pin, and fails when it goes through a proxy or over plain `http`.
    /// List a backup pin for every host.
    @Default(<String, Set<String>>{}) Map<String, Set<String>> pins,

    /// Trusts every certificate chain, for a debugging proxy such as
    /// Proxyman. It takes effect only while assertions are enabled:
    /// Flutter debug builds, `dart test`, and `dart run --enable-asserts`.
    /// Release builds and `dart compile exe` ignore it. Pins still apply.
    @Default(false) bool debugTrustAnyCertificate,
  }) = _IoAdapterConfig;

  const new _();

  /// Throws [ArgumentError] when a field is malformed.
  void validate() {
    final max = maxConnectionsPerHost;
    if (max != null && max < 1) {
      throw ArgumentError('maxConnectionsPerHost must be at least 1');
    }
    if (idleTimeout.isNegative) {
      throw ArgumentError('idleTimeout must not be negative');
    }
    final proxy = this.proxy;
    if (proxy != null && !_isProxy(proxy)) {
      throw ArgumentError('proxy "$proxy" must be host:port');
    }
    for (final MapEntry(key: host, value: hostPins) in pins.entries) {
      if (host.isEmpty) {
        throw ArgumentError('pin host "" is empty');
      }
      final key = host.toLowerCase();
      // A wildcard or a trailing dot never equals a request's host.
      if (!isHostKey(key) || key.contains('*') || key.endsWith('.')) {
        throw ArgumentError('pin host "$host" must be a bare host name');
      }
      if (hostPins.isEmpty) {
        throw ArgumentError('pin host "$host" has no pin');
      }
      for (final pin in hostPins) {
        if (canonicalPin(pin) == null) {
          throw ArgumentError(
            'pin "$pin" for $host must be "sha256/" followed by base64 '
            'of 32 bytes',
          );
        }
      }
    }
  }

  /// Whether [proxy] is a host name or IPv4 address, a colon, and a port
  /// from 1 to 65535.
  static bool _isProxy(String proxy) {
    final colon = proxy.lastIndexOf(':');
    if (colon <= 0) return false;
    final host = proxy.substring(0, colon);
    final port = proxy.substring(colon + 1);
    if (host.contains(':') || !isHostKey(host.toLowerCase())) return false;
    if (!RegExp(r'^\d{1,5}$').hasMatch(port)) return false;
    final number = int.parse(port);
    return number >= 1 && number <= 65535;
  }
}
