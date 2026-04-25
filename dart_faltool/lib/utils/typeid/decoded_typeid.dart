import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/decoded_typeid.freezed.dart';

/// Freezed model representing a decoded TypeID, split into its component parts.
///
/// [toString] reconstructs the full TypeID string in `prefix_suffix` form.
@freezed
abstract class DecodedTypeId with _$DecodedTypeId {
  /// Creates a [DecodedTypeId] with the given [prefix], [suffix], and [uuid].
  const factory DecodedTypeId({
    /// The type prefix (e.g., `'user'`); empty string for prefix-less TypeIDs.
    required String prefix,

    /// The base32-encoded UUID suffix (26 characters).
    required String suffix,

    /// The UUID string extracted from the TypeID.
    required String uuid,
  }) = _DecodedTypeId;

  const DecodedTypeId._();

  @override
  String toString() => prefix.isEmpty ? suffix : '${prefix}_$suffix';
}
