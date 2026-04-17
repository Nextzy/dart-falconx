import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultErrorType sealed class', () {
    test('SystemErrorType implements DefaultErrorType', () {
      expect(SystemErrorType.unknown, isA<DefaultErrorType>());
      expect(SystemErrorType.system, isA<DefaultErrorType>());
      expect(SystemErrorType.unexpected, isA<DefaultErrorType>());
      expect(SystemErrorType.concurrency, isA<DefaultErrorType>());
    });

    test('InputErrorType implements DefaultErrorType', () {
      expect(InputErrorType.validation, isA<DefaultErrorType>());
      expect(InputErrorType.invalidFormat, isA<DefaultErrorType>());
      expect(InputErrorType.invalidValue, isA<DefaultErrorType>());
      expect(InputErrorType.outOfRange, isA<DefaultErrorType>());
      expect(InputErrorType.argument, isA<DefaultErrorType>());
      expect(InputErrorType.type, isA<DefaultErrorType>());
    });

    test('TimeoutErrorType implements DefaultErrorType', () {
      expect(TimeoutErrorType.timeout, isA<DefaultErrorType>());
      expect(TimeoutErrorType.deadline, isA<DefaultErrorType>());
    });

    test('StorageErrorType implements DefaultErrorType', () {
      expect(StorageErrorType.storage, isA<DefaultErrorType>());
      expect(StorageErrorType.cache, isA<DefaultErrorType>());
      expect(StorageErrorType.database, isA<DefaultErrorType>());
      expect(StorageErrorType.fileSystem, isA<DefaultErrorType>());
    });

    test('ConnectivityErrorType implements DefaultErrorType', () {
      expect(ConnectivityErrorType.connection, isA<DefaultErrorType>());
      expect(ConnectivityErrorType.socket, isA<DefaultErrorType>());
      expect(ConnectivityErrorType.tls, isA<DefaultErrorType>());
      expect(ConnectivityErrorType.dns, isA<DefaultErrorType>());
      expect(ConnectivityErrorType.http, isA<DefaultErrorType>());
    });

    test('AsyncErrorType implements DefaultErrorType', () {
      expect(AsyncErrorType.stream, isA<DefaultErrorType>());
      expect(AsyncErrorType.future, isA<DefaultErrorType>());
      expect(AsyncErrorType.isolate, isA<DefaultErrorType>());
    });

    test('AccessErrorType implements DefaultErrorType', () {
      expect(AccessErrorType.permission, isA<DefaultErrorType>());
      expect(AccessErrorType.unauthorized, isA<DefaultErrorType>());
      expect(AccessErrorType.deviceNotSupported, isA<DefaultErrorType>());
    });

    test('ExternalErrorType implements DefaultErrorType', () {
      expect(ExternalErrorType.thirdParty, isA<DefaultErrorType>());
      expect(ExternalErrorType.serviceUnavailable, isA<DefaultErrorType>());
    });

    test('BusinessErrorType implements DefaultErrorType', () {
      expect(BusinessErrorType.businessRule, isA<DefaultErrorType>());
      expect(BusinessErrorType.notFound, isA<DefaultErrorType>());
      expect(BusinessErrorType.conflict, isA<DefaultErrorType>());
      expect(BusinessErrorType.deprecated, isA<DefaultErrorType>());
    });
  });

  group('defaultMessage', () {
    test('SystemErrorType has correct messages', () {
      expect(
        SystemErrorType.unknown.defaultMessage,
        'Something went wrong. Please try again.',
      );
      expect(SystemErrorType.system.defaultMessage, 'System error occurred.');
      expect(
        SystemErrorType.unexpected.defaultMessage,
        'An unexpected error occurred.',
      );
      expect(
        SystemErrorType.concurrency.defaultMessage,
        'Concurrent modification error.',
      );
    });

    test('InputErrorType has correct messages', () {
      expect(
        InputErrorType.validation.defaultMessage,
        'Invalid input. Please check your data.',
      );
      expect(InputErrorType.invalidFormat.defaultMessage, 'Invalid format.');
      expect(
        InputErrorType.invalidValue.defaultMessage,
        'Invalid value provided.',
      );
      expect(InputErrorType.outOfRange.defaultMessage, 'Value out of range.');
      expect(
        InputErrorType.argument.defaultMessage,
        'Invalid argument provided.',
      );
      expect(InputErrorType.type.defaultMessage, 'Type error occurred.');
    });

    test('TimeoutErrorType has correct messages', () {
      expect(
        TimeoutErrorType.timeout.defaultMessage,
        'Request timed out. Please try again.',
      );
      expect(
        TimeoutErrorType.deadline.defaultMessage,
        'Operation deadline exceeded.',
      );
    });

    test('StorageErrorType has correct messages', () {
      expect(
        StorageErrorType.storage.defaultMessage,
        'Storage error occurred.',
      );
      expect(StorageErrorType.cache.defaultMessage, 'Cache error occurred.');
      expect(
        StorageErrorType.database.defaultMessage,
        'Database error occurred.',
      );
      expect(StorageErrorType.fileSystem.defaultMessage, 'File system error.');
    });
  });

  group('pattern matching', () {
    test('can switch on specific value', () {
      const DefaultErrorType type = StorageErrorType.cache;
      final result = switch (type) {
        StorageErrorType.cache => 'cache',
        _ => 'other',
      };
      expect(result, 'cache');
    });

    test('can switch on group', () {
      const DefaultErrorType type = ConnectivityErrorType.socket;
      final result = switch (type) {
        SystemErrorType() => 'system',
        InputErrorType() => 'input',
        TimeoutErrorType() => 'timeout',
        StorageErrorType() => 'storage',
        ConnectivityErrorType() => 'connectivity',
        AsyncErrorType() => 'async',
        AccessErrorType() => 'access',
        ExternalErrorType() => 'external',
        BusinessErrorType() => 'business',
      };
      expect(result, 'connectivity');
    });
  });
}
