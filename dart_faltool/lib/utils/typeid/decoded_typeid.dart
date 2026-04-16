import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'generated/decoded_typeid.freezed.dart';

@freezed
abstract class DecodedTypeId with _$DecodedTypeId {
  const factory DecodedTypeId({
    required String prefix,
    required String suffix,
    required UuidValue uuid,
  }) = _DecodedTypeId;

  const DecodedTypeId._();

  @override
  String toString() => prefix.isEmpty ? suffix : '${prefix}_$suffix';
}
