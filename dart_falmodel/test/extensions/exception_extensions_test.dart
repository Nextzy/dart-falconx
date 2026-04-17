import 'dart:async';

import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:test/test.dart';

void main() {
  /// Helper: calls toException() on an object and returns the resolved type.
  Object detectType(Object exception) => exception.toException().type;

  group('_detectErrorType — Input', () {
    test('FormatException maps to InputErrorType.invalidFormat', () {
      expect(detectType(const FormatException()), InputErrorType.invalidFormat);
    });

    test('TypeError maps to InputErrorType.type', () {
      // Create a real TypeError by catching one
      try {
        const dynamic value = 'not an int';
        // Cast will throw TypeError at runtime — variable is never used.
        // ignore: unused_local_variable
        final result = value as int;
        // We need to catch TypeError to test _detectErrorType mapping.
        // ignore: avoid_catching_errors
      } on TypeError catch (e) {
        expect(detectType(e), InputErrorType.type);
        return;
      }
      fail('Expected TypeError');
    });

    test('RangeError maps to InputErrorType.outOfRange', () {
      expect(detectType(RangeError('test')), InputErrorType.outOfRange);
    });

    test('ArgumentError maps to InputErrorType.argument', () {
      expect(detectType(ArgumentError('test')), InputErrorType.argument);
    });
  });

  group('_detectErrorType — Timeout', () {
    test('TimeoutException maps to TimeoutErrorType.timeout', () {
      expect(
        detectType(TimeoutException('test')),
        TimeoutErrorType.timeout,
      );
    });
  });

  group('_detectErrorType — System', () {
    test('StateError maps to SystemErrorType.system', () {
      expect(detectType(StateError('test')), SystemErrorType.system);
    });

    test('UnsupportedError maps to SystemErrorType.unexpected', () {
      expect(
        detectType(UnsupportedError('test')),
        SystemErrorType.unexpected,
      );
    });

    test('ConcurrentModificationError maps to SystemErrorType.concurrency', () {
      expect(
        detectType(ConcurrentModificationError()),
        SystemErrorType.concurrency,
      );
    });
  });

  group('_detectErrorType — Async', () {
    test('AsyncError maps to AsyncErrorType.stream', () {
      expect(
        detectType(AsyncError('inner', StackTrace.current)),
        AsyncErrorType.stream,
      );
    });
  });

  group('_detectErrorType — Fallback', () {
    test('unknown Error falls back to SystemErrorType.unexpected', () {
      expect(detectType(UnimplementedError()), SystemErrorType.unexpected);
    });

    test('null falls back to SystemErrorType.unknown', () {
      final exception = null.toException();
      expect(exception.type, SystemErrorType.unknown);
    });

    test('plain String falls back to SystemErrorType.unknown', () {
      expect(detectType('just a string'), SystemErrorType.unknown);
    });
  });

  group('toCommonResultFailure defaults', () {
    test('uses SystemErrorType.unknown when no type given', () {
      // Extension is on Exception?, must be nullable to test.
      // ignore: unnecessary_nullable_for_final_variable_declarations
      final Exception? ex = Exception('test');
      final result = ex.toCommonResultFailure();
      expect(result.exception.type, SystemErrorType.unknown);
    });
  });
}
