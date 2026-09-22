import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logic/muscle_group_colors.dart' show AppColorPalette;
import '../../logic/plate_calculator.dart'
    show standardPlatesKg, standardPlatesLbs;
import '../../logic/progression.dart' show ExperienceLevel;
import '../../logic/summary_period.dart' show WeekStart, SummaryPeriod;
import '../../logic/units.dart';

export '../../logic/progression.dart' show ExperienceLevel;
export '../../logic/summary_period.dart' show WeekStart, SummaryPeriod;

const _weightUnitKey = 'weight_unit';
const _weekStartKey = 'week_start';
const _summaryPeriodKey = 'summary_period';
const _themeModeKey = 'theme_mode';
const _workoutRemindersKey = 'workout_reminders_enabled';
const _weeklyDigestKey = 'weekly_digest_enabled';
const _reminderMinutesKey = 'reminder_time_minutes';
const _digestWeekdayKey = 'digest_weekday';
const _hasSeenOnboardingKey = 'has_seen_onboarding';
const _lastSeenWhatsNewRevisionKey = 'last_seen_whats_new_revision';
const _showProgressChartsKey = 'show_progress_charts';
const _colorPaletteKey = 'color_palette';
const _bodyTrackingKey = 'body_tracking';
const _reportDetailKey = 'report_detail';
const _clockFormatKey = 'clock_format';
const _experienceLevelKey = 'experience_level';
const _availableEquipmentKey = 'available_equipment';
const _progressionSuggestionsEnabledKey = 'progression_suggestions_enabled';
const _availablePlatesKgKey = 'available_plates_kg';
const _availablePlatesLbsKey = 'available_plates_lbs';
const _focusModeEnabledKey = 'focus_mode_enabled';
const _focusModeHideProgressKey = 'focus_mode_hide_progress';
const _focusModeHideStreaksKey = 'focus_mode_hide_streaks';
const _standardLibraryDismissedKey = 'standard_library_dismissed';

/// How times of day (currently just the reminder-time setting) are
/// displayed and entered. [system] follows the device's own 24-hour setting
/// (`MediaQuery.alwaysUse24HourFormat`) rather than this app's locale
/// guess - explicit [h24]/[h12] override it, since relying on system locale
/// alone doesn't cover someone who wants a specific format regardless of
/// their device's region setting (24-hour is standard in much of Europe
/// regardless of language, for instance).
enum ClockFormat { system, h24, h12 }

extension ClockFormatLabel on ClockFormat {
  String get label => switch (this) {
    ClockFormat.system => 'Match system',
    ClockFormat.h24 => '24-hour',
    ClockFormat.h12 => '12-hour (AM/PM)',
  };
}

/// How much detail the Progress tab's "Share summary" action includes -
/// see `progress_screen.dart`'s `_shareSummary`. [brief] is the original
/// sessions/volume/PRs-only text; [detailed] adds the per-exercise top-set
/// dashboard, closer to what someone would actually want to hand a trainer.
enum ReportDetail { brief, detailed }

extension ReportDetailLabel on ReportDetail {
  String get label => switch (this) {
    ReportDetail.brief => 'Brief',
    ReportDetail.detailed => 'Detailed',
  };

  String get description => switch (this) {
    ReportDetail.brief => 'Sessions, volume, and PRs for the period.',
    ReportDetail.detailed =>
      'Everything in Brief, plus the current top set for every exercise - '
          'closer to what you\'d hand a trainer.',
  };
}

/// UI label for `ExperienceLevel` (defined in `lib/logic/progression.dart`,
/// kept free of UI strings per this project's DB/Flutter-free `lib/logic/`
/// convention) - lives here alongside `ReportDetailLabel`/etc. instead.
extension ExperienceLevelLabel on ExperienceLevel {
  String get label => switch (this) {
    ExperienceLevel.beginner => 'Beginner',
    ExperienceLevel.intermediate => 'Intermediate',
    ExperienceLevel.advanced => 'Advanced',
  };
}

/// Whether the user has opted into body-measurement tracking.
///
/// Tri-state on purpose. Weighing yourself is not a neutral act - for some
/// people it's unhelpful or actively harmful - so the feature is off until
/// asked for, and someone who declines is never asked again. [notAsked] is
/// distinct from [declined] precisely so a "no" is remembered as a no.
enum BodyTracking { notAsked, enabled, declined }

class AppPreferences {
  final WeightUnit weightUnit;
  final WeekStart weekStart;
  final SummaryPeriod summaryPeriod;
  final ThemeMode themeMode;

