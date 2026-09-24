import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/request_id_config.freezed.dart';

/// Makes a new request ID.
typedef RequestIdGenerator = String Function();

/// Request ID settings; a non-null box stamps an ID on every request.
///
/// Every retry attempt and every re-send after a token refresh carries the
/// ID of the first attempt. On the web, a custom header makes the browser
/// send a CORS preflight, so the server must list [headerName] in
/// `Access-Control-Allow-Headers`.
@freezed
abstract class RequestIdConfig with _$RequestIdConfig {
  /// Creates request ID settings.
  const factory({
    /// Header that carries the ID.
    @Default('X-Request-ID') String headerName,

    /// Makes a new ID; null makes a UUID v7.
    RequestIdGenerator? generate,
  }) = _RequestIdConfig;
}
