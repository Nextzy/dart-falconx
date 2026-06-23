import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:dio/dio.dart';

/// Enum of all network error types, covering general connectivity issues and
/// every standard HTTP 4XX/5XX status code.
enum NetworkErrorType {
  // ─── General ───

  /// An unrecognized or unclassified error.
  unknown,

  // ─── Network / Connection ───

  /// A general network-level error (e.g., socket failure).
  network,

  /// A request or connection timeout.
  timeout,

  /// No internet connection is available.
  noInternet,

  /// A generic 4XX client error.
  clientError,

  /// A generic 5XX server error.
  serverError,

  // ─── HTTP 4XX Client Errors ───

  /// HTTP 400 Bad Request.
  badRequest,

  /// HTTP 401 Unauthorized.
  unauthorized,

  /// HTTP 402 Payment Required.
  paymentRequired,

  /// HTTP 403 Forbidden.
  forbidden,

  /// HTTP 404 Not Found.
  notFound,

  /// HTTP 405 Method Not Allowed.
  methodNotAllowed,

  /// HTTP 406 Not Acceptable.
  notAcceptable,

  /// HTTP 407 Proxy Authentication Required.
  proxyAuthRequired,

  /// HTTP 408 Request Timeout.
  requestTimeout,

  /// HTTP 409 Conflict.
  conflict,

  /// HTTP 410 Gone.
  gone,

  /// HTTP 411 Length Required.
  lengthRequired,

  /// HTTP 412 Precondition Failed.
  preconditionFailed,

  /// HTTP 413 Content Too Large.
  contentTooLarge,

  /// HTTP 414 URI Too Long.
  uriTooLong,

  /// HTTP 415 Unsupported Media Type.
  unsupportedMediaType,

  /// HTTP 416 Range Not Satisfiable.
  rangeNotSatisfiable,

  /// HTTP 417 Expectation Failed.
  expectationFailed,

  /// HTTP 421 Misdirected Request.
  misdirectedRequest,

  /// HTTP 422 Unprocessable Content.
  unprocessableContent,

  /// HTTP 423 Locked.
  locked,

  /// HTTP 424 Failed Dependency.
  failedDependency,

  /// HTTP 425 Too Early.
  tooEarly,

  /// HTTP 426 Upgrade Required.
  upgradeRequired,

  /// HTTP 428 Precondition Required.
  preconditionRequired,

  /// HTTP 429 Too Many Requests.
  tooManyRequests,

  /// HTTP 431 Request Header Fields Too Large.
  headerFieldsTooLarge,

  /// HTTP 451 Unavailable For Legal Reasons.
  unavailableForLegal,

  // ─── HTTP 5XX Server Errors ───

  /// HTTP 500 Internal Server Error.
  internalServerError,

  /// HTTP 501 Not Implemented.
  notImplemented,

  /// HTTP 502 Bad Gateway.
  badGateway,

  /// HTTP 503 Service Unavailable.
  serviceUnavailable,

  /// HTTP 504 Gateway Timeout.
  gatewayTimeout,

  /// HTTP 505 HTTP Version Not Supported.
  httpVersionNotSupported,

  /// HTTP 506 Variant Also Negotiates.
  variantAlsoNegotiates,

  /// HTTP 507 Insufficient Storage.
  insufficientStorage,

  /// HTTP 508 Loop Detected.
  loopDetected,

  /// HTTP 510 Not Extended.
  notExtended,

  /// HTTP 511 Network Authentication Required.
  networkAuthRequired;

