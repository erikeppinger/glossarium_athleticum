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

  group('body tracking is opt-in', () {
    test('starts as not-asked and is therefore off', () {
      final notifier = AppPreferencesNotifier();
      expect(notifier.state.bodyTracking, BodyTracking.notAsked);
      expect(
        notifier.state.bodyTrackingEnabled,
        isFalse,
        reason: 'never on until explicitly asked for',
      );
    });

    test('a decline is remembered as distinct from never-asked', () async {
      final notifier = AppPreferencesNotifier();
      await notifier.setBodyTracking(BodyTracking.declined);

      final reloaded = AppPreferencesNotifier();
      await reloaded.load();
      expect(
        reloaded.state.bodyTracking,
        BodyTracking.declined,
        reason: 'so the prompt is never shown again after a no',
      );
      expect(reloaded.state.bodyTrackingEnabled, isFalse);
    });

    test('opting in persists and enables the feature', () async {
      final notifier = AppPreferencesNotifier();
      await notifier.setBodyTracking(BodyTracking.enabled);

      final reloaded = AppPreferencesNotifier();
      await reloaded.load();
      expect(reloaded.state.bodyTrackingEnabled, isTrue);
    });
  });

  group('experience level', () {
    test('defaults to intermediate, matching the old hardcoded behavior', () {
      final notifier = AppPreferencesNotifier();
      expect(notifier.state.experienceLevel, ExperienceLevel.intermediate);
    });

    test('setExperienceLevel updates state and persists', () async {
      final notifier = AppPreferencesNotifier();
      await notifier.setExperienceLevel(ExperienceLevel.advanced);
      expect(notifier.state.experienceLevel, ExperienceLevel.advanced);

      final reloaded = AppPreferencesNotifier();
      await reloaded.load();
      expect(reloaded.state.experienceLevel, ExperienceLevel.advanced);
    });
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
