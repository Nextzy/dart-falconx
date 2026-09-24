import 'package:dart_falconnect/lib.dart';

/// Base class of every HTTP client in FalconX: one [Dio] configured by one
/// [HttpClientConfig].
///
/// The client orders the interceptor chain itself: the config's own
/// `interceptors`, then log, cache, concurrency limit, rate limit, retry,
/// the cache's offline fallback when its box enables it, and the exception
/// handler last. [configure] applies a new
/// configuration to requests that start after it returns; requests already
/// running finish on the configuration they started with. Interceptors
/// whose box is unchanged are kept, with their state.
///
/// A subclass passes its configuration to the super constructor. An
/// interceptor that needs [dio] is built in the subclass constructor body,
/// which then calls [configure].
abstract class BaseHttpClient implements RequestApiService {
  /// Creates a client on [dio] and applies [config].
  ///
  /// [config] owns the base URL, timeouts, content type, redirects,
  /// `validateStatus`, and its header keys, so values set on [dio] for
  /// those are replaced; the adapter and every other option stay.
  new({required Dio dio, HttpClientConfig config = const HttpClientConfig()})
    : _dio = dio,
      _defaultValidateStatus = BaseOptions().validateStatus {
    configure(config);
  }

  final Dio _dio;
  final ValidateStatus _defaultValidateStatus;
  final NetworkExceptionHandlerInterceptor _defaultExceptionHandler =
      DefaultNetworkExceptionHandlerInterceptor();

  HttpClientConfig? _config;
  Interceptor? _log;
  CacheInterceptor? _cache;
  ConcurrencyLimitInterceptor? _concurrency;
  Interceptor? _rateLimit;
  RetryInterceptor? _retry;

  /// The underlying Dio instance, for Retrofit and advanced use.
  Dio get dio => _dio;

  /// The base URL new requests use.
  String get baseUrl => _dio.options.baseUrl;

  /// The Dio base options.
  BaseOptions get options => _dio.options;

  /// The current interceptor chain. Add interceptors through
  /// [addInterceptors] or the config: [configure] rebuilds this list.
  Interceptors get interceptors => _dio.interceptors;

  /// The configuration new requests use.
  HttpClientConfig get currentConfig => _config!;

  /// Applies [config] to requests that start after this call returns.
  ///
  /// Throws, and keeps the current configuration, when an interceptor
  /// cannot be built from [config] or dio rejects one of its options.
  void configure(HttpClientConfig config) {
    // A dry run on a scratch Dio: dio checks options in its setters, so a
    // value it rejects throws here, before this client changes.
    config.applyTo(Dio());
    final previous = _config;
    final log = _keepOrBuild(previous?.log, config.log, _log, _buildLog);
    final cache = _keepOrBuild(
      previous?.cache,
      config.cache,
      _cache,
      (box) => CacheInterceptor(
        config: _keepStore(box, previous?.cache),
        logPrint: _diagnostic,
      ),
    );
    final cacheFallback = cache != null && _hasFallback(cache.config)
        ? cache.fallback
        : null;
    final concurrency = _keepOrBuild(
      previous?.concurrency,
      config.concurrency,
      _concurrency,
      (box) => ConcurrencyLimitInterceptor(config: box, logPrint: _diagnostic),
    );
    final rateLimit =
        _rateLimit != null && previous?.rateLimit == config.rateLimit
        ? _rateLimit
        : _buildRateLimit(config.rateLimit);
    final retry = _keepOrBuild(
      previous?.retry,
      config.retry,
      _retry,
      (box) => RetryInterceptor(config: box, dio: _dio, logPrint: _diagnostic),
    );

    _applyOptions(previous, config);
    _dio.interceptors
      ..clear()
      ..addAll([
        ...config.interceptors,
        ?log,
        ?cache,
        ?concurrency,
        ?rateLimit,
        ?retry,
        ?cacheFallback,
        config.exceptionHandler ?? _defaultExceptionHandler,
      ]);
    _config = config;
    _log = log;
    _cache = cache;
    _concurrency = concurrency;
    _rateLimit = rateLimit;
    _retry = retry;
  }

  /// Sets the base URL of the current configuration.
  void setupBaseUrl(String baseUrl) {
    configure(currentConfig.copyWith(baseUrl: baseUrl));
  }

  /// Adds [interceptors] to the custom slot of the current configuration,
  /// so they run first and survive later [configure] calls.
  void addInterceptors(Iterable<Interceptor> interceptors) {
    configure(
      currentConfig.copyWith(
        interceptors: [...currentConfig.interceptors, ...interceptors],
      ),
    );
  }