  /// A reminder on the morning of each scheduled workout.
  final bool workoutRemindersEnabled;

  /// A weekly "here's your training week" overview.
  final bool weeklyDigestEnabled;

  /// Minutes past midnight that reminders fire at (shared by both kinds).
  final int reminderTimeMinutes;

  /// Which weekday the weekly digest lands on (DateTime.monday..sunday).
  final int digestWeekday;

  /// Whether the first-launch tour has been completed or skipped.
  final bool hasSeenOnboarding;

  /// The highest "What's new" revision (see `whats_new_content.dart`'s
  /// `currentWhatsNewRevision`) this device has already been shown. Defaults
  /// to 0, same as a never-set int always would - deliberately NOT defaulted
  /// to "already caught up," because that default has to serve two very
  /// different devices identically: a brand-new install (which finishes
  /// onboarding - see its own `_finish()` - and stamps this to the current
  /// revision right then, since the tour just covered everything in it) and
  /// an *existing* device that had the app before this feature shipped at
  /// all (which has never had this key set either, and should see the sheet
  /// at least once to catch up - 0 makes that happen automatically).
  final int lastSeenWhatsNewRevision;

  /// Whether the Progress tab shows its swipeable trend charts above the
  /// numeric summary. On for people who read shapes faster than numbers;
  /// off for a compact numbers-only view.
  final bool showProgressCharts;

  /// Which muscle-group colour palette to use across the library, plans and
  /// sessions - includes colour-vision-deficiency-safe options.
  final AppColorPalette colorPalette;

  /// Opt-in state for body-measurement tracking. Off until asked for.
  final BodyTracking bodyTracking;

  /// Default detail level for the Progress tab's shared summary text.
  final ReportDetail reportDetail;

  /// How to display/enter times of day - see [ClockFormat].
  final ClockFormat clockFormat;

  /// Feeds `suggestNextSet`'s per-level progression increment (see
  /// `lib/logic/progression.dart`) - defaults to `intermediate` so an
  /// existing user who never sets this sees the exact same suggestions as
  /// before this preference existed.
  final ExperienceLevel experienceLevel;

  /// Equipment tags (see `lib/logic/equipment_matching.dart`) the user says
  /// they have access to - feeds the Exercise Library's "My equipment"
  /// filter. Defaults to empty; the filter chip itself defaults to
  /// inactive (same opt-in-per-session shape as the existing muscle-area
  /// filter chip) rather than being gated on whether this has ever been
  /// set, so "I deliberately own nothing but bodyweight" is a valid,
  /// representable choice rather than being indistinguishable from
  /// "never configured."
  final Set<String> availableEquipment;

  /// Whether History's "Suggested next session" card (built from
  /// `suggestNextSet`) is shown at all - some people find an algorithm
  /// telling them what to lift next intrusive rather than helpful. Defaults
  /// to on, matching the feature's existing always-on behavior.
  final bool progressionSuggestionsEnabled;

  /// Which plate sizes the plate calculator should actually use, per unit,
  /// heaviest first (the order `calculatePlateLoad`'s greedy algorithm
  /// relies on - see `lib/logic/plate_calculator.dart`) - not every gym
  /// stocks every standard size (a 25kg-less gym, or one with unusual sizes
  /// like 40kg), so this is user-editable rather than always the fixed
  /// `standardPlatesKg`/`standardPlatesLbs` lists. A `List`, not a `Set` -
  /// Dart's `double` can't be a const set element (it overrides `==`, which
  /// a const set element must not do), and a `const` constructor needs a
  /// const default; membership/dedup is still enforced wherever this is
  /// edited (`plate_calculator_screen.dart`), just not by the type itself.
  /// Defaults below duplicate `standardPlatesKg`/`standardPlatesLbs`'s own
  /// values (a `const` constructor can't call `.toList()` on them either,
  /// since that isn't a const expression) so an existing user sees identical
  /// behavior until they actually change something on the plate calculator
  /// screen - keep in sync if those standard lists ever change.
  final List<double> availablePlatesKg;
  final List<double> availablePlatesLbs;

  /// The master "just let me train" switch - requested directly by a user
  /// who wanted a way to train without being shown progress reports,
  /// summaries, or suggestions at all, not just individually-mutable ones.
  /// The two sub-toggles below only take effect while this is also on, via
  /// [hideProgressActive]/[hideStreaksActive] - so turning the master switch
  /// off always restores everything regardless of their own state, and
  /// turning it back on defaults to hiding both again (both sub-toggles
  /// default to `true`) rather than silently remembering a half-off state
  /// from months ago.
  final bool focusModeEnabled;

