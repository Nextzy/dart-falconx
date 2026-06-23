# DateTime Extension Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `date_time_extension.dart` to delegate relative time formatting to the `timeago` package and remove members duplicated by `dartx`.

**Architecture:** Remove 7 dartx-duplicated members + `DateTimeLocalizations` class + hand-rolled `toRelative()`. Replace with `timeago.format()` call. Add `timeago` re-export to `dart_faltool.dart`. Update tests to match new behavior.

**Tech Stack:** Dart, timeago ^3.7.1, dartx ^1.2.0, intl ^0.20.2

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `dart_faltool/lib/extensions/date_time_extension.dart` | Modify | Remove duplicated members, refactor `toRelative()`, delete `DateTimeLocalizations` |
| `dart_faltool/lib/dart_faltool.dart` | Modify | Add `timeago` re-export |
| `dart_faltool/test/extensions/date_time_extension_test.dart` | Modify | Remove tests for deleted members, update `toRelative()` expectations |

---

### Task 1: Add `timeago` re-export to `dart_faltool.dart`

**Files:**
- Modify: `dart_faltool/lib/dart_faltool.dart:34`

- [ ] **Step 1: Add the timeago export**

In `dart_faltool/lib/dart_faltool.dart`, insert a new line after `stack_trace` (line 32) and before `uuid` (line 33) to maintain alphabetical order:

```dart
export 'package:stack_trace/stack_trace.dart';
export 'package:timeago/timeago.dart';
export 'package:uuid/uuid.dart';
```

- [ ] **Step 2: Verify no analyzer errors**

Run:
```bash
cd dart_faltool && dart analyze lib/dart_faltool.dart
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
cd dart_faltool && git add lib/dart_faltool.dart && git commit -m "feat(faltool): add timeago re-export to dart_faltool.dart"
```

---

### Task 2: Remove dartx-duplicated members from the extension

**Files:**
- Modify: `dart_faltool/lib/extensions/date_time_extension.dart`

Remove these members from `FalconToolDateTimeExtensions`:

- [ ] **Step 1: Remove `startOfDay` getter (line 24)**

Remove:
```dart
  /// Gets the start of the day (00:00:00).
  /// 
  /// Example:
  /// ```dart
  /// DateTime(2023, 5, 15, 14, 30).startOfDay; // 2023-05-15 00:00:00
  /// ```
  DateTime get startOfDay => DateTime(year, month, day);
```

Consumers should use dartx's `.date` instead.

- [ ] **Step 2: Remove `startOfMonth` getter (line 27)**

Remove:
```dart
  /// Gets the start of the month.
  DateTime get startOfMonth => DateTime(year, month, 1);
```

Consumers should use dartx's `.firstDayOfMonth`.

- [ ] **Step 3: Remove `endOfMonth` getter (lines 29-30)**

Remove:
```dart
  /// Gets the end of the month.
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);
```

Consumers should use dartx's `.lastDayOfMonth.endOfDay`.

- [ ] **Step 4: Remove `startOfYear` getter (lines 32-33)**

Remove:
```dart
  /// Gets the start of the year.
  DateTime get startOfYear => DateTime(year, 1, 1);
```

Consumers should use dartx's `.firstDayOfYear`.

- [ ] **Step 5: Remove `endOfYear` getter (lines 35-36)**

Remove:
```dart
  /// Gets the end of the year.
  DateTime get endOfYear => DateTime(year, 12, 31, 23, 59, 59, 999);
```

Consumers should use dartx's `.lastDayOfYear.endOfDay`.

- [ ] **Step 6: Remove `isYesterday` getter (lines 80-86)**

Remove:
```dart
  /// Checks if this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
```

Consumers should use dartx's `.wasYesterday`.

- [ ] **Step 7: Remove `isWeekday` getter (lines 94-96)**

Remove:
```dart
  /// Checks if this date is on a weekday.
  bool get isWeekday =>
      weekday != DateTime.saturday && weekday != DateTime.sunday;
```

Consumers should use dartx's `.isWorkday`.

- [ ] **Step 8: Update `humanReadableDay()` to use `wasYesterday`**

In the `humanReadableDay` method, change `isYesterday` to `wasYesterday`:

Before:
```dart
    if (isYesterday) {
      return Intl.message('Yesterday', name: 'yesterday');
    }
