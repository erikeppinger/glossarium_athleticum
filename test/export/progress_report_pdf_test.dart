import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/export/progress_report_pdf.dart';
import 'package:training_app/logic/units.dart';

void main() {
  const emptySummary = PeriodSummary(
    sessionsScheduled: 0,
    sessionsCompleted: 0,
    totalVolume: 0,
    prCount: 0,
  );

  test('an empty period still produces a valid, non-empty PDF', () async {
    final bytes = await buildProgressReportPdf(
      rangeLabel: 'Aug 31 - Sep 6',
      summary: emptySummary,
      dailyTotals: const [],
      dashboard: const [],
      exerciseNames: const {},
      unit: WeightUnit.kg,
      generatedAt: DateTime(2026, 9, 6),
    );

    expect(bytes, isNotEmpty);
    // %PDF is the standard PDF file signature.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('a populated period with a chart and exercise table produces a valid PDF', () async {
    final bytes = await buildProgressReportPdf(
      rangeLabel: 'Aug 31 - Sep 6',
      summary: const PeriodSummary(
        sessionsScheduled: 3,
        sessionsCompleted: 3,
        totalVolume: 14977,
        prCount: 6,
        adHocActivityCount: 2,
        adHocDurationSec: 3000,
        adHocDistanceMeters: 8000,
      ),
      dailyTotals: [
        DailyTotals(
          day: DateTime(2026, 8, 31),
          volume: 5000,
          sets: 10,
          reps: 80,
          prs: 3,
          sessions: 1,
        ),
        DailyTotals(
          day: DateTime(2026, 9, 3),
          volume: 9977,
          sets: 15,
          reps: 120,
          prs: 3,
          sessions: 1,
        ),
      ],
      dashboard: [
        ExerciseProgressSummary(
          exerciseId: 'EX006',
          lastLoggedAt: DateTime.utc(2026, 9, 3),
          topWeight: 110,
          topReps: 8,
          isPr: true,
        ),
        ExerciseProgressSummary(
          exerciseId: 'EX003',
          lastLoggedAt: DateTime.utc(2026, 8, 31),
          topWeight: 22,
          topReps: 10,
          isPr: false,
        ),
      ],
      exerciseNames: const {'EX006': 'Back Squat', 'EX003': 'Goblet Squat (Light)'},
      unit: WeightUnit.kg,
      weightChange: (deltaKg: -1.0, currentKg: 79.0, baselineDate: DateTime(2026, 8, 1)),
      generatedAt: DateTime(2026, 9, 6),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('many exercises (forcing a multi-page table) still produces a valid PDF', () async {
    final dashboard = [
      for (var i = 0; i < 60; i++)
        ExerciseProgressSummary(
          exerciseId: 'EX$i',
          lastLoggedAt: DateTime.utc(2026, 9, 1),
          topWeight: 50.0 + i,
          topReps: 8,
          isPr: i % 10 == 0,
        ),
    ];

    final bytes = await buildProgressReportPdf(
      rangeLabel: 'September 2026',
      summary: const PeriodSummary(
        sessionsScheduled: 20,
        sessionsCompleted: 18,
        totalVolume: 200000,
        prCount: 6,
      ),
      dailyTotals: const [],
      dashboard: dashboard,
      exerciseNames: {for (var i = 0; i < 60; i++) 'EX$i': 'Exercise $i'},
      unit: WeightUnit.lbs,
      generatedAt: DateTime(2026, 9, 30),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
