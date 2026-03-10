import 'package:dart_falmodel/lib.dart';

class NetworkUpgradeRequiredException extends NetworkClientException {
  const NetworkUpgradeRequiredException({
    super.statusCode = 426,
    super.type = NetworkErrorType.upgradeRequired,
    super.userMessage,
    super.developerMessage,
    super.response,
    super.requestOptions,
    super.stackTrace,
    super.errors,
  });
}