```

After:
```dart
    if (wasYesterday) {
      return Intl.message('Yesterday', name: 'yesterday');
    }
```

Also simplify the method by removing the locale-setting side effect (the `Intl.defaultLocale = locale` line) and using inline returns:

Before:
```dart
  String humanReadableDay({String? locale}) {
    if (locale != null) {
      Intl.defaultLocale = locale;
    }
    
    if (isToday) {
      return Intl.message('Today', name: 'today');
    }
    if (isYesterday) {
      return Intl.message('Yesterday', name: 'yesterday');
    }
    if (isTomorrow) {
      return Intl.message('Tomorrow', name: 'tomorrow');
    }
    return format('EEEE, MMM dd', locale: locale);
  }
```

After:
```dart
  String humanReadableDay({String? locale}) {
    if (locale != null) {
      Intl.defaultLocale = locale;
    }

    if (isToday) {
      return Intl.message('Today', name: 'today');
    }
    if (wasYesterday) {
      return Intl.message('Yesterday', name: 'yesterday');
    }
    if (isTomorrow) {
      return Intl.message('Tomorrow', name: 'tomorrow');
    }
    return format('EEEE, MMM dd', locale: locale);
  }
```

- [ ] **Step 9: Verify analyzer passes**

Run:
```bash
cd dart_faltool && dart analyze lib/extensions/date_time_extension.dart
```
Expected: No issues found (or only warnings from the test file which we fix next).

- [ ] **Step 10: Commit**

```bash
cd dart_faltool && git add lib/extensions/date_time_extension.dart && git commit -m "refactor(faltool): remove dartx-duplicated DateTime members

Remove startOfDay, startOfMonth, endOfMonth, startOfYear, endOfYear,
isYesterday, isWeekday — all available via dartx (package:time).
Update humanReadableDay() to use dartx wasYesterday."
```

---

### Task 3: Refactor `toRelative()` to use `timeago` and delete `DateTimeLocalizations`

**Files:**
- Modify: `dart_faltool/lib/extensions/date_time_extension.dart`

- [ ] **Step 1: Add `timeago` prefixed import at top of file**

The file currently has:
```dart
import 'package:dart_faltool/lib.dart';
```

Add below it:
```dart
import 'package:timeago/timeago.dart' as timeago;
```

We need a prefixed import because `timeago` exports a top-level `format()` function that would conflict with the extension's own `format()` method.

- [ ] **Step 2: Replace `toRelative()` method body**

Replace the entire `toRelative()` method (lines 208-337) with:

```dart
  /// Formats as a relative time string using the timeago package.
  ///
  /// Uses the [timeago] package for localized relative time formatting.
  /// Register locales at app startup via `timeago.setLocaleMessages()`.
  ///
  /// Example:
  /// ```dart
  /// DateTime.now().subtract(Duration(minutes: 5)).toRelative(); // '5 minutes ago'
  /// DateTime.now().add(Duration(hours: 2)).toRelative(allowFromNow: true); // '2 hours from now'
  /// ```
  String toRelative({String? locale, bool allowFromNow = false}) {
    return timeago.format(this, locale: locale, allowFromNow: allowFromNow);
  }
```

- [ ] **Step 3: Delete the `DateTimeLocalizations` class**

Remove the entire class (lines 528-568 approximately — the class at the bottom of the file):

```dart
/// Helper class for localizable date/time strings.
/// 
/// This class provides static methods to get localized strings
/// without hardcoding them in the extension methods.
class DateTimeLocalizations {
  /// Gets localized 'Today' string.
  static String today({String? locale}) {
    ...
  }

  /// Gets localized 'Yesterday' string.
  static String yesterday({String? locale}) {
    ...
  }

  /// Gets localized 'Tomorrow' string.
  static String tomorrow({String? locale}) {
    ...
  }

  /// Gets localized 'just now' string.
  static String justNow({String? locale}) {
    ...
  }

