# Models

`package: dart_falmodel` unless marked.

## `BaseModel<T>`

`abstract class BaseModel<T> with Equatable`: `stringify` is true, `T copyWith()` is abstract, you supply `props`. `UniqueModel<T>` adds `id` (defaults to `UuidGenerator.getV4()`) with `props = [id]`; it is not `const`. `FirebaseModel` and `FirebaseTimestampModel({createdAt, updatedAt})` are Equatable bases for Firestore documents.

```dart
class User extends BaseModel<User> {
  const User({required this.id, required this.name});
  final String id;
  final String name;
  @override
  List<Object?> get props => [id, name];
  @override
  User copyWith({String? id, String? name}) => User(id: id ?? this.id, name: name ?? this.name);
}
```

## Requests

- `BaseRequest`: Equatable root of every request and socket model.
- `BaseRequestBody`: implement `Map<String, Object?> toJson()`; `toJsonStr()` is provided. Pass as `data:` to `BaseHttpClient.post/patch/put/delete`.
- `BaseFormDataBody`: `toJson()` plus `Future<FormData> toFormData()`; pass the form data to `postFormData` / `putFormData`.
- `PaginatedRequest({page = 1, pageSize = 20})`: `toQueryParameters()` returns `{'page', 'page_size'}`.

```dart
class CreateUserBody extends BaseRequestBody {
  const CreateUserBody({required this.name});
  final String name;
  @override
  Map<String, Object?> toJson() => {'name': name};
  @override
  List<Object?> get props => [name];
}
```

## Responses

- `BaseResponse<T> extends Response<T>` (Dio): `BaseResponse.success(data:, requestOptions:, headers?)`, `BaseResponse.noContent(requestOptions:)`, `isSuccessful`, `isClientError`, `isServerError`. Typedefs `BoolResponse`, `IntResponse`, `DoubleResponse`, `StringResponse`, `ListResponse<T>`, `MapResponse<K, V>`, `EmptyResponse`.
- `PaginatedResponse<T>({items, page, pageSize, totalItems, totalPages})`: `hasNextPage`, `hasPreviousPage`, `nextPage`, `previousPage`, `isFirstPage`, `isLastPage`, `itemCount`, `isEmpty`, `isNotEmpty`, `startIndex`, `endIndex`, `copyWith`. `PaginatedResponseWithMetadata<T>` adds `metadata`.
- `RemoteError({code, message, userMessage, developerMessage})` (Freezed): `fromJson`, `fromData(dynamic)`.

## `UserFeedback`

Freezed sealed class with variants `Success`, `Warning`, `Failure`, `Information`, each `({String? message, FeedbackLevel level = FeedbackLevel.medium})`. `FeedbackLevel { low, medium, high, critical }` has `isProminent`. Getters `successMessage`, `errorMessage`, `warningMessage`, `informationMessage`; `match(onSuccess:, onWarning:, onFailure:, onInformation:)`; statics `warningFromException`, `failureFromException`; from an exception, `CommonException.toFailure() / toWarning() / toInformation()`. `VoidFailureCallback = void Function(Failure)`.

## `DatasourceBoundState` (`package: dart_falconnect`)

Static helpers that turn local and remote calls into `Result` streams. Every thrown error becomes `Result.failure(e.toException())`, optionally rewritten by `handleError: (CommonException, StackTrace?) => CommonException`.

| Method | Parameters | Emits |
|---|---|---|
| `asLocalResultStream<D>` | `loadFromDbFuture` (required), `handleError`, `log` | one local result |
| `asLocalResultFuture<D>` | same | first result |
| `asRemoteResultStream<R, D>` | `callRemoteFuture` (required), `processResponse` (required when `R != D`), `handleError`, `log` | one remote result |
| `asRemoteResultFuture<R, D>` | `createCallFuture` (required), `processResponse`, `handleError` | first result |
| `asResultStream<R, D>` | `loadFromDbFuture`, `shouldFetch(D?)`, `callRemoteFuture`, `processResponse`, `handleError`, `log` | local, then remote when `shouldFetch` returns true |

```dart
Stream<Result<User>> watchUser(String id) =>
    DatasourceBoundState.asResultStream<UserDto, User>(
      loadFromDbFuture: () => db.getUser(id),
      shouldFetch: (u) => u == null || u.isStale,
      callRemoteFuture: () => api.getUser(id),
      processResponse: (dto) => dto.toDomain(),
    );
```

Notes: with both callbacks, a DB failure ends the stream with one failure and never reaches remote; with neither, `UnimplementedError` is thrown. `asRemoteResultFuture` names its callback `createCallFuture` while the stream variant uses `callRemoteFuture`. There is no `saveCallResult` parameter; persist inside `processResponse`.
