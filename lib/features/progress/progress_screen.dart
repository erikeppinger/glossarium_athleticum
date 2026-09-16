import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/session_log_dao.dart';
import '../../export/progress_report_pdf.dart';
import '../../home_screen.dart' show settingsAppBarAction;
import '../../logic/body_weight_trend.dart';
import '../../logic/period_comparison.dart';
import '../../logic/summary_period.dart';
import '../../logic/units.dart';
import '../history/history_screen.dart';
import '../history/workout_history_screen.dart';
import '../plans/plan_providers.dart';
import '../settings/app_preferences.dart';
import 'body_measurements_screen.dart';
import 'progress_charts.dart';
import 'progress_providers.dart';

/// The Progress tab's three period views. Kept separate from
/// [SummaryPeriod] (which only knows week/month, and is what
/// `AppPreferences.summaryPeriod` persists as a default) because "custom"
/// has no calendar-aware meaning to persist as a default - it's always
/// picked fresh, per visit.
enum _ViewMode { week, month, custom }

String _periodNoun(_ViewMode mode) => switch (mode) {
  _ViewMode.week => 'week',
  _ViewMode.month => 'month',
  _ViewMode.custom => 'period',
};

/// The dashboard/share-text label for one exercise's latest top set - "60kg
/// × 8" when it has a weight, or just "24 reps" (that session's total, see
/// [ExerciseProgressSummary]'s own doc comment) for a no-weight exercise,
/// where a weight figure would be meaningless.
String _topSetLabel(ExerciseProgressSummary entry, WeightUnit unit) {
  final weight = entry.topWeight;
  if (weight == null) {
    return '${entry.topReps} rep${entry.topReps == 1 ? '' : 's'}';
  }
  return '${formatWeightInUnit(weight, unit)} × ${entry.topReps}';
}

