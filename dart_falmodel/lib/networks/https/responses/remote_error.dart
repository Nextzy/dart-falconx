import 'package:dart_falmodel/lib.dart';

part 'generated/remote_error.freezed.dart';

part 'generated/remote_error.g.dart';

/// Freezed model representing an error payload returned by a remote API.
///
/// Used to deserialize structured error bodies from HTTP responses.
@freezed
abstract class RemoteError with _$RemoteError {
  /// Creates a [RemoteError] with optional code, message, and
  /// developer/user messages.
  const factory RemoteError({
    int? code,
    String? message,
    String? userMessage,
    String? developerMessage,
  }) = _RemoteError;

  /// Deserializes a [RemoteError] from a JSON map.
  factory RemoteError.fromJson(Map<String, dynamic> json) =>
      _$RemoteErrorFromJson(json);

  /// Creates a [RemoteError] from an arbitrary [data] value.
  ///
  /// If [data] is a `Map<String, dynamic>`, delegates to `fromJson`;
  /// otherwise converts the value to a string message.
  factory RemoteError.fromData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return RemoteError.fromJson(data);
    } else {
      return RemoteError(message: data.toString());
    }
  }
}
