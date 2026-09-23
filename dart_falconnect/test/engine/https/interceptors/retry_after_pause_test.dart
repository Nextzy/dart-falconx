import 'dart:async';

import 'package:dart_falconnect/engine/https/interceptors/local_rate_limit.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

RetryAfterPause _pause({
  Duration maxPauseWait = const Duration(seconds: 10),
  Duration maxPause = const Duration(minutes: 10),
  Duration? defaultPause = const Duration(seconds: 5),
  int maxHeld = 50,
  bool holdRequests = true,
}) => RetryAfterPause(
  maxPauseWait: maxPauseWait,
  maxPause: maxPause,
  defaultPause: defaultPause,
  maxHeld: maxHeld,
  holdRequests: holdRequests,
);

Response<dynamic> _response(
  int status, {
  String host = 'a.test',
  String? retryAfter,
}) => Response<dynamic>(
  requestOptions: RequestOptions(path: 'https://$host/x'),
  statusCode: status,
  headers: Headers.fromMap({
    if (retryAfter != null) 'retry-after': [retryAfter],
  }),
);

Duration _remaining(PauseAdmission admission) =>
    (admission as PauseReject).remaining;

void main() {
  test('passes an unpaused host', () {
    expect(_pause().admit('a.test'), isA<PausePass>());
  });

  test('429 with Retry-After pauses only that host', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));

      expect(pause.admit('a.test'), isA<PauseHold>());
      expect(pause.admit('b.test'), isA<PausePass>());
      async.elapse(const Duration(seconds: 3));
      expect(pause.admit('a.test'), isA<PausePass>());
    });
  });

  test('429 without Retry-After pauses for defaultPause', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429));

      async.elapse(const Duration(milliseconds: 4999));
      expect(pause.isPaused('a.test'), isTrue);
      async.elapse(const Duration(milliseconds: 1));
      expect(pause.isPaused('a.test'), isFalse);
    });
  });

  test('a null defaultPause ignores a 429 without Retry-After', () {
    final pause = _pause(defaultPause: null)..observe(_response(429));
    expect(pause.isPaused('a.test'), isFalse);
  });

  test('503 pauses only with Retry-After; other statuses never', () {
    final pause = _pause()
      ..observe(_response(503))
      ..observe(_response(500, retryAfter: '9'))
      ..observe(_response(200, retryAfter: '9'));
    expect(pause.isPaused('a.test'), isFalse);

    pause.observe(_response(503, retryAfter: '9'));
    expect(pause.isPaused('a.test'), isTrue);
  });

  test('a local 429 starts no pause', () {
    final options = RequestOptions(path: 'https://a.test/x');
    final local = localRateLimitRejection(
      options,
      retryAfter: const Duration(seconds: 30),
    ).response!;
    expect(local.isLocalRateLimit, isTrue);

    final pause = _pause()..observe(local);
    expect(pause.isPaused('a.test'), isFalse);
  });

  test('Retry-After: 0 starts no pause', () {
    final pause = _pause()..observe(_response(429, retryAfter: '0'));
    expect(pause.isPaused('a.test'), isFalse);
  });

  test('clamps a pause to maxPause', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '86400'));

      expect(_remaining(pause.admit('a.test')), const Duration(minutes: 10));
      async.elapse(const Duration(minutes: 10));
      expect(pause.isPaused('a.test'), isFalse);
    });
  });

  test('extends a pause but never shortens it', () {
    fakeAsync((async) {
      final pause = _pause(maxPauseWait: Duration.zero)
        ..observe(_response(429, retryAfter: '20'))
        ..observe(_response(429, retryAfter: '5'));
      expect(_remaining(pause.admit('a.test')), const Duration(seconds: 20));

      pause.observe(_response(429, retryAfter: '40'));
      expect(_remaining(pause.admit('a.test')), const Duration(seconds: 40));
    });
  });

  test('rejects when the remaining pause exceeds maxPauseWait', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '11'));

      expect(_remaining(pause.admit('a.test')), const Duration(seconds: 11));
      async.elapse(const Duration(seconds: 1));
      expect(pause.admit('a.test'), isA<PauseHold>());
    });
  });

  test('rejects instead of holding when holdRequests is false', () {
    final pause = _pause(holdRequests: false)
      ..observe(_response(429, retryAfter: '1'));
    expect(pause.admit('a.test'), isA<PauseReject>());
  });

  test('releases held requests in order when the pause ends', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      final released = <int>[];
      for (var i = 0; i < 3; i++) {
        unawaited(pause.wait('a.test', null).then((_) => released.add(i)));
      }
      expect(pause.heldByHost, {'a.test': 3});

      async.elapse(const Duration(milliseconds: 2999));
      expect(released, isEmpty);
      async.elapse(const Duration(milliseconds: 1));
      expect(released, [0, 1, 2]);
      expect(pause.heldByHost, isEmpty);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('keeps holding when a new 429 extends the pause', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      var released = false;
      unawaited(pause.wait('a.test', null).then((_) => released = true));

      async.elapse(const Duration(seconds: 2));
      pause.observe(_response(429, retryAfter: '4'));
      async.elapse(const Duration(seconds: 1));
      expect(released, isFalse);
      async.elapse(const Duration(seconds: 3));
      expect(released, isTrue);
    });
  });

  test('releases held requests when an extension exceeds maxPauseWait', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      var released = false;
      unawaited(pause.wait('a.test', null).then((_) => released = true));

      async.elapse(const Duration(seconds: 2));
      pause.observe(_response(429, retryAfter: '60'));
      async.elapse(const Duration(seconds: 1));
      expect(released, isTrue, reason: 'released at the old end time');
      expect(
        _remaining(pause.admit('a.test')),
        const Duration(seconds: 59),
        reason: 'the extension stands for new requests',
      );
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('rejects once the hold queue is full', () {
    fakeAsync((async) {
      final pause = _pause(maxHeld: 2)
        ..observe(_response(429, retryAfter: '3'));
      unawaited(pause.wait('a.test', null));
      unawaited(pause.wait('a.test', null));

      expect(pause.admit('a.test'), isA<PauseReject>());
      async.elapse(const Duration(seconds: 3));
    });
  });

  test('a cancelled request leaves the hold queue at once', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      final token = CancelToken();
      Object? failure;
      unawaited(
        pause.wait('a.test', token).catchError((Object e) => failure = e),
      );

      token.cancel('user left');
      async.flushMicrotasks();

      expect(failure, isA<DioException>());
      expect(pause.heldByHost, isEmpty);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('a pause with nobody held creates no timer', () {
    fakeAsync((async) {
      _pause().observe(_response(429, retryAfter: '600'));
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('reports the end time of active pauses only', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      expect(pause.pausedUntilByHost.keys, ['a.test']);

      async.elapse(const Duration(seconds: 3));
      expect(pause.pausedUntilByHost, isEmpty);
    });
  });

  test('dispose fails held requests and forgets pauses', () {
    fakeAsync((async) {
      final pause = _pause()..observe(_response(429, retryAfter: '3'));
      Object? failure;
      unawaited(
        pause.wait('a.test', null).catchError((Object e) => failure = e),
      );

      pause
        ..dispose()
        ..dispose();
      async.flushMicrotasks();

      expect(failure, isA<StateError>());
      expect(pause.admit('a.test'), isA<PausePass>());
      pause.observe(_response(429, retryAfter: '3'));
      expect(pause.isPaused('a.test'), isFalse);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('rejects invalid settings', () {
    expect(
      () => _pause(maxPauseWait: const Duration(seconds: -1)),
      throwsArgumentError,
    );
    expect(() => _pause(maxPause: Duration.zero), throwsArgumentError);
    expect(() => _pause(defaultPause: Duration.zero), throwsArgumentError);
    expect(() => _pause(maxHeld: -1), throwsArgumentError);
  });

  test('local 429 carries Retry-After rounded up to whole seconds', () {
    final options = RequestOptions(path: 'https://a.test/x');
    final paused = localRateLimitRejection(
      options,
      retryAfter: const Duration(milliseconds: 2100),
    );
    final brief = localRateLimitRejection(
      options,
      retryAfter: const Duration(milliseconds: 10),
    );
    final full = localRateLimitRejection(options);

    expect(paused.type, DioExceptionType.badResponse);
    expect(paused.response?.statusCode, 429);
    expect(paused.response?.headers.value('retry-after'), '3');
    expect(brief.response?.headers.value('retry-after'), '1');
    expect(full.response?.headers.value('retry-after'), isNull);
  });
}
