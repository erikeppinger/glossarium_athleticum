import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/app_database.dart' show LoggedSet, PlanExercise;
import '../data/daos/session_log_dao.dart';
import '../logic/body_weight_trend.dart';
import '../logic/chart_axis.dart';
import '../logic/rx_deviation.dart';
import '../logic/set_measure.dart';
import '../logic/units.dart';

/// Builds the "hand this to a coach" PDF version of the Progress tab's
/// summary: header, summary stats, a volume-over-time chart, and (when
/// [includeExerciseDashboard] is true) the exercise dashboard as a real
/// table - the same Brief/Detailed split the plain-text share already has
/// (see `progress_screen.dart`'s `_buildShareText`), so picking "Brief" as
/// the default share detail in Settings affects the PDF export the same way
/// it affects the plain-text one, instead of the PDF always showing
/// everything regardless of that preference. Deliberately excludes
/// everything else on the Progress screen (the sets/reps/PRs mini-charts, a
/// calendar view, per-exercise history) to stay a fast, uncluttered read.
///
/// Pure data in, bytes out - no DB/Riverpod/widget-tree dependency, matching
/// this project's `lib/logic/`/`lib/export/` convention of keeping business
/// logic testable without a widget tree. [generatedAt] is a parameter (not
/// read from `DateTime.now()` internally) purely so tests can pin it.
Future<Uint8List> buildProgressReportPdf({
  required String rangeLabel,
  required PeriodSummary summary,
  required List<DailyTotals> dailyTotals,
  required List<ExerciseProgressSummary> dashboard,
  required Map<String, String> exerciseNames,
  required WeightUnit unit,
  BodyWeightChange? weightChange,
  DateTime? generatedAt,
  bool includeExerciseDashboard = true,
  // The "hand this to a trainer" counterpart to [dashboard]'s top-set-only
  // table: every workout in the period with its full set-by-set breakdown
  // (and every ad-hoc activity individually, not just its aggregate count in
  // [_summaryStats]). Null/empty renders nothing extra - the existing
  // summary report is unaffected when a caller never passes this.
  List<CompletedWorkout>? fullLog,
  // Who the plan(s) behind [fullLog] were created by (e.g. a trainer's own
  // name - see `Plans.createdBy`) - shown in the header when the caller can
  // confidently attribute the whole report to one person. Left for the
  // caller to resolve (typically "the one non-null value shared by every
  // workout in range, or null if the range mixes plans/trainers or has
  // none") rather than decided here, since that's a policy call about
  // multi-plan reports, not something this pure PDF builder should guess at.
  String? trainerName,
}) async {
  final doc = pw.Document();
  final now = generatedAt ?? DateTime.now();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        _header(rangeLabel, now, trainerName),
        pw.SizedBox(height: 18),
        _summaryStats(summary, unit, weightChange),
        pw.SizedBox(height: 24),
        if (dailyTotals.isNotEmpty) ...[
          _volumeChart(dailyTotals, unit),
          pw.SizedBox(height: 24),
        ],
        // The heading and the table are separate top-level MultiPage
        // children, not nested together in one Column, so the table can be
        // split across pages on its own (a pw.Table is page-break-aware as
        // a direct MultiPage child; wrapped inside another layout widget it
        // isn't, and a long dashboard would blow past the page-count guard
        // instead of paginating cleanly - found via a 60-exercise test).
        if (includeExerciseDashboard) ...[
          pw.Text(
            'Exercise dashboard',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (dashboard.isEmpty)
            pw.Text(
              'No logged sets yet.',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            )
          else
            _exerciseTable(dashboard, exerciseNames, unit),
        ],
        if (fullLog != null && fullLog.isNotEmpty) ...[
          pw.Text(
            'Full training log',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Flagged rows (colored) differ from what was prescribed - '
            'fewer sets, under target, a near-failure effort, a skipped '
            'exercise, or a note from the trainee. Everything else went as '
            'planned.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          // A single Table, one row per exercise (or per ad-hoc activity) -
          // not one bordered Container per workout. A Table is the one
          // widget in this package that's page-break-aware as a direct
          // MultiPage child (see the exercise-dashboard table above): a
          // Container/Column holding a whole multi-exercise workout doesn't
          // get that treatment and can split mid-exercise, with its border
          // left open on one side - confirmed live on a real multi-page
          // export. Visual grouping into "workouts" comes from an alternating
          // light background per workout and the session header appearing
          // once per group, not from a border around the whole thing.
          _fullLogTable(fullLog, unit),
        ] else if (fullLog != null)
          pw.Text(
            'Nothing logged in this period.',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
      ],
    ),
  );

  return doc.save();
}

