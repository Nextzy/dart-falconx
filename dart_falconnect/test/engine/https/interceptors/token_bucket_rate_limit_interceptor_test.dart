import 'dart:async';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falconnect/engine/https/interceptors/token_bucket_rate_limit_interceptor.dart';
import 'package:dart_faltool/dart_faltool.dart'
    show RateLimitExceededException, TokenBucketPolicy;
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

/// Records what the interceptor does with each request, standing in for the
/// rest of the Dio chain.
class _RecordingHandler extends RequestInterceptorHandler {
  new(this.log);

  final _Log log;

  @override
  void next(RequestOptions requestOptions) => log.forwarded.add(requestOptions);

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) {
    log.rejected.add(error);
    log.rejectCallsFollowing.add(callFollowingErrorInterceptor);
  }
}

/// Records the fake time at which each request is forwarded.
class _TimedHandler extends _RecordingHandler {
  new(super.log, this.async, this.sentAt);

  final FakeAsync async;
  final List<Duration> sentAt;

  @override
  void next(RequestOptions requestOptions) {
    super.next(requestOptions);
    sentAt.add(async.elapsed);
  }
}

class _Log {
  final forwarded = <RequestOptions>[];
  final rejected = <DioException>[];
  final rejectCallsFollowing = <bool>[];
}

/// Swallows `next` so an unobserved handler future never reports an error.
class _SilentResponseHandler extends ResponseInterceptorHandler {
  @override
  void next(Response<dynamic> response) {}
}

/// Swallows `next` so an unobserved handler future never reports an error.
class _SilentErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException error) {}
}

Response<dynamic> _serverResponse(
  int status, {
  String host = 'a.test',
  String? retryAfter,
}) => Response<dynamic>(
  requestOptions: RequestOptions(path: 'https://$host/items'),
  statusCode: status,
  headers: Headers.fromMap({
    if (retryAfter != null) 'retry-after': [retryAfter],
  }),
);

/// Feeds a server response through `onResponse`, as a client whose
/// `validateStatus` accepts 429 would.
void _respond(
  TokenBucketRateLimitInterceptor interceptor,
  Response<dynamic> response,
) => interceptor.onResponse(response, _SilentResponseHandler());

/// Feeds a server error through `onError`.
void _fail(
  TokenBucketRateLimitInterceptor interceptor,
  Response<dynamic> response,
) => interceptor.onError(
  DioException.badResponse(
    statusCode: response.statusCode!,
    requestOptions: response.requestOptions,
    response: response,
  ),
  _SilentErrorHandler(),
);

const _config = HttpClientConfig();

void _send(
  TokenBucketRateLimitInterceptor interceptor,
  _Log log, {
  String url = 'https://a.test/items',
  int times = 1,
}) {
  for (var i = 0; i < times; i++) {
    unawaited(
      interceptor.onRequest(RequestOptions(path: url), _RecordingHandler(log)),
    );
  }
}

