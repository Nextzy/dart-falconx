import 'package:dart_falconnect/lib.dart';

class DatasourceBoundState<DataType, ResponseType> {
  DatasourceBoundState._();

  static const String TAG = 'DatasourceBoundState';

  /// Converts a local database operation into a Stream that handles local data
  /// fetching only.
  /// Returns a Stream of Either<Exception, DataType> to handle success and
  /// exception cases.
  ///
  /// This is a local-only version focused solely on database operations,
  /// without any remote API calls.
  ///
  /// Parameters:
  /// * [loadFromDbFuture] - Required function to load data from local database.
  ///   Returns Future<DataType>.
  ///
  /// * [handleError] - Optional custom error handler.
  ///   Takes (error, stackTrace) and returns custom Exception.
  ///   If not provided, default Exception will be used.
  ///
  /// Flow:
  /// 1. Executes [loadFromDbFuture] to fetch local data
  /// 2. Emits local data as Either.Right<DataType>
  ///
  /// Error Handling:
  /// - All database errors are wrapped in Either.Left<Exception>
  /// - Custom error handling can be implemented via [handleError]
  /// - Default Exception includes error message, exception, and stack trace
  ///
  /// Example:
  /// ```dart
  /// final stream = NetworkBoundResource.asLocalStream<DomainModel>(
  ///   loadFromDbFuture: () => database.loadData(),
  ///   handleError: (error, stackTrace) => DatabaseException(error),
  /// );
  /// ```
  static Stream<Either<Exception, DataType>> asLocalStream<DataType>({
    required Future<DataType> Function() loadFromDbFuture,
    Exception Function(Object error, StackTrace? stacktrace)? handleError,
    bool log = false,
  }) async* {
    try {
      final dataFromDb = await loadFromDbFuture();
      if (log) print('Success load data from database');
      yield Right(dataFromDb);
      return;
    } on Exception catch (exception, stackTrace) {
      if (log) print('Load from DB failed: $exception');
      final tmpException = handleError?.call(exception, stackTrace);
      yield Left(tmpException ?? exception);
      return;
    }
  }

  static Future<Either<Exception, DataType>> asLocalFuture<DataType>({
    required Future<DataType> Function() loadFromDbFuture,
    Exception Function(Object error, StackTrace? stacktrace)? handleError,
    bool log = false,
  }) => asLocalStream(
    loadFromDbFuture: loadFromDbFuture,
    handleError: handleError,
    log: log,
  ).first;

  /// Converts a remote API call into a Stream that handles remote operations only.
  /// Returns a Stream of Either<Exception, DataType> to handle success and exception cases.
  ///
  /// This is a simplified version of asStream() that only handles remote data fetching,
  /// without local database operations.
  ///
  /// Parameters:
  /// * [callRemoteFuture] - Required function to fetch data from remote source.
  ///   Returns Future<ResponseType>.
  ///
  /// * [processResponse] - Required when ResponseType differs from DataType.
  ///   Converts ResponseType to DataType.
  ///   If not provided, ResponseType must be the same as DataType for direct casting.
  ///
  /// * [handleError] - Optional custom error handler.
  ///   Takes (error, stackTrace) and returns custom Exception.
  ///   If not provided, default Exception will be used.
  ///
  /// Flow:
  /// 1. Executes [callRemoteFuture] to fetch remote data
  /// 2. If [processResponse] exists, converts ResponseType to DataType
  /// 3. If no [processResponse], attempts direct cast from ResponseType to DataType
  /// 4. Emits processed data as Either.Right<DataType>
  ///
  /// Error Handling:
  /// - All errors are wrapped in Either.Left<Exception>
  /// - Custom error handling can be implemented via [handleError]
  /// - Default Exception includes error message, exception, and stack trace
  ///
  /// Example:
  /// ```dart
  /// final stream = NetworkBoundResource.asRemoteStream<ApiResponse, DomainModel>(
  ///   createCallFuture: () => api.fetchData(),
  ///   processResponse: (response) => response.toDomainModel(),
  ///   handleError: (error, stackTrace) => CustomException(error),
  /// );
  /// ```
  static Stream<Either<Exception, DataType>>
  asRemoteStream<ResponseType, DataType>({
    required Future<ResponseType> Function() callRemoteFuture,
    FutureOr<DataType> Function(ResponseType response)? processResponse,
    Exception Function(Object error, StackTrace? stacktrace)? handleError,
    bool log = false,
  }) async* {
    assert(
      ResponseType == DataType ||
          (!(ResponseType == DataType) && processResponse != null),
      'You need to specify the `processResponse` when the DataType and ResponseType types are different',
    );
    try {
      final response = await callRemoteFuture();
      if (log) print('Success fetch data');

      late DataType data;
      if (processResponse != null) {
        final processedData = await processResponse(response);
        data = processedData;
      } else {
        final castData = response as DataType;
        data = castData;
      }

      yield Right(data);
      return;
    } on Exception catch (exception, stackTrace) {
      if (log) print('Fetching failed: $exception');
      final tmpException = handleError?.call(exception, stackTrace);
      yield Left(tmpException ?? exception);
      return;
    }
  }

