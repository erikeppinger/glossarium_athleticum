import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/daos/session_log_dao.dart';
import '../../home_screen.dart' show settingsAppBarAction;
import '../../logic/summary_period.dart';
import '../../logic/units.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share summary',
            onPressed: summaryAsync.valueOrNull == null
                ? null
                : () => _shareSummary(period, range, summaryAsync.value!),
          ),
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
                onPressed: () => setState(() => _offset -= 1),
              ),
              Text(
                _formatRange(range, period),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
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
            data: (summary) =>
                _SummaryCards(summary: summary, unit: prefs.weightUnit),
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
                      trailing: entry.isPr
                          ? const Icon(Icons.emoji_events, color: Colors.amber)
                          : null,
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
  ) async {
    final unit = ref.read(appPreferencesProvider).weightUnit;
    final buffer = StringBuffer()
      ..writeln('Training progress - ${_formatRange(range, period)}')
      ..writeln()
      ..writeln(
        'Sessions completed: ${summary.sessionsCompleted} / ${summary.sessionsScheduled}',
      )
      ..writeln(
        'Total volume: ${formatWeightInUnit(summary.totalVolume, unit)}',
      )
      ..writeln('Personal records: ${summary.prCount}');

    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }
}

class _SummaryCards extends StatelessWidget {
  final PeriodSummary summary;
  final WeightUnit unit;

  const _SummaryCards({required this.summary, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Sessions',
            value: '${summary.sessionsCompleted}/${summary.sessionsScheduled}',
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
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
