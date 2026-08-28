import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logic/summary_period.dart' show WeekStart, SummaryPeriod;
import '../../logic/units.dart';

export '../../logic/summary_period.dart' show WeekStart, SummaryPeriod;

const _weightUnitKey = 'weight_unit';
const _weekStartKey = 'week_start';
const _summaryPeriodKey = 'summary_period';
const _themeModeKey = 'theme_mode';

class AppPreferences {
  final WeightUnit weightUnit;
  final WeekStart weekStart;
  final SummaryPeriod summaryPeriod;
  final ThemeMode themeMode;

  const AppPreferences({
    this.weightUnit = WeightUnit.kg,
    this.weekStart = WeekStart.monday,
    this.summaryPeriod = SummaryPeriod.week,
    this.themeMode = ThemeMode.system,
  });

  AppPreferences copyWith({
    WeightUnit? weightUnit,
    WeekStart? weekStart,
    SummaryPeriod? summaryPeriod,
    ThemeMode? themeMode,
  }) => AppPreferences(
    weightUnit: weightUnit ?? this.weightUnit,
    weekStart: weekStart ?? this.weekStart,
    summaryPeriod: summaryPeriod ?? this.summaryPeriod,
    themeMode: themeMode ?? this.themeMode,
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
}

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferences>(
      (ref) => AppPreferencesNotifier(),
    );
