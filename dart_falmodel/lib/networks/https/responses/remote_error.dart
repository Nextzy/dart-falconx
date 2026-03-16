import 'package:dart_falmodel/lib.dart';

part 'generated/remote_error.freezed.dart';

part 'generated/remote_error.g.dart';

@freezed
abstract class RemoteError with _$RemoteError {
  const factory RemoteError({
    int? code,
    String? message,
    String? userMessage,
    String? developerMessage,
  }) = _RemoteError;

  factory RemoteError.fromJson(Map<String, dynamic> json) =>
      _$RemoteErrorFromJson(json);

  factory RemoteError.fromData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return RemoteError.fromJson(data);
    } else {
      return RemoteError(message: data.toString());
    }
  }
}
