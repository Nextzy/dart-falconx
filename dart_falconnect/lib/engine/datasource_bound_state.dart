import 'package:dart_falconnect/lib.dart';

/// Utility class providing static repository-pattern helpers that convert
/// asynchronous local and remote operations into typed [Result] streams.
class DatasourceBoundState<T, ResponseType> {
  DatasourceBoundState._();

  /// Tag used for debug-logging identification.
  static const String TAG = 'DatasourceBoundState';

  /// Converts a local database operation into a Stream that handles
  /// local data fetching only.
  /// Returns a Stream of `Result<DataType>` to handle success and
  /// exception cases.
  ///
  /// This is a local-only version focused solely on database operations,
  /// without any remote API calls.
  ///
  /// Parameters:
  /// * [loadFromDbFuture] - Required function to load data from local
  ///   database. Returns `Future<DataType>`.
  ///
  /// * [handleError] - Optional custom error handler.
  ///   Takes (error, stackTrace) and returns custom Exception.
  ///   If not provided, default Exception will be used.
  ///
  /// Flow:
  /// 1. Executes [loadFromDbFuture] to fetch local data
  /// 2. Emits local data as `Result.Right<DataType>`
  ///
  /// Error Handling:
  /// - All database errors are wrapped in `Result.Left<Exception>`
  /// - Custom error handling can be implemented via [handleError]
  /// - Default Exception includes error message, exception, and
  ///   stack trace
  ///
  /// Example:
  /// ```dart
  /// final stream = NetworkBoundResource.asLocalStream<DomainModel>(
  ///   loadFromDbFuture: () => database.loadData(),
  ///   handleError: (error, stackTrace) => DatabaseException(error),
  /// );
  /// ```
  static Stream<Result<DsType>> asLocalResultStream<DsType>({
    required Future<DsType> Function() loadFromDbFuture,
    CommonException Function(
      CommonException error,
      StackTrace? stacktrace,
    )?
    handleError,
    bool log = false,
  }) async* {
    try {
      final dataFromDb = await loadFromDbFuture();
      if (log) {
        // Intentional debug logging for datasource operations.
        // ignore: avoid_print
        print('Success load data from database');
      }
      yield Result.success(dataFromDb);
      return;
      // Catches all exceptions including non-Exception types
      // from external code.
      // ignore: avoid_catches_without_on_clauses
    } catch (exception, stackTrace) {
      if (log) {
        // Intentional debug logging for datasource operations.
        // ignore: avoid_print
        print('Load from DB failed: $exception');
      }
      final commonException = exception.toException(stackTrace: stackTrace);
      yield Result.failure(
        handleError?.call(commonException, stackTrace) ?? commonException,
      );
      return;
    }
  }

  /// Convenience wrapper around [asLocalResultStream] that returns the first
  /// emitted [Result] as a [Future].
  ///
  /// Parameters mirror [asLocalResultStream]: [loadFromDbFuture] is required,
  /// [handleError] and [log] are optional.
  static Future<Result<DsType>> asLocalResultFuture<DsType>({
    required Future<DsType> Function() loadFromDbFuture,
    CommonException Function(
      CommonException error,
      StackTrace? stacktrace,
    )?
    handleError,
    bool log = false,
  }) => asLocalResultStream(
    loadFromDbFuture: loadFromDbFuture,
    handleError: handleError,
    log: log,
  ).first;

