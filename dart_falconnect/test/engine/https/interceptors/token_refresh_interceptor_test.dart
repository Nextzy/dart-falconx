import 'dart:async';
import 'dart:convert';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_faltool/dart_faltool.dart' show TokenBucketPolicy;
import 'package:test/test.dart';

import '_scripted_adapter.dart';

class _Client extends BaseHttpClient {
  new(HttpClientAdapter adapter, HttpClientConfig config)
    : super(
        dio: Dio()
          ..httpClientAdapter = adapter
          ..transformer = FoldingTransformer(),
        config: config,
      );
}

/// A server that answers 200 to the current token and 401 to any other.
///
/// [statusFor] overrides the answer for a request.
class _Server implements HttpClientAdapter {
  new(this.tokens, {this.statusFor});

  final _Tokens tokens;
  final int? Function(RequestOptions options)? statusFor;
  final List<RequestOptions> requests = [];

  /// Completes once the server has answered [count] requests.
  Future<void> answered(int count) async {
    while (requests.length < count) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    requests.add(options);
    final status =
        statusFor?.call(options) ??
        (options.headers['authorization'] == 'Bearer ${tokens.server}'
            ? 200
            : 401);
    return reply(status)(options);
  }

  @override
  void close({bool force = false}) {}
}

/// The app's token store: `current` is what the app holds, `server` what
/// the server accepts. A refresh copies `server` into `current`.
class _Tokens {
  String? current = 'old';
  String server = 'new';
  int reads = 0;
  int refreshes = 0;
  int failures = 0;

  /// Completed by a test to let a running refresh finish.
  Completer<void>? gate;

  /// What the next refresh returns.
  bool succeeds = true;

  Future<bool> refresh() async {
    refreshes++;
    await gate?.future;
    if (succeeds) current = server;
    return succeeds;
  }

  String? read() {
    reads++;
    return current;
  }

