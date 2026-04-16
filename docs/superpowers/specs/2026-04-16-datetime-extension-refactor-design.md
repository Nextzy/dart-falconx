# DateTime Extension Refactor — timeago + dartx dedup

**Date:** 2026-04-16
**Package:** dart_faltool
**File:** `lib/extensions/date_time_extension.dart`

## Goal

Refactor `date_time_extension.dart` to:
1. Replace the hand-rolled `toRelative()` (~130 lines) with the `timeago` package (already a dependency)
2. Remove members that duplicate what `dartx` (via `package:time`) already provides
3. Delete the `DateTimeLocalizations` helper class (no longer needed)

Net reduction: ~190 lines.

## Members to Remove

These are duplicated by `dartx` (`DateTimeTimeExtension` from `package:time`):

| Custom member | dartx equivalent |
|---|---|
| `startOfDay` | `.date` |
| `startOfMonth` | `.firstDayOfMonth` |
| `endOfMonth` | `.lastDayOfMonth` + `.endOfDay` |
| `startOfYear` | `.firstDayOfYear` |
| `endOfYear` | `.lastDayOfYear` + `.endOfDay` |
| `isYesterday` | `.wasYesterday` |
| `isWeekday` | `.isWorkday` |

**Note on `endOfMonth`/`endOfYear`:** The current implementation sets time to `23:59:59.999`. dartx's `lastDayOfMonth`/`lastDayOfYear` returns the date only (time zeroed). Consumers needing end-of-day precision should chain `.endOfDay` (from dartx) which sets `23:59:59.999999`. This is a minor behavior change (`.999` vs `.999999` microseconds) — acceptable.

## Members to Keep

These have no dartx equivalent or provide better naming:

- `quarter`, `weekOfYear` — no dartx equivalent
- `isPast`, `isFuture` — no dartx equivalent
- `isSameDay`, `isSameMonth`, `isSameYear` — dartx has `isAtSameDayAs` etc., but our naming is cleaner; one-liners with no maintenance burden
- `isBetween` — no dartx equivalent
- `addDays`, `subtractDays`, `addMonths`, `subtractMonths`, `addYears`, `subtractYears` — semantic convenience; `addMonths` handles day overflow correctly
- `nextWeekday`, `previousWeekday` — no dartx equivalent
- `format()` + predefined format getters (`toIso8601`, `toDateOnly`, `toTimeOnly`, `toShortDate`, `toFullDate`, `toMonthYear`) — uses `intl`, no dartx equivalent
- `humanReadableDay()` — unique (Today/Yesterday/Tomorrow labels)
- `toUnixTimestamp`, `toJsTimestamp`, `age`, `daysUntil`, `hoursUntil` — no dartx equivalent
- Entire `FalconToolIntToDateTimeExtensions` — no dartx equivalent
- Entire `FalconToolDateTimeNullExtensions` — no dartx equivalent
- Entire `FalconToolDurationExtensions` — except `inWeeks` which is already commented out (dartx provides it)

## `toRelative()` Refactor

### Before (~130 lines)
Hand-rolled `Intl.plural` / `Intl.message` for each time bucket (seconds, minutes, hours, days, weeks, months, years) with past/future variants.

### After (~3 lines)
```dart
String toRelative({String? locale, bool allowFromNow = false}) {
  return timeago.format(this, locale: locale, allowFromNow: allowFromNow);
}
```

- `timeago` handles all time buckets and 50+ built-in locales
- `allowFromNow` parameter exposes timeago's future date support (replaces the existing future handling)
- Locale registration (e.g. `timeago.setLocaleMessages('th', ThMessages())`) is the consumer's responsibility at app startup — not done in the extension

## `DateTimeLocalizations` Class — Delete

The entire `DateTimeLocalizations` class (~40 lines) is deleted. It was only used by `toRelative()` for "just now" / "in a moment" strings. With `timeago` handling this, the class is unused.

`humanReadableDay()` already uses `Intl.message` directly — no impact.

## Re-export Strategy

Add to `dart_faltool.dart`:
```dart
export 'package:timeago/timeago.dart';
```

This allows consumers to call `timeago.setDefaultLocale()` and `timeago.setLocaleMessages()` without adding a direct dependency.

## `humanReadableDay()` — Minor Update

After removing `isYesterday`, replace with dartx's `wasYesterday` in the method body:

```dart
String humanReadableDay({String? locale}) {
  if (isToday) return Intl.message('Today', name: 'today');
  if (wasYesterday) return Intl.message('Yesterday', name: 'yesterday');
  if (isTomorrow) return Intl.message('Tomorrow', name: 'tomorrow');
  return format('EEEE, MMM dd', locale: locale);
}
```

## Test Updates

File: `test/extensions/date_time_extension_test.dart`

1. **Remove tests for deleted members**: `startOfDay`, `endOfDay` (custom), `startOfMonth`, `endOfMonth`, `startOfYear`, `endOfYear`, `isYesterday` direct tests
2. **Update `toRelative()` expected values** to match `timeago` output format:
   - "just now" → timeago returns "a moment ago" (for < 1 minute)
   - "5 minutes ago" → timeago returns "5 minutes ago" (same)
   - "in 2 hours" → timeago returns "2 hours from now" (with `allowFromNow: true`)
   - Verify exact strings from timeago's `EnMessages` class
3. **Delete `DateTimeLocalizations` test group**
4. **Update `isYesterday` references** in comparison tests to use `wasYesterday`
5. **Keep all other test groups unchanged**: formatting, calculations, conversions, nullable, duration

## Scope Boundaries

**In scope:**
- `date_time_extension.dart` — remove/refactor as described
- `date_time_extension_test.dart` — update to match
- `dart_faltool.dart` — add timeago re-export

**Out of scope:**
- Other packages in the monorepo — verified via grep: removed members (`startOfDay`, `startOfMonth`, `endOfMonth`, `startOfYear`, `endOfYear`, `isYesterday`, `isWeekday`) are only used in `date_time_extension.dart` and its test file
- Custom timeago locale registration
- Changes to `pubspec.yaml` (timeago already a dependency)