  /// Gets localized 'in a moment' string.
  static String inAMoment({String? locale}) {
    ...
  }
}
```

Delete the entire class including all methods and docs.

- [ ] **Step 4: Update `FalconToolDateTimeNullExtensions.toRelative()`**

The nullable extension also has a `toRelative` forwarder. Update its signature to match:

Before:
```dart
  /// Safely converts to relative time string with localization support.
  String? toRelative({String? locale}) => this?.toRelative(locale: locale);
```

After:
```dart
  /// Safely converts to relative time string with localization support.
  String? toRelative({String? locale, bool allowFromNow = false}) =>
      this?.toRelative(locale: locale, allowFromNow: allowFromNow);
```

- [ ] **Step 5: Verify analyzer passes**

Run:
```bash
cd dart_faltool && dart analyze lib/extensions/date_time_extension.dart
```
Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
cd dart_faltool && git add lib/extensions/date_time_extension.dart && git commit -m "refactor(faltool): replace toRelative() with timeago package

Replace ~130 lines of hand-rolled Intl.plural relative time formatting
with timeago.format(). Delete DateTimeLocalizations helper class.
Add allowFromNow parameter for future date support."
```

---

### Task 4: Update tests for removed members

**Files:**
- Modify: `dart_faltool/test/extensions/date_time_extension_test.dart`

- [ ] **Step 1: Remove `startOfDay` test (lines 13-31)**

Remove the test `'should extract start of day from any time'`. This tested the custom `startOfDay` getter which is now removed (dartx provides `.date`).

- [ ] **Step 2: Remove `endOfDay` test (lines 33-57)**

Remove the test `'should extract end of day from any time'`. This tested a custom `endOfDay` getter (dartx provides `.endOfDay`).

- [ ] **Step 3: Remove `startOfMonth/endOfMonth` test (lines 59-87)**

Remove the test `'should extract start and end of month'`. These tested `startOfMonth` and `endOfMonth` which are now removed.

- [ ] **Step 4: Remove `startOfYear/endOfYear` test (lines 89-118)**

Remove the test `'should extract start and end of year'`. These tested `startOfYear` and `endOfYear` which are now removed.

- [ ] **Step 5: Update `isYesterday` references in comparison tests**

In the test `'should identify today, yesterday, and tomorrow'` (around line 231), change `isYesterday` to `wasYesterday`:

Before:
```dart
        when('checking if dates are yesterday', () {
          then('yesterday should return true', () {
            expect(yesterday.isYesterday, isTrue);
          });

          and('today should return false', () {
            expect(today.isYesterday, isFalse);
          });
        });
```

After:
```dart
        when('checking if dates are yesterday', () {
          then('yesterday should return true', () {
            expect(yesterday.wasYesterday, isTrue);
          });

          and('today should return false', () {
            expect(today.wasYesterday, isFalse);
          });
        });
```

- [ ] **Step 6: Verify tests compile after member removal**

Run:
```bash
cd dart_faltool && dart analyze test/extensions/date_time_extension_test.dart
```
Expected: No issues found (or only the toRelative test issues we fix in the next task).

- [ ] **Step 7: Commit**

```bash
cd dart_faltool && git add test/extensions/date_time_extension_test.dart && git commit -m "test(faltool): remove tests for dartx-duplicated DateTime members

Remove tests for startOfDay, endOfDay, startOfMonth, endOfMonth,
startOfYear, endOfYear. Update isYesterday to wasYesterday."
```

---

### Task 5: Update `toRelative()` tests and remove `DateTimeLocalizations` tests

**Files:**
- Modify: `dart_faltool/test/extensions/date_time_extension_test.dart`

The `timeago` package (EnMessages) produces these exact strings:
- < 45 seconds: `"a moment ago"`
- ~1 minute: `"a minute ago"`
- 2-44 minutes: `"N minutes ago"`
- ~1 hour: `"about an hour ago"`
- 2-23 hours: `"N hours ago"`
- ~1 day: `"a day ago"`
- 2-29 days: `"N days ago"`
- ~1 month: `"about a month ago"`
- 2-11 months: `"N months ago"`
- ~1 year: `"about a year ago"`
- 2+ years: `"N years ago"`

Future dates (with `allowFromNow: true`): suffix changes from `"ago"` to `"from now"`.

