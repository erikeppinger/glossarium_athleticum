// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get unitsAndDisplaySectionTitle => 'Einheiten & Anzeige';

  @override
  String get weightUnitTitle => 'Gewichtseinheit';

  @override
  String get weightUnitKg => 'Kilogramm (kg)';

  @override
  String get weightUnitLbs => 'Pfund (lbs)';

  @override
  String get themeTitle => 'Design';

  @override
  String get clockFormatTitle => 'Uhrzeitformat';

  @override
  String get colourPaletteTitle => 'Farbpalette';

  @override
  String get fitnessLevelTitle => 'Fitnesslevel';

  @override
  String fitnessLevelSubtitle(String level) {
    return '$level - fließt in die automatischen Trainingsvorschläge im Übungsverlauf ein.';
  }

  @override
  String get availableEquipmentTitle => 'Verfügbare Ausrüstung';

  @override
  String get availableEquipmentEmptySubtitle =>
      'Nur Körpergewicht - wird für den Filter \"Meine Ausrüstung\" in der Übungsbibliothek verwendet.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';
}
