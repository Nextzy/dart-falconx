import 'dart:async';

import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/src/engine/https/cancel_watch.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/host_key.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/retry_after_pause.dart'
    show localRateLimitRejection;
import 'package:dart_faltool/dart_faltool.dart'
    show Bulkhead, BulkheadRejectedException, immutable;
import 'package:dio/dio.dart';

/// Activity counters of a [ConcurrencyLimitInterceptor].
@immutable
class ConcurrencyLimitStatistics {
  /// Creates a statistics snapshot.
  const new({
    required this.forwarded,
    required this.rejected,
    required this.activeByHost,
    required this.waitingByHost,
    required this.globalActive,
    required this.globalWaiting,
  });

  /// Requests passed to the next handler since construction, retry
  /// attempts included.
  final int forwarded;

  /// Requests rejected with a local 429 because a queue was full.
  final int rejected;

  /// Slots held in each host's own limit, keyed by host. Only hosts with a
  /// request in flight or queued appear.
  final Map<String, int> activeByHost;

  /// Requests queued for each host's own limit, keyed by host.
  final Map<String, int> waitingByHost;

  /// Slots held in the global limit; 0 without one.
  final int globalActive;

  /// Requests queued for the global limit; 0 without one.
  final int globalWaiting;
}

/// Limits how many requests are in flight at once, per host and for all
/// hosts together, with `resilience` `Bulkhead`s.
///
/// A request takes a slot in `onRequest` and gives it back when its
/// response or error passes this interceptor, or when its `CancelToken`
/// cancels. A host's limit comes from `hosts[host]` when that key exists,
/// otherwise from `perHost`; a null value means no host limit. Every
/// request to a limited host also takes a `global` slot when `global` is
/// set. A request to a host with neither limit is forwarded synchronously.
///
/// When no slot is free, a request waits in a FIFO queue of at most
/// `maxQueueSize` per host and `maxGlobalQueueSize` globally, or fails at
/// once when `queueRequests` is false. A full queue fails the request with
/// a local 429 that answers `isLocalRateLimit`, carries a
/// `BulkheadRejectedException` as its error, and has no `Retry-After`.
/// There is no limit on the time spent in a queue; pass a `CancelToken`
/// with a deadline to bound it. A cancelled request keeps its queue place
/// until it reaches the head of the queue, so it still counts toward the
/// queue size until then.
///
/// A retry attempt or a re-send that carries the `RequestOptions.extra` of
/// a request still holding a slot reuses that slot, so a retry never waits
/// for its own earlier attempt.
///
/// Place it after `CacheInterceptor` and any interceptor that answers in
/// `onRequest`: a request answered after this interceptor without calling
/// the response or error interceptors keeps its slot forever. Place it
/// before the rate limiter, so the slot is taken before the tokens, before
/// `RetryInterceptor`, and before the network exception handler, which
/// stops the error chain. A request holds its slot while the rate limiter
/// holds it, so set `perHost` below `global` to keep one slow or paused
/// host from taking every global slot.
///
/// A request that never ends holds its slot: keep dio's connect and
/// receive timeouts set. A `ResponseType.stream` response gives its slot
/// back when its headers arrive, before its body is read. On a server,
/// build one interceptor per process; each process, isolate, or instance
/// counts only its own requests.
class ConcurrencyLimitInterceptor extends Interceptor {
  /// Creates a concurrency limit interceptor.
  ///
  /// Each key of [hosts] must be a bare host exactly as `Uri.host` returns
  /// it: lowercase, with no port, brackets, or spaces. Every limit that is
  /// set must be at least 1; queue sizes must not be negative.
  new({
    required this.config,
    this.global,
    this.perHost,
    Map<String, int?> hosts = const {},
    this.queueRequests = true,
    this.maxQueueSize = 50,
    this.maxGlobalQueueSize = 500,
  }) : _hosts = _validated(
         global: global,
         perHost: perHost,
         hosts: hosts,
         maxQueueSize: maxQueueSize,
         maxGlobalQueueSize: maxGlobalQueueSize,
       ),
       _globalBulkhead = global == null
           ? null
           : Bulkhead(
               maxConcurrent: global,
               maxQueued: queueRequests ? maxGlobalQueueSize : 0,
             );

  /// Configuration; `enableLogging` gates diagnostic prints.
  final HttpClientConfig config;

  /// Most requests in flight to all hosts together; null means no limit.
  final int? global;

