import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/decoded_typeid.freezed.dart';

@freezed
abstract class DecodedTypeId with _$DecodedTypeId {
  const factory DecodedTypeId({
    required String prefix,
    required String suffix,
    required String uuid,
  }) = _DecodedTypeId;

  const DecodedTypeId._();

  @override
  String toString() => prefix.isEmpty ? suffix : '${prefix}_$suffix';
}
