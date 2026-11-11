/// Switches for features that are built but currently hidden.
/// Flip a flag back to `true` to show the feature again; nothing is removed.
class FeatureFlags {
  FeatureFlags._();

  /// Floating "AR Guide" button on Home (Week 7 optional AR guide).
  /// The AR guide screen and its route still exist.
  static bool showArGuideButton = true;

  /// "Campus Tour · x/6 visited" progress card on the Home dashboards.
  /// The Campus Tour screen still shows its own progress.
  static bool showHomeTourProgress = true;

  /// Student Records: programme filter chips above the list (search stays).
  static bool showRecordsProgramFilter = true;

  /// Student Records: email address on each student card.
  static bool showRecordsEmail = true;

  /// Student Records: year level on each student card.
  static bool showRecordsYearLevel = true;
}
