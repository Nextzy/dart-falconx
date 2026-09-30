import 'dart:developer';

import 'package:dart_faltool/dart_faltool.dart';
import 'package:test/test.dart';

void main() {
  test("dart:developer's log stays reachable next to the barrel", () {
    expect(() => log('dart_faltool'), returnsNormally);
  });

  test('the barrel still re-exports the rest of dart:math', () {
    expect(max(1, 2), 2);
  });
}
