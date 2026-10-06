import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/daos/session_log_dao.dart'
    show MeasuredHistory, RepsHistoryEntry;
import '../../logic/chart_axis.dart';
import '../../logic/one_rep_max.dart';
import '../../logic/progression.dart';
import '../../logic/set_measure.dart';
import '../../logic/units.dart';
import '../progress/progress_providers.dart';
import '../settings/app_preferences.dart';

class HistoryScreen extends ConsumerWidget {
  final String exerciseId;
  final String exerciseName;

  const HistoryScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseProgressionHistoryProvider(exerciseId));
    // Only actually read when the weight-based history above turns out
    // empty (see below) - a bodyweight/band/Time-type exercise (e.g. Hip
    // Circles) never has weight-based history at all, and used to just show
    // "No logged sets yet for this exercise" even when it had been logged
    // plenty of times, since [exerciseProgressionHistoryProvider] only ever
    // sees weight-bearing sets.
    final repsOnlyAsync = ref.watch(repsOnlyHistoryProvider(exerciseId));
    // A hold or a carry: its times or distances come before any reps it
    // may have been logged with before time/distance sets existed.
    final measuredAsync = ref.watch(measuredHistoryProvider(exerciseId));
    final estimatedOneRepMax = ref
        .watch(estimatedOneRepMaxProvider(exerciseId))
        .valueOrNull;
    final prefs = ref.watch(appPreferencesProvider);
    final unit = prefs.weightUnit;

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName)),
      body: historyAsync.when(
        data: (history) {
          final measured = measuredAsync.valueOrNull;
          if (history.isEmpty && measured != null) {
            return _MeasuredHistoryView(history: measured);
          }
          if (history.isEmpty) {
            return repsOnlyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (repsHistory) {
                if (repsHistory.isEmpty) {
                  return const Center(
                    child: Text('No logged sets yet for this exercise.'),
                  );
                }
                return _RepsOnlyHistory(history: repsHistory);
              },
            );
          }
          final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));
          final suggestion = prefs.progressionSuggestionsEnabled
              ? suggestNextSet(
                  history: sorted,
                  level: prefs.experienceLevel,
                  unit: unit,
                )
              : null;
          final maxWeight = sorted
              .map((e) => e.weight)
              .reduce((a, b) => a > b ? a : b);
          final maxWeightDisplay = kgToDisplay(maxWeight, unit);
          // Shared with the Progress tab's charts - see lib/logic/chart_axis.dart
          // for why the top has to be an exact multiple of the interval.
          final axis = niceAxis(maxWeightDisplay);
          final chartMaxY = axis.max;
          final chartInterval = axis.interval;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (estimatedOneRepMax != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Estimated 1RM: '
                        '${formatWeightInUnit(estimatedOneRepMax, unit)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      tooltip: 'What is this based on?',
                      onPressed: () => _showOneRepMaxNote(context),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (suggestion != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Suggested next session',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, size: 20),
                              tooltip: 'What is this based on?',
                              onPressed: () => _showScienceNote(context),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(suggestion.rationale),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Weight over time (${unit == WeightUnit.lbs ? 'lbs' : 'kg'})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // The "Sessions" list below already renders every one of these
              // points as text, so this is a secondary/redundant summary
              // rather than the only way to get the data - still worth
              // stating up front, since fl_chart itself has no text
              // alternative and a screen-reader user shouldn't have to
              // reconstruct the trend from a reversed list further down.
              Semantics(
                label:
                    'Weight over time chart. Latest: '
                    '${formatWeightInUnit(sorted.last.weight, unit)}. '
                    'Highest: ${formatWeightInUnit(maxWeight, unit)}.',
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: chartMaxY,
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: chartInterval,
                              reservedSize: 40,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < sorted.length; i++)
                                FlSpot(
                                  i.toDouble(),
                                  kgToDisplay(sorted[i].weight, unit),
                                ),
                            ],
                            isCurved: false,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Sessions', style: Theme.of(context).textTheme.titleMedium),
              for (final entry in sorted.reversed)
                ListTile(
                  title: Text(
                    '${formatWeightInUnit(entry.weight, unit)} × ${entry.reps}',
                  ),
                  subtitle: Text(DateFormat.yMMMd().format(entry.date)),
                  trailing: entry.weight == maxWeight
                      ? const Icon(Icons.emoji_events, color: Colors.amber)
                      : null,
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _showOneRepMaxNote(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What is this based on?'),
        content: const SingleChildScrollView(
          child: Text(oneRepMaxScienceNote),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showScienceNote(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What is this based on?'),
        content: const SingleChildScrollView(
          child: Text(progressionScienceNote),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// The reps-over-time fallback shown instead of [HistoryScreen]'s normal
/// weight-based view for an exercise that has never logged a weight
/// (bodyweight/band/Time-type, e.g. Hip Circles) - no 1RM estimate and no
/// auto-progression suggestion here, since both are genuinely weight-based
/// math (see `lib/logic/one_rep_max.dart`/`lib/logic/progression.dart`), just
/// the trend and session list a weight-based exercise gets, reduced to total
/// reps per session (see `RepsHistoryEntry`'s own doc comment for why total
/// rather than a single "top" set - there's no weight axis to pick one by).
class _RepsOnlyHistory extends StatelessWidget {
  final List<RepsHistoryEntry> history;

  const _RepsOnlyHistory({required this.history});

  @override
  Widget build(BuildContext context) {
    final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));
    final maxReps = sorted
        .map((e) => e.totalReps)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final axis = niceAxis(maxReps);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Reps over time',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Semantics(
          label:
              'Reps over time chart. Latest: ${sorted.last.totalReps} reps. '
              'Highest: ${maxReps.toInt()} reps.',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: axis.max,
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: axis.interval,
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < sorted.length; i++)
                          FlSpot(i.toDouble(), sorted[i].totalReps.toDouble()),
                      ],
                      isCurved: false,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Sessions', style: Theme.of(context).textTheme.titleMedium),
        for (final entry in sorted.reversed)
          ListTile(
            title: Text(
              '${entry.totalReps} rep${entry.totalReps == 1 ? '' : 's'}'
              ' (${entry.setCount} set${entry.setCount == 1 ? '' : 's'})',
            ),
            subtitle: Text(DateFormat.yMMMd().format(entry.date)),
            trailing: entry.totalReps == maxReps.toInt()
                ? const Icon(Icons.emoji_events, color: Colors.amber)
                : null,
          ),
      ],
    );
  }
}

