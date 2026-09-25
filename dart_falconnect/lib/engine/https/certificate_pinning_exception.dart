/// Why a request to a pinned host failed.
enum PinFailure {
  /// The leaf certificate matches none of the host's pins.
  mismatch,

  /// The request would go through a proxy, where no pin can be checked.
  proxied,

  /// The request uses plain `http`, which has no certificate.
  plainHttp,

  /// The connection has no certificate, or its certificate cannot be read.
  unreadableCertificate,
}

/// A request to a pinned host failed before any of it was sent.
///
/// `BaseHttpClient` delivers it as the `error` of a `DioException` whose
/// type is `badCertificate`, which `RetryInterceptor` never retries.
class CertificatePinningException implements Exception {
  /// Creates a pinning failure for [host].
  const new({
    required this.host,
    required this.failure,
    required this.expected,
    this.presented,
  });

  /// The lowercase host of the request.
  final String host;

  /// Why the request failed.
  final PinFailure failure;

  /// The host's pins.
  final Set<String> expected;

  /// The pin of the certificate the server presented, when one was read.
  final String? presented;

  @override
  String toString() {
    final pins = expected.join(', ');
    return switch (failure) {
      PinFailure.mismatch =>
        'CertificatePinningException: $host presented $presented, '
            'expected one of $pins',
      PinFailure.proxied =>
        'CertificatePinningException: $host is pinned and cannot be '
            'reached through a proxy',
      PinFailure.plainHttp =>
        'CertificatePinningException: $host is pinned and cannot be '
            'reached over plain http',
      PinFailure.unreadableCertificate =>
        'CertificatePinningException: $host presented no readable '
            'certificate, expected one of $pins',
    };
  }
}
