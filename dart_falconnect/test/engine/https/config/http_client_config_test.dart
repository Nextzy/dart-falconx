import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

bool _acceptAll(int? status) => true;

void main() {
  test('defaults reproduce the options of DefaultHttpClient', () {
    const config = HttpClientConfig();

    expect(config.baseUrl, '');
    expect(config.connectTimeout, const Duration(seconds: 20));
    expect(config.receiveTimeout, const Duration(seconds: 20));
    expect(config.sendTimeout, isNull);
    expect(config.contentType, Headers.jsonContentType);
    expect(config.headers, isEmpty);
    expect(config.validateStatus, isNull);
    expect(config.rateLimit, const RateLimitConfig.none());
    expect(config.log, isNull);
    expect(config.cache, isNull);
    expect(config.concurrency, isNull);
    expect(config.retry, isNull);
    expect(config.interceptors, isEmpty);
    expect(config.exceptionHandler, isNull);
  });

  test('copyWith turns a box off with null', () {
    const config = HttpClientConfig(log: LogConfig(), retry: RetryConfig());

    final quiet = config.copyWith(log: null);

    expect(quiet.log, isNull);
    expect(quiet.retry, const RetryConfig());
  });

  test('effectiveHeaders adds User-Agent when set', () {
    const config = HttpClientConfig(
      headers: {'X-A': '1'},
      userAgent: 'falcon/2',
    );

    expect(config.effectiveHeaders, {'X-A': '1', 'User-Agent': 'falcon/2'});
    expect(const HttpClientConfig().effectiveHeaders, isEmpty);
  });

  test('applyTo writes the owned fields and leaves the others', () {
    final dio = Dio(
      BaseOptions(headers: {'X-Old': 'kept'}, responseType: ResponseType.plain),
    );
    final validate = dio.options.validateStatus;

    const HttpClientConfig(
      baseUrl: 'https://a.test',
      sendTimeout: Duration(seconds: 3),
      headers: {'X-New': '1'},
      maxRedirects: 2,
    ).applyTo(dio);

    expect(dio.options.baseUrl, 'https://a.test');
    expect(dio.options.sendTimeout, const Duration(seconds: 3));
    expect(dio.options.maxRedirects, 2);
    expect(dio.options.contentType, Headers.jsonContentType);
    expect(dio.options.headers['X-Old'], 'kept');
    expect(dio.options.headers['X-New'], '1');
    expect(dio.options.responseType, ResponseType.plain);
    expect(dio.options.validateStatus, same(validate));
  });

  test('applyTo writes validateStatus when it is set', () {
    final dio = Dio();

    const HttpClientConfig(validateStatus: _acceptAll).applyTo(dio);

    expect(dio.options.validateStatus(404), isTrue);
  });
}