- [ ] **Step 1: Update `toRelative()` test expectations**

Replace the test `'should format relative time correctly'` (around line 707) with updated expectations matching `timeago` output:

```dart
      test('should format relative time correctly', () {
        // Given
        late DateTime now;

        given('the current time', () {
          now = DateTime.now();
        });

        // When & Then
        final relativeTimeTestCases = [
          (
            time: now,
            expected: 'a moment ago',
            description: 'current time',
          ),
          (
            time: now.subtract(const Duration(minutes: 5)),
            expected: '5 minutes ago',
            description: '5 minutes ago',
          ),
          (
            time: now.subtract(const Duration(hours: 2)),
            expected: '2 hours ago',
            description: '2 hours ago',
          ),
          (
            time: now.subtract(const Duration(days: 3)),
            expected: '3 days ago',
            description: '3 days ago',
          ),
        ];

        for (final testCase in relativeTimeTestCases) {
          when('formatting ${testCase.description}', () {
            final result = testCase.time.toRelative();

            then('it should return "${testCase.expected}"', () {
              expect(result, equals(testCase.expected));
            });
          });
        }
      });

      test('should format future dates with allowFromNow', () {
        // Given
        late DateTime now;

        given('the current time', () {
          now = DateTime.now();
        });

        // When
        when('formatting a date 2 hours in the future with allowFromNow', () {
          final futureDate = now.add(const Duration(hours: 2, minutes: 1));
          final result = futureDate.toRelative(allowFromNow: true);

          // Then
          then('it should contain "from now"', () {
            expect(result, contains('from now'));
          });
        });
      });
```

Key changes from original:
- `'just now'` → `'a moment ago'` (timeago's default English)
- `'in 2 hours'` → moved to separate test with `allowFromNow: true`, expects `'from now'` suffix
- Changed `contains` to `equals` for exact string matching (except future test which uses `contains`)

- [ ] **Step 2: Delete the `DateTimeLocalizations` test group**

Remove the entire group `'Feature: DateTime Localizations'` (around lines 1259-1279):

```dart
  group('Feature: DateTime Localizations', () {
    test('should provide localized strings', () {
      // Given & When & Then
      final localizationTestCases = [
        (method: DateTimeLocalizations.today, expected: 'Today'),
        (method: DateTimeLocalizations.yesterday, expected: 'Yesterday'),
        (method: DateTimeLocalizations.tomorrow, expected: 'Tomorrow'),
        (method: DateTimeLocalizations.justNow, expected: 'just now'),
        (method: DateTimeLocalizations.inAMoment, expected: 'in a moment'),
      ];

      for (final testCase in localizationTestCases) {
        when('getting localized string', () {
          final result = testCase.method();

          then('it should return "${testCase.expected}"', () {
            expect(result, equals(testCase.expected));
          });
        });
      }
    });
  });
```

- [ ] **Step 3: Run all tests**

Run:
```bash
cd dart_faltool && dart test test/extensions/date_time_extension_test.dart
```
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
cd dart_faltool && git add test/extensions/date_time_extension_test.dart && git commit -m "test(faltool): update toRelative() tests for timeago output format

Update expected strings to match timeago EnMessages output.
Add test for allowFromNow future date formatting.
Remove DateTimeLocalizations test group."
```

---

### Task 6: Final verification

**Files:** None (verification only)

- [ ] **Step 1: Run full analyzer**

```bash
cd dart_faltool && dart analyze
```
Expected: No issues found.

- [ ] **Step 2: Run dart format**

```bash
cd dart_faltool && dart format lib/extensions/date_time_extension.dart test/extensions/date_time_extension_test.dart
```
Expected: Files formatted (or already formatted).

- [ ] **Step 3: Run full test suite**

```bash
cd dart_faltool && dart test
```
Expected: All tests pass.

- [ ] **Step 4: Commit any format fixes**

If dart format changed anything:
```bash
cd dart_faltool && git add -A && git commit -m "style(faltool): dart format date_time_extension files"
```

- [ ] **Step 5: Verify line count reduction**

```bash
wc -l dart_faltool/lib/extensions/date_time_extension.dart
```
Expected: ~370 lines or fewer (down from 568).
