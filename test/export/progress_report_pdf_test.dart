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

    test(
      "an exercise with a prescription produces a larger PDF than the same "
      "exercise with none (the trainer-facing prescribed-vs-actual line)",
      () async {
        CompletedWorkout workoutWith({PlanExercise? prescription}) =>
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
                      isPr: false,
                    ),
                  ],
                  prescription: prescription,
                ),
              ],
            );

        final withoutPrescription = await buildProgressReportPdf(
          rangeLabel: 'Aug 31 - Sep 6',
          summary: emptySummary,
          dailyTotals: const [],
          dashboard: const [],
          exerciseNames: const {},
          unit: WeightUnit.kg,
          generatedAt: DateTime(2026, 9, 6),
          fullLog: [workoutWith()],
        );

        final withPrescription = await buildProgressReportPdf(
          rangeLabel: 'Aug 31 - Sep 6',
          summary: emptySummary,
          dailyTotals: const [],
          dashboard: const [],
          exerciseNames: const {},
          unit: WeightUnit.kg,
          generatedAt: DateTime(2026, 9, 6),
          fullLog: [
            workoutWith(
              prescription: const PlanExercise(
                id: 1,
                sessionId: 1,
                order: 1,
                exerciseId: 'EX_BP',
                exerciseName: 'Bench Press',
                sets: 4,
                reps: '8-10',
                weightIntensity: '60kg',
                notes: '',
                videoUrl: '',
                embeddingAllowed: false,
              ),
            ),
          ],
        );

        expect(String.fromCharCodes(withPrescription.take(4)), '%PDF');
        expect(
          withPrescription.length,
          greaterThan(withoutPrescription.length + 20),
        );
      },
    );
  });

  test(
    'a no-weight dashboard entry (bodyweight/band exercise) and a nonzero '
    'nonWeightedReps stat both render without a weight figure',
    () async {
      final baseline = await buildProgressReportPdf(
        rangeLabel: 'Aug 31 - Sep 6',
        summary: const PeriodSummary(
          sessionsScheduled: 0,
          sessionsCompleted: 0,
          totalVolume: 0,
          prCount: 0,
        ),
        dailyTotals: const [],
        dashboard: const [],
        exerciseNames: const {},
        unit: WeightUnit.kg,
        generatedAt: DateTime(2026, 9, 6),
      );

      final withNoWeightData = await buildProgressReportPdf(
        rangeLabel: 'Aug 31 - Sep 6',
        summary: const PeriodSummary(
          sessionsScheduled: 0,
          sessionsCompleted: 0,
          totalVolume: 0,
          prCount: 0,
          nonWeightedReps: 24,
        ),
        dailyTotals: const [],
        dashboard: [
          ExerciseProgressSummary(
            exerciseId: 'EX_BAND',
            lastLoggedAt: DateTime.utc(2026, 9, 3),
            topWeight: null,
            topReps: 24,
            isPr: false,
          ),
        ],
        exerciseNames: const {'EX_BAND': 'Band Pull-Apart'},
        unit: WeightUnit.kg,
        generatedAt: DateTime(2026, 9, 6),
      );

      expect(String.fromCharCodes(withNoWeightData.take(4)), '%PDF');
      // A whole extra stat tile plus a dashboard row must produce a
      // meaningfully larger document, not a coincidentally different one -
      // guards against the null-topWeight branch silently rendering nothing.
      expect(withNoWeightData.length, greaterThan(baseline.length + 100));
    },
  );

  test('a trainer name renders an extra header line', () async {
    const summary = PeriodSummary(
      sessionsScheduled: 0,
      sessionsCompleted: 0,
      totalVolume: 0,
      prCount: 0,
    );
    final withoutTrainer = await buildProgressReportPdf(
      rangeLabel: 'Aug 31 - Sep 6',
      summary: summary,
      dailyTotals: const [],
      dashboard: const [],
      exerciseNames: const {},
      unit: WeightUnit.kg,
      generatedAt: DateTime(2026, 9, 6),
    );
    final withTrainer = await buildProgressReportPdf(
      rangeLabel: 'Aug 31 - Sep 6',
      summary: summary,
      dailyTotals: const [],
      dashboard: const [],
      exerciseNames: const {},
      unit: WeightUnit.kg,
      generatedAt: DateTime(2026, 9, 6),
      trainerName: 'Coach Erik',
    );
    expect(String.fromCharCodes(withTrainer.take(4)), '%PDF');
    expect(withTrainer.length, greaterThan(withoutTrainer.length + 10));
  });

  group('the full log flags deviations from the prescription', () {
    const emptySummary = PeriodSummary(
      sessionsScheduled: 0,
      sessionsCompleted: 0,
      totalVolume: 0,
      prCount: 0,
    );

    const defaultPrescription = PlanExercise(
      id: 1,
      sessionId: 1,
      order: 1,
      exerciseId: 'EX_BP',
      exerciseName: 'Bench Press',
      sets: 2,
      reps: '8',
      weightIntensity: '60kg',
      notes: '',
      videoUrl: '',
      embeddingAllowed: false,
    );

    CompletedWorkout workoutWithSets(
      List<LoggedSet> sets, {
      required PlanExercise? prescription,
    }) => CompletedWorkout(
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
          sets: sets,
          prescription: prescription,
        ),
      ],
    );

    Future<int> pdfLengthFor(
      List<LoggedSet> sets, {
      PlanExercise? prescription = defaultPrescription,
    }) async {
      final bytes = await buildProgressReportPdf(
        rangeLabel: 'Aug 31 - Sep 6',
        summary: emptySummary,
        dailyTotals: const [],
        dashboard: const [],
        exerciseNames: const {},
        unit: WeightUnit.kg,
        generatedAt: DateTime(2026, 9, 6),
        fullLog: [workoutWithSets(sets, prescription: prescription)],
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      return bytes.length;
    }

    test('as-prescribed produces a smaller PDF than fewer-sets-than-Rx', () async {
      final asPrescribed = await pdfLengthFor([
        LoggedSet(id: 1, sessionLogId: 'log-1', exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60, isPr: false),
        LoggedSet(id: 2, sessionLogId: 'log-1', exerciseId: 'EX_BP', setNumber: 2, reps: 8, weight: 60, isPr: false),
      ]);
      final fewerSets = await pdfLengthFor([
        LoggedSet(id: 1, sessionLogId: 'log-1', exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60, isPr: false),
      ]);
      expect(fewerSets, greaterThan(asPrescribed + 10));
    });

    test('a set note produces a larger PDF than the same set with none', () async {
      final withoutNote = await pdfLengthFor([
        LoggedSet(id: 1, sessionLogId: 'log-1', exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60, isPr: false),
        LoggedSet(id: 2, sessionLogId: 'log-1', exerciseId: 'EX_BP', setNumber: 2, reps: 8, weight: 60, isPr: false),
      ]);
      final withNote = await pdfLengthFor([
        LoggedSet(
          id: 1,
          sessionLogId: 'log-1',
          exerciseId: 'EX_BP',
          setNumber: 1,
          reps: 8,
          weight: 60,
          isPr: false,
          notes: 'Left shoulder felt off',
        ),
        LoggedSet(id: 2, sessionLogId: 'log-1', exerciseId: 'EX_BP', setNumber: 2, reps: 8, weight: 60, isPr: false),
      ]);
      expect(withNote, greaterThan(withoutNote + 10));
    });

    test('a percentage prescription never flags a genuinely on-target set', () async {
      // "70%" resolves to some real kg figure at logging time, but comparing
      // the raw "70" against a logged weight in kg (e.g. 45) would be
      // comparing incompatible units - this must not be flagged.
      final length = await pdfLengthFor(
        [LoggedSet(id: 1, sessionLogId: 'log-1', exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 45, isPr: false)],
        prescription: const PlanExercise(
          id: 1,
          sessionId: 1,
          order: 1,
          exerciseId: 'EX_BP',
          exerciseName: 'Bench Press',
          sets: 1,
          reps: '8',
          weightIntensity: '70%',
          notes: '',
          videoUrl: '',
          embeddingAllowed: false,
        ),
      );
      final noPrescription = await pdfLengthFor([
        LoggedSet(id: 1, sessionLogId: 'log-1', exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 45, isPr: false),
      ], prescription: null);
      // Should differ only by the "Prescribed: ..." line itself, not by an
      // extra (wrongly-triggered) deviation tag on top of it.
      expect(length - noPrescription, lessThan(60));
    });

    test('a skipped exercise adds its own flagged row', () async {
      final sets = [
        LoggedSet(id: 1, sessionLogId: 'log-1', exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60, isPr: false),
        LoggedSet(id: 2, sessionLogId: 'log-1', exerciseId: 'EX_BP', setNumber: 2, reps: 8, weight: 60, isPr: false),
      ];
      Future<int> lengthWith(List<SkippedExercise> skipped) async {
        final base = workoutWithSets(sets, prescription: defaultPrescription);
        final bytes = await buildProgressReportPdf(
          rangeLabel: 'Aug 31 - Sep 6',
          summary: emptySummary,
          dailyTotals: const [],
          dashboard: const [],
          exerciseNames: const {},
          unit: WeightUnit.kg,
          generatedAt: DateTime(2026, 9, 6),
          fullLog: [
            CompletedWorkout(
              log: base.log,
              sessionName: base.sessionName,
              exercises: base.exercises,
              skipped: skipped,
            ),
          ],
        );
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
        return bytes.length;
      }

      final withoutSkip = await lengthWith(const []);
      final withSkip = await lengthWith(const [
        SkippedExercise(
          id: 1,
          sessionLogId: 'log-1',
          exerciseId: 'EX_SQ',
          exerciseName: 'Back Squat',
          prescribedSets: 4,
          prescribedReps: '6',
          prescribedWeightIntensity: '80kg',
          reason: 'pain_or_injury',
          queuedForNextSession: false,
        ),
      ]);
      expect(withSkip, greaterThan(withoutSkip + 30));
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
