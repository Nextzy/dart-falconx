extension FalconToolIntValidatorExtension on int {
  /// Returns `true` if this int is a valid day-of-month (1–31).
  bool get isValidDayOfMonth => this >= 1 && this <= 31;
}
