import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

import '../interceptors/_scripted_adapter.dart';
import 'no_token_api.dart';

class _Client extends BaseHttpClient {
  new(HttpClientAdapter adapter)
    : super(
        dio: Dio()
          ..httpClientAdapter = adapter
          ..transformer = FoldingTransformer(),
        config: HttpClientConfig(
          auth: AuthConfig(accessToken: () => 't1', refresh: () async => false),
        ),
      );
}

void main() {
  late ScriptedAdapter adapter;
  late NoTokenApi api;

  setUp(() {
    adapter = ScriptedAdapter([reply(200)]);
    api = NoTokenApi(_Client(adapter).dio);
  });

  test('an endpoint without an annotation sends the token', () async {
    await api.private();

    expect(adapter.requests.single.headers['authorization'], 'Bearer t1');
  });

  test('@noToken sends no token', () async {
    await api.public();

    expect(adapter.requests.single.headers, isNot(contains('authorization')));
    expect(adapter.requests.single.useToken, isFalse);
  });

  test('@Extras() with useTokenExtraKey false sends no token', () async {
    await api.withExtras({useTokenExtraKey: false});

    expect(adapter.requests.single.headers, isNot(contains('authorization')));
  });
}