  /// Completes once `accessToken` has been read [count] times.
  Future<void> readTimes(int count) async {
    while (reads < count) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  AuthConfig config({RefreshCallback? refresh}) => AuthConfig(
    accessToken: read,
    refresh: refresh ?? this.refresh,
    onAuthFailed: (_) => failures++,
  );
}

Future<DioException> _failure(Future<Object?> request) => request.then(
  (_) => fail('the request succeeded'),
  onError: (Object error) => error as DioException,
);

void main() {
  group('refresh', () {
    test('many 401s at once share one refresh, and every request is sent '
        'again with the new token', () async {
      final tokens = _Tokens()..gate = Completer<void>();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final requests = [
        for (var i = 0; i < 5; i++) client.dio.get<dynamic>('/x'),
      ];
      // Five stamps and five 401s have read the token: every request now
      // waits in the refresh interceptor.
      await tokens.readTimes(10);
      tokens.gate!.complete();
      final responses = await Future.wait(requests);

      expect(tokens.refreshes, 1);
      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(
        server.requests.skip(5).map((r) => r.headers['authorization']),
        everyElement('Bearer new'),
      );
      expect(server.requests, hasLength(10));
    });

    test('a 401 that arrives after another refresh is sent again without '
        'refreshing', () async {
      final tokens = _Tokens();
      final gated = GatedAdapter();
      final client = _Client(gated, HttpClientConfig(auth: tokens.config()));

      final first = client.dio.get<dynamic>('/x');
      final second = client.dio.get<dynamic>('/x');
      while (gated.requests.length < 2) {
        await Future<void>.delayed(Duration.zero);
      }
      gated.requests[0].respond(401);
      while (gated.requests.length < 3) {
        await Future<void>.delayed(Duration.zero);
      }
      gated.requests[2].respond(200);
      await first;
      gated.requests[1].respond(401);
      while (gated.requests.length < 4) {
        await Future<void>.delayed(Duration.zero);
      }
      gated.requests[3].respond(200);
      await second;

      expect(tokens.refreshes, 1);
      expect(gated.requests[1].options.headers['authorization'], 'Bearer old');
      expect(gated.requests[3].options.headers['authorization'], 'Bearer new');
    });

    test('a token read that ends after a refresh finished joins that refresh '
        'instead of starting another', () async {
      final tokens = _Tokens()..gate = Completer<void>();
      final slowRead = Completer<void>();
      var reads = 0;
      final server = _Server(tokens);
      final client = _Client(
        server,
        HttpClientConfig(
          auth: AuthConfig(
            accessToken: () async {
              // The read sees the store as it is when the read starts.
              final value = tokens.current;
              // Reads 1 and 2 are the stamps, 3 and 4 the two 401s: the
              // second 401's read outlasts the refresh.
              if (++reads == 4) await slowRead.future;
              return value;
            },
            refresh: tokens.refresh,
          ),
        ),
      );

      final requests = [
        client.dio.get<dynamic>('/x'),
        client.dio.get<dynamic>('/x'),
      ];
      while (reads < 4) {
        await Future<void>.delayed(Duration.zero);
      }
      tokens.gate!.complete();
      // The refreshing request's re-send reaches the server once the refresh
      // is over.
      await server.answered(3);
      slowRead.complete();
      final responses = await Future.wait(requests);

      expect(tokens.refreshes, 1);
      expect(responses.map((r) => r.statusCode), everyElement(200));
    });

    test('a request that starts during a refresh waits and carries the new '
        'token', () async {
      final tokens = _Tokens()..gate = Completer<void>();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final first = client.dio.get<dynamic>('/x');
      await server.answered(1);
      await Future<void>.delayed(Duration.zero);
      final later = client.dio.get<dynamic>('/y');
      await Future<void>.delayed(Duration.zero);
      expect(server.requests, hasLength(1));
      tokens.gate!.complete();
      await Future.wait([first, later]);

      final toY = server.requests.where((r) => r.path == '/y');
      expect(toY.single.headers['authorization'], 'Bearer new');
      expect(tokens.refreshes, 1);
    });
  });

  group('failure', () {
    test('a refresh that returns false calls onAuthFailed once, and every '
        'waiting request fails with its 401', () async {
      final tokens = _Tokens()
        ..succeeds = false
        ..gate = Completer<void>();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final failures = [
        for (var i = 0; i < 3; i++) _failure(client.dio.get<dynamic>('/x')),
      ];
      await tokens.readTimes(6);
      tokens.gate!.complete();
      final errors = await Future.wait(failures);

      expect(errors.map((e) => e.response?.statusCode), everyElement(401));
      expect(tokens.refreshes, 1);
      expect(tokens.failures, 1);
      expect(server.requests, hasLength(3));
    });

    test('a later 401 with the token that failed causes no refresh and no '
        'second onAuthFailed', () async {
      final tokens = _Tokens()..succeeds = false;
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      await _failure(client.dio.get<dynamic>('/x'));
      await _failure(client.dio.get<dynamic>('/x'));

      expect(tokens.refreshes, 1);
      expect(tokens.failures, 1);
    });

    test('a refresh that throws fails like one that returns false, and the '
        'diagnostics say so', () async {
      final lines = <Object?>[];
      final tokens = _Tokens();
      final server = _Server(tokens);
      final client = _Client(
        server,
        HttpClientConfig(
          log: LogConfig(logPrint: lines.add, request: false),
          auth: tokens.config(refresh: () async => throw StateError('down')),
        ),
      );

      final error = await _failure(client.dio.get<dynamic>('/x'));

      expect(error.response?.statusCode, 401);
      expect(tokens.failures, 1);
      expect(lines, contains(startsWith('[AuthSession] Refresh threw')));
    });

    test('a re-send that gets a 401 again calls onAuthFailed and does not '
        'refresh again', () async {
      final tokens = _Tokens();
      final server = _Server(tokens, statusFor: (_) => 401);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final error = await _failure(client.dio.get<dynamic>('/x'));

      expect(error.response?.statusCode, 401);
      expect(tokens.refreshes, 1);
      expect(tokens.failures, 1);
      expect(server.requests, hasLength(2));
    });

    test(
      'a 401 that arrives after logout passes on without a refresh',
      () async {
        final tokens = _Tokens();
        final server = _Server(
          tokens,
          statusFor: (_) {
            // The app logs out while the request is in flight.
            tokens.current = null;
            return 401;
          },
        );
        final client = _Client(server, HttpClientConfig(auth: tokens.config()));

        final error = await _failure(client.dio.get<dynamic>('/x'));

        expect(error.response?.statusCode, 401);
        expect(tokens.refreshes, 0);
        expect(tokens.failures, 0);
      },
    );

    test('a 401 on a request sent without a token passes on', () async {
      final tokens = _Tokens()..current = null;
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final error = await _failure(client.dio.get<dynamic>('/x'));

      expect(error.response?.statusCode, 401);
      expect(tokens.refreshes, 0);
      expect(tokens.failures, 0);
    });

    test('an accessToken that throws while handling a 401 passes the 401 on '
        'without a refresh', () async {
      final tokens = _Tokens();
      final server = _Server(tokens);
      var reads = 0;
      final client = _Client(
        server,
        HttpClientConfig(
          auth: AuthConfig(
            accessToken: () =>
                ++reads == 1 ? tokens.current : throw StateError('locked'),
            refresh: tokens.refresh,
          ),
        ),
      );

      final error = await _failure(client.dio.get<dynamic>('/x'));

      expect(error.response?.statusCode, 401);
      expect(tokens.refreshes, 0);
    });

    test('a throwing onAuthFailed goes to the diagnostics and leaves the '
        '401 unchanged', () async {
      final lines = <Object?>[];
      final tokens = _Tokens()..succeeds = false;
      final server = _Server(tokens);
      final client = _Client(
        server,
        HttpClientConfig(
          log: LogConfig(logPrint: lines.add, request: false),
          auth: AuthConfig(
            accessToken: () => tokens.current,
            refresh: tokens.refresh,
            onAuthFailed: (_) => throw StateError('router gone'),
          ),
        ),
      );

      final error = await _failure(client.dio.get<dynamic>('/x'));
      await Future<void>.delayed(Duration.zero);

      expect(error.response?.statusCode, 401);
      expect(lines, contains(startsWith('[AuthSession] onAuthFailed threw')));
    });
  });

  group('bodies and cancels', () {
    test('a Stream body refreshes and passes its 401 on', () async {
      final tokens = _Tokens();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final error = await _failure(
        client.dio.post<dynamic>(
          '/x',
          data: Stream.value(utf8.encode('{}')),
          options: Options(headers: {Headers.contentLengthHeader: 2}),
        ),
      );

      expect(error.response?.statusCode, 401);
      expect(tokens.refreshes, 1);
      expect(tokens.current, 'new');
      expect(server.requests, hasLength(1));
    });

    test('a FormData body is cloned for the re-send', () async {
      final tokens = _Tokens();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));

      final response = await client.dio.post<dynamic>(
        '/x',
        data: FormData.fromMap({'a': '1'}),
      );

      expect(response.statusCode, 200);
      expect(server.requests, hasLength(2));
      expect(server.requests[1].data, isA<FormData>());
      expect(server.requests[1].data, isNot(same(server.requests[0].data)));
    });

    test('a cancel while waiting for the refresh fails that request at once; '
        'the refresh completes for the others', () async {
      final tokens = _Tokens()..gate = Completer<void>();
      final server = _Server(tokens);
      final client = _Client(server, HttpClientConfig(auth: tokens.config()));
      final cancel = CancelToken();

      final cancelled = _failure(
        client.dio.get<dynamic>('/a', cancelToken: cancel),
      );
      final other = client.dio.get<dynamic>('/b');
      await server.answered(2);
      await Future<void>.delayed(Duration.zero);
      cancel.cancel();
      final error = await cancelled;
      tokens.gate!.complete();
      final response = await other;

      expect(error.type, DioExceptionType.cancel);
      expect(response.statusCode, 200);
      expect(server.requests.where((r) => r.path == '/a'), hasLength(1));
    });
  });

  group('the chain', () {
    test('a failed re-send skips the outer retry and exception handler, which '
        'it already passed', () async {
      final handled = <int?>[];
      final tokens = _Tokens();
      final server = _Server(
        tokens,
        statusFor: (o) =>
            o.headers['authorization'] == 'Bearer new' ? 500 : 401,
      );
      final client = _Client(
        server,
        HttpClientConfig(
          auth: tokens.config(),
          retry: const RetryConfig(maxAttempts: 2, delay: Duration.zero),
          exceptionHandler: _CountingHandler(handled),
        ),
      );

      final error = await _failure(client.dio.get<dynamic>('/x'));

      expect(error.response?.statusCode, 500);
      expect(server.requests, hasLength(4));
      expect(handled, [500, 500, 500]);
    });

    test('the re-send takes a new slot and a new token and leaves none '
        'held', () async {
      final tokens = _Tokens();
      final server = _Server(tokens);
      final client = _Client(
        server,
        HttpClientConfig(
          auth: tokens.config(),
          concurrency: const ConcurrencyConfig(global: 1),
          rateLimit: const RateLimitConfig.tokenBucket(
            global: [TokenBucketPolicy(permits: 10, per: Duration(minutes: 1))],
          ),
        ),
      );
      addTearDown(client.dispose);

      await client.dio.get<dynamic>('/x');

      final concurrency = client.interceptors
          .whereType<ConcurrencyLimitInterceptor>()
          .single
          .getStatistics();
      final rateLimit = client.interceptors
          .whereType<TokenBucketRateLimitInterceptor>()
          .single
          .getStatistics();
      expect(concurrency.globalActive, 0);
      expect(concurrency.forwarded, 2);
      expect(rateLimit.forwarded, 2);
    });

    test('the JSON log prints both attempts with one request ID', () async {
      final lines = <Object?>[];
      final tokens = _Tokens();
      final server = _Server(tokens);
      final client = _Client(
        server,
        HttpClientConfig(
          log: LogConfig.json(logPrint: lines.add, diagnostics: false),
          requestId: RequestIdConfig(generate: () => 'id-1'),
          auth: tokens.config(),
        ),
      );

      await client.dio.get<dynamic>('/x');

      final fields = [
        for (final line in lines) jsonDecode(line! as String) as Map,
      ];
      expect(fields, hasLength(2));
      expect(fields.map((f) => f['falconx.request.id']), ['id-1', 'id-1']);
      expect(fields[0]['http.response.status_code'], 401);
      expect(fields[0], isNot(contains('falconx.auth.resent')));
      expect(fields[1]['falconx.auth.resent'], isTrue);
    });
  });

  group('zone guard', () {
    test('a refresh that calls the same client with the token does not '
        'deadlock', () async {
      final tokens = _Tokens();
      late final _Client client;
      final server = _Server(
        tokens,
        statusFor: (o) => o.path == '/refresh' ? 200 : null,
      );
      client = _Client(
        server,
        HttpClientConfig(
          auth: tokens.config(
            refresh: () async {
              tokens.refreshes++;
              await client.dio.get<dynamic>('/refresh');
              tokens.current = tokens.server;
              return true;
            },
          ),
        ),
      );

      final response = await client.dio
          .get<dynamic>('/x')
          .timeout(const Duration(seconds: 5));

      expect(response.statusCode, 200);
      expect(tokens.refreshes, 1);
    });

    test('a 401 from inside the refresh starts no nested refresh', () async {
      final tokens = _Tokens();
      late final _Client client;
      final server = _Server(tokens);
      client = _Client(
        server,
        HttpClientConfig(
          auth: tokens.config(
            refresh: () async {
              tokens.refreshes++;
              await client.dio.get<dynamic>('/refresh');
              return true;
            },
          ),
        ),
      );

      final error = await _failure(
        client.dio.get<dynamic>('/x').timeout(const Duration(seconds: 5)),
      );

      expect(error.response?.statusCode, 401);
      expect(tokens.refreshes, 1);
      expect(tokens.failures, 1);
    });
  });
}

/// An exception handler that records the status of every error it sees.
class _CountingHandler extends DefaultNetworkExceptionHandlerInterceptor {
  new(this.handled);

  final List<int?> handled;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handled.add(err.response?.statusCode);
    super.onError(err, handler);
  }
}
