import 'dart:math' as math;
import 'package:dart_faltool/lib.dart';
import 'package:test/test.dart';

// Test class for groupBy and other tests
@immutable
class Person {
  const Person(this.name, this.age, this.city);

  final String name;
  final int age;
  final String city;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age &&
          city == other.city;

  @override
  int get hashCode => name.hashCode ^ age.hashCode ^ city.hashCode;
}

void main() {
  group('FalconToolIterableExtensions', () {
    group('reduceOrNull', () {
      test('should reduce non-empty collection', () {
        final numbers = [1, 2, 3, 4, 5];
        final result = numbers.reduceOrNull((a, b) => a + b);
        expect(result, 15);
      });

      test('should return null for empty collection', () {
        final numbers = <int>[];
        final result = numbers.reduceOrNull((a, b) => a + b);
        expect(result, null);
      });

      test(
        'should return single element for single-item collection',
        () {
          final numbers = [42];
          final result = numbers.reduceOrNull((a, b) => a + b);
          expect(result, 42);
        },
      );

      test('should work with string concatenation', () {
        final words = ['Hello', ' ', 'World'];
        final result = words.reduceOrNull((a, b) => a + b);
        expect(result, 'Hello World');
      });
    });

    group('reduceSafe', () {
      test('should reduce non-empty collection', () {
        final numbers = [1, 2, 3, 4, 5];
        final result = numbers.reduceSafe((a, b) => a + b, 0);
        expect(result, 15);
      });

      test(
        'should return default value for empty collection',
        () {
          final numbers = <int>[];
          final result = numbers.reduceSafe((a, b) => a + b, 100);
          expect(result, 100);
        },
      );

      test(
        'should return single element for single-item collection',
        () {
          final numbers = [42];
          final result = numbers.reduceSafe((a, b) => a + b, 0);
          expect(result, 42);
        },
      );
    });

    group('groupBy', () {
      test('should group elements by key function', () {
        final words = [
          'hello',
          'world',
          'hi',
          'dart',
          'flutter',
        ];
        final grouped = words.groupBy((word) => word.length);

        expect(grouped[2], ['hi']);
        expect(grouped[4], ['dart']);
        expect(grouped[5], ['hello', 'world']);
        expect(grouped[7], ['flutter']);
      });

      test('should handle empty collection', () {
        final empty = <String>[];
        final grouped = empty.groupBy((word) => word.length);
        expect(grouped, <int, List<String>>{});
      });

      test('should group objects by property', () {
        final people = [
          const Person('Alice', 25, 'NYC'),
          const Person('Bob', 30, 'LA'),
          const Person('Charlie', 25, 'NYC'),
          const Person('David', 30, 'NYC'),
        ];

        final byAge = people.groupBy((person) => person.age);
        expect(byAge[25]?.length, 2);
        expect(byAge[30]?.length, 2);

        final byCity = people.groupBy((person) => person.city);
        expect(byCity['NYC']?.length, 3);
        expect(byCity['LA']?.length, 1);
      });
    });

    group('whereIndexed', () {
      test('should filter elements by index', () {
        final letters = ['a', 'b', 'c', 'd', 'e'];
        final evenIndexed = letters
            .whereIndexed((value, index) => index.isEven)
            .toList();
        expect(evenIndexed, ['a', 'c', 'e']);
      });

      test(
        'should filter elements by value and index',
        () {
          final numbers = [10, 21, 32, 43, 54];
          final result = numbers
              .whereIndexed(
                (value, index) => index.isOdd && value > 30,
              )
              .toList();
          expect(result, [43]);
        },
      );

      test('should handle empty collection', () {
        final empty = <String>[];
        final result = empty.whereIndexed((value, index) => true).toList();
        expect(result, <String>[]);
      });
    });

    group('minBy', () {
      test('should find minimum element by selector', () {
        final people = [
          const Person('Alice', 25, 'NYC'),
          const Person('Bob', 30, 'LA'),
          const Person('Charlie', 20, 'Chicago'),
        ];

        final youngest = people.minBy((p) => p.age);
        expect(youngest?.name, 'Charlie');
        expect(youngest?.age, 20);
      });

      test('should return null for empty collection', () {
        final empty = <Person>[];
        final result = empty.minBy((p) => p.age);
        expect(result, null);
      });

      test('should handle single element', () {
        final single = [const Person('Alice', 25, 'NYC')];
        final result = single.minBy((p) => p.age);
        expect(result?.name, 'Alice');
      });

      test('should work with strings', () {
        final words = ['apple', 'banana', 'cherry', 'date'];
        final shortest = words.minBy((w) => w.length);
        expect(shortest, 'date');
      });
    });

    group('maxBy', () {
      test('should find maximum element by selector', () {
        final people = [
          const Person('Alice', 25, 'NYC'),
          const Person('Bob', 30, 'LA'),
          const Person('Charlie', 20, 'Chicago'),
        ];

        final oldest = people.maxBy((p) => p.age);
        expect(oldest?.name, 'Bob');
        expect(oldest?.age, 30);
      });

      test('should return null for empty collection', () {
        final empty = <Person>[];
        final result = empty.maxBy((p) => p.age);
        expect(result, null);
      });

      test('should work with strings', () {
        final words = ['apple', 'banana', 'cherry', 'date'];
        final longest = words.maxBy((w) => w.length);
        expect(longest, 'banana');
      });
    });

    group('chunked', () {
      test('should chunk iterable into specified size', () {
        final numbers = [1, 2, 3, 4, 5, 6, 7];
        final chunks = numbers.chunked(3).toList();

        expect(chunks.length, 3);
        expect(chunks[0], [1, 2, 3]);
        expect(chunks[1], [4, 5, 6]);
        expect(chunks[2], [7]);
      });

      test('should handle exact division', () {
        final numbers = [1, 2, 3, 4, 5, 6];
        final chunks = numbers.chunked(2).toList();

        expect(chunks.length, 3);
        expect(chunks[0], [1, 2]);
        expect(chunks[1], [3, 4]);
        expect(chunks[2], [5, 6]);
      });

      test(
        'should handle chunk size larger than collection',
        () {
          final numbers = [1, 2, 3];
          final chunks = numbers.chunked(5).toList();

          expect(chunks.length, 1);
          expect(chunks[0], [1, 2, 3]);
        },
      );

      test('should throw on non-positive chunk size', () {
        final numbers = [1, 2, 3];
        expect(
          () => numbers.chunked(0).toList(),
          throwsArgumentError,
        );
        expect(
          () => numbers.chunked(-1).toList(),
          throwsArgumentError,
        );
      });

      test('should handle empty collection', () {
        final empty = <int>[];
        final chunks = empty.chunked(3).toList();
        expect(chunks, <List<int>>[]);
      });
    });

    group('intersperse', () {
      test(
        'should intersperse separator between elements',
        () {
          final letters = ['a', 'b', 'c'];
          final result = letters.intersperse('-').toList();
          expect(result, ['a', '-', 'b', '-', 'c']);
        },
      );

      test('should handle single element', () {
        final single = ['a'];
        final result = single.intersperse('-').toList();
        expect(result, ['a']);
      });

      test('should handle empty collection', () {
        final empty = <String>[];
        final result = empty.intersperse('-').toList();
        expect(result, <String>[]);
      });

      test('should work with numbers', () {
        final numbers = [1, 2, 3, 4];
        final result = numbers.intersperse(0).toList();
        expect(result, [1, 0, 2, 0, 3, 0, 4]);
      });
    });

    group('flatten', () {
      test('should flatten nested iterables', () {
        final nested = [
          [1, 2],
          [3, 4],
          [5],
        ];
        final flat = nested.flatten().toList();
        expect(flat, [1, 2, 3, 4, 5]);
      });

      test('should handle empty nested lists', () {
        final nested = [
          [1, 2],
          <int>[],
          [3, 4],
        ];
        final flat = nested.flatten().toList();
        expect(flat, [1, 2, 3, 4]);
      });

      test('should handle all empty lists', () {
        final nested = [<int>[], <int>[], <int>[]];
        final flat = nested.flatten().toList();
        expect(flat, <int>[]);
      });

      test('should work with strings', () {
        final nested = [
          ['hello', 'world'],
          ['dart', 'flutter'],
        ];
        final flat = nested.flatten().toList();
        expect(
          flat,
          ['hello', 'world', 'dart', 'flutter'],
        );
      });
    });

    group('zip', () {
      test('should zip two iterables of same length', () {
        final numbers = [1, 2, 3];
        final letters = ['a', 'b', 'c'];
        final zipped = numbers.zip(letters).toList();

        expect(zipped.length, 3);
        expect(zipped[0], (1, 'a'));
        expect(zipped[1], (2, 'b'));
        expect(zipped[2], (3, 'c'));
      });

      test('should stop at shorter iterable', () {
        final numbers = [1, 2, 3, 4, 5];
        final letters = ['a', 'b', 'c'];
        final zipped = numbers.zip(letters).toList();

        expect(zipped.length, 3);
        expect(zipped.last, (3, 'c'));
      });

      test('should handle empty iterables', () {
        final numbers = <int>[];
        final letters = ['a', 'b', 'c'];
        final zipped = numbers.zip(letters).toList();
        expect(zipped, <(int, String)>[]);
      });
    });

    group('partition', () {
      test(
        'should partition elements based on predicate',
        () {
          final numbers = [1, 2, 3, 4, 5, 6];
          final (odds, evens) = numbers.partition((n) => n.isEven);

          expect(evens.toList(), [2, 4, 6]);
          expect(odds.toList(), [1, 3, 5]);
        },
      );

      test('should handle all matching predicate', () {
        final numbers = [2, 4, 6, 8];
        final (odds, evens) = numbers.partition((n) => n.isEven);

        expect(evens.toList(), [2, 4, 6, 8]);
        expect(odds.toList(), <int>[]);
      });

      test('should handle none matching predicate', () {
        final numbers = [1, 3, 5, 7];
        final (odds, evens) = numbers.partition((n) => n.isEven);

        expect(evens.toList(), <int>[]);
        expect(odds.toList(), [1, 3, 5, 7]);
      });

      test('should handle empty collection', () {
        final empty = <int>[];
        final (notMatching, matching) = empty.partition((n) => n > 0);

        expect(matching.toList(), <int>[]);
        expect(notMatching.toList(), <int>[]);
      });
    });

    group('randomElement', () {
      test('should return element from collection', () {
        final colors = ['red', 'green', 'blue'];
        final random = colors.randomElement();

        expect(random, isNotNull);
        expect(colors.contains(random), true);
      });

      test('should return null for empty collection', () {
        final empty = <String>[];
        final random = empty.randomElement();
        expect(random, null);
      });

      test('should work with custom Random', () {
        final numbers = [1, 2, 3, 4, 5];
        final random = numbers.randomElement(math.Random(42));
        expect(random, isNotNull);
        expect(numbers.contains(random), true);
      });
    });

    group('joinToString', () {
      test('should join elements with default separator', () {
        final numbers = [1, 2, 3];
        final result = numbers.joinToString();
        expect(result, '1, 2, 3');
      });

      test(
        'should use custom separator, prefix, and postfix',
        () {
          final numbers = [1, 2, 3];
          final result = numbers.joinToString(
            separator: ' | ',
            prefix: '[',
            postfix: ']',
          );
          expect(result, '[1] | [2] | [3]');
        },
      );

      test('should apply transform function', () {
        final numbers = [1, 2, 3];
        final result = numbers.joinToString(
          transform: (n) => 'Item $n',
        );
        expect(result, 'Item 1, Item 2, Item 3');
      });

      test('should respect limit and truncate', () {
        final numbers = [1, 2, 3, 4, 5];
        final result = numbers.joinToString(
          limit: 3,
          truncated: '...',
        );
        expect(result, '1, 2, 3...');
      });

      test('should handle empty collection', () {
        final empty = <int>[];
        final result = empty.joinToString(
          prefix: '[',
          postfix: ']',
        );
        expect(result, '');
      });
    });

    group('sum', () {
      test('should calculate sum of numbers', () {
        final numbers = [1, 2, 3, 4, 5];
        expect(numbers.sum(), 15);
      });

      test('should handle doubles', () {
        final numbers = [1.5, 2.5, 3.0];
        expect(numbers.sum(), 7.0);
      });

      test('should handle mixed int and double', () {
        final numbers = <num>[1, 2.5, 3];
        expect(numbers.sum(), 6.5);
      });

      test('should return 0 for empty collection', () {
        final empty = <int>[];
        expect(empty.sum(), 0);
      });

      test('should ignore non-numeric values', () {
        final mixed = ['a', 1, 'b', 2, 'c', 3];
        expect(mixed.sum(), 6);
      });
    });

    group('average', () {
      test('should calculate average of numbers', () {
        final numbers = [1, 2, 3, 4, 5];
        expect(numbers.average(), 3.0);
      });

      test('should handle doubles', () {
        final numbers = [1.5, 2.5, 3.0];
        expect(numbers.average(), closeTo(2.333, 0.001));
      });

      test('should return null for empty collection', () {
        final empty = <int>[];
        expect(empty.average(), 0.0);
      });

      test('should ignore non-numeric values', () {
        final mixed = ['a', 1, 'b', 2, 'c', 3];
        expect(mixed.average(), 2.0);
      });

      test('should return null if no numeric values', () {
        final strings = ['a', 'b', 'c'];
        expect(strings.average(), null);
      });
    });
  });

  group('FalconToolNullIterableExtensions', () {
    group('reduceOrNull', () {
      test('should reduce non-null collection', () {
        final Iterable<int> numbers = [1, 2, 3, 4, 5];
        final result = numbers.reduceOrNull((a, b) => a + b);
        expect(result, 15);
      });

      test('should return null for null collection', () {
        Iterable<int>? numbers;
        final result = numbers.reduceOrNull((a, b) => a + b);
        expect(result, null);
      });

      test(
        'should return null for empty non-null collection',
        () {
          final Iterable<int> numbers = <int>[];
          final result = numbers.reduceOrNull((a, b) => a + b);
          expect(result, null);
        },
      );
    });

    group('reduceSafe', () {
      test('should reduce non-null collection', () {
        final Iterable<int> numbers = [1, 2, 3, 4, 5];
        final result = numbers.reduceSafe((a, b) => a + b, 0);
        expect(result, 15);
      });

      test('should return default for null collection', () {
        Iterable<int>? numbers;
        final result = numbers.reduceSafe((a, b) => a + b, 100);
        expect(result, 100);
      });

      test(
        'should return default for empty non-null collection',
        () {
          final Iterable<int> numbers = <int>[];
          final result = numbers.reduceSafe((a, b) => a + b, 100);
          expect(result, 100);
        },
      );
    });

    group('isNullOrEmpty', () {
      test('should return true for null', () {
        Iterable<int>? numbers;
        expect(numbers.isNullOrEmpty, true);
      });

      test('should return true for empty collection', () {
        final Iterable<int> numbers = <int>[];
        expect(numbers.isNullOrEmpty, true);
      });

      test('should return false for non-empty collection', () {
        final Iterable<int> numbers = [1, 2, 3];
        expect(numbers.isNullOrEmpty, false);
      });
    });

    group('isNotNullOrEmpty', () {
      test('should return false for null', () {
        Iterable<int>? numbers;
        expect(numbers.isNotNullOrEmpty, false);
      });

      test('should return false for empty collection', () {
        final Iterable<int> numbers = <int>[];
        expect(numbers.isNotNullOrEmpty, false);
      });

      test(
        'should return true for non-empty collection',
        () {
          final Iterable<int> numbers = [1, 2, 3];
          expect(numbers.isNotNullOrEmpty, true);
        },
      );
    });

    group('orEmpty', () {
      test('should return collection when not null', () {
        final Iterable<int> numbers = [1, 2, 3];
        expect(numbers.orEmpty, [1, 2, 3]);
      });

      test('should return empty iterable when null', () {
        Iterable<int>? numbers;
        expect(numbers.orEmpty, <int>[]);
      });
    });

    group('orEmptyList', () {
      test('should return list when not null', () {
        final Iterable<int> numbers = [1, 2, 3];
        final list = numbers.orEmptyList;
        expect(list, [1, 2, 3]);
        expect(list, isA<List<int>>());
      });

      test('should return empty list when null', () {
        Iterable<int>? numbers;
        final list = numbers.orEmptyList;
        expect(list, <int>[]);
        expect(list, isA<List<int>>());
      });
    });

    group('orEmptySet', () {
      test('should return set when not null', () {
        final Iterable<int> numbers = [1, 2, 2, 3];
        final set = numbers.orEmptySet;
        expect(set, {1, 2, 3});
        expect(set, isA<Set<int>>());
      });

      test('should return empty set when null', () {
        Iterable<int>? numbers;
        final set = numbers.orEmptySet;
        expect(set, <int>{});
        expect(set, isA<Set<int>>());
      });
    });

    group('ifNotEmpty', () {
      test(
        'should execute action for non-empty collection',
        () {
          var executed = false;
          Iterable<int>? values;
          [1, 2, 3].ifNotEmpty((iterable) {
            executed = true;
            values = iterable;
          });

          expect(executed, true);
          expect(values, [1, 2, 3]);
        },
      );

      test('should not execute action for null', () {
        var executed = false;
        (null as Iterable<int>?).ifNotEmpty((iterable) {
          executed = true;
        });

        expect(executed, false);
      });

      test(
        'should not execute action for empty collection',
        () {
          var executed = false;
          <int>[].ifNotEmpty((iterable) {
            executed = true;
          });

          expect(executed, false);
        },
      );
    });
  });
}
