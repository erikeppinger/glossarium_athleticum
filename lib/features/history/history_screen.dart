import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/app_database_provider.dart';
import '../../logic/chart_axis.dart';
import '../../logic/progression.dart';
import '../../logic/units.dart';
import '../settings/app_preferences.dart';

final _progressionHistoryProvider =
    FutureProvider.family<List<ProgressionHistoryEntry>, String>((
      ref,
      exerciseId,
    ) {
      final db = ref.watch(appDatabaseProvider);
      return db.sessionLogDao.getProgressionHistory(exerciseId);
    });

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
    final historyAsync = ref.watch(_progressionHistoryProvider(exerciseId));
    final prefs = ref.watch(appPreferencesProvider);
    final unit = prefs.weightUnit;

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName)),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: Text('No logged sets yet for this exercise.'),
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
              if (suggestion != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suggested next session',
                          style: Theme.of(context).textTheme.titleMedium,
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
}
