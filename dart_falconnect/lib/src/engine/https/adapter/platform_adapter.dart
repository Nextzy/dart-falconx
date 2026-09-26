/// Builds the platform's HTTP adapter from the box of `HttpClientConfig`
/// that the platform reads: `ioAdapter` on dart:io, `webAdapter` on the
/// web, and none elsewhere.
library;

export 'platform_adapter_stub.dart'
    if (dart.library.io) 'platform_adapter_io.dart'
    if (dart.library.js_interop) 'platform_adapter_web.dart';