  /// Whether Focus Mode hides the Progress tab's own content (replaced with
  /// a plain "Focus mode is on" screen) and the trophy icon shown when
  /// logging a new personal record mid-session. Deliberately does not affect
  /// `history_screen.dart`'s own PR badge on already-logged sets - that's a
  /// factual record looked up on purpose, not a proactive nudge, which is
  /// the specific thing Focus Mode is for.
  final bool focusModeHideProgress;

  /// Whether Focus Mode hides the Today tab's streak card and "this week"
  /// summary card - kept independent of [focusModeHideProgress] since some
  /// people want to lose the PR-chasing but still like seeing their streak.
  final bool focusModeHideStreaks;

  /// Whether the bundled 47-exercise strongman-themed example library has
  /// been deliberately deleted - see `library_management_screen.dart`'s
  /// "Standard library" delete action. `exercise_seed_loader.dart`'s
  /// `seedExerciseLibrary()` normally re-upserts every seed row on *every*
  /// app start (by design, so it survives a plain uninstall/data-clear
  /// cycle), which would otherwise silently undo a delete the moment the
  /// app is next launched - this flag is what `main.dart`'s startup step
  /// checks to skip reseeding once someone has actually asked for it gone.
  /// Deleting again after re-importing the same content via the "Exercise
  /// library" template (which creates ordinary custom exercises, not seed
  /// rows) is a no-op here, since that path never touches this flag.
  final bool standardLibraryDismissed;

  const AppPreferences({
    this.weightUnit = WeightUnit.kg,
    this.weekStart = WeekStart.monday,
    this.summaryPeriod = SummaryPeriod.week,
    this.themeMode = ThemeMode.system,
    this.workoutRemindersEnabled = false,
    this.weeklyDigestEnabled = false,
    this.reminderTimeMinutes = 8 * 60,
    this.digestWeekday = DateTime.monday,
    this.hasSeenOnboarding = false,
    this.lastSeenWhatsNewRevision = 0,
    this.showProgressCharts = true,
    this.colorPalette = AppColorPalette.pastel,
    this.bodyTracking = BodyTracking.notAsked,
    this.reportDetail = ReportDetail.brief,
    this.clockFormat = ClockFormat.system,
    this.experienceLevel = ExperienceLevel.intermediate,
    this.availableEquipment = const {},
    this.progressionSuggestionsEnabled = true,
    this.availablePlatesKg = const [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25],
    this.availablePlatesLbs = const [45.0, 35.0, 25.0, 10.0, 5.0, 2.5],
    this.focusModeEnabled = false,
    this.focusModeHideProgress = true,
    this.focusModeHideStreaks = true,
    this.standardLibraryDismissed = false,
  });

  /// Whether the body-measurement UI should be visible at all.
  bool get bodyTrackingEnabled => bodyTracking == BodyTracking.enabled;

  /// Whether Progress-tab content and the in-session PR trophy should
  /// actually be hidden right now - both the master switch and this specific
  /// sub-toggle have to be on.
  bool get hideProgressActive => focusModeEnabled && focusModeHideProgress;

  /// Whether Today's streak/"this week" cards should actually be hidden
  /// right now - see [hideProgressActive].
  bool get hideStreaksActive => focusModeEnabled && focusModeHideStreaks;

