import 'dart:async';

import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('runs every watch once, in registration order, with the error', () {
    final token = CancelToken();
    final calls = <String>[];
    watchCancel(token, (e) => calls.add('first ${e.type.name}'));
    watchCancel(token, (e) => calls.add('second ${e.type.name}'));
    expect(activeCancelWatches(token), 2);

    token.cancel();
    return Future<void>.delayed(Duration.zero, () {
      expect(calls, ['first cancel', 'second cancel']);
      expect(activeCancelWatches(token), 0);
    });
  });

  test('a removed watch never runs', () {
    final token = CancelToken();
    var ran = false;
    final remove = watchCancel(token, (_) => ran = true);
    remove();
    expect(activeCancelWatches(token), 0);

    token.cancel();
    return Future<void>.delayed(Duration.zero, () => expect(ran, isFalse));
  });

  test('a watch on a cancelled token runs in a microtask', () async {
    final token = CancelToken()..cancel();
    await Future<void>.delayed(Duration.zero);
    var ran = false;
    watchCancel(token, (_) => ran = true);
    final removed = watchCancel(token, (_) => fail('removed watch ran'));

    expect(ran, isFalse);
    removed();
    await Future<void>.delayed(Duration.zero);
    expect(ran, isTrue);
  });

  test('finished watches leave nothing behind on a long-lived token', () {
    final token = CancelToken();
    for (var i = 0; i < 1000; i++) {
      watchCancel(token, (_) {})();
    }
    expect(activeCancelWatches(token), 0);
  });

  test('a throwing watch does not stop the others', () async {
    final token = CancelToken();
    final calls = <String>[];
    final errors = <Object>[];

    await runZonedGuarded(() async {
      watchCancel(token, (_) => throw StateError('boom'));
      watchCancel(token, (_) => calls.add('second'));
      token.cancel();
      await Future<void>.delayed(Duration.zero);
    }, (error, _) => errors.add(error));

    expect(calls, ['second']);
    expect(errors.single, isA<StateError>());
    expect(activeCancelWatches(token), 0);
  });
}
