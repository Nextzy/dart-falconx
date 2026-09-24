import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

void main() {
  group('PerformanceStatistics.toJson characterization', () {
    const stats = PerformanceStatistics(
      totalRequests: 3,
      successfulRequests: 2,
      failedRequests: 1,
      statusCodeCounts: {200: 2, 404: 1},
      errorCounts: {'timeout': 1},
      totalRequestSize: 30,
      totalResponseSize: 90,
      totalDuration: Duration(milliseconds: 450),
      minDuration: Duration(milliseconds: 50),
      maxDuration: Duration(milliseconds: 300),
      recentDurations: [
        Duration(milliseconds: 100),
        Duration(milliseconds: 300),
        Duration(milliseconds: 50),
      ],
    );

    test('emits every key with computed values', () {
      // statusCodeCounts keys stringify: JSON object keys must be strings.
      expect(stats.toJson(), {
        'totalRequests': 3,
        'successfulRequests': 2,
        'failedRequests': 1,
        'successRate': 2 / 3 * 100,
        'statusCodeCounts': {'200': 2, '404': 1},
        'errorCounts': {'timeout': 1},
        'totalRequestSize': 30,
        'totalResponseSize': 90,
        'averageRequestSize': 10,
        'averageResponseSize': 30,
        'totalDuration': 450,
        'averageDuration': 150,
        'medianDuration': 100,
        'minDuration': 50,
        'maxDuration': 300,
      });
    });

    test("emits exactly today's key set", () {
      expect(
        stats.toJson().keys,
        unorderedEquals([
          'totalRequests',
          'successfulRequests',
          'failedRequests',
          'successRate',
          'statusCodeCounts',
          'errorCounts',
          'totalRequestSize',
          'totalResponseSize',
          'averageRequestSize',
          'averageResponseSize',
          'totalDuration',
          'averageDuration',
          'medianDuration',
          'minDuration',
          'maxDuration',
        ]),
      );
    });

    test('zero requests divide by zero into zeros, not throws', () {
      const empty = PerformanceStatistics(
        totalRequests: 0,
        successfulRequests: 0,
        failedRequests: 0,
        statusCodeCounts: {},
        errorCounts: {},
        totalRequestSize: 0,
        totalResponseSize: 0,
        totalDuration: Duration.zero,
        minDuration: Duration.zero,
        maxDuration: Duration.zero,
        recentDurations: [],
      );

      final json = empty.toJson();
      expect(json['successRate'], 0.0);
      expect(json['averageRequestSize'], 0);
      expect(json['averageResponseSize'], 0);
      expect(json['averageDuration'], 0);
      expect(json['medianDuration'], 0);
    });

    test('even window averages the two middle durations', () {
      const even = PerformanceStatistics(
        totalRequests: 2,
        successfulRequests: 2,
        failedRequests: 0,
        statusCodeCounts: {},
        errorCounts: {},
        totalRequestSize: 0,
        totalResponseSize: 0,
        totalDuration: Duration(milliseconds: 300),
        minDuration: Duration(milliseconds: 100),
        maxDuration: Duration(milliseconds: 200),
        recentDurations: [
          Duration(milliseconds: 100),
          Duration(milliseconds: 201),
        ],
      );

      // (100 + 201) / 2 truncates to 150.
      expect(even.toJson()['medianDuration'], 150);
    });
  });
}
