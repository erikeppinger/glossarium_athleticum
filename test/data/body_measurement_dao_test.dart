import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('upsert then getAll round-trips', () async {
    await db.bodyMeasurementDao.upsert(
      id: 'm1',
      measuredAt: DateTime(2026, 8, 20),
      weightKg: 82.5,
      waistCm: 88,
      notes: 'Morning, fasted',
    );

    final all = await db.bodyMeasurementDao.getAll();
    expect(all, hasLength(1));
    expect(all.single.weightKg, 82.5);
    expect(all.single.waistCm, 88);
    expect(all.single.notes, 'Morning, fasted');
  });

  test('the time component is zeroed so a day has one canonical key', () async {
    await db.bodyMeasurementDao.upsert(
      id: 'm1',
      measuredAt: DateTime(2026, 8, 20, 14, 37),
      weightKg: 82.5,
    );
    final all = await db.bodyMeasurementDao.getAll();
    expect(all.single.measuredAt, DateTime(2026, 8, 20));
  });

  test('recording twice on the same day updates rather than duplicating', () async {
    await db.bodyMeasurementDao.upsert(
      id: 'm1',
      measuredAt: DateTime(2026, 8, 20, 7),
      weightKg: 82.5,
    );
    await db.bodyMeasurementDao.upsert(
      id: 'm2', // a different id, but the same day
      measuredAt: DateTime(2026, 8, 20, 19),
      weightKg: 83.1,
    );

    final all = await db.bodyMeasurementDao.getAll();
    expect(all, hasLength(1));
    expect(all.single.weightKg, 83.1);
    expect(
      all.single.id,
      'm1',
      reason: "the original day's row is updated, keeping its id",
    );
  });

  test('different days coexist, newest first', () async {
    await db.bodyMeasurementDao.upsert(
      id: 'm1',
      measuredAt: DateTime(2026, 8, 20),
      weightKg: 82.5,
    );
    await db.bodyMeasurementDao.upsert(
      id: 'm2',
      measuredAt: DateTime(2026, 8, 27),
      weightKg: 82.0,
    );

    final all = await db.bodyMeasurementDao.getAll();
    expect(all.map((m) => m.id), ['m2', 'm1']);
  });

  test('getForDay ignores the time component', () async {
    await db.bodyMeasurementDao.upsert(
      id: 'm1',
      measuredAt: DateTime(2026, 8, 20),
      weightKg: 82.5,
    );
    expect(
      await db.bodyMeasurementDao.getForDay(DateTime(2026, 8, 20, 22, 15)),
      isNotNull,
    );
    expect(
      await db.bodyMeasurementDao.getForDay(DateTime(2026, 8, 21)),
      isNull,
    );
  });

  test('deleteMeasurement removes just that entry', () async {
    await db.bodyMeasurementDao.upsert(
      id: 'm1',
      measuredAt: DateTime(2026, 8, 20),
      weightKg: 82.5,
    );
    await db.bodyMeasurementDao.upsert(
      id: 'm2',
      measuredAt: DateTime(2026, 8, 21),
      weightKg: 82.0,
    );

    await db.bodyMeasurementDao.deleteMeasurement('m1');
    final all = await db.bodyMeasurementDao.getAll();
    expect(all.map((m) => m.id), ['m2']);
  });

  test('wipeAllData clears measurements too', () async {
    await db.bodyMeasurementDao.upsert(
      id: 'm1',
      measuredAt: DateTime(2026, 8, 20),
      weightKg: 82.5,
    );
    await db.maintenanceDao.wipeAllData();
    expect(await db.bodyMeasurementDao.getAll(), isEmpty);
  });
}
