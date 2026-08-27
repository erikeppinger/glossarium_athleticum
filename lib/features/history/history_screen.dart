import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/app_database_provider.dart';
import '../../logic/progression.dart';

final _progressionHistoryProvider = FutureProvider.family<
  List<ProgressionHistoryEntry>,
  String
>((ref, exerciseId) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionLogDao.getProgressionHistory(exerciseId);
});

/// Currently fixed at intermediate - Phase 6 (onboarding) will feed the
/// user's actual experience level in here instead.
const _defaultLevel = ExperienceLevel.intermediate;

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

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName)),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: Text('No logged sets yet for this exercise.'),
            );
          }
          final sorted = [...history]
            ..sort((a, b) => a.date.compareTo(b.date));
          final suggestion = suggestNextSet(
            history: sorted,
            level: _defaultLevel,
          );
          final maxWeight = sorted
              .map((e) => e.weight)
              .reduce((a, b) => a > b ? a : b);
          // Round the axis top up to a clean multiple of 10 and pick an
          // interval that divides it evenly, so grid labels never land close
          // enough together to overlap (fl_chart's default interval can
          // otherwise pick e.g. 70 when maxY is 72, cramming both labels at
          // the top).
          final chartMaxY = ((maxWeight * 1.2) / 10).ceil() * 10.0;
          final chartInterval = chartMaxY / 5;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
              Text('Weight over time', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
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
                            FlSpot(i.toDouble(), sorted[i].weight),
                        ],
                        isCurved: false,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Sessions', style: Theme.of(context).textTheme.titleMedium),
              for (final entry in sorted.reversed)
                ListTile(
                  title: Text('${formatWeight(entry.weight)} × ${entry.reps}'),
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
