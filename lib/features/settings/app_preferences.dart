import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logic/muscle_group_colors.dart' show AppColorPalette;
import '../../logic/summary_period.dart' show WeekStart, SummaryPeriod;
import '../../logic/units.dart';

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
  });

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
}

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferences>(
      (ref) => AppPreferencesNotifier(),
    );