  AppPreferences copyWith({
    WeightUnit? weightUnit,
    WeekStart? weekStart,
    SummaryPeriod? summaryPeriod,
    ThemeMode? themeMode,
    bool? workoutRemindersEnabled,
    bool? weeklyDigestEnabled,
    int? reminderTimeMinutes,
    int? digestWeekday,
    bool? hasSeenOnboarding,
    int? lastSeenWhatsNewRevision,
    bool? showProgressCharts,
    AppColorPalette? colorPalette,
    BodyTracking? bodyTracking,
    ReportDetail? reportDetail,
    ClockFormat? clockFormat,
    ExperienceLevel? experienceLevel,
    Set<String>? availableEquipment,
    bool? progressionSuggestionsEnabled,
    List<double>? availablePlatesKg,
    List<double>? availablePlatesLbs,
    bool? focusModeEnabled,
    bool? focusModeHideProgress,
    bool? focusModeHideStreaks,
    bool? standardLibraryDismissed,
  }) => AppPreferences(
    weightUnit: weightUnit ?? this.weightUnit,
    weekStart: weekStart ?? this.weekStart,
    summaryPeriod: summaryPeriod ?? this.summaryPeriod,
    themeMode: themeMode ?? this.themeMode,
    workoutRemindersEnabled:
        workoutRemindersEnabled ?? this.workoutRemindersEnabled,
    weeklyDigestEnabled: weeklyDigestEnabled ?? this.weeklyDigestEnabled,
    reminderTimeMinutes: reminderTimeMinutes ?? this.reminderTimeMinutes,
    digestWeekday: digestWeekday ?? this.digestWeekday,
    hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    lastSeenWhatsNewRevision:
        lastSeenWhatsNewRevision ?? this.lastSeenWhatsNewRevision,
    showProgressCharts: showProgressCharts ?? this.showProgressCharts,
    colorPalette: colorPalette ?? this.colorPalette,
    bodyTracking: bodyTracking ?? this.bodyTracking,
    reportDetail: reportDetail ?? this.reportDetail,
    clockFormat: clockFormat ?? this.clockFormat,
    experienceLevel: experienceLevel ?? this.experienceLevel,
    availableEquipment: availableEquipment ?? this.availableEquipment,
    progressionSuggestionsEnabled:
        progressionSuggestionsEnabled ?? this.progressionSuggestionsEnabled,
    availablePlatesKg: availablePlatesKg ?? this.availablePlatesKg,
    availablePlatesLbs: availablePlatesLbs ?? this.availablePlatesLbs,
    focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
    focusModeHideProgress:
        focusModeHideProgress ?? this.focusModeHideProgress,
    focusModeHideStreaks: focusModeHideStreaks ?? this.focusModeHideStreaks,
    standardLibraryDismissed:
        standardLibraryDismissed ?? this.standardLibraryDismissed,
  );
}

/// Loads persisted display preferences and lets the settings screen update
/// them. Kept separate from the app database - these are per-device display
/// choices, not synced/backed-up plan data.
class AppPreferencesNotifier extends StateNotifier<AppPreferences> {
  AppPreferencesNotifier() : super(const AppPreferences());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppPreferences(
      weightUnit: prefs.getString(_weightUnitKey) == 'lbs'
          ? WeightUnit.lbs
          : WeightUnit.kg,
      weekStart: prefs.getString(_weekStartKey) == 'sunday'
          ? WeekStart.sunday
          : WeekStart.monday,
      summaryPeriod: prefs.getString(_summaryPeriodKey) == 'month'
          ? SummaryPeriod.month
          : SummaryPeriod.week,
      themeMode: switch (prefs.getString(_themeModeKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      workoutRemindersEnabled: prefs.getBool(_workoutRemindersKey) ?? false,
      weeklyDigestEnabled: prefs.getBool(_weeklyDigestKey) ?? false,
      reminderTimeMinutes: prefs.getInt(_reminderMinutesKey) ?? 8 * 60,
      digestWeekday: prefs.getInt(_digestWeekdayKey) ?? DateTime.monday,
      hasSeenOnboarding: prefs.getBool(_hasSeenOnboardingKey) ?? false,
      lastSeenWhatsNewRevision:
          prefs.getInt(_lastSeenWhatsNewRevisionKey) ?? 0,
      showProgressCharts: prefs.getBool(_showProgressChartsKey) ?? true,
      colorPalette: AppColorPalette.values.firstWhere(
        (p) => p.name == prefs.getString(_colorPaletteKey),
        orElse: () => AppColorPalette.pastel,
      ),
      bodyTracking: BodyTracking.values.firstWhere(
        (b) => b.name == prefs.getString(_bodyTrackingKey),
        orElse: () => BodyTracking.notAsked,
      ),
      reportDetail: ReportDetail.values.firstWhere(
        (d) => d.name == prefs.getString(_reportDetailKey),
        orElse: () => ReportDetail.brief,
      ),
      clockFormat: ClockFormat.values.firstWhere(
        (f) => f.name == prefs.getString(_clockFormatKey),
        orElse: () => ClockFormat.system,
      ),
      experienceLevel: ExperienceLevel.values.firstWhere(
        (l) => l.name == prefs.getString(_experienceLevelKey),
        orElse: () => ExperienceLevel.intermediate,
      ),
      availableEquipment:
          prefs.getStringList(_availableEquipmentKey)?.toSet() ?? const {},
      progressionSuggestionsEnabled:
          prefs.getBool(_progressionSuggestionsEnabledKey) ?? true,
      availablePlatesKg:
          prefs.getStringList(_availablePlatesKgKey)?.map(double.parse).toList() ??
          standardPlatesKg,
      availablePlatesLbs:
          prefs.getStringList(_availablePlatesLbsKey)?.map(double.parse).toList() ??
          standardPlatesLbs,
      focusModeEnabled: prefs.getBool(_focusModeEnabledKey) ?? false,
      focusModeHideProgress:
          prefs.getBool(_focusModeHideProgressKey) ?? true,
      focusModeHideStreaks: prefs.getBool(_focusModeHideStreaksKey) ?? true,
      standardLibraryDismissed:
          prefs.getBool(_standardLibraryDismissedKey) ?? false,
    );
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    state = state.copyWith(weightUnit: unit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightUnitKey, unit.name);
  }

  Future<void> setWeekStart(WeekStart start) async {
    state = state.copyWith(weekStart: start);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weekStartKey, start.name);
  }

