// Run by io_adapter_test.dart in a process of its own, so the debug switch
// meets a VM whose assertions are off, as in a release build. Prints
// `trusted` when the self-signed server answers, `rejected` when its
// handshake fails.
import 'dart:io';

import 'package:dart_falconnect/dart_falconnect.dart';

class _Client extends BaseHttpClient {
  new()
    : super(
        dio: Dio(),
        config: const HttpClientConfig(
          ioAdapter: IoAdapterConfig(debugTrustAnyCertificate: true),
        ),
      );
}

Future<void> main() async {
  final context = SecurityContext()
    ..useCertificateChain('test/fixtures/localhost.crt.pem')
    ..usePrivateKey('test/fixtures/localhost.key.pem');
  final server = await HttpServer.bindSecure(
    InternetAddress.loopbackIPv4,
    0,
    context,
  );
  server.listen((request) => request.response.close());
  final client = _Client();
  try {
    await client.dio.get<Object?>('https://localhost:${server.port}/');
    stdout.write('trusted');
  } on DioException catch (error) {
    stdout.write(
      error.error is HandshakeException ? 'rejected' : 'error: ${error.error}',
    );
  } finally {
    client.dispose();
    await server.close(force: true);
  }
}
