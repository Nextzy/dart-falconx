import 'package:dart_falconnect/dart_falconnect.dart';

part 'generated/no_token_api.g.dart';

/// A Retrofit API that proves `@noToken` and `@Extras()` reach the auth
/// interceptors through generated code.
@RestApi()
abstract class NoTokenApi {
  factory(Dio dio) = _NoTokenApi;

  @GET('/public')
  @noToken
  Future<void> public();

  @GET('/private')
  Future<void> private();

  @GET('/extras')
  Future<void> withExtras(@Extras() Map<String, dynamic> extras);
}
