import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

String _variant(LogConfig config) => switch (config) {
  PrettyLogConfig() => 'pretty',
  JsonLogConfig() => 'json',
};

void main() {
  test('LogConfig() is the pretty variant with the defaults of 2.0.0', () {
    expect(const LogConfig(), isA<PrettyLogConfig>());

    const config = LogConfig() as PrettyLogConfig;
    expect(config.request, isTrue);
    expect(config.requestHeader, isTrue);
    expect(config.requestBody, isTrue);
    expect(config.responseHeader, isFalse);
    expect(config.responseBody, isTrue);
    expect(config.error, isTrue);
  });

  test('LogConfig.json() logs no header or body by default', () {
    expect(const LogConfig.json(), isA<JsonLogConfig>());

    const config = LogConfig.json() as JsonLogConfig;
    expect(config.requestHeaders, isFalse);
    expect(config.responseHeaders, isFalse);
    expect(config.requestBody, isFalse);
    expect(config.responseBody, isFalse);
    expect(config.maxBodyBytes, 4096);
  });

  test('a switch over both variants is exhaustive', () {
    expect(
      [_variant(const LogConfig()), _variant(const LogConfig.json())],
      ['pretty', 'json'],
    );
  });

  test('the shared fields read through the LogConfig type', () {
    for (final config in const <LogConfig>[LogConfig(), LogConfig.json()]) {
      expect(config.redactHeaders, defaultRedactedHeaders);
      expect(config.redactQueryParameters, defaultRedactedQueryParameters);
      expect(config.logPrint, isNull);
      expect(config.diagnostics, isTrue);
    }
  });

  test('variants compare by value', () {
    expect(const LogConfig.json(), const JsonLogConfig());
    expect(
      const LogConfig.json(maxBodyBytes: 10),
      isNot(const LogConfig.json()),
    );
    expect(const LogConfig(), isNot(const LogConfig.json()));
    expect(
      const LogConfig(redactHeaders: {'x-a'}),
      const LogConfig(redactHeaders: {'x-a'}),
    );
  });
}
