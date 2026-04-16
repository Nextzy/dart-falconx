import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

// Test class for object extensions
class User {
  User(this.name, this.age, [this.email]);

  String name;
  int age;
  String? email;
}

void main() {
  group('FalconToolNullableObject', () {
    group('let', () {
      test('should execute function when value is not null', () {
        const name = 'John';
        var executed = false;
        String? receivedValue;

        name.let((value) {
          executed = true;
          receivedValue = value;
        });

        expect(executed, true);
        expect(receivedValue, 'John');
      });

      test('should not execute function when value is null', () {
        String? name;
        var executed = false;

        name.let((value) {
          executed = true;
        });

        expect(executed, false);
      });

      test('should work with complex objects', () {
        final user = User('Alice', 25);
        String? userName;

        user.let((u) {
          userName = u.name;
        });

        expect(userName, 'Alice');
      });
    });

    group('map', () {
      test('should transform non-null value', () {
        const name = 'John';
        final length = name.map((value) => value.length);
        expect(length, 4);
      });

      test('should return null for null value', () {
        String? name;
        final length = name.map((value) => value.length);
        expect(length, null);
      });

      test('should work with type conversion', () {
        const number = 42;
        final text =
            number.map((value) => 'Number: $value');
        expect(text, 'Number: 42');
      });
    });

    group('mapOr', () {
      test('should transform non-null value', () {
        const name = 'John';
        final length =
            name.mapOr((value) => value.length, 0);
        expect(length, 4);
      });

      test('should return default for null value', () {
        String? name;
        final length =
            name.mapOr((value) => value.length, 0);
        expect(length, 0);
      });
    });

    group('mapOrElse', () {
      test('should transform non-null value', () {
        const name = 'John';
        final message = name.mapOrElse(
          (value) => 'Hello, $value',
          () => 'Hello, guest',
        );
        expect(message, 'Hello, John');
      });

      test('should call orElse for null value', () {
        String? name;
        final message = name.mapOrElse(
          (value) => 'Hello, $value',
          () => 'Hello, guest',
        );
        expect(message, 'Hello, guest');
      });

      test('should handle lazy evaluation', () {
        const number = 42;
        var orElseCalled = false;

        final result = number.mapOrElse(
          (value) => value * 2,
          () {
            orElseCalled = true;
            return 0;
          },
        );

        expect(result, 84);
        expect(orElseCalled, false);
      });
    });

    group('orDefault', () {
      test('should return value when not null', () {
        const name = 'John';
        expect(name.orDefault('Anonymous'), 'John');
      });

      test('should return default when null', () {
        String? name;
        expect(name.orDefault('Anonymous'), 'Anonymous');
      });
    });

    group('orElse', () {
      test('should return value when not null', () {
        const cachedName = 'John';
        expect(
          cachedName.orElse(() => 'FetchedName'),
          'John',
        );
      });

      test('should call provider when null', () {
        String? cachedName;
        var providerCalled = false;

        final name = cachedName.orElse(() {
          providerCalled = true;
          return 'FetchedName';
        });

        expect(name, 'FetchedName');
        expect(providerCalled, true);
      });
    });

    group('takeIf', () {
      test('should return value when predicate is true', () {
        const age = 25;
        final adultAge = age.takeIf((value) => value >= 18);
        expect(adultAge, 25);
      });

      test('should return null when predicate is false', () {
        const age = 15;
        final adultAge = age.takeIf((value) => value >= 18);
        expect(adultAge, null);
      });

      test('should return null when value is null', () {
        int? age;
        final adultAge = age.takeIf((value) => value >= 18);
        expect(adultAge, null);
      });
    });

    group('takeUnless', () {
      test('should return value when predicate is false', () {
        const input = 'valid';
        final validInput =
            input.takeUnless((value) => value.isEmpty);
        expect(validInput, 'valid');
      });

      test('should return null when predicate is true', () {
        const input = '';
        final validInput =
            input.takeUnless((value) => value.isEmpty);
        expect(validInput, null);
      });

      test('should return null when value is null', () {
        String? input;
        final validInput =
            input.takeUnless((value) => value.isEmpty);
        expect(validInput, null);
      });
    });

    group('fold', () {
      test('should execute onValue when not null', () {
        const name = 'John';
        var nullCalled = false;
        var valueCalled = false;
        String? receivedValue;

        name.fold(
          onNull: () {
            nullCalled = true;
          },
          onValue: (value) {
            valueCalled = true;
            receivedValue = value;
          },
        );

        expect(nullCalled, false);
        expect(valueCalled, true);
        expect(receivedValue, 'John');
      });

      test('should execute onNull when null', () {
        String? name;
        var nullCalled = false;
        var valueCalled = false;

        name.fold(
          onNull: () {
            nullCalled = true;
          },
          onValue: (value) {
            valueCalled = true;
          },
        );

        expect(nullCalled, true);
        expect(valueCalled, false);
      });
    });

    group('match', () {
      test('should return onValue result when not null', () {
        const name = 'John';
        final message = name.match(
          onNull: () => 'Hello, guest',
          onValue: (value) => 'Hello, $value',
        );
        expect(message, 'Hello, John');
      });

      test('should return onNull result when null', () {
        String? name;
        final message = name.match(
          onNull: () => 'Hello, guest',
          onValue: (value) => 'Hello, $value',
        );
        expect(message, 'Hello, guest');
      });
    });

    group('chain', () {
      test(
        'should chain operations when all return non-null',
        () {
          const firstName = 'john';
          final upperName = firstName
              .chain(
                (name) => name.isNotEmpty ? name : null,
              )
              .chain((name) => name.toUpperCase());
          expect(upperName, 'JOHN');
        },
      );

      test('should return null when chain breaks', () {
        const firstName = '';
        final upperName = firstName
            .chain(
              (name) => name.isNotEmpty ? name : null,
            )
            .chain((name) => name.toUpperCase());
        expect(upperName, null);
      });

      test(
        'should return null when initial value is null',
        () {
          String? firstName;
          final upperName = firstName
              .chain(
                (name) => name.isNotEmpty ? name : null,
              )
              .chain((name) => name.toUpperCase());
          expect(upperName, null);
        },
      );
    });

    group('isNull and isNotNull', () {
      test('should correctly check null values', () {
        String? nullValue;
        const nonNullValue = 'test';

        expect(nullValue.isNull, true);
        expect(nullValue.isNotNull, false);
        expect(nonNullValue.isNull, false);
        expect(nonNullValue.isNotNull, true);
      });
    });

    group('toFuture', () {
      test('should convert null to Future', () async {
        String? value;
        final future = value.toFuture();
        expect(await future, null);
      });

      test('should convert non-null to Future', () async {
        const value = 'test';
        final future = value.toFuture();
        expect(await future, 'test');
      });
    });

    group('toFutureOr', () {
      test(
        'should convert non-null to successful Future',
        () async {
          const token = 'valid-token';
          final future = token.toFutureOr(
            () => Exception('Not authenticated'),
          );
          expect(await future, 'valid-token');
        },
      );

      test('should convert null to failed Future', () async {
        String? token;
        final future = token.toFutureOr(
          () => Exception('Not authenticated'),
        );

        expect(
          () => future,
          throwsA(isA<Exception>()),
        );
      });
    });
  });

  group('FalconToolObject', () {
    group('also', () {
      test('should execute action and return object', () {
        final user = User('John', 25);
        var actionExecuted = false;

        final result = user.also((u) {
          actionExecuted = true;
          u
            ..age = 30
            ..email = 'john@example.com';
        });

        expect(actionExecuted, true);
        expect(result, same(user));
        expect(user.age, 30);
        expect(user.email, 'john@example.com');
      });

      test('should chain multiple also calls', () {
        final user = User('John', 25)
            .also((u) => u.age = 30)
            .also((u) => u.email = 'john@example.com')
            ..also((u) => u.name = u.name.toUpperCase());

        expect(user.name, 'JOHN');
        expect(user.age, 30);
        expect(user.email, 'john@example.com');
      });
    });

    group('run', () {
      test('should transform object and return result', () {
        const text = 'Hello';
        final length = text.run((str) => str.length);
        expect(length, 5);
      });

      test('should work with complex transformations', () {
        final user = User('John', 25);
        final summary = user.run(
          (u) => '${u.name} is ${u.age} years old',
        );
        expect(summary, 'John is 25 years old');
      });
    });

    group('applyIf', () {
      test(
        'should apply transformation when condition is true',
        () {
          final number = 5
              .applyIf(true, (n) => n * 2)
              .applyIf(false, (n) => n + 10);
          expect(number, 10);
        },
      );

      test(
        'should not apply when condition is false',
        () {
          final number = 5
              .applyIf(false, (n) => n * 2)
              .applyIf(false, (n) => n + 10);
          expect(number, 5);
        },
      );

      test('should work with objects', () {
        const isDebug = true;
        final user = User('John', 25).applyIf(
          isDebug,
          (u) => User('DEBUG_${u.name}', u.age),
        );
        expect(user.name, 'DEBUG_John');
      });
    });

    group('applyIfLazy', () {
      test(
        'should apply when lazy condition is true',
        () {
          var conditionEvaluated = false;

          final result = 10.applyIfLazy(
            () {
              conditionEvaluated = true;
              return true;
            },
            (n) => n * 2,
          );

          expect(result, 20);
          expect(conditionEvaluated, true);
        },
      );

      test(
        'should not evaluate condition when not needed',
        () {
          var conditionEvaluated = false;

          final result = 10.applyIfLazy(
            () {
              conditionEvaluated = true;
              return false;
            },
            (n) => n * 2,
          );

          expect(result, 10);
          expect(conditionEvaluated, true);
        },
      );
    });

    group('wrapInList', () {
      test('should wrap value in list', () {
        final list = 42.wrapInList();
        expect(list, [42]);
        expect(list.length, 1);
      });

      test('should work with objects', () {
        final user = User('John', 25);
        final list = user.wrapInList();
        expect(list.length, 1);
        expect(list[0], user);
      });
    });

    group('asSet', () {
      test('should wrap value in set', () {
        final set = 42.asSet();
        expect(set, {42});
        expect(set.length, 1);
      });

      test('should work with objects', () {
        final user = User('John', 25);
        final set = user.asSet();
        expect(set.length, 1);
        expect(set.first, user);
      });
    });

    group('asFuture', () {
      test('should wrap value in Future', () async {
        final future = 'Hello'.asFuture();
        expect(await future, 'Hello');
      });
    });

    group('asStream', () {
      test('should wrap value in Stream', () async {
        final stream = 'Hello'.asStream();
        final events = await stream.toList();
        expect(events, ['Hello']);
      });
    });

    group('isIn', () {
      test('should check if value is in collection', () {
        const status = 'active';
        expect(status.isIn(['active', 'pending']), true);
        expect(
          status.isIn(['inactive', 'deleted']),
          false,
        );
      });

      test('should work with empty collection', () {
        expect(42.isIn(<int>[]), false);
      });

      test('should work with different types', () {
        const number = 2;
        expect(number.isIn([1, 2, 3]), true);
        expect(number.isIn([4, 5, 6]), false);
      });
    });

    group('isNotIn', () {
      test('should check if value is not in collection', () {
        const status = 'deleted';
        expect(
          status.isNotIn(['active', 'pending']),
          true,
        );
        expect(
          status.isNotIn(['deleted', 'archived']),
          false,
        );
      });

      test('should work with empty collection', () {
        expect(42.isNotIn(<int>[]), true);
      });
    });
  });
}