  Future<void> setSummaryPeriod(SummaryPeriod period) async {
    state = state.copyWith(summaryPeriod: period);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_summaryPeriodKey, period.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setWorkoutRemindersEnabled(bool enabled) async {
    state = state.copyWith(workoutRemindersEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_workoutRemindersKey, enabled);
  }

  Future<void> setWeeklyDigestEnabled(bool enabled) async {
    state = state.copyWith(weeklyDigestEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weeklyDigestKey, enabled);
  }

  Future<void> setReminderTimeMinutes(int minutes) async {
    state = state.copyWith(reminderTimeMinutes: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderMinutesKey, minutes);
  }

  Future<void> setDigestWeekday(int weekday) async {
    state = state.copyWith(digestWeekday: weekday);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_digestWeekdayKey, weekday);
  }

  Future<void> setHasSeenOnboarding(bool seen) async {
    state = state.copyWith(hasSeenOnboarding: seen);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, seen);
  }

  Future<void> setLastSeenWhatsNewRevision(int revision) async {
    state = state.copyWith(lastSeenWhatsNewRevision: revision);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSeenWhatsNewRevisionKey, revision);
  }

  Future<void> setShowProgressCharts(bool show) async {
    state = state.copyWith(showProgressCharts: show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showProgressChartsKey, show);
  }

  Future<void> setColorPalette(AppColorPalette palette) async {
    state = state.copyWith(colorPalette: palette);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorPaletteKey, palette.name);
  }

  Future<void> setBodyTracking(BodyTracking value) async {
    state = state.copyWith(bodyTracking: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bodyTrackingKey, value.name);
  }

  Future<void> setReportDetail(ReportDetail value) async {
    state = state.copyWith(reportDetail: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reportDetailKey, value.name);
  }

  Future<void> setClockFormat(ClockFormat value) async {
    state = state.copyWith(clockFormat: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clockFormatKey, value.name);
  }

  Future<void> setExperienceLevel(ExperienceLevel value) async {
    state = state.copyWith(experienceLevel: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_experienceLevelKey, value.name);
  }

  Future<void> setAvailableEquipment(Set<String> value) async {
    state = state.copyWith(availableEquipment: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_availableEquipmentKey, value.toList());
  }

  Future<void> setProgressionSuggestionsEnabled(bool enabled) async {
    state = state.copyWith(progressionSuggestionsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_progressionSuggestionsEnabledKey, enabled);
  }

  Future<void> setAvailablePlatesKg(List<double> value) async {
    state = state.copyWith(availablePlatesKg: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _availablePlatesKgKey,
      value.map((p) => p.toString()).toList(),
    );
  }

  Future<void> setAvailablePlatesLbs(List<double> value) async {
    state = state.copyWith(availablePlatesLbs: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _availablePlatesLbsKey,
      value.map((p) => p.toString()).toList(),
    );
  }

  Future<void> setFocusModeEnabled(bool enabled) async {
    state = state.copyWith(focusModeEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_focusModeEnabledKey, enabled);
  }

  Future<void> setFocusModeHideProgress(bool hide) async {
    state = state.copyWith(focusModeHideProgress: hide);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_focusModeHideProgressKey, hide);
  }

  Future<void> setFocusModeHideStreaks(bool hide) async {
    state = state.copyWith(focusModeHideStreaks: hide);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_focusModeHideStreaksKey, hide);
  }

  Future<void> setStandardLibraryDismissed(bool dismissed) async {
    state = state.copyWith(standardLibraryDismissed: dismissed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_standardLibraryDismissedKey, dismissed);
  }
}

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferences>(
      (ref) => AppPreferencesNotifier(),
    );
