extension FalconDateTimeValidatorExtension on DateTime {
  /// Returns `true` if this date is strictly before [to].
  bool isValidDateRange(DateTime to) => isBefore(to);
}