/// `formatWeightChange`'s ↓/↑ glyphs have no Unicode coverage in the pdf
/// package's default built-in font (confirmed via a "no font to draw ↓"
/// warning when this used the shared formatter as-is) - swapped for plain
/// words here rather than bundling a whole extra font asset just for two
/// glyphs. The Flutter-side callers of formatWeightChange are unaffected;
/// this only touches the PDF's own rendering.
String _pdfSafeWeightChange(BodyWeightChange change, WeightUnit unit) {
  return formatWeightChange(
    change,
    unit,
  ).replaceFirst('↓', 'Down ').replaceFirst('↑', 'Up ');
}

pw.Widget _header(String rangeLabel, DateTime generatedAt, String? trainerName) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Training Progress',
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(rangeLabel, style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
      if (trainerName != null && trainerName.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          'Plan by $trainerName',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
      pw.SizedBox(height: 2),
      pw.Text(
        'Generated ${DateFormat.yMMMd().add_jm().format(generatedAt)}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      ),
      pw.SizedBox(height: 10),
      pw.Divider(color: PdfColors.grey400, thickness: 0.75),
    ],
  );
}

pw.Widget _summaryStats(
  PeriodSummary summary,
  WeightUnit unit,
  BodyWeightChange? weightChange,
) {
  final stats = <(String, String)>[
    // "Scheduled", not "Sessions" - this is completed-of-scheduled
    // (adherence), matching the same relabel on the in-app card and share
    // text - see progress_screen.dart's comment on why.
    ('Scheduled', '${summary.sessionsCompleted}/${summary.sessionsScheduled}'),
    ('Volume', formatWeightInUnit(summary.totalVolume, unit)),
    ('PRs', '${summary.prCount}'),
    if (weightChange != null)
      ('Bodyweight', _pdfSafeWeightChange(weightChange, unit)),
    if (summary.adHocActivityCount > 0) ...[
      ('Activities', '${summary.adHocActivityCount}'),
      if (summary.adHocDurationSec > 0)
        ('Active time', formatDurationSec(summary.adHocDurationSec)),
      if (summary.adHocDistanceMeters > 0)
        ('Distance', formatDistanceMeters(summary.adHocDistanceMeters)),
    ],
    if (summary.nonWeightedReps > 0)
      ('Bodyweight reps', '${summary.nonWeightedReps}'),
  ];

  return pw.Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final (label, value) in stats)
        pw.Container(
          width: 130,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                value,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ),
    ],
  );
}

