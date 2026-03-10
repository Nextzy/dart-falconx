import 'package:dart_falconnect/lib.dart';

class SocketBoundResource<EntityType, ResponseType> {
  SocketBoundResource._();

  static const String TAG = 'SocketBoundResource';

  static Stream<Result<EntityType>>
      asStream<EntityType, ResponseType>({
    bool Function(EntityType? data)? whenSave,
    required Stream<ResponseType> Function()
        createCallStream,
    FutureOr<EntityType> Function(
      ResponseType result,
    )?
        processResponse,
    Future<void> Function(EntityType item)?
        saveCallResult,
    VoidErrorCallback? error,
    bool log = false,
  }) {
    assert(
      ResponseType == EntityType ||
          (!(ResponseType == EntityType) &&
              processResponse != null),
      'You need to specify the `processResponse` '
      'when the EntityType and ResponseType types '
      'are different',
    );

    // Start: inner function
    void onHandleException({
      required VoidErrorCallback? onError,
      required Object exception,
      required StackTrace? stackTrace,
      required EventSink<Result<EntityType>> sink,
    }) {
      try {
        onError?.call(exception, stackTrace);
        // Catches all exceptions including non-Exception types
        // from external callback code.
        // ignore: avoid_catches_without_on_clauses
      } catch (
        callbackException,
        callbackStackTrace
      ) {
        sink.add(
          Result.failure(
            callbackException.toException(
              stackTrace: callbackStackTrace,
            ),
          ),
        );
        return;
      }

      sink.add(
        Result.failure(
          exception.toException(
            stackTrace: stackTrace,
          ),
        ),
      );

      if (log) {
        // Intentional debug logging for socket operations.
        // ignore: avoid_print
        print('Operation failed $exception');
      }
    }
    // End: inner function

    return createCallStream().transform(
      StreamTransformer<ResponseType,
          Result<EntityType>>.fromHandlers(
        handleData: (response, sink) async {
          try {
            late EntityType data;
            if (processResponse != null) {
              final processedData =
                  await processResponse(response);
              data = processedData;
            } else {
              final castData =
                  response as EntityType;
              data = castData;
            }

            if ((whenSave?.call(data) ?? false) &&
                saveCallResult != null) {
              await saveCallResult(data);
              if (log) {
                // Intentional debug logging for socket operations.
                // ignore: avoid_print
                print('Success save result data');
              }
            }
            sink.add(Result.success(data));
          } on Exception catch (
            exception,
            stackTrace
          ) {
            onHandleException(
              onError: error,
              exception: exception,
              stackTrace: stackTrace,
              sink: sink,
            );
          }
        },
        handleError:
            (exception, stackTrace, sink) {
          onHandleException(
            onError: error,
            exception: exception,
            stackTrace: stackTrace,
            sink: sink,
          );
        },
        handleDone: (sink) {
          sink.close();
        },
      ),
    );
  }
}
