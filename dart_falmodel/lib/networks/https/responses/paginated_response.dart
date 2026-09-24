import 'package:dart_falmodel/lib.dart';

part 'generated/paginated_response.g.dart';

/// Generic paginated response for list endpoints.
///
/// Provides a standardized structure for paginated API responses
/// with metadata about the current page, total items, and navigation.
///
/// Type parameter [T] represents the type of items in the list.
///
/// Example:
/// ```dart
/// class UserListResponse extends PaginatedResponse<User> {
///   const UserListResponse({
///     required super.items,
///     required super.page,
///     required super.pageSize,
///     required super.totalItems,
///     required super.totalPages,
///   });
///
///   factory UserListResponse.fromJson(Map<String, dynamic> json) {
///     return UserListResponse(
///       items: (json['users'] as List)
///           .map((e) => User.fromJson(e as Map<String, dynamic>))
///           .toList(),
///       page: json['page'] as int,
///       pageSize: json['page_size'] as int,
///       totalItems: json['total_items'] as int,
///       totalPages: json['total_pages'] as int,
///     );
///   }
/// }
/// ```
@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponse<T> extends BaseRequest {
  /// Creates a paginated response.
  ///
  /// [items] is the list of items for the current page.
  /// [page] is the current page number (1-indexed).
  /// [pageSize] is the number of items per page.
  /// [totalItems] is the total number of items across all pages.
  /// [totalPages] is the total number of pages.
  const new({
    this.items = const [],
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  /// Deserializes a [PaginatedResponse] from a JSON map.
  factory fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$PaginatedResponseFromJson(json, fromJsonT);

  /// The items for the current page.
  ///
  /// Excluded from JSON: subclasses override `toJson` to serialize items
  /// under their own key.
  @JsonKey(includeToJson: false, includeFromJson: false)
  final List<T> items;

  /// The current page number (1-indexed).
  @JsonKey(name: 'page')
  final int page;

  /// The number of items per page.
  @JsonKey(name: 'page_size')
  final int pageSize;

  /// The total number of items across all pages.
  @JsonKey(name: 'total_items')
  final int totalItems;

  /// The total number of pages.
  @JsonKey(name: 'total_pages')
  final int totalPages;

  /// Whether there is a next page.
  @JsonKey(name: 'has_next_page', includeToJson: true, includeFromJson: false)
  bool get hasNextPage => page < totalPages;

  /// Whether there is a previous page.
  @JsonKey(
    name: 'has_previous_page',
    includeToJson: true,
    includeFromJson: false,
  )
  bool get hasPreviousPage => page > 1;

  /// The next page number, or null if on the last page.
  int? get nextPage => hasNextPage ? page + 1 : null;

  /// The previous page number, or null if on the first page.
  int? get previousPage => hasPreviousPage ? page - 1 : null;

  /// Whether this is the first page.
  bool get isFirstPage => page == 1;

  /// Whether this is the last page.
  bool get isLastPage => page == totalPages;

  /// The number of items on the current page.
  int get itemCount => items.length;

  /// Whether the current page is empty.
  bool get isEmpty => items.isEmpty;

  /// Whether the current page has items.
  bool get isNotEmpty => items.isNotEmpty;

  /// The starting index of items on this page (0-indexed).
  int get startIndex => (page - 1) * pageSize;

  /// The ending index of items on this page (0-indexed).
  int get endIndex => startIndex + itemCount - 1;

  /// Creates a copy with updated values.
  PaginatedResponse<T> copyWith({
    List<T>? items,
    int? page,
    int? pageSize,
    int? totalItems,
    int? totalPages,
  }) {
    return PaginatedResponse<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  /// Converts this response to a JSON map.
  ///
  /// Note: This only includes metadata. Subclasses should override
  /// to include the actual items with proper serialization.
  Map<String, dynamic> toJson() =>
      _$PaginatedResponseToJson(this, (value) => value);

  @override
  List<Object?> get props => [items, page, pageSize, totalItems, totalPages];
}

/// A paginated response with additional metadata.
///
/// Extends [PaginatedResponse] to include custom metadata that might
/// be returned by the API alongside pagination information.
///
/// Example:
/// ```dart
/// class ProductListResponse extends PaginatedResponseWithMetadata<Product> {
///   const ProductListResponse({
///     required super.items,
///     required super.page,
///     required super.pageSize,
///     required super.totalItems,
///     required super.totalPages,
///     required super.metadata,
///   });
///
///   // Access typed metadata
///   List<String> get availableFilters =>
///       (metadata['filters'] as List?)?.cast<String>() ?? [];
///
///   String? get searchQuery => metadata['query'] as String?;
/// }
/// ```
@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponseWithMetadata<T> extends PaginatedResponse<T> {
  /// Creates a paginated response with metadata.
  const new({
    super.items,
    required super.page,
    required super.pageSize,
    required super.totalItems,
    required super.totalPages,
    required this.metadata,
  });

  /// Deserializes a [PaginatedResponseWithMetadata] from a JSON map.
  factory fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$PaginatedResponseWithMetadataFromJson(json, fromJsonT);

  /// Additional metadata returned by the API.
  final Map<String, dynamic> metadata;

  @override
  PaginatedResponseWithMetadata<T> copyWith({
    List<T>? items,
    int? page,
    int? pageSize,
    int? totalItems,
    int? totalPages,
    Map<String, dynamic>? metadata,
  }) {
    return PaginatedResponseWithMetadata<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts this response to a JSON map with the metadata appended.
  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'metadata': metadata};

  @override
  List<Object?> get props => [...super.props, metadata];
}