  static Future<Either<Exception, DataType>>
  asRemoteFuture<ResponseType, DataType>({
    required Future<ResponseType> Function() createCallFuture,
    FutureOr<DataType> Function(ResponseType response)? processResponse,
    Exception Function(Object error, StackTrace? stacktrace)? handleError,
  }) => asRemoteStream(
    callRemoteFuture: createCallFuture,
    processResponse: processResponse,
    handleError: handleError,
  ).first;

  /// Converts asynchronous operations into a Stream that handles both local database and remote API operations.
  /// Returns a Stream of Either<Exception, DataType> to handle success and exception cases.
  ///
  /// This method implements a Repository Pattern with offline-first capability and provides
  /// a structured flow for data operations.
  ///
  /// Parameters:
  /// * [loadFromDbFuture] - Optional function to load data from local database.
  ///   Returns Future<DataType>.
  ///
  /// * [shouldFetch] - Optional function to determine if remote fetch is needed.
  ///   Takes current local data as parameter and returns bool.
  ///   If true, remote fetch will be executed even if local data exists.
  ///
  /// * [callRemoteFuture] - Optional function to fetch data from remote source.
  ///   Returns Future<ResponseType>.
  ///
  /// * [processResponse] - Required when ResponseType differs from DataType.
  ///   Converts ResponseType to DataType.
  ///
  /// * [handleError] - Optional custom error handler.
  ///   Takes (error, stackTrace) and returns custom Exception.
  ///   If not provided, default Exception will be used.
  ///
  /// Flow:
  /// 1. If [loadFromDbFuture] exists:
  ///    - Loads local data first
  ///    - Emits local data if successful
  ///    - If [shouldFetch] returns true, proceeds to fetch remote data
  ///
  /// 2. If [callRemoteFuture] exists:
  ///    - Fetches remote data
  ///    - Processes response using [processResponse] if provided
  ///    - Emits processed data
  ///
  /// Error Handling:
  /// - All errors are wrapped in Either.Left<Exception>
  /// - Custom error handling can be implemented via [handleError]
  /// - Default Exception includes error message, exception, and stack trace
  ///
  /// Example:
  /// ```dart
  /// final stream = NetworkBoundResource.asStream<ApiResponse, DomainModel>(
  ///   loadFromDbFuture: () => database.loadData(),
  ///   shouldFetch: (data) => data == null || data.isStale,
  ///   createCallFuture: () => api.fetchData(),
  ///   saveCallResult: (response) => database.saveData(response),
  ///   processResponse: (response) => response.toDomainModel(),
  ///   handleError: (error, stackTrace) => CustomException(error),
  /// );
  /// ```
  static Stream<Either<Exception, DataType>> asStream<ResponseType, DataType>({
    Future<DataType> Function()? loadFromDbFuture,
    bool Function(DataType? data)? shouldFetch,
    Future<ResponseType> Function()? callRemoteFuture,
    FutureOr<DataType> Function(ResponseType response)? processResponse,
    Exception Function(Object error, StackTrace? stacktrace)? handleError,
    bool log = false,
  }) async* {
    assert(
      ResponseType == DataType ||
          (!(ResponseType == DataType) && processResponse != null),
      'You need to specify the `processResponse` when the DataType and ResponseType types are different',
    );

    ///========================= INNER METHOD =========================///
    Stream<Either<Exception, DataType>> fetchRemoteData() async* {
      if (callRemoteFuture != null) {
        try {
          final response = await callRemoteFuture();
          if (log) {
            print('Success fetch data');
          }

          late DataType data;
          if (processResponse != null) {
            final processedData = await processResponse(response);
            if (log) {
              print('Success process response data');
            }
            data = processedData;
          } else {
            final castData = response as DataType;
            data = castData;
          }
          yield Right(data);
        } on Exception catch (exception, stackTrace) {
          if (log) {
            print('Fetching failed: $exception');
          }
          final tmpException = handleError?.call(exception, stackTrace);
          yield Left(tmpException ?? exception);
        }
      }
      return;
    }

    Future<DataType> loadDbData() async {
      try {
        return await loadFromDbFuture!.call();
      } on Exception catch (exception, stackTrace) {
        if (log) {
          print('Load from DB failed: $exception');
        }
        final tmpException = handleError?.call(exception, stackTrace);
        throw tmpException ?? exception;
      }
    }

    ///========================= END INNER =========================///

    if (loadFromDbFuture != null && callRemoteFuture != null) {
      DataType dataFromDb;
      try {
        dataFromDb = await loadDbData();
      } on Exception catch (exception) {
        yield Left(exception);
        return;
      }
      if (log) print('Success load data from database');

      if (shouldFetch != null && shouldFetch(dataFromDb)) {
        if (log) print('Loading... data from network');
        yield Right(dataFromDb);
        yield* fetchRemoteData();
        return;
      } else {
        if (log) print('Fetching data its not necessary');
        yield Right(dataFromDb);
        return;
      }
    } else if (loadFromDbFuture != null) {
      DataType dataFromDb;
      try {
        dataFromDb = await loadDbData();
      } on Exception catch (exception) {
        yield Left(exception);
        return;
      }
      if (log) print('Success load data from database');
      yield Right(dataFromDb);
      return;
    } else if (callRemoteFuture != null) {
      if (log) print('Loading... data from network');
      yield* fetchRemoteData();
      return;
    } else {
      throw UnimplementedError(
        'Please implement loadFromDbFuture or createCallFuture',
      );
    }
  }
}
