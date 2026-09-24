import 'dart:math';

import 'package:dart_falconnect/engine/https/config/cache_config.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/retry_attempts.dart';
import 'package:dart_faltool/dart_faltool.dart' show sha256;
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

const String _policyKey = 'dart_falconnect.cache.policy';
const String _forKey = 'dart_falconnect.cache.for';
const String _fallbackKey = 'dart_falconnect.cache.fallback';

/// Tells a response answered by [CacheInterceptor] apart from one fetched
/// from the network.
extension FalconCacheHitResponseExtensions on Response<dynamic> {
  /// Whether [CacheInterceptor] answered this response from its store,
  /// without a network round trip, or through [CacheInterceptor.fallback].
  bool get isCacheHit => extra[extraFromNetworkKey] == false;

  /// Whether [CacheInterceptor.fallback] answered this response after the
  /// request failed.
  bool get isCacheFallback => extra[_fallbackKey] == true;
}

/// Per-request cache settings on [RequestOptions].
extension FalconCacheRequestOptionsExtensions on RequestOptions {
  /// Policy for this request; null uses `CacheConfig.policy`, or
  /// [CachePolicy.forceCache] when [cacheFor] is set.
  CachePolicy? get cachePolicy => extra[_policyKey] as CachePolicy?;
  set cachePolicy(CachePolicy? value) => extra = {...extra, _policyKey: value};

  /// Caches this request's response for this long, whatever the server's
  /// headers say. Must be positive.
  Duration? get cacheFor => extra[_forKey] as Duration?;
  set cacheFor(Duration? value) =>
      extra = {...extra, _forKey: _checkCacheFor(value)};
}

/// Per-request cache settings on [Options].
extension FalconCacheOptionsExtensions on Options {
  /// Policy for this request; null uses `CacheConfig.policy`, or
  /// [CachePolicy.forceCache] when [cacheFor] is set.
  CachePolicy? get cachePolicy => extra?[_policyKey] as CachePolicy?;
  set cachePolicy(CachePolicy? value) => extra = {...?extra, _policyKey: value};

  /// Caches this request's response for this long, whatever the server's
  /// headers say. Must be positive.
  Duration? get cacheFor => extra?[_forKey] as Duration?;
  set cacheFor(Duration? value) =>
      extra = {...?extra, _forKey: _checkCacheFor(value)};
}

Duration? _checkCacheFor(Duration? value) {
  if (value != null && value <= Duration.zero) {
    throw ArgumentError.value(value, 'cacheFor', 'must be positive');
  }
  return value;
}

/// Caches `GET` responses on `dio_cache_interceptor`.
///
/// By default it follows the server's cache headers: it stores what a
/// response marks cacheable, answers from [store] while an entry is fresh,
/// and revalidates a stale entry with `If-None-Match` or
/// `If-Modified-Since`. A request can force caching with `cacheFor`.
///
/// A hit is a new [Response] decoded from stored bytes and bound to the
/// current request; it passes every response interceptor of the chain.
/// Entries are keyed by the URL and the headers of `CacheConfig.keyHeaders`.
/// A streamed request ([ResponseType.stream], as `Dio.download` sends) is
/// never stored or answered from the cache.
///
/// Place it before `ConcurrencyLimitInterceptor`, so a hit takes no slot,
/// and place [fallback] after `RetryInterceptor`.
class CacheInterceptor extends Interceptor {
  /// Creates a cache on [config]; with no `config.store`, entries live in a
  /// new `MemCacheStore` of `config.maxSize` bytes.
  ///
  /// Throws an [ArgumentError] when `config.maxSize` is not positive.
  new({this.config = const CacheConfig(), this.logPrint})
    : store = config.store ?? _memoryStore(config.maxSize);

  /// Policy, key, store, and offline settings.
  final CacheConfig config;

  /// Prints diagnostics; null prints nothing.
  final void Function(String message)? logPrint;

  /// The store entries live in.
  final CacheStore store;

  /// Answers failed `GET` requests from [store]; place it after
  /// `RetryInterceptor`, so it answers only after the last retry. It passes
  /// every error on unless `hitCacheOnNetworkFailure` or
  /// `hitCacheOnErrorCodes` is set.
  late final Interceptor fallback = _CacheFallback(this);

