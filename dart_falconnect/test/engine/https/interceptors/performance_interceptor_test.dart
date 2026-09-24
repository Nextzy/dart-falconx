import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show clock;
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '_scripted_adapter.dart';

void main() {
  test('records a completed request with its timing and sizes', () {
    fakeAsync((async) {
      final interceptor = PerformanceInterceptor();
      final adapter = GatedAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = adapter
        ..transformer = FoldingTransformer()
        ..interceptors.add(interceptor);

      dio.get<dynamic>('/x').ignore();
      async.elapse(const Duration(milliseconds: 500));
      adapter.requests.single.respond(200);
      async.elapse(Duration.zero);

      final metrics = interceptor.getRecentMetrics();
      expect(metrics, hasLength(1));
      expect(metrics.single.method, 'GET');
      expect(metrics.single.url, 'https://a.test/x');
      expect(metrics.single.statusCode, 200);
      expect(metrics.single.error, isNull);
      expect(metrics.single.endTime, isNotNull);
      expect(metrics.single.requestSize, greaterThan(0));
      expect(metrics.single.responseSize, greaterThan(0));
      expect(
        metrics.single.totalDuration.inMilliseconds,
        greaterThanOrEqualTo(500),
      );

      final stats = interceptor.getStatistics();
      expect(stats.totalRequests, 1);
      expect(stats.successfulRequests, 1);
      expect(stats.failedRequests, 0);
      expect(stats.statusCodeCounts, {200: 1});
      expect(stats.successRate, 100.0);
    });
  });

  test('records a failed request with its error and status', () {
    fakeAsync((async) {
      final interceptor = PerformanceInterceptor();
      final adapter = GatedAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = adapter
        ..transformer = FoldingTransformer()
        ..interceptors.add(interceptor);

      dio
          .get<dynamic>('/x')
          .then((_) => fail('unreachable'), onError: (_) {})
          .ignore();
      async.elapse(const Duration(milliseconds: 300));
      adapter.requests.single.respond(500);
      async.elapse(Duration.zero);

      final metrics = interceptor.getRecentMetrics();
      expect(metrics, hasLength(1));
      expect(metrics.single.statusCode, 500);
      expect(metrics.single.error, contains('badResponse'));
      expect(metrics.single.responseSize, isNotNull);

      final stats = interceptor.getStatistics();
      expect(stats.totalRequests, 1);
      expect(stats.successfulRequests, 0);
      expect(stats.failedRequests, 1);
      expect(stats.errorCounts, {metrics.single.error: 1});
      expect(stats.successRate, 0.0);
    });
  });

  test('records a network error without a response', () {
    fakeAsync((async) {
      final interceptor = PerformanceInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = ScriptedAdapter([
          failWith(DioExceptionType.connectionTimeout),
        ])
        ..transformer = FoldingTransformer()
        ..interceptors.add(interceptor);

      dio
          .get<dynamic>('/x')
          .then((_) => fail('unreachable'), onError: (_) {})
          .ignore();
      async.elapse(const Duration(milliseconds: 10));

      final metrics = interceptor.getRecentMetrics();
      expect(metrics, hasLength(1));
      expect(metrics.single.statusCode, isNull);
      expect(metrics.single.responseSize, isNull);
      expect(metrics.single.error, contains('connectionTimeout'));

      final stats = interceptor.getStatistics();
      expect(stats.failedRequests, 1);
      expect(stats.statusCodeCounts, isEmpty);
    });
  });

  test('RequestMetrics.toJson reports the request shape', () {
    fakeAsync((async) {
      final interceptor = PerformanceInterceptor();
      final adapter = GatedAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = adapter
        ..transformer = FoldingTransformer()
        ..interceptors.add(interceptor);

      dio.get<dynamic>('/x').ignore();
      async.elapse(const Duration(milliseconds: 250));
      adapter.requests.single.respond(200);
      async.elapse(Duration.zero);

      final json = interceptor.getRecentMetrics().single.toJson();
      expect(
        json.keys,
        unorderedEquals(<String>[
          'method',
          'url',
          'startTime',
          'endTime',
          'statusCode',
          'error',
          'totalDuration',
          'requestSize',
          'responseSize',
        ]),
      );
      expect(json['method'], 'GET');
      expect(json['url'], 'https://a.test/x');
      expect(json['startTime'], isA<String>());
      expect(json['endTime'], isA<String>());
      expect(json['statusCode'], 200);
      expect(json['error'], isNull);
      expect(json['totalDuration'], greaterThanOrEqualTo(250));
      expect(json['requestSize'], greaterThan(0));
      expect(json['responseSize'], greaterThan(0));
    });
  });

  test('RequestMetrics is immutable and copyWith keeps the start', () {
    fakeAsync((async) {
      final start = clock.now();
      final inFlight = RequestMetrics(
        method: 'GET',
        url: 'https://a.test/x',
        startTime: start,
        requestSize: 12,
      );
      async.elapse(const Duration(milliseconds: 40));

      final completed = inFlight.copyWith(
        endTime: clock.now(),
        statusCode: 200,
        responseSize: 34,
      );

      expect(inFlight.endTime, isNull);
      expect(inFlight.statusCode, isNull);
      expect(inFlight.totalDuration, const Duration(milliseconds: 40));
      expect(completed.startTime, start);
      expect(completed.method, 'GET');
      expect(completed.requestSize, 12);
      expect(completed.statusCode, 200);
      expect(completed.responseSize, 34);
    });
  });

  test('getStatistics aggregates durations and sizes across requests', () {
    fakeAsync((async) {
      final interceptor = PerformanceInterceptor();
      final adapter = GatedAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = adapter
        ..transformer = FoldingTransformer()
        ..interceptors.add(interceptor);

      dio.get<dynamic>('/x').ignore();
      async.elapse(const Duration(milliseconds: 100));
      adapter.requests[0].respond(200);
      async.elapse(Duration.zero);

      dio.get<dynamic>('/y').ignore();
      async.elapse(const Duration(milliseconds: 300));
      adapter.requests[1].respond(404);
      async.elapse(Duration.zero);

      dio.get<dynamic>('/z').ignore();
      async.elapse(const Duration(milliseconds: 50));
      adapter.requests[2].respond(200);
      async.elapse(Duration.zero);

      final stats = interceptor.getStatistics();
      expect(stats.totalRequests, 3);
      expect(stats.successfulRequests, 2);
      expect(stats.failedRequests, 1);
      expect(stats.statusCodeCounts, {200: 2, 404: 1});
      expect(stats.totalRequestSize, greaterThan(0));
      expect(stats.totalResponseSize, greaterThan(0));
      expect(stats.totalDuration, const Duration(milliseconds: 450));
      expect(stats.minDuration, const Duration(milliseconds: 50));
      expect(stats.maxDuration, const Duration(milliseconds: 300));
      // Integer division of 450 ms by 3 truncates to 150 ms.
      expect(stats.averageDuration, const Duration(milliseconds: 150));
      expect(stats.medianDuration, const Duration(milliseconds: 100));
      expect(stats.toJson()['averageResponseSize'], greaterThan(0));
    });
  });

  test('getUrlStatistics groups numeric path segments under one pattern', () {
    fakeAsync((async) {
      final interceptor = PerformanceInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = ScriptedAdapter([reply(200), reply(200)])
        ..transformer = FoldingTransformer()
        ..interceptors.add(interceptor);

      dio.get<dynamic>('/users/1').ignore();
      async.elapse(Duration.zero);
      dio.get<dynamic>('/users/42').ignore();
      async.elapse(Duration.zero);

      final byUrl = interceptor.getUrlStatistics();
      expect(byUrl.keys, ['https://a.test/users/{id}']);
      expect(byUrl.values.single.totalRequests, 2);
    });
  });

  test('a statistics snapshot stays unchanged by later requests', () {
    fakeAsync((async) {
      final interceptor = PerformanceInterceptor();
      final adapter = GatedAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = adapter
        ..transformer = FoldingTransformer()
        ..interceptors.add(interceptor);

      dio.get<dynamic>('/x').ignore();
      async.elapse(const Duration(milliseconds: 100));
      adapter.requests[0].respond(200);
      async.elapse(Duration.zero);

      final early = interceptor.getStatistics();
      expect(early.totalRequests, 1);
      expect(early.recentDurations, hasLength(1));

      dio.get<dynamic>('/y').ignore();
      async.elapse(const Duration(milliseconds: 50));
      adapter.requests[1].respond(500);
      async.elapse(Duration.zero);

      final late = interceptor.getStatistics();
      expect(late.totalRequests, 2);
      expect(late.successfulRequests, 1);
      expect(early.totalRequests, 1);
      expect(early.successfulRequests, 1);
      expect(early.failedRequests, 0);
      expect(early.recentDurations, hasLength(1));
    });
  });

  test('statistics snapshots expose unmodifiable collections', () {
    fakeAsync((async) {
      final interceptor = PerformanceInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = ScriptedAdapter([reply(200)])
        ..transformer = FoldingTransformer()
        ..interceptors.add(interceptor);

      dio.get<dynamic>('/x').ignore();
      async.elapse(Duration.zero);

      final stats = interceptor.getStatistics();
      expect(() => stats.statusCodeCounts[500] = 1, throwsUnsupportedError);
      expect(() => stats.errorCounts['boom'] = 1, throwsUnsupportedError);
      expect(
        () => stats.recentDurations.add(Duration.zero),
        throwsUnsupportedError,
      );
      expect(
        () => interceptor.getUrlStatistics()['https://a.test/x'] = interceptor
            .getStatistics(),
        throwsUnsupportedError,
      );
    });
  });

  test('getRecentMetrics keeps only the newest maxMetricsHistory entries', () {
    fakeAsync((async) {
      final interceptor = PerformanceInterceptor(
        config: const PerformanceConfig(maxMetricsHistory: 2),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = ScriptedAdapter([
          reply(200),
          reply(200),
          reply(200),
        ])
        ..transformer = FoldingTransformer()
        ..interceptors.add(interceptor);

      dio.get<dynamic>('/a').ignore();
      async.elapse(Duration.zero);
      dio.get<dynamic>('/b').ignore();
      async.elapse(Duration.zero);
      dio.get<dynamic>('/c').ignore();
      async.elapse(Duration.zero);

      expect(
        [for (final metrics in interceptor.getRecentMetrics()) metrics.url],
        ['https://a.test/b', 'https://a.test/c'],
      );
      expect(
        [
          for (final metrics in interceptor.getRecentMetrics(limit: 1))
            metrics.url,
        ],
        ['https://a.test/c'],
      );
      expect(interceptor.getStatistics().totalRequests, 3);
    });
  });

  test('clear resets every collected metric and statistic', () {
    fakeAsync((async) {
      final interceptor = PerformanceInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'https://a.test'))
        ..httpClientAdapter = ScriptedAdapter([reply(200)])
        ..transformer = FoldingTransformer()
        ..interceptors.add(interceptor);

      dio.get<dynamic>('/x').ignore();
      async.elapse(Duration.zero);
      expect(interceptor.getStatistics().totalRequests, 1);

      interceptor.clear();
      expect(interceptor.getRecentMetrics(), isEmpty);
      expect(interceptor.getStatistics().totalRequests, 0);
      expect(interceptor.getUrlStatistics(), isEmpty);
    });
  });
}
