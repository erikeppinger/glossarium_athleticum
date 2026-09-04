// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get unitsAndDisplaySectionTitle => 'Units & display';

  @override
  String get weightUnitTitle => 'Weight unit';

  @override
  String get weightUnitKg => 'Kilograms (kg)';

  @override
  String get weightUnitLbs => 'Pounds (lbs)';

  @override
  String get themeTitle => 'Theme';

  @override
  String get clockFormatTitle => 'Clock format';

  @override
  String get colourPaletteTitle => 'Colour palette';

  @override
  String get fitnessLevelTitle => 'Fitness level';

  @override
  String fitnessLevelSubtitle(String level) {
    return '$level - feeds auto-progression suggestions in exercise history.';
  }

  @override
  String get availableEquipmentTitle => 'Available equipment';

  @override
  String get availableEquipmentEmptySubtitle =>
      'Bodyweight only - feeds the Exercise Library\'s \"My equipment\" filter.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';
}