  /// Disposes the stateful interceptors of the current configuration.
  ///
  /// Needed at the end of a test or a CLI; a Flutter app never calls it.
  /// A later [configure] builds new limiters instead of keeping these.
  void dispose() {
    final rateLimit = _rateLimit;
    if (rateLimit is TokenBucketRateLimitInterceptor) {
      rateLimit.dispose();
    } else if (rateLimit is RetryAfterPauseInterceptor) {
      rateLimit.dispose();
    }
    _concurrency?.dispose();
    _rateLimit = null;
    _concurrency = null;
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'GET',
    path,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> post<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'POST',
    path,
    data: data?.toJson(),
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> postFormData<T>(
    String path, {
    FormData? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'POST',
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> patch<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'PATCH',
    path,
    data: data?.toJson(),
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> put<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'PUT',
    path,
    data: data?.toJson(),
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> putFormData<T>(
    String path, {
    FormData? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'PUT',
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  @override
  Future<Response<T>> delete<T>(
    String path, {
    BaseRequestBody? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool isUseToken = true,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) => _request(
    'DELETE',
    path,
    data: data?.toJson(),
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    isUseToken: isUseToken,
    converter: converter,
    catchError: catchError,
  );

  /// The one request path behind every public method.
  Future<Response<T>> _request<T>(
    String method,
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    required bool isUseToken,
    required JsonResponseConverter<T> converter,
    RequestErrorCallback<T>? catchError,
  }) {
    final requestOptions = (options ?? Options()).copyWith(method: method)
      ..useToken = isUseToken;
    return _dio
        .request<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: requestOptions,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        )
        .mapJson(converter)
        .catchWhenError(catchError);
  }

  /// [box], carrying the current cache's memory store when only settings
  /// that leave the stored entries valid changed since [before].
  CacheConfig _keepStore(CacheConfig box, CacheConfig? before) {
    final current = _cache;
    if (current == null ||
        before == null ||
        box.store != null ||
        before.store != null ||
        box.maxSize != before.maxSize) {
      return box;
    }
    return box.copyWith(store: current.store);
  }

  static bool _hasFallback(CacheConfig box) =>
      box.hitCacheOnNetworkFailure || box.hitCacheOnErrorCodes.isNotEmpty;

  /// Keeps [current] when its box did not change, else builds a new one.
  static I? _keepOrBuild<B extends Object, I extends Object>(
    B? before,
    B? after,
    I? current,
    I Function(B box) build,
  ) {
    if (after == null) return null;
    if (current != null && before == after) return current;
    return build(after);
  }

  Interceptor _buildLog(LogConfig box) => switch (box) {
    PrettyLogConfig() => _buildPrettyLog(box),
    JsonLogConfig() => HttpJsonLogInterceptor(config: box),
  };

  HttpLogInterceptor _buildPrettyLog(PrettyLogConfig box) {
    final log = HttpLogInterceptor(
      request: box.request,
      requestHeader: box.requestHeader,
      requestBody: box.requestBody,
      responseHeader: box.responseHeader,
      responseBody: box.responseBody,
      error: box.error,
      redactHeaders: box.redactHeaders,
      redactQueryParameters: box.redactQueryParameters,
    );
    final printer = box.logPrint;
    if (printer != null) log.logPrint = printer;
    return log;
  }

  Interceptor? _buildRateLimit(RateLimitConfig box) => switch (box) {
    NoRateLimitConfig() => null,
    PauseOnlyRateLimitConfig() => RetryAfterPauseInterceptor(
      config: box,
      logPrint: _diagnostic,
    ),
    TokenBucketRateLimitConfig() => TokenBucketRateLimitInterceptor(
      config: box,
      logPrint: _diagnostic,
    ),
  };

  /// Writes the options [next] owns and removes the header keys that
  /// [previous] set and [next] drops. Other fields and keys stay.
  void _applyOptions(HttpClientConfig? previous, HttpClientConfig next) {
    if (previous != null) {
      final kept = next.effectiveHeaders;
      for (final key in previous.effectiveHeaders.keys) {
        if (!kept.containsKey(key)) _dio.options.headers.remove(key);
      }
    }
    next.applyTo(_dio);
    _dio.options.validateStatus = next.validateStatus ?? _defaultValidateStatus;
  }

  /// Prints an interceptor diagnostic through the current log box, as a
  /// JSON line when the box is a [JsonLogConfig]. A printer that throws is
  /// ignored, so a diagnostic never fails a request.
  void _diagnostic(String message) {
    final log = _config?.log;
    if (log == null || !log.diagnostics) return;
    final line = switch (log) {
      PrettyLogConfig() => message,
      JsonLogConfig() => jsonEncode({
        'timestamp': clock.now().toUtc().toIso8601String(),
        'severity_text': 'DEBUG',
        'body': message,
      }),
    };
    try {
      final printer = log.logPrint;
      if (printer != null) {
        printer(line);
      } else {
        // Diagnostics go to the console when the config sets no printer.
        // ignore: avoid_print
        print(line);
      }
    } on Object {
      // A broken log sink must not turn a request into a failure.
    }
  }
}