  /// Converts a remote API call into a Stream that handles remote
  /// operations only.
  /// Returns a Stream of `Result<DataType>` to handle success and
  /// exception cases.
  ///
  /// This is a simplified version of asStream() that only handles
  /// remote data fetching, without local database operations.
  ///
  /// Parameters:
  /// * [callRemoteFuture] - Required function to fetch data from
  ///   remote source. Returns `Future<ResponseType>`.
  ///
  /// * [processResponse] - Required when ResponseType differs from
  ///   DataType. Converts ResponseType to DataType.
  ///   If not provided, ResponseType must be the same as DataType
  ///   for direct casting.
  ///
  /// * [handleError] - Optional custom error handler.
  ///   Takes (error, stackTrace) and returns custom Exception.
  ///   If not provided, default Exception will be used.
  ///
  /// Flow:
  /// 1. Executes [callRemoteFuture] to fetch remote data
  /// 2. If [processResponse] exists, converts ResponseType to
  ///    DataType
  /// 3. If no [processResponse], attempts direct cast from
  ///    ResponseType to DataType
  /// 4. Emits processed data as `Result.Right<DataType>`
  ///
  /// Error Handling:
  /// - All errors are wrapped in `Result.Left<Exception>`
  /// - Custom error handling can be implemented via [handleError]
  /// - Default Exception includes error message, exception, and
  ///   stack trace
  ///
  /// Example:
  /// ```dart
  /// final stream =
  ///     NetworkBoundResource.asRemoteStream<ApiResponse, DomainModel>(
  ///   createCallFuture: () => api.fetchData(),
  ///   processResponse: (response) => response.toDomainModel(),
  ///   handleError: (error, stackTrace) => CustomException(error),
  /// );
  /// ```
  static Stream<Result<DsType>> asRemoteResultStream<ResponseType, DsType>({
    required Future<ResponseType> Function() callRemoteFuture,
    FutureOr<DsType> Function(ResponseType response)? processResponse,
    CommonException Function(
      CommonException error,
      StackTrace? stacktrace,
    )?
    handleError,
    bool log = false,
  }) async* {
    assert(
      ResponseType == DsType ||
          (!(ResponseType == DsType) && processResponse != null),
      'You need to specify the `processResponse` when the '
      'DataType and ResponseType types are different',
    );
    try {
      final response = await callRemoteFuture();
      if (log) {
        // Intentional debug logging for datasource operations.
        // ignore: avoid_print
        print('Success fetch data');
      }

      late DsType data;
      if (processResponse != null) {
        final processedData = await processResponse(response);
        data = processedData;
      } else {
        final castData = response as DsType;
        data = castData;
      }

      yield Result.success(data);
      return;
      // Catches all exceptions including non-Exception types
      // from external code.
      // ignore: avoid_catches_without_on_clauses
    } catch (exception, stackTrace) {
      if (log) {
        // Intentional debug logging for datasource operations.
        // ignore: avoid_print
        print('Fetching failed: $exception');
      }
      final commonException = exception.toException(stackTrace: stackTrace);
      yield Result.failure(
        handleError?.call(commonException, stackTrace) ?? commonException,
      );
      return;
    }
  }

  /// Convenience wrapper around [asRemoteResultStream] that returns the first
  /// emitted [Result] as a [Future].
  ///
  /// Parameters mirror [asRemoteResultStream]: [createCallFuture] is required;
  /// `processResponse` is required when `ResponseType` differs from `DsType`;
  /// [handleError] is optional.
  static Future<Result<DsType>> asRemoteResultFuture<ResponseType, DsType>({
    required Future<ResponseType> Function() createCallFuture,
    FutureOr<DsType> Function(ResponseType response)? processResponse,
    CommonException Function(
      CommonException error,
      StackTrace? stacktrace,
    )?
    handleError,
  }) => asRemoteResultStream(
    callRemoteFuture: createCallFuture,
    processResponse: processResponse,
    handleError: handleError,
  ).first;

