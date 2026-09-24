import 'dart:async';

import 'package:dart_faltool/dart_faltool.dart' show visibleForTesting;
import 'package:dio/dio.dart';

final Expando<_CancelHub> _hubs = Expando<_CancelHub>('cancel watch hub');

/// Runs [onCancel] once if [token] cancels before the returned function is
/// called.
///
/// The token gets one `whenCancel` listener, however many watches exist,
/// and a finished watch leaves nothing behind. Listening to `whenCancel`
/// directly adds a listener per wait that can never be removed. A watch on
/// a token that is already cancelled runs in a microtask, unless it is
/// removed first.
void Function() watchCancel(
  CancelToken token,
  void Function(DioException error) onCancel,
) => (_hubs[token] ??= _CancelHub(token)).add(onCancel);

/// Watches on [token] that have neither run nor been removed.
@visibleForTesting
int activeCancelWatches(CancelToken token) =>
    _hubs[token]?._watches.length ?? 0;

class _CancelHub {
  new(this._token) {
    unawaited(_token.whenCancel.then(_fire));
  }

  final CancelToken _token;
  final Map<Object, void Function(DioException error)> _watches = {};
  bool _fired = false;

  void Function() add(void Function(DioException error) onCancel) {
    final key = Object();
    _watches[key] = onCancel;
    if (_fired) {
      scheduleMicrotask(() => _run(key, _token.cancelError!));
    }
    return () => _watches.remove(key);
  }

  void _fire(DioException error) {
    _fired = true;
    for (final key in _watches.keys.toList()) {
      try {
        _run(key, error);
      } on Object catch (thrown, stackTrace) {
        // One failing watch must not stop the others; the error still
        // reaches the zone, as an uncaught error would.
        Zone.current.handleUncaughtError(thrown, stackTrace);
      }
    }
  }

  void _run(Object key, DioException error) {
    _watches.remove(key)?.call(error);
  }
}
