import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/app_database.dart';
import '../../data/daos/session_log_dao.dart';
import '../../export/progress_report_pdf.dart';
import '../../home_screen.dart' show settingsAppBarAction;
import '../../logic/body_weight_trend.dart';
import '../../logic/summary_period.dart';
import '../../logic/units.dart';
import '../history/history_screen.dart';
import '../history/workout_history_screen.dart';
import '../plans/plan_providers.dart';
import '../settings/app_preferences.dart';
import 'body_measurements_screen.dart';
import 'progress_charts.dart';
import 'progress_providers.dart';

/// The Progress tab: a chooseable week/month overview summary (sessions
/// completed vs scheduled, volume, PRs) plus a cross-exercise dashboard of
/// the most recent top set per exercise, with a plain-text share/export.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  SummaryPeriod? _period;
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final period = _period ?? prefs.summaryPeriod;
    final range = computeSummaryRange(
      period: period,
      weekStart: prefs.weekStart,
      offset: _offset,
      now: DateTime.now(),
    );
    final summaryAsync = ref.watch(periodSummaryProvider(range));
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
                    period,
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
                    period,
                    range,
                    summaryAsync.value!,
                    dashboardAsync.valueOrNull,
                    exerciseNamesAsync.valueOrNull,
                    weightChange,
                    share: action == _ShareAction.pdfShare,
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
          SegmentedButton<SummaryPeriod>(
            segments: const [
              ButtonSegment(value: SummaryPeriod.week, label: Text('Week')),
              ButtonSegment(value: SummaryPeriod.month, label: Text('Month')),
            ],
            selected: {period},
            onSelectionChanged: (selected) => setState(() {
              _period = selected.first;
              _offset = 0;
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous ${period == SummaryPeriod.week ? 'week' : 'month'}',
                onPressed: () => setState(() => _offset -= 1),
              ),
              Text(
                _formatRange(range, period),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next ${period == SummaryPeriod.week ? 'week' : 'month'}',
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
                        '${formatWeightInUnit(entry.topWeight, prefs.weightUnit)} × ${entry.topReps} • ${DateFormat.yMMMd().format(entry.lastLoggedAt)}',
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

  String _formatRange(PeriodRange range, SummaryPeriod period) {
    if (period == SummaryPeriod.month) {
      return DateFormat.yMMMM().format(range.start);
    }
    final lastDay = range.end.subtract(const Duration(days: 1));
    return '${DateFormat.MMMd().format(range.start)} - ${DateFormat.MMMd().format(lastDay)}';
  }

  Future<void> _shareSummary(
    SummaryPeriod period,
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
      ..writeln('Training progress - ${_formatRange(range, period)}')
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
          '- $name: ${formatWeightInUnit(entry.topWeight, unit)} × '
          '${entry.topReps}${entry.isPr ? ' (PR)' : ''} '
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
    SummaryPeriod period,
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
      rangeLabel: _formatRange(range, period),
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

    final fileName =
        'training-progress-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';

    if (share) {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(tempFile.path)], text: 'Training progress report'),
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

enum _ShareAction { brief, detailed, pdfShare, pdfSave }

class _SummaryCards extends StatelessWidget {
  final PeriodSummary summary;
  final WeightUnit unit;
  final BodyWeightChange? weightChange;

  const _SummaryCards({
    required this.summary,
    required this.unit,
    this.weightChange,
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
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(label: 'PRs', value: '${summary.prCount}'),
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
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: 'Active time',
                  value: formatDurationSec(summary.adHocDurationSec),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: 'Distance',
                  value: summary.adHocDistanceMeters > 0
                      ? formatDistanceMeters(summary.adHocDistanceMeters)
                      : '—',
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

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
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
          ],
        ),
      ),
    );
  }
}