  /// Converts asynchronous operations into a Stream that handles
  /// both local database and remote API operations.
  /// Returns a Stream of `Result<DataType>` to handle success and
  /// exception cases.
  ///
  /// This method implements a Repository Pattern with offline-first
  /// capability and provides a structured flow for data operations.
  ///
  /// Parameters:
  /// * [loadFromDbFuture] - Optional function to load data from
  ///   local database. Returns `Future<DataType>`.
  ///
  /// * [shouldFetch] - Optional function to determine if remote
  ///   fetch is needed. Takes current local data as parameter and
  ///   returns bool. If true, remote fetch will be executed even if
  ///   local data exists.
  ///
  /// * [callRemoteFuture] - Optional function to fetch data from
  ///   remote source. Returns `Future<ResponseType>`.
  ///
  /// * [processResponse] - Required when ResponseType differs from
  ///   DataType. Converts ResponseType to DataType.
  ///
  /// * [handleError] - Optional custom error handler.
  ///   Takes (error, stackTrace) and returns custom Exception.
  ///   If not provided, default Exception will be used.
  ///
  /// Flow:
  /// 1. If [loadFromDbFuture] exists:
  ///    - Loads local data first
  ///    - Emits local data if successful
  ///    - If [shouldFetch] returns true, proceeds to fetch remote
  ///      data
  ///
  /// 2. If [callRemoteFuture] exists:
  ///    - Fetches remote data
  ///    - Processes response using [processResponse] if provided
  ///    - Emits processed data
  ///
  /// Error Handling:
  /// - All errors are wrapped in `Result.Left<Exception>`
  /// - Custom error handling can be implemented via [handleError]
  /// - Default Exception includes error message, exception, and
  ///   stack trace
  ///
  /// Example:
  /// ```dart
  /// final stream =
  ///     NetworkBoundResource.asStream<ApiResponse, DomainModel>(
  ///   loadFromDbFuture: () => database.loadData(),
  ///   shouldFetch: (data) => data == null || data.isStale,
  ///   createCallFuture: () => api.fetchData(),
  ///   saveCallResult: (response) => database.saveData(response),
  ///   processResponse: (response) => response.toDomainModel(),
  ///   handleError: (error, st) => CustomException(error),
  /// );
  /// ```
  static Stream<Result<DsType>> asResultStream<ResponseType, DsType>({
    Future<DsType> Function()? loadFromDbFuture,
    bool Function(DsType? data)? shouldFetch,
    Future<ResponseType> Function()? callRemoteFuture,
    FutureOr<DsType> Function(ResponseType response)? processResponse,
    CommonException Function(
      CommonException error,
      StackTrace? stacktrace,
    )?
    handleError,
    bool log = false,
  }) async* {
    assert(
      ResponseType == DsType ||
          (!(ResponseType == DsType) && processResponse != null),
      'You need to specify the `processResponse` when the '
      'DataType and ResponseType types are different',
    );

    ///================ INNER METHOD ================///
    Stream<Result<DsType>> fetchRemoteData() async* {
      if (callRemoteFuture != null) {
        try {
          final response = await callRemoteFuture();
          if (log) {
            // Intentional debug logging for datasource operations.
            // ignore: avoid_print
            print('Success fetch data');
          }

          late DsType data;
          if (processResponse != null) {
            final processedData = await processResponse(response);
            if (log) {
              // Intentional debug logging for datasource operations.
              // ignore: avoid_print
              print('Success process response data');
            }
            data = processedData;
          } else {
            final castData = response as DsType;
            data = castData;
          }
          yield Result.success(data);
          // Catches all exceptions including non-Exception types
          // from external code.
          // ignore: avoid_catches_without_on_clauses
        } catch (exception, stackTrace) {
          if (log) {
            // Intentional debug logging for datasource operations.
            // ignore: avoid_print
            print('Fetching failed: $exception');
          }
          final commonException = exception.toException(stackTrace: stackTrace);
          yield Result.failure(
            handleError?.call(commonException, stackTrace) ?? commonException,
          );
        }
      }
      return;
    }

    Future<DsType> loadDbData() async {
      try {
        return await loadFromDbFuture!.call();
      } on Exception catch (exception, stackTrace) {
        if (log) {
          // Intentional debug logging for datasource operations.
          // ignore: avoid_print
          print('Load from DB failed: $exception');
        }

        final commonException = exception.toException(stackTrace: stackTrace);
        throw handleError?.call(commonException, stackTrace) ?? commonException;
      }
    }

    ///================ END INNER ================///

    if (loadFromDbFuture != null && callRemoteFuture != null) {
      DsType dataFromDb;
      try {
        dataFromDb = await loadDbData();
        // Catches all exceptions including non-Exception types
        // from external code.
        // ignore: avoid_catches_without_on_clauses
      } catch (exception, stackTrace) {
        yield Result.failure(
          exception.toException(
            stackTrace: stackTrace,
          ),
        );
        return;
      }
      if (log) {
        // Intentional debug logging for datasource operations.
        // ignore: avoid_print
        print('Success load data from database');
      }

      if (shouldFetch != null && shouldFetch(dataFromDb)) {
        if (log) {
          // Intentional debug logging for datasource operations.
          // ignore: avoid_print
          print('Loading... data from network');
        }
        yield Result.success(dataFromDb);
        yield* fetchRemoteData();
        return;
      } else {
        if (log) {
          // Intentional debug logging for datasource operations.
          // ignore: avoid_print
          print('Fetching data its not necessary');
        }
        yield Result.success(dataFromDb);
        return;
      }
    } else if (loadFromDbFuture != null) {
      DsType dataFromDb;
      try {
        dataFromDb = await loadDbData();
        // Catches all exceptions including non-Exception types
        // from external code.
        // ignore: avoid_catches_without_on_clauses
      } catch (exception, stackTrace) {
        yield Result.failure(
          exception.toException(
            stackTrace: stackTrace,
          ),
        );
        return;
      }
      if (log) {
        // Intentional debug logging for datasource operations.
        // ignore: avoid_print
        print('Success load data from database');
      }
      yield Result.success(dataFromDb);
      return;
    } else if (callRemoteFuture != null) {
      if (log) {
        // Intentional debug logging for datasource operations.
        // ignore: avoid_print
        print('Loading... data from network');
      }
      yield* fetchRemoteData();
      return;
    } else {
      throw UnimplementedError(
        'Please implement loadFromDbFuture or createCallFuture',
      );
    }
  }
}
