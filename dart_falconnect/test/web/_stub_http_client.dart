// Minimal concrete subclasses for web verification.
// Used by compile_smoke.dart and engine_web_test.dart.
// Not a public API — filename starts with underscore.
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falmodel/dart_falmodel.dart';

class StubHttpClient extends BaseHttpClient {
  StubHttpClient({required super.dio});
}

class StubSocketClient extends SocketClient {
  StubSocketClient(super.baseUrl);

  @override
  void setupConfig(SocketOptions configs) {
    // no-op — defaults from SocketClient are sufficient for smoke
  }
}
