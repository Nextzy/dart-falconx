// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../paginated_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedResponse<T> _$PaginatedResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => $checkedCreate(
  'PaginatedResponse',
  json,
  ($checkedConvert) {
    final val = PaginatedResponse<T>(
      page: $checkedConvert('page', (v) => (v as num).toInt()),
      pageSize: $checkedConvert('page_size', (v) => (v as num).toInt()),
      totalItems: $checkedConvert('total_items', (v) => (v as num).toInt()),
      totalPages: $checkedConvert('total_pages', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'pageSize': 'page_size',
    'totalItems': 'total_items',
    'totalPages': 'total_pages',
  },
);

Map<String, dynamic> _$PaginatedResponseToJson<T>(
  PaginatedResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'page': instance.page,
  'page_size': instance.pageSize,
  'total_items': instance.totalItems,
  'total_pages': instance.totalPages,
  'has_next_page': instance.hasNextPage,
  'has_previous_page': instance.hasPreviousPage,
};

PaginatedResponseWithMetadata<T> _$PaginatedResponseWithMetadataFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => $checkedCreate(
  'PaginatedResponseWithMetadata',
  json,
  ($checkedConvert) {
    final val = PaginatedResponseWithMetadata<T>(
      page: $checkedConvert('page', (v) => (v as num).toInt()),
      pageSize: $checkedConvert('page_size', (v) => (v as num).toInt()),
      totalItems: $checkedConvert('total_items', (v) => (v as num).toInt()),
      totalPages: $checkedConvert('total_pages', (v) => (v as num).toInt()),
      metadata: $checkedConvert('metadata', (v) => v as Map<String, dynamic>),
    );
    return val;
  },
  fieldKeyMap: const {
    'pageSize': 'page_size',
    'totalItems': 'total_items',
    'totalPages': 'total_pages',
  },
);

Map<String, dynamic> _$PaginatedResponseWithMetadataToJson<T>(
  PaginatedResponseWithMetadata<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'page': instance.page,
  'page_size': instance.pageSize,
  'total_items': instance.totalItems,
  'total_pages': instance.totalPages,
  'has_next_page': instance.hasNextPage,
  'has_previous_page': instance.hasPreviousPage,
  'metadata': instance.metadata,
};
