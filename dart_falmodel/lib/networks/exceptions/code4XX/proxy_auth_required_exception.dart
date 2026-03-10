import 'package:dart_falmodel/lib.dart';

class NetworkProxyAuthRequiredException extends NetworkClientException {
  const NetworkProxyAuthRequiredException({
    super.statusCode = 407,
    super.type = NetworkErrorType.proxyAuthRequired,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
