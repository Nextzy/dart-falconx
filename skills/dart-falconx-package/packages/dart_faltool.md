# dart_faltool reference

Utility extensions, helper functions, and re-exported third-party libraries.

---

## Re-exported third-party libraries

All of these are available after `import 'package:dart_falconx/dart_falconx.dart'`:

| Package              | Key types / usage                                               | Hidden members                                                                                                                                                                                        |
|----------------------|-----------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `fpdart`             | `Either`, `Option`, `IO`, `IOEither`                            | `State`, `Task`                                                                                                                                                                                       |
| `rxdart`             | `PublishSubject`, `BehaviorSubject`, stream operators           | —                                                                                                                                                                                                     |
| `dartx`              | Kotlin-style extensions on all core types                       | `IterableAll`, `IterableAppend`, `IterableNumAverageExtension`, `IterableNumSumExtension`, `IterablePartition`, `IterableZip`, `MapOrEmpty`, `NumCoerceInRangeExtension`, `StringCapitalizeExtension` |
| `time`               | Duration extensions (`.seconds`, `.minutes`, `.hours`, `.days`) | —                                                                                                                                                                                                     |
| `intl`               | `DateFormat`, `NumberFormat`, `Intl`                            | —                                                                                                                                                                                                     |
| `big_decimal`        | `BigDecimal` arbitrary-precision arithmetic                     | —                                                                                                                                                                                                     |
| `numeral`            | Compact number formatting (`Numeral`)                           | —                                                                                                                                                                                                     |
| `timeago`            | `timeago.format(dateTime)`                                      | —                                                                                                                                                                                                     |
| `equatable`          | `Equatable`, `EquatableMixin`                                   | —                                                                                                                                                                                                     |
| `meta`               | `@immutable`, `@protected`, `@visibleForTesting`                | —                                                                                                                                                                                                     |
| `freezed_annotation` | `@freezed`, `@Freezed`, `@JsonKey`                              | —                                                                                                                                                                                                     |
| `json_annotation`    | `@JsonSerializable`, `@JsonKey`                                 | —                                                                                                                                                                                                     |
| `hashlib`            | SHA-256, SHA-3, and other hash digests                          | —                                                                                                                                                                                                     |
| `retry`              | `retry()` function with exponential backoff                     | —                                                                                                                                                                                                     |
| `stack_trace`        | `Trace`, `Frame`                                                | —                                                                                                                                                                                                     |
| `version`            | `Version` SemVer parsing                                        | —                                                                                                                                                                                                     |
| `rrule`              | `RecurrenceRule` iCalendar RRULE                                | `DateTimeRrule`                                                                                                                                                                                       |
| `data`               | Data-structure / buffer helpers                                 | `Field`                                                                                                                                                                                               |
| `enum_to_string`     | `EnumToString.convertToString`, `EnumToString.fromString`       | —                                                                                                                                                                                                     |

Also re-exports `dart:async`, `dart:convert`, `dart:math`, `dart:typed_data`.

---

## Extension catalog

### String — `FalconToolStringExtension` on `String`

```dart
str.toIntOrZero()          // int (0 on failure)
str.toDoubleOrZero()       // double
str.toBoolean()            // bool — 'true'/'1' → true, 'false'/'0' → false; throws otherwise
str.toBooleanOrNull()      // bool?
str.toMap()                // Map<String, dynamic> — FormatException if not valid JSON
str.toMapOrNull()          // Map<String, dynamic>?
str.toMapOrEmpty()         // Map<String, dynamic>
str.toBytes()              // Uint8List (UTF-8)
str.hashSha256({int? length}) // SHA-256 hex string; truncated/padded to length if given
str.removeHttp             // strips 'http://' or 'https://'
str.containsIgnoreCase(p)  // bool
str.countOccurrences(p)    // int
str.escapeHtml()           // &lt; &gt; etc.
str.unescapeHtml()
```