  /// Returns a human-readable default message for this error type.
  String get defaultMessage => switch (this) {
    NetworkErrorType.unknown => 'Something went wrong. Please try again.',
    NetworkErrorType.network => 'Network error. Please check your connection.',
    NetworkErrorType.timeout => 'Request timed out. Please try again.',
    NetworkErrorType.noInternet => 'No internet connection.',
    NetworkErrorType.clientError => 'Client error. Please check your request.',
    NetworkErrorType.serverError => 'Server error. Please try again later.',
    NetworkErrorType.badRequest => 'Bad request.',
    NetworkErrorType.paymentRequired => 'Payment required.',
    NetworkErrorType.methodNotAllowed => 'Method not allowed.',
    NetworkErrorType.notAcceptable => 'Not acceptable.',
    NetworkErrorType.proxyAuthRequired => 'Proxy authentication required.',
    NetworkErrorType.requestTimeout => 'Request timed out.',
    NetworkErrorType.gone => 'The requested resource is no longer available.',
    NetworkErrorType.lengthRequired => 'Content length required.',
    NetworkErrorType.preconditionFailed => 'Precondition failed.',
    NetworkErrorType.contentTooLarge => 'Content too large.',
    NetworkErrorType.uriTooLong => 'URI too long.',
    NetworkErrorType.unsupportedMediaType => 'Unsupported media type.',
    NetworkErrorType.rangeNotSatisfiable => 'Range not satisfiable.',
    NetworkErrorType.expectationFailed => 'Expectation failed.',
    NetworkErrorType.misdirectedRequest => 'Misdirected request.',
    NetworkErrorType.unprocessableContent => 'Unprocessable content.',
    NetworkErrorType.locked => 'Resource is locked.',
    NetworkErrorType.failedDependency => 'Failed dependency.',
    NetworkErrorType.tooEarly => 'Too early.',
    NetworkErrorType.upgradeRequired => 'Upgrade required.',
    NetworkErrorType.preconditionRequired => 'Precondition required.',
    NetworkErrorType.tooManyRequests =>
      'Too many requests. Please try again later.',
    NetworkErrorType.headerFieldsTooLarge => 'Request header fields too large.',
    NetworkErrorType.unavailableForLegal => 'Unavailable for legal reasons.',
    NetworkErrorType.internalServerError => 'Internal server error.',
    NetworkErrorType.notImplemented => 'Not implemented.',
    NetworkErrorType.badGateway => 'Bad gateway.',
    NetworkErrorType.serviceUnavailable => 'Service is currently unavailable.',
    NetworkErrorType.gatewayTimeout => 'Gateway timeout.',
    NetworkErrorType.httpVersionNotSupported => 'HTTP version not supported.',
    NetworkErrorType.variantAlsoNegotiates => 'Variant also negotiates.',
    NetworkErrorType.insufficientStorage => 'Insufficient storage.',
    NetworkErrorType.loopDetected => 'Loop detected.',
    NetworkErrorType.notExtended => 'Not extended.',
    NetworkErrorType.networkAuthRequired => 'Network authentication required.',
    NetworkErrorType.unauthorized => 'Please log in to continue.',
    NetworkErrorType.forbidden =>
      'You do not have permission to perform this action.',
    NetworkErrorType.notFound => 'The requested resource was not found.',
    NetworkErrorType.conflict => 'A conflict occurred. Please try again.',
  };

  /// Maps this error type to its HTTP status code, or `null` if not
  /// HTTP-specific.
  int? get statusCode => switch (this) {
    NetworkErrorType.badRequest => 400,
    NetworkErrorType.unauthorized => 401,
    NetworkErrorType.paymentRequired => 402,
    NetworkErrorType.forbidden => 403,
    NetworkErrorType.notFound => 404,
    NetworkErrorType.methodNotAllowed => 405,
    NetworkErrorType.notAcceptable => 406,
    NetworkErrorType.proxyAuthRequired => 407,
    NetworkErrorType.requestTimeout => 408,
    NetworkErrorType.conflict => 409,
    NetworkErrorType.gone => 410,
    NetworkErrorType.lengthRequired => 411,
    NetworkErrorType.preconditionFailed => 412,
    NetworkErrorType.contentTooLarge => 413,
    NetworkErrorType.uriTooLong => 414,
    NetworkErrorType.unsupportedMediaType => 415,
    NetworkErrorType.rangeNotSatisfiable => 416,
    NetworkErrorType.expectationFailed => 417,
    NetworkErrorType.misdirectedRequest => 421,
    NetworkErrorType.unprocessableContent => 422,
    NetworkErrorType.locked => 423,
    NetworkErrorType.failedDependency => 424,
    NetworkErrorType.tooEarly => 425,
    NetworkErrorType.upgradeRequired => 426,
    NetworkErrorType.preconditionRequired => 428,
    NetworkErrorType.tooManyRequests => 429,
    NetworkErrorType.headerFieldsTooLarge => 431,
    NetworkErrorType.unavailableForLegal => 451,
    NetworkErrorType.internalServerError => 500,
    NetworkErrorType.notImplemented => 501,
    NetworkErrorType.badGateway => 502,
    NetworkErrorType.serviceUnavailable => 503,
    NetworkErrorType.gatewayTimeout => 504,
    NetworkErrorType.httpVersionNotSupported => 505,
    NetworkErrorType.variantAlsoNegotiates => 506,
    NetworkErrorType.insufficientStorage => 507,
    NetworkErrorType.loopDetected => 508,
    NetworkErrorType.notExtended => 510,
    NetworkErrorType.networkAuthRequired => 511,
    _ => null,
  };

