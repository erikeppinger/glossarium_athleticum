import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/body_measurements_table.dart';

part 'body_measurement_dao.g.dart';

@DriftAccessor(tables: [BodyMeasurements])
class BodyMeasurementDao extends DatabaseAccessor<AppDatabase>
    with _$BodyMeasurementDaoMixin {
  BodyMeasurementDao(super.db);

  /// Newest first - what the history list and chart both want.
  Future<List<BodyMeasurement>> getAll() =>
      (select(bodyMeasurements)
            ..orderBy([(m) => OrderingTerm.desc(m.measuredAt)]))
          .get();

  Future<BodyMeasurement?> getForDay(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    return (select(
      bodyMeasurements,
    )..where((m) => m.measuredAt.equals(dayOnly))).getSingleOrNull();
  }

  /// One entry per day: recording twice on the same date replaces the
  /// earlier entry rather than stacking up duplicates a chart would have to
  /// disambiguate.
  Future<void> upsert({
    required String id,
    required DateTime measuredAt,
    double? weightKg,
    double? bodyFatPercent,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? thighCm,
    double? armCm,
    String notes = '',
  }) async {
    final dayOnly = DateTime(
      measuredAt.year,
      measuredAt.month,
      measuredAt.day,
    );
    final existing = await getForDay(dayOnly);
    await into(bodyMeasurements).insertOnConflictUpdate(
      BodyMeasurementsCompanion.insert(
        id: existing?.id ?? id,
        measuredAt: dayOnly,
        weightKg: Value(weightKg),
        bodyFatPercent: Value(bodyFatPercent),
        chestCm: Value(chestCm),
        waistCm: Value(waistCm),
        hipsCm: Value(hipsCm),
        thighCm: Value(thighCm),
        armCm: Value(armCm),
        notes: Value(notes),
      ),
    );
  }

  Future<void> deleteMeasurement(String id) =>
      (delete(bodyMeasurements)..where((m) => m.id.equals(id))).go();
}