/// History for a hold or a carry: each session's longest time (or furthest
/// distance) over time, and the session list. No 1RM or progression
/// suggestion, same as the reps-only view - both are weight-based.
class _MeasuredHistoryView extends StatelessWidget {
  final MeasuredHistory history;

  const _MeasuredHistoryView({required this.history});

  @override
  Widget build(BuildContext context) {
    final isTime = history.measure == SetMeasure.time;
    String format(double value) =>
        isTime ? formatSetDuration(value) : formatSetDistance(value);
    final entries = history.entries;
    final best = entries.map((e) => e.best).reduce((a, b) => a > b ? a : b);
    final axis = niceAxis(best);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          isTime ? 'Longest set per session' : 'Furthest set per session',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Semantics(
          label:
              'Chart of the best set per session. Latest: '
              '${format(entries.last.best)}. Best: ${format(best)}.',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: axis.max,
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: axis.interval,
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < entries.length; i++)
                          FlSpot(i.toDouble(), entries[i].best),
                      ],
                      isCurved: false,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isTime ? 'Seconds' : 'Metres',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Text('Sessions', style: Theme.of(context).textTheme.titleMedium),
        for (final entry in entries.reversed)
          ListTile(
            title: Text(
              'Best ${format(entry.best)}'
              ' (${entry.setCount} set${entry.setCount == 1 ? '' : 's'}, '
              '${format(entry.total)} total)',
            ),
            subtitle: Text(DateFormat.yMMMd().format(entry.date)),
            trailing: entry.best == best
                ? const Icon(Icons.emoji_events, color: Colors.amber)
                : null,
          ),
      ],
    );
  }
}