/// The Progress tab: a chooseable week/month overview summary (sessions
/// completed vs scheduled, volume, PRs) plus a cross-exercise dashboard of
/// the most recent top set per exercise, with a plain-text share/export.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  _ViewMode? _viewMode;
  int _offset = 0;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);

    // Skip every other provider watch below entirely while this is on - same
    // reasoning as the `bodyTrackingEnabled` gate further down: don't pay for
    // a DB read for a feature that's deliberately off.
    if (prefs.hideProgressActive) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Progress'),
          actions: [settingsAppBarAction(context)],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.center_focus_strong,
                  size: 40,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Focus mode is on',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                Text(
                  '"A work of art is never finished, only abandoned."',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 4),
                Text(
                  '— Paul Valéry',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Progress and PRs are hidden. Nothing is deleted - your '
                  'history is all still there.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => ref
                      .read(appPreferencesProvider.notifier)
                      .setFocusModeHideProgress(false),
                  child: const Text('Show progress again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final viewMode =
        _viewMode ??
        (prefs.summaryPeriod == SummaryPeriod.week
            ? _ViewMode.week
            : _ViewMode.month);
    final PeriodRange range;
    final PeriodRange previousRange;
    if (viewMode == _ViewMode.custom && _customRange != null) {
      final customStart = _customRange!.start;
      // showDateRangePicker's end date is inclusive (the last selected day
      // itself), so +1 day turns it into this project's usual half-open
      // [start, end) convention every range-scoped query expects.
      final customEnd = _customRange!.end.add(const Duration(days: 1));
      final baseRange = (
        start: DateTime(customStart.year, customStart.month, customStart.day),
        end: DateTime(customEnd.year, customEnd.month, customEnd.day),
      );
      range = shiftedRange(baseRange, _offset);
      previousRange = shiftedRange(range, -1);
    } else {
      final period = viewMode == _ViewMode.month
          ? SummaryPeriod.month
          : SummaryPeriod.week;
      range = computeSummaryRange(
        period: period,
        weekStart: prefs.weekStart,
        offset: _offset,
        now: DateTime.now(),
      );
      previousRange = computeSummaryRange(
        period: period,
        weekStart: prefs.weekStart,
        offset: _offset - 1,
        now: DateTime.now(),
      );
    }
    final summaryAsync = ref.watch(periodSummaryProvider(range));
    // Only fetched to compute the "vs previous period" deltas shown on the
    // summary cards - a second, independent FutureProvider read (same family,
    // different key) rather than a new query, so it benefits from whatever
    // caching periodSummaryProvider already has for a range the user just
    // navigated away from (e.g. flipping back and forth with the chevrons).
    final previousSummaryAsync = ref.watch(periodSummaryProvider(previousRange));
    final comparison =
        summaryAsync.valueOrNull != null && previousSummaryAsync.valueOrNull != null
        ? comparePeriods(
            current: summaryAsync.value!,
            previous: previousSummaryAsync.value!,
          )
        : null;
    final dashboardAsync = ref.watch(exerciseProgressDashboardProvider);
    final exerciseNamesAsync = ref.watch(allExercisesForMatchingProvider);
    final currentStreak = ref.watch(currentStreakProvider).valueOrNull ?? 0;
    // Hidden entirely unless body tracking is on, same gate as the app-bar
    // icon into BodyMeasurementsScreen - watching the provider at all when
    // it's off would be a pointless DB read for a feature that's off.
    final weightChange = prefs.bodyTrackingEnabled
        ? computeBodyWeightChange(
            readings: [
              for (final m
                  in ref.watch(bodyMeasurementsProvider).valueOrNull ?? [])
                if (m.weightKg != null)
                  (measuredAt: m.measuredAt, weightKg: m.weightKg!),
            ],
            range: range,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          PopupMenuButton<_ShareAction>(
            icon: const Icon(Icons.share),
            tooltip: 'Share summary',
            enabled: summaryAsync.valueOrNull != null,
            onSelected: (action) {
              switch (action) {
                case _ShareAction.brief:
                case _ShareAction.detailed:
                  _shareSummary(
                    viewMode,
                    range,
                    summaryAsync.value!,
                    action == _ShareAction.brief
                        ? ReportDetail.brief
                        : ReportDetail.detailed,
                    dashboardAsync.valueOrNull,
                    exerciseNamesAsync.valueOrNull,
                    weightChange,
                    currentStreak,
                  );
                case _ShareAction.pdfShare:
                case _ShareAction.pdfSave:
                  _exportPdf(
                    context,
                    viewMode,
                    range,
                    summaryAsync.value!,
                    dashboardAsync.valueOrNull,
                    exerciseNamesAsync.valueOrNull,
                    weightChange,
                    share: action == _ShareAction.pdfShare,
                  );
                case _ShareAction.fullLogShare:
                case _ShareAction.fullLogSave:
                  _exportFullLogPdf(
                    context,
                    viewMode,
                    range,
                    summaryAsync.value!,
                    weightChange,
                    share: action == _ShareAction.fullLogShare,
                  );
              }
            },
            itemBuilder: (context) => [
              for (final detail in ReportDetail.values)
                PopupMenuItem(
                  value: detail == ReportDetail.brief
                      ? _ShareAction.brief
                      : _ShareAction.detailed,
                  child: Text(
                    'Share ${detail.label.toLowerCase()}'
                    '${detail == prefs.reportDetail ? ' (default)' : ''}',
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _ShareAction.pdfShare,
                child: Text('Share as PDF'),
              ),
              const PopupMenuItem(
                value: _ShareAction.pdfSave,
                child: Text('Save as PDF'),
              ),
              const PopupMenuDivider(),
              // A separate "hand this to a trainer" export - every set/rep
              // actually logged plus every ad-hoc activity individually,
              // rather than the aggregate-only report above. Deliberately a
              // distinct action rather than a third Brief/Detailed level,
              // since "everything I did, set by set" is a different kind of
              // document from a highlights summary, not just a longer one.
              const PopupMenuItem(
                value: _ShareAction.fullLogShare,
                child: Text('Share full log (PDF)'),
              ),
              const PopupMenuItem(
                value: _ShareAction.fullLogSave,
                child: Text('Save full log (PDF)'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Workout history',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const WorkoutHistoryScreen(),
              ),
            ),
          ),
          // Hidden entirely unless the user opted in - see
          // body_tracking_prompt.dart for why this isn't on by default.
          if (prefs.bodyTrackingEnabled)
            IconButton(
              icon: const Icon(Icons.straighten),
              tooltip: 'Body measurements',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BodyMeasurementsScreen(),
                ),
              ),
            ),
          settingsAppBarAction(context),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period-independent (a streak isn't scoped to the selected
          // week/month) - shown above the period controls rather than
          // inside _SummaryCards, which only ever renders period-scoped data.
          const _StreakCard(),
          const SizedBox(height: 16),
          SegmentedButton<_ViewMode>(
            segments: const [
              ButtonSegment(value: _ViewMode.week, label: Text('Week')),
              ButtonSegment(value: _ViewMode.month, label: Text('Month')),
              ButtonSegment(
                value: _ViewMode.custom,
                icon: Icon(Icons.date_range),
                label: Text('Custom'),
              ),
            ],
            selected: {viewMode},
            onSelectionChanged: (selected) => _onViewModeChanged(selected.first),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous ${_periodNoun(viewMode)}',
                onPressed: () => setState(() => _offset -= 1),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatRange(range, viewMode),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (viewMode == _ViewMode.custom)
                      TextButton(
                        onPressed: () => _pickCustomRange(initial: _customRange),
                        child: const Text('Change dates'),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next ${_periodNoun(viewMode)}',
                onPressed: _offset >= 0
                    ? null
                    : () => setState(() => _offset += 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          summaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
            data: (summary) => _SummaryCards(
              summary: summary,
              unit: prefs.weightUnit,
              weightChange: weightChange,
              comparison: comparison,
              // Reported live: activities were summarized here but never
              // listed anywhere from this screen - tapping through to the
              // same period's activities (reusing WorkoutHistoryScreen,
              // scoped and ad-hoc-only) closes that gap directly.
              onActivitiesTap: summary.adHocActivityCount > 0
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkoutHistoryScreen(
                          range: range,
                          adHocOnly: true,
                          title: 'Activities • ${_formatRange(range, viewMode)}',
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          if (prefs.showProgressCharts) ...[
            const SizedBox(height: 16),
            ref
                .watch(dailyTotalsProvider(range))
                .when(
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Text('Error: $error'),
                  data: (totals) => ProgressCharts(
                    totals: totals,
                    unit: prefs.weightUnit,
                  ),
                ),
          ],
          const SizedBox(height: 24),
          Text(
            'Exercise dashboard',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          dashboardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
            data: (dashboard) {
              if (dashboard.isEmpty) {
                return const Text('No logged sets yet.');
              }
              final names = {
                for (final e in exerciseNamesAsync.valueOrNull ?? [])
                  e.id: e.name,
              };
              return Column(
                children: [
                  for (final entry in dashboard)
                    ListTile(
                      title: Text(names[entry.exerciseId] ?? entry.exerciseId),
                      subtitle: Text(
                        '${_topSetLabel(entry, prefs.weightUnit)} • ${DateFormat.yMMMd().format(entry.lastLoggedAt)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (entry.isPr)
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      // Tapping through to the full weight-over-time chart
                      // for this exercise - the dashboard row only shows the
                      // latest top set, which says nothing about direction.
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HistoryScreen(
                            exerciseId: entry.exerciseId,
                            exerciseName:
                                names[entry.exerciseId] ?? entry.exerciseId,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Custom uses the same "MMMd - MMMd" format as week - only month gets its
  /// own single-name format, since it's the only mode with a calendar unit
  /// short enough to name outright.
  String _formatRange(PeriodRange range, _ViewMode mode) {
    if (mode == _ViewMode.month) {
      return DateFormat.yMMMM().format(range.start);
    }
    final lastDay = range.end.subtract(const Duration(days: 1));
    return '${DateFormat.MMMd().format(range.start)} - ${DateFormat.MMMd().format(lastDay)}';
  }

  Future<void> _onViewModeChanged(_ViewMode mode) async {
    if (mode == _ViewMode.custom) {
      await _pickCustomRange(initial: _customRange);
      return;
    }
    setState(() {
      _viewMode = mode;
      _offset = 0;
    });
  }

  /// Opens the date-range picker and, if the user actually picks a range
  /// (as opposed to cancelling), switches to/stays on Custom with it. A
  /// cancel leaves whatever mode/range was already showing untouched, rather
  /// than dropping into an empty custom selection.
  Future<void> _pickCustomRange({DateTimeRange? initial}) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: initial,
    );
    if (picked == null) return;
    setState(() {
      _viewMode = _ViewMode.custom;
      _customRange = picked;
      _offset = 0;
    });
  }

  Future<void> _shareSummary(
    _ViewMode mode,
    PeriodRange range,
    PeriodSummary summary,
    ReportDetail detail,
    List<ExerciseProgressSummary>? dashboard,
    List<Exercise>? exercises,
    BodyWeightChange? weightChange,
    int currentStreak,
  ) async {
    final unit = ref.read(appPreferencesProvider).weightUnit;
    final buffer = StringBuffer()
      ..writeln('Training progress - ${_formatRange(range, mode)}')
      ..writeln();
    // Period-independent, so it's stated up front rather than folded into
    // the period-scoped lines below - same "hide a meaningless stat" gate
    // as the in-app streak card.
    if (currentStreak > 0) {
      buffer.writeln(
        '$currentStreak day${currentStreak == 1 ? '' : 's'} streak',
      );
    }
    buffer
      ..writeln(
        // "Scheduled", not "Sessions completed" - this is completed-of-
        // scheduled (adherence), not a total workout count. A session
        // logged against a plan that's never had a date assigned to it
        // contributes to Volume/PRs below but not to this ratio, so
        // labelling it as total sessions would read as contradicting a
        // nonzero Volume/PRs line right underneath it.
        'Scheduled sessions completed: ${summary.sessionsCompleted} / ${summary.sessionsScheduled}',
      )
      ..writeln(
        'Total volume: ${formatWeightInUnit(summary.totalVolume, unit)}',
      )
      ..writeln('Personal records: ${summary.prCount}');

    // Same "hide a meaningless stat" gate as the summary cards' equivalent.
    if (summary.nonWeightedReps > 0) {
      buffer.writeln('Bodyweight reps: ${summary.nonWeightedReps}');
    }

    // Same opt-in gate as the summary cards - only ever present when body
    // tracking is on and there's actually a comparison to make.
    if (weightChange != null) {
      buffer.writeln('Bodyweight: ${formatWeightChange(weightChange, unit)}');
    }

    // Ad-hoc activities (walks/runs/etc.) previously never appeared in this
    // summary at all, even though they're real logged training - shown in
    // both Brief and Detailed, same bar as sessions/volume/PRs above.
    if (summary.adHocActivityCount > 0) {
      final parts = [
        '${summary.adHocActivityCount} activit${summary.adHocActivityCount == 1 ? 'y' : 'ies'}',
        if (summary.adHocDurationSec > 0)
          formatDurationSec(summary.adHocDurationSec),
        if (summary.adHocDistanceMeters > 0)
          formatDistanceMeters(summary.adHocDistanceMeters),
      ];
      buffer.writeln('Other activities: ${parts.join(', ')}');
    }

    // Adds the per-exercise top-set dashboard - what someone would actually
    // want to hand a trainer, versus Brief's period-level numbers alone.
    if (detail == ReportDetail.detailed &&
        dashboard != null &&
        dashboard.isNotEmpty) {
      final names = {for (final e in exercises ?? []) e.id: e.name};
      buffer
        ..writeln()
        ..writeln('Current top sets:');
      for (final entry in dashboard) {
        final name = names[entry.exerciseId] ?? entry.exerciseId;
        buffer.writeln(
          '- $name: ${_topSetLabel(entry, unit)}'
          '${entry.isPr ? ' (PR)' : ''} '
          '(${DateFormat.yMMMd().format(entry.lastLoggedAt)})',
        );
      }
    }

    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  /// Builds the PDF report and either shares it (a temp file + the share
  /// sheet) or saves it (a SAF "Save as" dialog) - the exact Save/Share
  /// pattern already used for the plan/library templates, see
  /// `templates_screen.dart`.
  Future<void> _exportPdf(
    BuildContext context,
    _ViewMode mode,
    PeriodRange range,
    PeriodSummary summary,
    List<ExerciseProgressSummary>? dashboard,
    List<Exercise>? exercises,
    BodyWeightChange? weightChange, {
    required bool share,
  }) async {
    final prefs = ref.read(appPreferencesProvider);
    final unit = prefs.weightUnit;
    // Fetched regardless of the in-app showProgressCharts preference - the
    // report is a deliberate export, not the live screen, so it always
    // includes the volume chart.
    final dailyTotals = await ref.read(dailyTotalsProvider(range).future);
    final names = {for (final e in exercises ?? <Exercise>[]) e.id: e.name};

    final bytes = await buildProgressReportPdf(
      rangeLabel: _formatRange(range, mode),
      summary: summary,
      dailyTotals: dailyTotals,
      dashboard: dashboard ?? const [],
      exerciseNames: names,
      unit: unit,
      weightChange: weightChange,
      // Same Brief/Detailed default the plain-text share uses - previously
      // the PDF ignored this setting entirely and always showed the
      // exercise dashboard table, which looked like the Settings toggle did
      // nothing when someone had it set to Brief.
      includeExerciseDashboard: prefs.reportDetail == ReportDetail.detailed,
    );

    if (!context.mounted) return;
    await _sharePdfOrSave(
      context,
      bytes,
      fileNamePrefix: 'training-progress',
      shareText: 'Training progress report',
      share: share,
    );
  }

  /// The trainer-oriented counterpart to [_exportPdf]: every set actually
  /// logged and every ad-hoc activity individually, for whatever range is
  /// currently selected (most usefully a custom one - see
  /// [_pickCustomRange]), rather than the aggregate-only summary report.
  Future<void> _exportFullLogPdf(
    BuildContext context,
    _ViewMode mode,
    PeriodRange range,
    PeriodSummary summary,
    BodyWeightChange? weightChange, {
    required bool share,
  }) async {
    final unit = ref.read(appPreferencesProvider).weightUnit;
    final db = ref.read(appDatabaseProvider);
    final dailyTotals = await ref.read(dailyTotalsProvider(range).future);
    final fullLog = await db.sessionLogDao.getCompletedWorkoutsInRange(
      start: range.start,
      end: range.end,
    );

    final bytes = await buildProgressReportPdf(
      rangeLabel: _formatRange(range, mode),
      summary: summary,
      dailyTotals: dailyTotals,
      dashboard: const [],
      exerciseNames: const {},
      unit: unit,
      weightChange: weightChange,
      includeExerciseDashboard: false,
      fullLog: fullLog,
    );

    if (!context.mounted) return;
    await _sharePdfOrSave(
      context,
      bytes,
      fileNamePrefix: 'training-log',
      shareText: 'Training log',
      share: share,
    );
  }

  /// Shares a temp copy of [bytes] via the share sheet, or saves it through
  /// a SAF "Save as" dialog - the exact Save/Share pattern already used for
  /// the plan/library templates (see `templates_screen.dart`), shared here
  /// by both PDF export actions rather than duplicated.
  Future<void> _sharePdfOrSave(
    BuildContext context,
    Uint8List bytes, {
    required String fileNamePrefix,
    required String shareText,
    required bool share,
  }) async {
    final fileName =
        '$fileNamePrefix-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';

    if (share) {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(tempFile.path)], text: shareText),
      );
      return;
    }

    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uri == null ? 'Save cancelled.' : 'Saved.')),
    );
  }
}

enum _ShareAction {
  brief,
  detailed,
  pdfShare,
  pdfSave,
  fullLogShare,
  fullLogSave,
}

class _SummaryCards extends StatelessWidget {
  final PeriodSummary summary;
  final WeightUnit unit;
  final BodyWeightChange? weightChange;

  /// vs the immediately preceding period, when both it and this one have
  /// resolved - see `_ProgressScreenState.build`. Null while still loading.
  final PeriodComparison? comparison;

  /// Pushes a period-scoped, ad-hoc-only activity list (reusing
  /// WorkoutHistoryScreen) - null when there's nothing to show, which also
  /// naturally suppresses the tap ripple on a card with nothing behind it.
  final VoidCallback? onActivitiesTap;

  const _SummaryCards({
    required this.summary,
    required this.unit,
    this.weightChange,
    this.comparison,
    this.onActivitiesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                // "Scheduled" - this ratio is completed-of-scheduled
                // (adherence to plan_sessions with an assigned date), not a
                // total workout count. Labelling it "Sessions" reads as
                // contradicting the Volume/PRs cards next to it whenever
                // real work was logged against a session with no assigned
                // date (Volume/PRs count that; this ratio deliberately
                // doesn't - see getPeriodSummary's own doc comment).
                label: 'Scheduled',
                value:
                    '${summary.sessionsCompleted}/${summary.sessionsScheduled}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Volume',
                value: formatWeightInUnit(summary.totalVolume, unit),
                delta: comparison == null || !comparison!.hasVolumeComparison
                    ? null
                    : formatPercentDelta(
                        comparison!.volumeDeltaPercent,
                        isNew: comparison!.volumeIsNew,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'PRs',
                value: '${summary.prCount}',
                delta: comparison == null || !comparison!.hasPrComparison
                    ? null
                    : formatCountDelta(comparison!.prCountDelta),
              ),
            ),
          ],
        ),
        // Ad-hoc activities (walks/runs/etc.) previously didn't show up
        // anywhere in Progress at all - only in Workout History and the
        // calendar - even though they're real logged training. Only shown
        // when there's at least one, same as the body-tracking UI hiding
        // itself when there's nothing to show.
        if (summary.adHocActivityCount > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Activities',
                  value: '${summary.adHocActivityCount}',
                  delta: comparison == null
                      ? null
                      : formatCountDelta(comparison!.activityCountDelta),
                  // Reported live: these cards summarized ad-hoc activities
                  // but had no way to see them individually from here -
                  // tapping any of the three now opens exactly what they
                  // summarize, for this same period.
                  onTap: onActivitiesTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: 'Active time',
                  value: formatDurationSec(summary.adHocDurationSec),
                  onTap: onActivitiesTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: 'Distance',
                  value: summary.adHocDistanceMeters > 0
                      ? formatDistanceMeters(summary.adHocDistanceMeters)
                      : '—',
                  onTap: onActivitiesTap,
                ),
              ),
            ],
          ),
        ],
        // No-weight exercises (bodyweight/band/Time-type, e.g. a resistance-
        // band warm-up) have nothing to contribute to Volume above - kg ×
        // reps is meaningless without a kg - so without this they were
        // invisible in the period summary entirely, however consistently
        // they were actually trained. Only shown when there's at least one
        // such rep logged, same "hide a meaningless stat" pattern as the
        // ad-hoc activity cards above.
        if (summary.nonWeightedReps > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Bodyweight reps',
                  value: '${summary.nonWeightedReps}',
                ),
              ),
            ],
          ),
        ],
        // Bodyweight tracking is opt-in and otherwise invisible in Progress
        // entirely - see body_tracking_prompt.dart - and even once on, this
        // only appears once there are two readings to compare (see
        // computeBodyWeightChange), so a single weigh-in doesn't show a
        // meaningless "no change yet" card every period.
        if (weightChange != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Bodyweight',
                  value: formatWeightChange(weightChange!, unit),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

}

/// Consecutive days with any logged activity (see `lib/logic/streaks.dart`)
/// - hidden entirely at zero, same "don't show a meaningless stat" shape as
/// the other opt-in-feeling cards on this screen, since a 0-day streak reads
/// as discouraging rather than informative on a first visit.
class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(currentStreakProvider);
    final streak = streakAsync.valueOrNull ?? 0;
    if (streak == 0) return const SizedBox.shrink();
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.deepOrange),
            const SizedBox(width: 12),
            Text(
              '$streak day${streak == 1 ? '' : 's'} streak',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  /// A short "vs previous period" string (e.g. "+12%", "±0", "new") shown
  /// beneath the label - null omits the line entirely, same as before this
  /// existed.
  final String? delta;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    this.delta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              FittedBox(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              if (delta != null) ...[
                const SizedBox(height: 2),
                Text(
                  delta!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
