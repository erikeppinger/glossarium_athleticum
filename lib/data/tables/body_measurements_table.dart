import 'package:drift/drift.dart';

/// One body-measurement entry for a given day - bodyweight plus optional
/// circumference measurements. Deliberately separate from [LoggedSets]:
/// this is about the trainee's body over time, not about an exercise's
/// performance, and it's recorded outside any session.
///
/// All lengths are stored in centimetres and weight in kilograms, matching
/// the rest of the app's storage convention (display conversion happens at
/// the UI boundary - see lib/logic/units.dart).
class BodyMeasurements extends Table {
  TextColumn get id => text()();

  /// Date-only (time component zeroed by the DAO) - at most one entry per
  /// day, so re-recording the same day updates rather than duplicates.
  DateTimeColumn get measuredAt => dateTime()();

  RealColumn get weightKg => real().nullable()();
  RealColumn get bodyFatPercent => real().nullable()();
  RealColumn get chestCm => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get hipsCm => real().nullable()();
  RealColumn get thighCm => real().nullable()();
  RealColumn get armCm => real().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