  /// Most requests in flight to a host missing from `hosts`; null means no
  /// limit.
  final int? perHost;

  /// Whether a request with no free slot waits (`true`) or is rejected.
  final bool queueRequests;

  /// Queue capacity of each host limit.
  final int maxQueueSize;

  /// Queue capacity of the global limit.
  final int maxGlobalQueueSize;

  /// Gives every instance its own `extra` key, so two instances in one
  /// chain never overwrite each other's permit.
  static int _instances = 0;

  /// Key in `RequestOptions.extra` that holds this instance's permit.
  final String _permitKey =
      'dart_falconnect.concurrency.permit.${_instances++}';

  final Map<String, int?> _hosts;
  final Bulkhead? _globalBulkhead;
  final Map<String, _HostSlots> _hostSlots = {};
  final Set<_Permit> _waiting = {};
  int _forwarded = 0;
  int _rejected = 0;
  bool _disposed = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final host = options.uri.host;
    final hostLimit = _hosts.containsKey(host) ? _hosts[host] : perHost;
    if (hostLimit == null && _globalBulkhead == null) {
      _forwarded++;
      handler.next(options);
      return;
    }
    if (_disposed) {
      handler.reject(
        _cancelled(
          options,
          StateError('ConcurrencyLimitInterceptor disposed'),
          'Concurrency limiter disposed',
        ),
      );
      return;
    }
    if (_permitOf(options)?.isHeld ?? false) {
      // A retry attempt or re-send of a request that still holds its slot.
      _forwarded++;
      handler.next(options);
      return;
    }
    final cancelToken = options.cancelToken;
    if (cancelToken != null && cancelToken.isCancelled) {
      handler.reject(
        _cancelled(options, cancelToken.cancelError, 'Request cancelled'),
      );
      return;
    }
    final permit = _Permit();
    options.extra = {...options.extra, _permitKey: permit};
    if (cancelToken != null) {
      permit.unwatch = watchCancel(cancelToken, permit.release);
    }
    _waiting.add(permit);
    final slots = hostLimit == null
        ? null
        : _hostSlots.putIfAbsent(
            host,
            () => _HostSlots(_hostBulkhead(hostLimit), _globalBulkhead),
          );
    final taking = slots?.take(permit) ?? _globalBulkhead!.execute(permit.hold);
    unawaited(
      taking
          .then<void>((_) {}, onError: permit.reject)
          .whenComplete(() => _prune(host, slots)),
    );
    try {
      await permit.granted;
    } on BulkheadRejectedException catch (error) {
      _waiting.remove(permit);
      _rejected++;
      _log('Concurrency queue full for $host');
      handler.reject(localRateLimitRejection(options, error: error), true);
      return;
    } on Object catch (error) {
      // Cancelled, or disposed, while waiting for a slot.
      _waiting.remove(permit);
      handler.reject(_cancelled(options, error, 'Request cancelled'));
      return;
    }
    _waiting.remove(permit);
    _forwarded++;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _permitOf(response.requestOptions)?.release();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _permitOf(err.requestOptions)?.release();
    handler.next(err);
  }

  /// Returns the current activity counters.
  ConcurrencyLimitStatistics getStatistics() => ConcurrencyLimitStatistics(
    forwarded: _forwarded,
    rejected: _rejected,
    activeByHost: Map.unmodifiable({
      for (final entry in _hostSlots.entries)
        entry.key: entry.value.bulkhead.activeCount,
    }),
    waitingByHost: Map.unmodifiable({
      for (final entry in _hostSlots.entries)
        entry.key: entry.value.bulkhead.queueLength,
    }),
    globalActive: _globalBulkhead?.activeCount ?? 0,
    globalWaiting: _globalBulkhead?.queueLength ?? 0,
  );

  /// Cancels every request waiting for a slot.
  ///
  /// Requests in flight keep their slots and give them back when they end.
  /// Afterwards, requests to a limited host are cancelled, retry attempts
  /// included, and requests to an unlimited host pass. Calling it again has
  /// no effect.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final disposed = StateError('ConcurrencyLimitInterceptor disposed');
    for (final permit in _waiting.toList()) {
      permit.release(disposed);
    }
    _waiting.clear();
  }

  static Map<String, int?> _validated({
    required int? global,
    required int? perHost,
    required Map<String, int?> hosts,
    required int maxQueueSize,
    required int maxGlobalQueueSize,
  }) {
    void checkLimit(int? limit, String name) {
      if (limit != null && limit < 1) {
        throw ArgumentError.value(limit, name, 'must be at least 1 or null');
      }
    }

    void checkQueue(int size, String name) {
      if (size < 0) {
        throw ArgumentError.value(size, name, 'must not be negative');
      }
    }

    checkLimit(global, 'global');
    checkLimit(perHost, 'perHost');
    checkQueue(maxQueueSize, 'maxQueueSize');
    checkQueue(maxGlobalQueueSize, 'maxGlobalQueueSize');
    for (final entry in hosts.entries) {
      if (!isHostKey(entry.key)) {
        throw ArgumentError.value(
          entry.key,
          'hosts',
          'keys must be bare lowercase hosts, as Uri.host returns them',
        );
      }
      checkLimit(entry.value, 'hosts');
    }
    return Map.unmodifiable(hosts);
  }

  Bulkhead _hostBulkhead(int limit) => Bulkhead(
    maxConcurrent: limit,
    maxQueued: queueRequests ? maxQueueSize : 0,
  );

  _Permit? _permitOf(RequestOptions options) {
    final permit = options.extra[_permitKey];
    return permit is _Permit ? permit : null;
  }

  /// Forgets an idle host limit; an empty `Bulkhead` is the same as a new
  /// one, so the next request to the host builds a fresh one.
  void _prune(String host, _HostSlots? slots) {
    if (slots != null &&
        slots.bulkhead.activeCount == 0 &&
        slots.bulkhead.queueLength == 0 &&
        identical(_hostSlots[host], slots)) {
      _hostSlots.remove(host);
    }
  }

  DioException _cancelled(
    RequestOptions options,
    Object? error,
    String message,
  ) => DioException(
    requestOptions: options,
    type: DioExceptionType.cancel,
    error: error,
    message: message,
  );

  void _log(String message) {
    if (config.enableLogging) {
      // Intentional logging for concurrency limit diagnostics.
      // ignore: avoid_print
      print('[ConcurrencyLimitInterceptor] $message');
    }
  }
}

