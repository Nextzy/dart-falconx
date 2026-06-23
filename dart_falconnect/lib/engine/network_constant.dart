/// Common HTTP header name constants.
class HttpHeader {
  /// `Authorization` header name.
  static const AUTHORIZE = 'Authorization';

  /// `Accept-Language` header name.
  static const ACCEPT_LANGUAGE = 'Accept-Language';

  /// `Cache-Control` header name.
  static const CACHE_CONTROL = 'Cache-Control';

  /// `Content-Type` header name.
  static const CONTENT_TYPE = 'Content-Type';

  /// `Content-Length` header name.
  static const CONTENT_LENGTH = 'Content-Length';

  /// `Cookie` header name.
  static const COOKIE = 'Cookie';

  /// `Keep-Alive` header name.
  static const KEEP_ALIVE = 'Keep-Alive';

  /// `Origin` header name.
  static const ORIGIN = 'Origin';

  /// `User-Agent` header name.
  static const USER_AGENT = 'User-Agent';

  /// `x-api-key` header name.
  static const X_API_KEY = 'x-api-key';
}

/// Common HTTP status code constants.
class HttpCode {
  /// HTTP 200 OK.
  static const SUCCESS = 200;

  /// HTTP 401 Unauthorized.
  static const ERROR_UNAUTHORIZED = 401;

  /// HTTP 404 Not Found.
  static const ERROR_NOT_FOUND = 404;

  /// HTTP 500 Internal Server Error.
  static const ERROR_INTERNAL = 500;
}
