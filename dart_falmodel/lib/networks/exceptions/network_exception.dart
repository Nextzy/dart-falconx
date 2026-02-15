import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:dio/dio.dart';

class NetworkException extends CommonException<String> {
  const NetworkException({
    String? type,
    this.statusCode = 0,
    super.userMessage,
    super.developerMessage,
    this.response,
    this.requestOptions,
    super.stackTrace,
    this.errors,
  }) : super(code: type ?? 'UNKNOWN');

  final int statusCode;
  final Response? response;
  final RequestOptions? requestOptions;
  final List<NetworkException>? errors;

  DioException toDioException({
    RequestOptions? requestOptions,
    Response? response,
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
    msg += '>>Type: $code\n';
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
