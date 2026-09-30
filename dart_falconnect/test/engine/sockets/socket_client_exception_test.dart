@TestOn('vm')
library;

import 'dart:io';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

void main() {
  test('SocketClientException names itself in toString', () {
    const exception = SocketClientException(message: 'closed');

    expect(
      exception.toString(),
      startsWith('SocketClientException{message: closed'),
    );
  });

  test('retry and unknown-operation errors are SocketClientExceptions', () {
    expect(
      const SocketRetryException(retryCount: 1),
      isA<SocketClientException>(),
    );
    expect(const SocketOperationNotFound(), isA<SocketClientException>());
  });

  test("dart:io's SocketException stays reachable next to the barrel", () {
    const exception = SocketException('refused');

    expect(exception.osError, isNull);
  });
}
