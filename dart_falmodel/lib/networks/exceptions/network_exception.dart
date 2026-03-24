import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:dio/dio.dart';

enum NetworkErrorType {
  // ─── General ───
  unknown,

  // ─── Network / Connection ───
  network,
  timeout,
  noInternet,
  clientError,
  serverError,

  // ─── HTTP 4XX Client Errors ───
  badRequest,
  unauthorized,
  paymentRequired,
  forbidden,
  notFound,
  methodNotAllowed,
  notAcceptable,
  proxyAuthRequired,
  requestTimeout,
  conflict,
  gone,
  lengthRequired,
  preconditionFailed,
  contentTooLarge,
  uriTooLong,
  unsupportedMediaType,
  rangeNotSatisfiable,
  expectationFailed,
  misdirectedRequest,
  unprocessableContent,
  locked,
  failedDependency,
  tooEarly,
  upgradeRequired,
  preconditionRequired,
  tooManyRequests,
  headerFieldsTooLarge,
  unavailableForLegal,

  // ─── HTTP 5XX Server Errors ───
  internalServerError,
  notImplemented,
  badGateway,
  serviceUnavailable,
  gatewayTimeout,
  httpVersionNotSupported,
  variantAlsoNegotiates,
  insufficientStorage,
  loopDetected,
  notExtended,
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

class NetworkException extends CommonException {
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

  final int statusCode;
  final Response<dynamic>? response;
  final RequestOptions? requestOptions;
  final List<NetworkException>? errors;

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
