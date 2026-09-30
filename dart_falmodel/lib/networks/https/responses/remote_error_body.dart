import 'package:dart_falmodel/src/src.dart';

part 'generated/remote_error_body.freezed.dart';

part 'generated/remote_error_body.g.dart';

/// Freezed model representing an error payload returned by a remote API.
///
/// Used to deserialize structured error bodies from HTTP responses.
@freezed
abstract class RemoteErrorBody with _$RemoteErrorBody {
  /// Creates a [RemoteErrorBody] with optional code, message, and
  /// developer/user messages.
  const factory({
    int? code,
    String? message,
    String? userMessage,
    String? developerMessage,
  }) = _RemoteErrorBody;

  /// Deserializes a [RemoteErrorBody] from a JSON map.
  factory fromJson(Map<String, dynamic> json) =>
      _$RemoteErrorBodyFromJson(json);

  /// Creates a [RemoteErrorBody] from an arbitrary [data] value.
  ///
  /// If [data] is a `Map<String, dynamic>`, delegates to `fromJson`;
  /// otherwise converts the value to a string message.
  factory fromData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return RemoteErrorBody.fromJson(data);
    } else {
      return RemoteErrorBody(message: data.toString());
    }
  }
}
