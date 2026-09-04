import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logic/muscle_group_colors.dart' show AppColorPalette;
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
const _showProgressChartsKey = 'show_progress_charts';
const _colorPaletteKey = 'color_palette';
const _bodyTrackingKey = 'body_tracking';
const _reportDetailKey = 'report_detail';
const _clockFormatKey = 'clock_format';
const _experienceLevelKey = 'experience_level';
const _availableEquipmentKey = 'available_equipment';
const _progressionSuggestionsEnabledKey = 'progression_suggestions_enabled';

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
    this.showProgressCharts = true,
    this.colorPalette = AppColorPalette.pastel,
    this.bodyTracking = BodyTracking.notAsked,
    this.reportDetail = ReportDetail.brief,
    this.clockFormat = ClockFormat.system,
    this.experienceLevel = ExperienceLevel.intermediate,
    this.availableEquipment = const {},
    this.progressionSuggestionsEnabled = true,
  });

  /// Whether the body-measurement UI should be visible at all.
  bool get bodyTrackingEnabled => bodyTracking == BodyTracking.enabled;

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
    bool? showProgressCharts,
    AppColorPalette? colorPalette,
    BodyTracking? bodyTracking,
    ReportDetail? reportDetail,
    ClockFormat? clockFormat,
    ExperienceLevel? experienceLevel,
    Set<String>? availableEquipment,
    bool? progressionSuggestionsEnabled,
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
    showProgressCharts: showProgressCharts ?? this.showProgressCharts,
    colorPalette: colorPalette ?? this.colorPalette,
    bodyTracking: bodyTracking ?? this.bodyTracking,
    reportDetail: reportDetail ?? this.reportDetail,
    clockFormat: clockFormat ?? this.clockFormat,
    experienceLevel: experienceLevel ?? this.experienceLevel,
    availableEquipment: availableEquipment ?? this.availableEquipment,
    progressionSuggestionsEnabled:
        progressionSuggestionsEnabled ?? this.progressionSuggestionsEnabled,
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
}

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferences>(
      (ref) => AppPreferencesNotifier(),
    );
