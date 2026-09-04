import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/daos/session_log_dao.dart';
import '../logic/body_weight_trend.dart';
import '../logic/chart_axis.dart';
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
}) async {
  final doc = pw.Document();
  final now = generatedAt ?? DateTime.now();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        _header(rangeLabel, now),
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

pw.Widget _header(String rangeLabel, DateTime generatedAt) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Training Progress',
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(rangeLabel, style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
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
            _cell('${formatWeightInUnit(entry.topWeight, unit)} × ${entry.topReps}'),
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
