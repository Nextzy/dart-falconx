import 'dart:async';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/rate_limit_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

/// Handler that records the options it forwards, standing in for the next
/// interceptor in the chain.
class _RecordingHandler extends RequestInterceptorHandler {
  new({required this.forwarded});

  final List<RequestOptions> forwarded;

  @override
  void next(RequestOptions requestOptions) {
    forwarded.add(requestOptions);
    super.next(requestOptions);
  }
}

void main() {
  test('drains every queued request when elapse advances time', () {
    fakeAsync((async) {
      final interceptor = RateLimitInterceptor(
        config: const HttpClientConfig(enableLogging: false),
        globalRateLimit: 1,
        perHostRateLimit: 1,
        queueRequests: true,
        maxQueueSize: 10,
      );

      final forwarded = <RequestOptions>[];
      var resolved = 0;

      void send(int index) {
        final handler = _RecordingHandler(forwarded: forwarded);
        final future = interceptor.onRequest(
          RequestOptions(
            path: '/test/$index',
            baseUrl: 'https://api.test.host',
          ),
          handler,
        );
        unawaited(future.then((_) => resolved++));
      }

      // Capacity is rateLimit * 10 = 10 tokens per bucket, so the first 10
      // requests pass straight through; requests 11-13 exceed capacity and
      // must queue instead of being rejected.
      for (var i = 0; i < 13; i++) {
        send(i);
      }
      async.flushMicrotasks();
      expect(
        forwarded.length,
        10,
        reason: 'only the capacity-worth of requests passes through unqueued',
      );

      // Advancing time refills the buckets and drains the queue: one token
      // per second per bucket, so ten seconds settle all three queued. The
      // completion counters are plain microtask callbacks, so they settle
      // with flushMicrotasks rather than a matcher that pumps real time.
      async
        ..elapse(const Duration(seconds: 10))
        ..flushMicrotasks();

      expect(resolved, 13, reason: 'every onRequest future completed');
      expect(forwarded.length, 13, reason: 'every queued request forwarded');
      expect(
        forwarded.map((options) => options.path),
        everyElement(startsWith('/test/')),
      );
    }, initialTime: DateTime.utc(2024, 6, 15, 12));
  });
}
