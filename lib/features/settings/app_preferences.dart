import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logic/units.dart';

enum WeekStart { monday, sunday }

const _weightUnitKey = 'weight_unit';
const _weekStartKey = 'week_start';

class AppPreferences {
  final WeightUnit weightUnit;
  final WeekStart weekStart;

  const AppPreferences({
    this.weightUnit = WeightUnit.kg,
    this.weekStart = WeekStart.monday,
  });

  AppPreferences copyWith({WeightUnit? weightUnit, WeekStart? weekStart}) =>
      AppPreferences(
        weightUnit: weightUnit ?? this.weightUnit,
        weekStart: weekStart ?? this.weekStart,
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
}

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferences>(
      (ref) => AppPreferencesNotifier(),
    );