/// A host's own limit, taken before the global one.
class _HostSlots {
  new(this.bulkhead, this._global);

  final Bulkhead bulkhead;
  final Bulkhead? _global;

  /// Takes the host slot, then the global slot. A permit abandoned while it
  /// waited for the host slot gives that slot back before it would join the
  /// global queue.
  Future<void> take(_Permit permit) => bulkhead.execute(() {
    final global = _global;
    return global == null || !permit.isWaiting
        ? permit.hold()
        : global.execute(permit.hold);
  });
}

enum _PermitState { waiting, held, abandoned, released }

/// One logical request's claim on a slot, kept in `RequestOptions.extra`.
class _Permit {
  final Completer<void> _granted = Completer<void>();
  final Completer<void> _released = Completer<void>();
  _PermitState _state = _PermitState.waiting;

  /// Removes the `CancelToken` watch; set when the request has a token.
  void Function()? unwatch;

  bool get isHeld => _state == _PermitState.held;

  bool get isWaiting => _state == _PermitState.waiting;

  /// Completes when every slot is taken; fails when the queue is full, or
  /// when the request is cancelled or disposed while it waits.
  Future<void> get granted => _granted.future;

  /// The innermost slot action: holds every slot until [release].
  Future<void> hold() {
    if (_state == _PermitState.abandoned) {
      // Cancelled while waiting: pass the slot straight on.
      _state = _PermitState.released;
      return Future<void>.value();
    }
    _state = _PermitState.held;
    _granted.complete();
    return _released.future;
  }

  /// Fails a permit a full queue rejected before granting it.
  void reject(Object error, StackTrace stackTrace) {
    if (_state == _PermitState.waiting) {
      _state = _PermitState.released;
      unwatch?.call();
      _granted.completeError(error, stackTrace);
    }
  }

  /// Gives the slot back, or abandons the wait; later calls do nothing.
  void release([Object? reason]) {
    switch (_state) {
      case _PermitState.waiting:
        _state = _PermitState.abandoned;
        unwatch?.call();
        _granted.completeError(reason ?? StateError('Request cancelled'));
      case _PermitState.held:
        _state = _PermitState.released;
        unwatch?.call();
        _released.complete();
      case _PermitState.abandoned:
      case _PermitState.released:
        return;
    }
  }

  @override
  String toString() => 'ConcurrencyPermit(${_state.name})';
}