pw.Widget _volumeChart(List<DailyTotals> dailyTotals, WeightUnit unit) {
  const chartHeight = 110.0;
  const labelHeight = 12.0;
  const barAreaHeight = chartHeight - labelHeight;
  final values = [for (final t in dailyTotals) kgToDisplay(t.volume, unit)];
  final maxValue = values.reduce((a, b) => a > b ? a : b);
  final axis = niceAxis(maxValue);
  // Only label a handful of bars - one label per bar overlaps into an
  // unreadable smear on a full month, same fix as the in-app chart.
  final labelStep = (dailyTotals.length / 6).ceil();
  // Gridline values from the top down (axis.max, axis.max - interval, ...,
  // 0), matching the in-app chart's left-hand axis labels rather than
  // leaving the bars with no absolute scale reference at all.
  final gridLines = <double>[
    for (var v = axis.max; v > 0; v -= axis.interval) v,
    0,
  ];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Volume (${unit == WeightUnit.lbs ? 'lbs' : 'kg'})',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 8),
      pw.SizedBox(
        height: chartHeight,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 28,
              height: barAreaHeight,
              child: pw.Stack(
                children: [
                  for (final line in gridLines)
                    pw.Positioned(
                      top: axis.max <= 0
                          ? barAreaHeight
                          : barAreaHeight - (line / axis.max) * barAreaHeight,
                      child: pw.Transform.translate(
                        offset: const PdfPoint(0, -4),
                        child: pw.Text(
                          _formatAxisValue(line),
                          style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < dailyTotals.length; i++)
                    pw.Expanded(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Container(
                            height: axis.max <= 0
                                ? 0
                                : (values[i] / axis.max) * barAreaHeight,
                            margin: const pw.EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.indigo400,
                              borderRadius: const pw.BorderRadius.vertical(
                                top: pw.Radius.circular(2),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.SizedBox(
                            height: labelHeight - 2,
                            child: i % labelStep == 0
                                ? pw.Text(
                                    DateFormat.Md().format(dailyTotals[i].day),
                                    style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// "10K"/"8K"-style compact axis labels, matching the in-app chart's
/// `_MetricChart` formatting.
String _formatAxisValue(double value) {
  if (value >= 1000) {
    final thousands = value / 1000;
    return '${thousands == thousands.roundToDouble() ? thousands.toStringAsFixed(0) : thousands.toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(0);
}

/// Returns the bare table (no heading) - it must be a direct MultiPage
/// child, not nested inside another layout widget, or its per-row
/// page-splitting doesn't kick in (see the comment where this is called).
pw.Widget _exerciseTable(
  List<ExerciseProgressSummary> dashboard,
  Map<String, String> exerciseNames,
  WeightUnit unit,
) {
  return pw.Table(
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    ),
    columnWidths: const {
      0: pw.FlexColumnWidth(3),
      1: pw.FlexColumnWidth(2),
      2: pw.FlexColumnWidth(2),
      3: pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _cell('Exercise', bold: true),
          _cell('Top set', bold: true),
          _cell('Date', bold: true),
          _cell('PR', bold: true),
        ],
      ),
      for (final entry in dashboard)
        pw.TableRow(
          children: [
            _cell(exerciseNames[entry.exerciseId] ?? entry.exerciseId),
            _cell(_topSetLabel(entry, unit)),
            _cell(DateFormat.yMMMd().format(entry.lastLoggedAt)),
            _cell(
              entry.isPr ? 'PR' : '',
              bold: entry.isPr,
              color: entry.isPr ? PdfColors.amber800 : null,
            ),
          ],
        ),
    ],
  );
}

/// The "Full training log" section - one [pw.Table] with one row per
/// exercise (or per ad-hoc activity), grouped visually into workouts via an
/// alternating light background and a header shown once per group, rather
/// than one bordered [pw.Container] per workout (see the call site's own
/// comment for why a Container-based card could split mid-exercise across a
/// page boundary with its border left open on one side).
pw.Widget _fullLogTable(List<CompletedWorkout> fullLog, WeightUnit unit) {
  final rows = <pw.TableRow>[];
  for (var w = 0; w < fullLog.length; w++) {
    final workout = fullLog[w];
    final background = w.isEven ? PdfColors.white : PdfColors.grey50;
    final log = workout.log;
    final detailParts = <String>[
      if (log.durationSec != null) formatDurationSec(log.durationSec!),
      if (log.distance != null) formatDistanceMeters(log.distance!),
    ];

    if (workout.exercises.isEmpty) {
      // An ad-hoc activity (or, in principle, an empty plan session) has no
      // per-exercise rows to fan out into - one row for the whole thing.
      rows.add(
        _logRow(background, [
          _workoutHeader(workout.sessionName, log.loggedAt),
          if (detailParts.isNotEmpty)
            pw.Text(
              detailParts.join(', '),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (log.notes != null && log.notes!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                log.notes!,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ),
        ]),
      );
      continue;
    }

    for (var e = 0; e < workout.exercises.length; e++) {
      final exercise = workout.exercises[e];
      final setNote = exercise.sets
          .map((s) => s.notes)
          .firstWhere((n) => n != null && n.isNotEmpty, orElse: () => null);
      final deviations = computeRxDeviations(
        prescription: exercise.prescription,
        actual: exercise.sets,
        noteText: setNote,
      );

      rows.add(
        _logRow(background, [
          // The workout header (and its own whole-session note, if any)
          // only appears once, above the first exercise in the group.
          if (e == 0) ...[
            _workoutHeader(workout.sessionName, log.loggedAt),
            if (log.notes != null && log.notes!.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  log.notes!,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            pw.SizedBox(height: 4),
          ],
          pw.Text(
            exercise.exerciseName,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          // What the plan actually called for, directly above what was
          // logged - the point of a trainer-facing report is seeing
          // prescribed vs. actual together, not hunting up the plan
          // separately. Absent for an exercise added mid-session with no
          // template row to compare against (see getCompletedWorkout's own
          // doc comment).
          if (exercise.prescription != null)
            pw.Text(
              'Prescribed: ${_formatPrescription(exercise.prescription!)}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          if (exercise.substituteFor != null)
            pw.Text(
              'In place of ${exercise.substituteFor}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          pw.Text(
            [for (final set in exercise.sets) _formatLoggedSet(set, unit)].join(',   '),
            style: const pw.TextStyle(fontSize: 9),
          ),
          for (final deviation in deviations)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: _deviationTag(deviation),
            ),
        ]),
      );
    }

    // Prescribed exercises that weren't done at all - after the logged
    // ones, so the session reads in the order it was actually trained.
    for (final skip in workout.skipped) {
      rows.add(
        _logRow(background, [
          pw.Text(
            skip.exerciseName,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Prescribed: ${skip.prescribedSets}×${skip.prescribedReps}'
            '${skip.prescribedWeightIntensity.isEmpty ? '' : ' @ ${skip.prescribedWeightIntensity}'}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Not done',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: _deviationTag(
              skippedDeviation(
                reasonKey: skip.reason,
                replacedByName: skip.replacedByExerciseName,
              ),
            ),
          ),
        ]),
      );
    }
  }

  return pw.Table(
    columnWidths: const {0: pw.FlexColumnWidth(1)},
    children: rows,
  );
}

pw.TableRow _logRow(PdfColor background, List<pw.Widget> children) {
  return pw.TableRow(
    decoration: pw.BoxDecoration(color: background),
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children),
      ),
    ],
  );
}

pw.Widget _workoutHeader(String sessionName, DateTime loggedAt) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        sessionName,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        DateFormat.yMMMd().format(loggedAt),
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    ],
  );
}

/// A small colored label calling out one way an exercise's actual sets
/// differ from what was prescribed (or a trainee's own note) - the point is
/// letting a trainer's eye jump straight to these across a long report,
/// rather than reading every prescribed/actual line pair to spot a
/// difference. Nothing renders at all for an exercise that matches its
/// prescription - see `computeRxDeviations`' own doc comment.
pw.Widget _deviationTag(RxDeviation deviation) {
  final (background, foreground) = switch (deviation.kind) {
    RxDeviationKind.hasNote => (PdfColors.blue50, PdfColors.blue900),
    RxDeviationKind.nearFailure ||
    RxDeviationKind.skippedForPain => (PdfColors.red50, PdfColors.red900),
    RxDeviationKind.fewerSets ||
    RxDeviationKind.belowTarget ||
    RxDeviationKind.skipped => (PdfColors.orange50, PdfColors.orange900),
  };
  final label = deviation.kind == RxDeviationKind.hasNote
      ? 'Note: ${deviation.label}'
      : deviation.label;
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: pw.BoxDecoration(
      color: background,
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.Text(
      label,
      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: foreground),
    ),
  );
}

/// One exercise dashboard row's "Top set" cell text - "60kg × 8" when the
/// entry has a weight, or just "24 reps" (that session's total - see
/// [ExerciseProgressSummary]'s own doc comment) for a no-weight exercise,
/// where a weight figure would be meaningless. Same logic as
/// `progress_screen.dart`'s private `_topSetLabel`, kept separate since the
/// two files don't share UI code.
String _topSetLabel(ExerciseProgressSummary entry, WeightUnit unit) {
  final weight = entry.topWeight;
  // A hold or a carry: best time or distance, plus its load if it had one.
  final measured = entry.topDurationSec != null
      ? formatSetDuration(entry.topDurationSec!)
      : entry.topDistance != null
      ? formatSetDistance(entry.topDistance!)
      : null;
  if (measured != null) {
    return weight == null
        ? measured
        : '$measured @ ${formatWeightInUnit(weight, unit)}';
  }
  if (weight == null) {
    return '${entry.topReps} rep${entry.topReps == 1 ? '' : 's'}';
  }
  return '${formatWeightInUnit(weight, unit)} × ${entry.topReps}';
}

/// "3×8-10 @ 60kg" - the plan's own text fields as authored, not converted
/// to [unit] the way a logged weight is, since `weightIntensity` is free
/// text (could be "60kg", "bodyweight", "RPE 8", ...), not a stored number.
String _formatPrescription(PlanExercise prescription) {
  final parts = [
    '${prescription.sets}×${prescription.reps}',
    if (prescription.weightIntensity.isNotEmpty) prescription.weightIntensity,
  ];
  return parts.join(' @ ');
}

String _formatLoggedSet(LoggedSet set, WeightUnit unit) {
  final measured = set.durationSec != null
      ? formatSetDuration(set.durationSec!)
      : set.distance != null
      ? formatSetDistance(set.distance!)
      : null;
  final String text;
  if (measured != null) {
    text = set.weight == null
        ? measured
        : '$measured @ ${formatWeightInUnit(set.weight!, unit)}';
  } else {
    final parts = <String>[
      if (set.weight != null) formatWeightInUnit(set.weight!, unit),
      if (set.reps != null) '${set.reps} reps',
    ];
    text = parts.isEmpty ? 'Logged' : parts.join(' × ');
  }
  return set.isPr ? '$text (PR)' : text;
}

pw.Widget _cell(String text, {bool bold = false, PdfColor? color}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
    ),
  );
}
