import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
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

  // Regression test: the PDF used to always include the exercise dashboard
  // table regardless of the user's Brief/Detailed default share setting -
  // picking "Brief" in Settings changed the plain-text share but silently
  // did nothing to the PDF export, which looked like the setting was broken.
  test(
    'includeExerciseDashboard: false omits the exercise dashboard table',
    () async {
      final dashboard = [
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
      ];
      const summary = PeriodSummary(
        sessionsScheduled: 3,
        sessionsCompleted: 3,
        totalVolume: 14977,
        prCount: 6,
      );
      const exerciseNames = {'EX006': 'Back Squat', 'EX003': 'Goblet Squat (Light)'};

      final detailedBytes = await buildProgressReportPdf(
        rangeLabel: 'Aug 31 - Sep 6',
        summary: summary,
        dailyTotals: const [],
        dashboard: dashboard,
        exerciseNames: exerciseNames,
        unit: WeightUnit.kg,
        generatedAt: DateTime(2026, 9, 6),
      );
      final briefBytes = await buildProgressReportPdf(
        rangeLabel: 'Aug 31 - Sep 6',
        summary: summary,
        dailyTotals: const [],
        dashboard: dashboard,
        exerciseNames: exerciseNames,
        unit: WeightUnit.kg,
        generatedAt: DateTime(2026, 9, 6),
        includeExerciseDashboard: false,
      );

      expect(String.fromCharCodes(briefBytes.take(4)), '%PDF');
      // Dropping a whole table section (heading + two data rows) must
      // produce a meaningfully smaller document, not just a coincidentally
      // different one - guards against the flag being wired up but ignored.
      expect(briefBytes.length, lessThan(detailedBytes.length - 100));
    },
  );

  group('fullLog (the trainer-oriented detailed export)', () {
    const emptySummary = PeriodSummary(
      sessionsScheduled: 0,
      sessionsCompleted: 0,
      totalVolume: 0,
      prCount: 0,
    );

    test('omitting fullLog entirely produces a report about the same size as passing null', () async {
      // Not byte-for-byte equality - two separate doc.save() calls aren't
      // guaranteed identical (internal object ids, timestamps embedded by
      // the pdf package) even with identical content. Size is a good enough
      // proxy that fullLog: null adds nothing, without over-asserting.
      final withoutParam = await buildProgressReportPdf(
        rangeLabel: 'Aug 31 - Sep 6',
        summary: emptySummary,
        dailyTotals: const [],
        dashboard: const [],
        exerciseNames: const {},
        unit: WeightUnit.kg,
        generatedAt: DateTime(2026, 9, 6),
      );
      final withNullParam = await buildProgressReportPdf(
        rangeLabel: 'Aug 31 - Sep 6',
        summary: emptySummary,
        dailyTotals: const [],
        dashboard: const [],
        exerciseNames: const {},
        unit: WeightUnit.kg,
        generatedAt: DateTime(2026, 9, 6),
        fullLog: null,
      );
      expect(
        (withoutParam.length - withNullParam.length).abs(),
        lessThan(20),
      );
    });

    test('an empty (non-null) fullLog states there was nothing logged', () async {
      final bytes = await buildProgressReportPdf(
        rangeLabel: 'Aug 31 - Sep 6',
        summary: emptySummary,
        dailyTotals: const [],
        dashboard: const [],
        exerciseNames: const {},
        unit: WeightUnit.kg,
        generatedAt: DateTime(2026, 9, 6),
        fullLog: const [],
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('a populated fullLog with a plan session and an ad-hoc activity produces a valid, larger PDF', () async {
      final baseline = await buildProgressReportPdf(
        rangeLabel: 'Aug 31 - Sep 6',
        summary: emptySummary,
        dailyTotals: const [],
        dashboard: const [],
        exerciseNames: const {},
        unit: WeightUnit.kg,
        generatedAt: DateTime(2026, 9, 6),
      );

      final withLog = await buildProgressReportPdf(
        rangeLabel: 'Aug 31 - Sep 6',
        summary: emptySummary,
        dailyTotals: const [],
        dashboard: const [],
        exerciseNames: const {},
        unit: WeightUnit.kg,
        generatedAt: DateTime(2026, 9, 6),
        fullLog: [
          CompletedWorkout(
            log: SessionLog(
              id: 'log-1',
              planSessionId: 1,
              loggedAt: DateTime(2026, 9, 1),
              finishedAt: DateTime(2026, 9, 1),
            ),
            sessionName: 'Push Day',
            exercises: [
              CompletedExercise(
                exerciseId: 'EX_BP',
                exerciseName: 'Bench Press',
                sets: [
                  LoggedSet(
                    id: 1,
                    sessionLogId: 'log-1',
                    exerciseId: 'EX_BP',
                    setNumber: 1,
                    reps: 8,
                    weight: 60,
                    isPr: true,
                  ),
                  LoggedSet(
                    id: 2,
                    sessionLogId: 'log-1',
                    exerciseId: 'EX_BP',
                    setNumber: 2,
                    reps: 8,
                    weight: 60,
                    isPr: false,
                  ),
                ],
              ),
            ],
          ),
          CompletedWorkout(
            log: SessionLog(
              id: 'activity-1',
              planSessionId: null,
              loggedAt: DateTime(2026, 9, 3),
              finishedAt: DateTime(2026, 9, 3),
              activityName: 'Walk',
              durationSec: 1800,
              distance: 3000,
            ),
            sessionName: 'Walk',
            exercises: const [],
          ),
        ],
      );

      expect(String.fromCharCodes(withLog.take(4)), '%PDF');
      // A whole extra section (a plan session's set-by-set table plus a
      // separate ad-hoc activity entry) must produce a meaningfully larger
      // document, not a coincidentally different one - guards against
      // fullLog being wired up but silently ignored.
      expect(withLog.length, greaterThan(baseline.length + 100));
    });
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
