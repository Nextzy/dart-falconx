import 'package:dart_falmodel/lib.dart';
import 'package:test/test.dart';

void main() {
  group('PaginatedResponse.toJson characterization', () {
    test('middle page emits metadata keys only, snake_case', () {
      const response = PaginatedResponse<String>(
        items: ['a', 'b'],
        page: 2,
        pageSize: 10,
        totalItems: 35,
        totalPages: 4,
      );

      expect(response.toJson(), {
        'page': 2,
        'page_size': 10,
        'total_items': 35,
        'total_pages': 4,
        'has_next_page': true,
        'has_previous_page': true,
      });
    });

    test('items never appear in the output', () {
      const response = PaginatedResponse<int>(
        items: [1, 2, 3],
        page: 1,
        pageSize: 3,
        totalItems: 3,
        totalPages: 1,
      );

      expect(response.toJson().containsKey('items'), isFalse);
    });

    test('first page has no previous; last page has no next', () {
      const first = PaginatedResponse<int>(
        items: [],
        page: 1,
        pageSize: 10,
        totalItems: 20,
        totalPages: 2,
      );
      const last = PaginatedResponse<int>(
        items: [],
        page: 2,
        pageSize: 10,
        totalItems: 20,
        totalPages: 2,
      );

      expect(first.toJson()['has_previous_page'], isFalse);
      expect(first.toJson()['has_next_page'], isTrue);
      expect(last.toJson()['has_previous_page'], isTrue);
      expect(last.toJson()['has_next_page'], isFalse);
    });
  });

  group('PaginatedResponseWithMetadata.toJson characterization', () {
    test('spreads pagination keys then metadata', () {
      const response = PaginatedResponseWithMetadata<String>(
        items: ['x'],
        page: 1,
        pageSize: 1,
        totalItems: 1,
        totalPages: 1,
        metadata: {
          'query': 'abc',
          'filters': ['p', 'q'],
        },
      );

      final json = response.toJson();
      expect(json, {
        'page': 1,
        'page_size': 1,
        'total_items': 1,
        'total_pages': 1,
        'has_next_page': false,
        'has_previous_page': false,
        'metadata': {
          'query': 'abc',
          'filters': ['p', 'q'],
        },
      });
      expect(json.keys.last, 'metadata');
    });

    test('empty metadata map still emits the key', () {
      const response = PaginatedResponseWithMetadata<int>(
        items: [],
        page: 1,
        pageSize: 1,
        totalItems: 0,
        totalPages: 0,
        metadata: {},
      );

      expect(response.toJson()['metadata'], isEmpty);
      expect(response.toJson().containsKey('metadata'), isTrue);
    });
  });
}