`dartx` adds: `str.reversed`, `str.toInt()`, `str.toIntOrNull()`, `str.isBlank`,
`str.isNotBlank`, `str.capitalize()` (note: `StringCapitalizeExtension` is hidden,
use `dartx`'s `capitalize` directly).

### String (nullable) — `FalconStringNullExtension` on `String?`

```dart
str?.or('default')         // String
str?.toIntOrNull()         // int?
str?.toIntOrZero()         // int
str?.toDoubleOrNull()      // double?
str?.toDoubleOrZero()      // double
str?.isUrl                 // bool
str?.isEmail               // bool
str?.isJson                // bool
str?.toBooleanOrNull()     // bool?
str?.toMapOrNull()         // Map?
str?.toMapOrEmpty()        // Map
str?.removeWhiteSpace      // String?
str?.normalizeWhitespace   // String?
```

### DateTime — `FalconToolDateTimeExtensions` on `DateTime`

```dart
dt.quarter                 // int 1-4
dt.weekOfYear              // int (ISO 8601)
dt.isPast / dt.isFuture    // bool
dt.isSameDay(other)        // bool
dt.isSameMonth(other)
dt.isSameYear(other)
dt.isBetween(start, end)   // bool

dt.addDays(n) / dt.subtractDays(n)
dt.addMonths(n)            // handles overflow (Jan 31 + 1 month = Feb 28/29)
dt.subtractMonths(n)
dt.addYears(n) / dt.subtractYears(n)
dt.nextWeekday(DateTime.monday)
dt.previousWeekday(DateTime.friday)

dt.format('yyyy-MM-dd', locale: 'th')  // DateFormat pattern
dt.toIso8601    // 'yyyy-MM-ddTHH:mm:ss'
dt.toDateOnly   // 'yyyy-MM-dd'
dt.toTimeOnly   // 'HH:mm:ss'
dt.toShortDate  // 'MMM dd, yyyy'
dt.toFullDate   // 'EEEE, MMMM dd, yyyy'
dt.toMonthYear  // 'MMMM yyyy'
dt.toRelative(locale: 'en', allowFromNow: true) // '5 minutes ago'
dt.humanReadableDay(locale: 'en') // 'Today' / 'Yesterday' / 'Tomorrow' / formatted date

dt.toUnixTimestamp  // int (seconds)
dt.toJsTimestamp    // int (milliseconds)
dt.age              // int (years since birthdate)
dt.daysUntil        // int
dt.hoursUntil       // int
```

**Int → DateTime extensions (`FalconToolIntToDateTimeExtensions`):**
```dart
1684156800.fromUnixToDateTime       // UTC DateTime from seconds
1684156800.fromUnixToLocalDateTime  // local DateTime
1684156800000.fromJsToDateTime      // UTC from milliseconds
```

**Nullable DateTime (`FalconToolDateTimeNullExtensions`):**
```dart
dt?.isNullOrPast / dt?.isNullOrFuture
dt?.format(pattern)         // String?
dt?.toRelative()            // String?
dt?.orNow                   // DateTime
dt?.orDefault(fallback)     // DateTime
dt?.toUnixTimestamp         // int?
dt?.age                     // int?
```

**Duration extensions (`FalconToolDurationExtensions`):**
```dart
dur.toHumanReadable()   // '2h 30m'
dur.toTimeString()      // 'HH:mm:ss'
dur.inYears             // double
// Operators + - * / are overloaded on Duration
```

### Number extensions

`FalconToolIntExtensions` on `int`:
```dart
n.absolute           // abs()
n.clampValue(min, max)
n.atLeast(min) / n.atMost(max)
n.inRange(min, max)  // bool
n.times((i) => ...)
n.generate<T>((i) => ...)  // List<T>
```

`FalconToolIntNullExtensions` on `int?`:
```dart
n?.orZero       // int
n?.isNullOrZero // bool
n?.isPositive / n?.isNegative
```

`FalconToolDoubleExtensions` on `double`:
```dart
d.roundToPlaces(2)   // 3.14
d.formatDecimal(2)   // '3.14'
d.toPercentage(decimalPlaces: 2)  // '12.34%'
d.toDegrees / d.toRadians
d.isWhole            // bool
d.fractionalPart     // double
```

`FalconToolNumExtensions` on `num`:
```dart
n.lerp(other, t)      // linear interpolation
n.mapRange(fromMin, fromMax, toMin, toMax) // double
```

### Object extensions

`FalconToolNullableObject<T>` on `T?`:
```dart
value?.let((v) => ...)          // execute if not null (side-effect)
value?.map((v) => transform(v)) // R?
value?.mapOr((v) => v, default) // R
value?.mapOrElse((v) => ..., () => default)
value?.orDefault(def)           // T
value?.orElse(() => compute())  // T
value?.takeIf((v) => condition) // T?
value?.takeUnless((v) => cond)  // T?
value?.fold(onNull: ..., onValue: ...)
value?.match(onNull: ..., onValue: ...)  // R
value?.chain((v) => nullable)   // R?
value?.isNull / value?.isNotNull
value?.toFuture()               // Future<T?>
value?.toFutureOr(() => error)  // Future<T>
```

`FalconToolObject<T>` on `T`:
```dart
obj.also((v) => sideEffect())  // T (Kotlin 'also')
obj.run((v) => transform(v))   // R
obj.applyIf(condition, (v) => transform(v))
obj.applyIfLazy(() => cond, (v) => transform(v))
obj.wrapInList()   // List<T>
obj.asSet()        // Set<T>
obj.asFuture()     // Future<T>
obj.asStream()     // Stream<T>
obj.isIn(iterable) // bool
obj.isNotIn(iterable)
```

### Collections

`FalconToolIterableExtensions` and list/map extensions add common
transforms, null-safe helpers, and group-by utilities on top of `dartx`.

`dartx` also provides extensive collection operators: `firstOrNull`,
`lastOrNull`, `sortedBy`, `groupBy`, `distinct`, `flatten`, `chunked`, etc.

---

## Utility functions and classes

### runCatching

Wraps a `Future<Result<T>>` lambda, catching any thrown exception into
`Result.failure(...)`. `CommonException` instances are wrapped as-is; all other
exceptions are converted via `.toException()` first.

```dart
final result = await runCatching(() async {
  final data = await remoteRepo.fetchUser(id);
  return Result.success(data);
});
// result is always Result<User> — never throws
```

### nowUtc

Current time as a UTC `DateTime`.

```dart
final ts = nowUtc; // DateTime, .isUtc == true
```

### constantTimeEquals

Constant-time string comparison — compare time does not vary with the position
of the first differing character. Use for secrets (tokens, HMACs, signatures) to
avoid timing side-channel leaks. Returns `false` immediately on length mismatch.

```dart
if (constantTimeEquals(providedToken, expectedToken)) {
  // authenticated
}
```

### randomDelay

Awaits a cryptographically-secure random delay in `[minMs, maxMs)` milliseconds
(default 100–300ms) to defend against timing-oracle attacks. Asserts
`maxMs > minMs >= 0`.

```dart
await randomDelay();                 // 100–300ms
await randomDelay(minMs: 50, maxMs: 150);
```

### TypeId

TypeID per the [jetify-com/typeid](https://github.com/jetify-com/typeid) spec
(UUIDv7 + base32 suffix + optional prefix).

```dart
// Generate
final id = TypeId.generate('user');   // 'user_01h234...'
final raw = TypeId.generate('');      // no prefix

// Decode
final decoded = TypeId.decode('user_01h234...');
// throws FormatException on invalid input
decoded.prefix   // 'user'
decoded.suffix   // base32 string
decoded.uuid     // canonical UUID string

// Safe decode
final d = TypeId.decodeOrNull('maybe_invalid'); // DecodedTypeId?

// Validate
TypeId.isValid('user_01h234...'); // bool
```

Prefix rules: lowercase `[a-z]` only, max 63 characters, no underscores.
`DecodedTypeId.toString()` reconstructs the full TypeID string.

### AppInfo

```dart
// Call once at app startup (no-op on web)
AppInfo.init();                    // reads pubspec.yaml
AppInfo.init('path/to/pubspec.yaml');

// Read anywhere
final version = AppInfo.version;   // String, default '1.0.0'
```

### UuidGenerator

```dart
final uuid = UuidGenerator.getV4(); // standard UUID v4 string
```