  late final DioCacheInterceptor _cache = DioCacheInterceptor(
    options: _options(policy: config.policy, maxStale: null),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isStream(options)) {
      handler.next(options);
      return;
    }
    // A lookup carries no maxStale: the library would push an entry's
    // deletion back on every hit, and an entry must expire on time.
    // A new map: the library writes into extra, which may be unmodifiable.
    options.extra = {
      ...options.extra,
      extraKey: _requestOptions(options, save: false),
    };
    _cache.onRequest(
      options,
      _RevalidatingHandler(
        handler,
        hadConditions: _hasConditions(options),
        onHit: () => _log('Hit for ${_describe(options)}'),
      ),
    );
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    if (_isStream(options)) {
      handler.next(response);
      return;
    }
    options.extra = {
      ...options.extra,
      extraKey: _requestOptions(options, save: true),
    };
    _cache.onResponse(response, handler);
  }

  // The library resolves inside onError, which skips every later error
  // interceptor; the fallback and 304 revalidation live elsewhere.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) =>
      handler.next(err);

  /// Deletes every entry of [store].
  Future<void> clearCache() => store.clean();

  CacheOptions _options({
    required CachePolicy policy,
    required Duration? maxStale,
  }) => CacheOptions(
    store: store,
    policy: policy,
    maxStale: maxStale,
    keyBuilder: _key,
  );

  /// The library options of one request. Only a save carries maxStale, which
  /// the library stamps on the entry it stores.
  CacheOptions _requestOptions(RequestOptions options, {required bool save}) {
    final cacheFor = options.cacheFor;
    return _options(
      policy:
          options.cachePolicy ??
          (cacheFor != null ? CachePolicy.forceCache : config.policy),
      maxStale: save ? cacheFor ?? config.maxStale : null,
    );
  }

  /// The store key: a digest of the URL and the listed headers the request
  /// carries, so header values such as tokens never sit in a key.
  String _key({required Uri url, Map<String, String>? headers, Object? body}) {
    final values = {
      for (final MapEntry(:key, :value) in (headers ?? const {}).entries)
        key.toLowerCase(): value,
    };
    final names = [for (final name in config.keyHeaders) name.toLowerCase()]
      ..sort();
    final input = StringBuffer('$url');
    for (final name in names) {
      final value = values[name];
      if (value != null) input.write('\n$name: $value');
    }
    return sha256.string(input.toString()).hex();
  }

  /// Answers [err] from [store], or returns null to pass it on.
  Future<Response<dynamic>?> _fallbackFor(DioException err) async {
    final options = err.requestOptions;
    if (err.type == DioExceptionType.cancel ||
        options.method.toUpperCase() != 'GET') {
      return null;
    }
    final status = err.response?.statusCode;
    final allowed = status == null
        ? config.hitCacheOnNetworkFailure
        : config.hitCacheOnErrorCodes.contains(status);
    if (!allowed) return null;
    try {
      final headers = Map<String, String>.of(options.getFlattenHeaders())
        ..removeWhere((name, _) => conditionalRequestHeaders.contains(name));
      final entry = await store.get(_key(url: options.uri, headers: headers));
      if (entry == null || entry.isStaled()) return null;
      final full = await entry.readContent(
        _options(policy: config.policy, maxStale: null),
        readHeaders: true,
        readBody: true,
      );
      final response = full.toResponse(options);
      response.extra[_fallbackKey] = true;
      _log(
        'Answered ${_describe(options)} from the cache after '
        '${status ?? err.type.name}',
      );
      return response;
      // A broken store must not replace the request's own error.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  /// The library's default per-entry limit. The memory store also needs an
  /// entry limit of at most a fifth of its total size.
  static const int _maxEntrySize = 512000;

  static MemCacheStore _memoryStore(int maxSize) {
    if (maxSize <= 0) {
      throw ArgumentError.value(maxSize, 'maxSize', 'must be positive');
    }
    return MemCacheStore(
      maxSize: maxSize,
      maxEntrySize: min(_maxEntrySize, maxSize ~/ 5),
    );
  }

  // The query may hold a secret, so diagnostics never print it.
  static String _describe(RequestOptions options) =>
      '${options.method} ${options.uri.host}${options.uri.path}';

  // The library can neither store nor serve a stream, and fails the request
  // when it tries, so a streamed request passes untouched.
  static bool _isStream(RequestOptions options) =>
      options.responseType == ResponseType.stream;

  static bool _hasConditions(RequestOptions options) =>
      conditionalRequestHeaders.any(options.headers.containsKey);

  void _log(String message) => logPrint?.call('[CacheInterceptor] $message');
}

/// Forwards to the real handler. A request the library made conditional
/// accepts `304`, so revalidation stays on the response path, where every
/// interceptor, `ConcurrencyLimitInterceptor` included, sees a response.
class _RevalidatingHandler extends RequestInterceptorHandler {
  new(this._handler, {required this.hadConditions, required this.onHit});

  final RequestInterceptorHandler _handler;

  /// Whether the app itself made the request conditional.
  final bool hadConditions;
  final void Function() onHit;

  @override
  void next(RequestOptions requestOptions) {
    if (!hadConditions && CacheInterceptor._hasConditions(requestOptions)) {
      final accept = requestOptions.validateStatus;
      requestOptions.validateStatus = (status) =>
          status == 304 || accept(status);
    }
    _handler.next(requestOptions);
  }

  @override
  void resolve(
    Response<dynamic> response, [
    bool callFollowingResponseInterceptor = false,
  ]) {
    onHit();
    _handler.resolve(response, callFollowingResponseInterceptor);
  }

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) => _handler.reject(error, callFollowingErrorInterceptor);
}

/// The offline fallback of [CacheInterceptor.fallback].
class _CacheFallback extends Interceptor {
  new(this._cache);

  final CacheInterceptor _cache;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // A retry attempt's error passes here inside the retry loop; only the
    // error the loop passes on after its last attempt may fall back.
    if (isOpenRetryAttempt(err.requestOptions)) return handler.next(err);
    final response = await _cache._fallbackFor(err);
    if (response == null) return handler.next(err);
    handler.resolve(response);
  }
}
