import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_app/features/settings/app_preferences.dart';
import 'package:training_app/logic/units.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to kg and Monday before load', () {
    final notifier = AppPreferencesNotifier();
    expect(notifier.state.weightUnit, WeightUnit.kg);
    expect(notifier.state.weekStart, WeekStart.monday);
  });

  test('setWeightUnit updates state and persists', () async {
    final notifier = AppPreferencesNotifier();
    await notifier.setWeightUnit(WeightUnit.lbs);
    expect(notifier.state.weightUnit, WeightUnit.lbs);

    final reloaded = AppPreferencesNotifier();
    await reloaded.load();
    expect(reloaded.state.weightUnit, WeightUnit.lbs);
  });

  test('setWeekStart updates state and persists', () async {
    final notifier = AppPreferencesNotifier();
    await notifier.setWeekStart(WeekStart.sunday);
    expect(notifier.state.weekStart, WeekStart.sunday);

    final reloaded = AppPreferencesNotifier();
    await reloaded.load();
    expect(reloaded.state.weekStart, WeekStart.sunday);
  });

  test('setSummaryPeriod updates state and persists', () async {
    final notifier = AppPreferencesNotifier();
    expect(notifier.state.summaryPeriod, SummaryPeriod.week);
    await notifier.setSummaryPeriod(SummaryPeriod.month);
    expect(notifier.state.summaryPeriod, SummaryPeriod.month);

    final reloaded = AppPreferencesNotifier();
    await reloaded.load();
    expect(reloaded.state.summaryPeriod, SummaryPeriod.month);
  });

  test('setThemeMode updates state and persists', () async {
    final notifier = AppPreferencesNotifier();
    expect(notifier.state.themeMode, ThemeMode.system);
    await notifier.setThemeMode(ThemeMode.dark);
    expect(notifier.state.themeMode, ThemeMode.dark);

    final reloaded = AppPreferencesNotifier();
    await reloaded.load();
    expect(reloaded.state.themeMode, ThemeMode.dark);
  });
}