  /// Creates a [NetworkErrorType] from an HTTP status code.
  static NetworkErrorType fromStatusCode(int statusCode) =>
      switch (statusCode) {
        400 => NetworkErrorType.badRequest,
        401 => NetworkErrorType.unauthorized,
        402 => NetworkErrorType.paymentRequired,
        403 => NetworkErrorType.forbidden,
        404 => NetworkErrorType.notFound,
        405 => NetworkErrorType.methodNotAllowed,
        406 => NetworkErrorType.notAcceptable,
        407 => NetworkErrorType.proxyAuthRequired,
        408 => NetworkErrorType.requestTimeout,
        409 => NetworkErrorType.conflict,
        410 => NetworkErrorType.gone,
        411 => NetworkErrorType.lengthRequired,
        412 => NetworkErrorType.preconditionFailed,
        413 => NetworkErrorType.contentTooLarge,
        414 => NetworkErrorType.uriTooLong,
        415 => NetworkErrorType.unsupportedMediaType,
        416 => NetworkErrorType.rangeNotSatisfiable,
        417 => NetworkErrorType.expectationFailed,
        421 => NetworkErrorType.misdirectedRequest,
        422 => NetworkErrorType.unprocessableContent,
        423 => NetworkErrorType.locked,
        424 => NetworkErrorType.failedDependency,
        425 => NetworkErrorType.tooEarly,
        426 => NetworkErrorType.upgradeRequired,
        428 => NetworkErrorType.preconditionRequired,
        429 => NetworkErrorType.tooManyRequests,
        431 => NetworkErrorType.headerFieldsTooLarge,
        451 => NetworkErrorType.unavailableForLegal,
        500 => NetworkErrorType.internalServerError,
        501 => NetworkErrorType.notImplemented,
        502 => NetworkErrorType.badGateway,
        503 => NetworkErrorType.serviceUnavailable,
        504 => NetworkErrorType.gatewayTimeout,
        505 => NetworkErrorType.httpVersionNotSupported,
        506 => NetworkErrorType.variantAlsoNegotiates,
        507 => NetworkErrorType.insufficientStorage,
        508 => NetworkErrorType.loopDetected,
        510 => NetworkErrorType.notExtended,
        511 => NetworkErrorType.networkAuthRequired,
        >= 400 && < 500 => NetworkErrorType.clientError,
        >= 500 && < 600 => NetworkErrorType.serverError,
        _ => NetworkErrorType.unknown,
      };

  /// Whether this error type represents a 4xx client error.
  bool get isClientError => (statusCode ?? 0) >= 400 && (statusCode ?? 0) < 500;

  /// Whether this error type represents a 5xx server error.
  bool get isServerError => (statusCode ?? 0) >= 500 && (statusCode ?? 0) < 600;
}

/// Base exception for all HTTP network errors, extending [CommonException] with
/// HTTP-specific fields such as [statusCode], [response], and [requestOptions].
class NetworkException extends CommonException {
  /// Creates a [NetworkException] with the given [type] and [statusCode].
  const NetworkException({
    required super.type,
    required this.statusCode,
    super.userMessage,
    super.developerMessage,
    this.response,
    this.requestOptions,
    super.stackTrace,
    this.errors,
  });

  /// The HTTP status code returned by the server.
  final int statusCode;

  /// The raw Dio response, if available.
  final Response<dynamic>? response;

  /// The Dio request options that produced this error.
  final RequestOptions? requestOptions;

  /// Optional list of nested network errors (e.g., validation sub-errors).
  final List<NetworkException>? errors;

  /// Converts this exception to a [DioException] for interoperability with Dio.
  DioException toDioException({
    RequestOptions? requestOptions,
    Response<dynamic>? response,
    StackTrace? stackTrace,
    DioExceptionType? type,
    String? message,
  }) => DioException(
    requestOptions: requestOptions ?? this.requestOptions ?? RequestOptions(),
    response: response ?? this.response,
    error: this,
    stackTrace: stackTrace ?? this.stackTrace ?? StackTrace.current,
    type: type ?? DioExceptionType.unknown,
    message: message ?? userMessage ?? developerMessage,
  );

  @override
  String toString() {
    var msg = '';
    if (statusCode != 0) msg += '>>Status code: $statusCode\n';
    msg += '>>Type: $type\n';
    if (userMessage != null && userMessage!.isNotEmpty) {
      msg += '>>User message: $userMessage\n';
    }
    if (developerMessage != null && developerMessage!.isNotEmpty) {
      msg += '>>Developer message: $developerMessage\n';
    }
    if (response != null) msg += '>>Response: $response\n';
    errors?.forEach(
      (error) => msg += '   $error]\n',
    );
    return msg;
  }
}