void main() {
  test('forwards synchronously and creates no timer when no policy is set', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(config: _config);
      final log = _Log();

      _send(interceptor, log, times: 20);

      expect(log.forwarded, hasLength(20));
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('forwards requests within burst without waiting', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 10, per: Duration(seconds: 1), burst: 5),
        ],
      );
      final log = _Log();

      _send(interceptor, log, times: 5);
      async.flushMicrotasks();

      expect(log.forwarded, hasLength(5));
      interceptor.dispose();
    });
  });

  test('drains queued requests at the refill rate', () {
    fakeAsync((async) {
      // Burst 10, then (13 - 10 + 1) = 4 refills per 10 s: one every 2.5 s.
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 13, per: Duration(seconds: 10), burst: 10),
        ],
      );
      final log = _Log();

      _send(interceptor, log, times: 13);
      async.flushMicrotasks();
      expect(log.forwarded, hasLength(10));

      async.elapse(const Duration(milliseconds: 2400));
      expect(log.forwarded, hasLength(10));

      async.elapse(const Duration(milliseconds: 5100));
      expect(log.forwarded, hasLength(13));
      expect(log.rejected, isEmpty);
      interceptor.dispose();
    });
  });

  test('a hosts entry replaces perHost for that host', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 2, per: Duration(seconds: 1), burst: 2),
        ],
        hosts: const {
          'b.test': [
            TokenBucketPolicy(permits: 5, per: Duration(seconds: 1), burst: 5),
          ],
        },
      );
      final logA = _Log();
      final logB = _Log();

      _send(interceptor, logA, times: 5);
      _send(interceptor, logB, url: 'https://b.test/items', times: 5);
      async.flushMicrotasks();

      expect(logA.forwarded, hasLength(2));
      expect(logB.forwarded, hasLength(5));
      interceptor.dispose();
    });
  });

  test('an empty hosts entry opts the host out of perHost', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
        hosts: const {'free.test': []},
      );
      final log = _Log();

      _send(interceptor, log, url: 'https://free.test/items', times: 20);

      expect(log.forwarded, hasLength(20));
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('matches hosts case-insensitively through Uri', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        hosts: const {
          'api.partner.test': [
            TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
          ],
        },
      );
      final log = _Log();

      _send(interceptor, log, url: 'https://API.Partner.test/x', times: 3);
      async.flushMicrotasks();

      expect(log.forwarded, hasLength(1));
      interceptor.dispose();
    });
  });

  test('rejects a hosts key that is not lowercase', () {
    expect(
      () => TokenBucketRateLimitInterceptor(
        config: _config,
        hosts: const {
          'API.partner.test': [
            TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
          ],
        },
      ),
      throwsArgumentError,
    );
  });

  test('rejects an invalid perHost or hosts policy at construction', () {
    const invalid = TokenBucketPolicy(permits: 0, per: Duration(seconds: 1));
    expect(
      () => TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [invalid],
      ),
      throwsArgumentError,
    );
    expect(
      () => TokenBucketRateLimitInterceptor(
        config: _config,
        hosts: const {
          'a.test': [invalid],
        },
      ),
      throwsArgumentError,
    );
  });

  test('limits the same host across ports', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
      );
      final log = _Log();

      _send(interceptor, log, url: 'https://a.test:8443/x');
      _send(interceptor, log, url: 'https://a.test:9443/x');
      async.flushMicrotasks();

      expect(log.forwarded, hasLength(1));
      interceptor.dispose();
    });
  });

  test('every tier holds its own ceiling', () {
    fakeAsync((async) {
      // Tier 1: 5 per second, burst 5. Tier 2: 8 per minute, burst 8.
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 5, per: Duration(seconds: 1), burst: 5),
          TokenBucketPolicy(permits: 8, per: Duration(minutes: 1), burst: 8),
        ],
      );
      final log = _Log();

      _send(interceptor, log, times: 20);
      async.flushMicrotasks();
      expect(log.forwarded, hasLength(5), reason: 'tier 1 burst');

      async.elapse(const Duration(seconds: 10));
      expect(log.forwarded, hasLength(8), reason: 'tier 2 ceiling');

      async.elapse(const Duration(seconds: 50));
      expect(log.forwarded, hasLength(9), reason: 'tier 2 refill at 60 s');
      interceptor.dispose();
    });
  });

  test('global tiers are shared by every host', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        global: const [
          TokenBucketPolicy(permits: 3, per: Duration(minutes: 1), burst: 3),
        ],
      );
      final log = _Log();

      _send(interceptor, log, times: 2);
      _send(interceptor, log, url: 'https://b.test/items', times: 2);
      async.flushMicrotasks();

      expect(log.forwarded, hasLength(3));
      expect(interceptor.getStatistics().globalWaiting, 1);
      interceptor.dispose();
    });
  });

  test('rejects with 429 when a queue is full', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
        maxQueueSize: 2,
      );
      final log = _Log();

      _send(interceptor, log, times: 4);
      async.flushMicrotasks();

      expect(log.forwarded, hasLength(1));
      expect(log.rejected, hasLength(1));
      final error = log.rejected.single;
      expect(error.type, DioExceptionType.badResponse);
      expect(error.response?.statusCode, 429);
      expect(error.response?.isLocalRateLimit, isTrue);
      expect(error.error, isA<RateLimitExceededException>());
      expect(log.rejectCallsFollowing.single, isTrue);

      final stats = interceptor.getStatistics();
      expect(stats.forwarded, 1);
      expect(stats.rejected, 1);
      expect(stats.waitingByHost, {'a.test': 2});
      expect(stats.globalWaiting, 0);
      interceptor.dispose();
    });
  });

  test('rejects at once when queueRequests is false', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
        queueRequests: false,
      );
      final log = _Log();

      _send(interceptor, log, times: 2);
      async.flushMicrotasks();

      expect(log.forwarded, hasLength(1));
      expect(log.rejected.single.response?.statusCode, 429);
      interceptor.dispose();
    });
  });

  test('dispose cancels waiting and new limited requests only', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ],
        hosts: const {'free.test': []},
      );
      final log = _Log();

      _send(interceptor, log, times: 3);
      async.flushMicrotasks();
      expect(log.forwarded, hasLength(1));

      interceptor
        ..dispose()
        ..dispose();
      async.flushMicrotasks();
      expect(log.rejected, hasLength(2));
      expect(
        log.rejected.map((e) => e.type),
        everyElement(DioExceptionType.cancel),
      );

      _send(interceptor, log, url: 'https://new.test/x');
      _send(interceptor, log, url: 'https://free.test/x');
      async.flushMicrotasks();
      expect(log.rejected, hasLength(3));
      expect(log.rejected.last.type, DioExceptionType.cancel);
      expect(log.forwarded, hasLength(2));
      expect(async.pendingTimers, isEmpty);
    });
  });

  group('pause', () {
    test('a 429 seen in onResponse pauses only its host', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(config: _config);
        final log = _Log();
        _respond(interceptor, _serverResponse(429, retryAfter: '3'));

        _send(interceptor, log);
        _send(interceptor, log, url: 'https://b.test/items');
        async.flushMicrotasks();
        expect(log.forwarded.map((o) => o.uri.host), ['b.test']);

        async.elapse(const Duration(seconds: 3));
        expect(log.forwarded, hasLength(2));
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('a 429 seen in onError pauses its host', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(config: _config);
        final log = _Log();
        _fail(interceptor, _serverResponse(429, retryAfter: '3'));

        _send(interceptor, log);
        async.flushMicrotasks();
        expect(log.forwarded, isEmpty);
        expect(interceptor.getStatistics().heldByHost, {'a.test': 1});
        expect(interceptor.getStatistics().pausedUntilByHost.keys, ['a.test']);

        async.elapse(const Duration(seconds: 3));
        expect(log.forwarded, hasLength(1));
      });
    });

    test('rejects with a local 429 when the pause exceeds maxPauseWait', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(config: _config);
        final log = _Log();
        _respond(interceptor, _serverResponse(429, retryAfter: '60'));

        _send(interceptor, log);
        async.flushMicrotasks();

        final error = log.rejected.single;
        expect(error.type, DioExceptionType.badResponse);
        expect(error.response?.isLocalRateLimit, isTrue);
        expect(error.response?.headers.value('retry-after'), '60');
        expect(log.rejectCallsFollowing.single, isTrue);
        expect(interceptor.getStatistics().rejected, 1);
      });
    });

    test('queueRequests false rejects instead of holding', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(
          config: _config,
          queueRequests: false,
        );
        final log = _Log();
        _respond(interceptor, _serverResponse(429, retryAfter: '1'));

        _send(interceptor, log);
        async.flushMicrotasks();

        expect(log.rejected.single.response?.statusCode, 429);
      });
    });

    test('a local 429 fed back through onError starts no pause', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(
          config: _config,
          perHost: const [
            TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
          ],
          queueRequests: false,
        );
        final log = _Log();
        _send(interceptor, log, times: 2);
        async.flushMicrotasks();

        interceptor.onError(log.rejected.single, _SilentErrorHandler());
        expect(interceptor.getStatistics().pausedUntilByHost, isEmpty);
        interceptor.dispose();
      });
    });

    test('forwards nothing during a pause, then keeps the ceiling', () {
      fakeAsync((async) {
        // One token per second, burst 1.
        final interceptor = TokenBucketRateLimitInterceptor(
          config: _config,
          perHost: const [
            TokenBucketPolicy(permits: 1, per: Duration(seconds: 1)),
          ],
        );
        final sentAt = <Duration>[];
        final log = _Log();
        for (var i = 0; i < 5; i++) {
          unawaited(
            interceptor.onRequest(
              RequestOptions(path: 'https://a.test/items'),
              _TimedHandler(log, async, sentAt),
            ),
          );
        }
        async.flushMicrotasks();
        expect(sentAt, [Duration.zero]);

        // The server answers the first request with a 3 s pause. Requests
        // that get tokens at 1 s and 2 s must not be forwarded.
        _respond(interceptor, _serverResponse(429, retryAfter: '3'));
        async.elapse(const Duration(milliseconds: 2999));
        expect(sentAt, [Duration.zero]);

        async.elapse(const Duration(seconds: 5));
        expect(sentAt, hasLength(5));
        for (var i = 1; i < sentAt.length; i++) {
          expect(
            sentAt[i] - sentAt[i - 1],
            greaterThanOrEqualTo(const Duration(seconds: 1)),
            reason: 'two forwards inside one 1 s window: $sentAt',
          );
        }
        expect(sentAt[1], greaterThanOrEqualTo(const Duration(seconds: 3)));
        interceptor.dispose();
      });
    });

    test('a request cancelled while it waits for tokens is not counted', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(
          config: _config,
          perHost: const [
            TokenBucketPolicy(permits: 1, per: Duration(seconds: 1)),
          ],
        );
        final log = _Log();
        final token = CancelToken();
        _send(interceptor, log);
        unawaited(
          interceptor.onRequest(
            RequestOptions(path: 'https://a.test/items', cancelToken: token),
            _RecordingHandler(log),
          ),
        );
        async.flushMicrotasks();

        token.cancel('user left');
        async.elapse(const Duration(seconds: 1));

        expect(log.forwarded, hasLength(1));
        expect(log.rejected.single.type, DioExceptionType.cancel);
        expect(interceptor.getStatistics().forwarded, 1);
        interceptor.dispose();
      });
    });

    test('dispose cancels held requests', () {
      fakeAsync((async) {
        final interceptor = TokenBucketRateLimitInterceptor(config: _config);
        final log = _Log();
        _respond(interceptor, _serverResponse(429, retryAfter: '3'));
        _send(interceptor, log);
        async.flushMicrotasks();

        interceptor.dispose();
        async.flushMicrotasks();

        expect(log.rejected.single.type, DioExceptionType.cancel);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('rejects invalid pause settings', () {
      expect(
        () => TokenBucketRateLimitInterceptor(
          config: _config,
          maxPause: Duration.zero,
        ),
        throwsArgumentError,
      );
    });
  });

  group('construction', () {
    test('rejects hosts keys Uri.host could never return', () {
      for (final key in ['api.a.test:8080', ' a.test', '[::1]', '']) {
        expect(
          () => TokenBucketRateLimitInterceptor(
            config: _config,
            hosts: {
              key: const [
                TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
              ],
            },
          ),
          throwsArgumentError,
          reason: '"$key"',
        );
      }
      expect(
        TokenBucketRateLimitInterceptor(
          config: _config,
          hosts: const {'::1': []},
        ),
        isNotNull,
      );
    });

    test('an invalid global policy throws', () {
      expect(
        () => TokenBucketRateLimitInterceptor(
          config: _config,
          global: const [
            TokenBucketPolicy(permits: 0, per: Duration(seconds: 1)),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('later changes to the caller maps do not reach the interceptor', () {
      fakeAsync((async) {
        final hosts = <String, List<TokenBucketPolicy>>{};
        final interceptor = TokenBucketRateLimitInterceptor(
          config: _config,
          hosts: hosts,
        );
        hosts['a.test'] = const [
          TokenBucketPolicy(permits: 1, per: Duration(minutes: 1)),
        ];
        final log = _Log();

        _send(interceptor, log, times: 3);

        expect(log.forwarded, hasLength(3));
        expect(
          () => interceptor.getStatistics().waitingByHost['x'] = 1,
          throwsUnsupportedError,
        );
      });
    });
  });

  test('host tiers and global tiers apply together', () {
    fakeAsync((async) {
      final interceptor = TokenBucketRateLimitInterceptor(
        config: _config,
        perHost: const [
          TokenBucketPolicy(permits: 2, per: Duration(minutes: 1), burst: 2),
        ],
        global: const [
          TokenBucketPolicy(permits: 3, per: Duration(minutes: 1), burst: 3),
        ],
      );
      final log = _Log();

      _send(interceptor, log, times: 3);
      _send(interceptor, log, url: 'https://b.test/items', times: 2);
      async.flushMicrotasks();

      expect(log.forwarded.where((o) => o.uri.host == 'a.test'), hasLength(2));
      expect(log.forwarded.where((o) => o.uri.host == 'b.test'), hasLength(1));
      final stats = interceptor.getStatistics();
      expect(stats.waitingByHost, {'a.test': 1, 'b.test': 0});
      expect(stats.globalWaiting, 1);
      interceptor.dispose();
    });
  });
}
