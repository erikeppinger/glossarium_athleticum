import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/daos/session_log_dao.dart';
import '../../logic/chart_axis.dart';
import '../../logic/units.dart';

enum _Metric { volume, sets, reps, prs }

extension on _Metric {
  String get label => switch (this) {
    _Metric.volume => 'Volume',
    _Metric.sets => 'Sets',
    _Metric.reps => 'Reps',
    _Metric.prs => 'Personal records',
  };
}

/// A swipeable set of per-day trend charts for the selected period - volume,
/// sets, reps, and PRs. Bars rather than lines: training days are discrete
/// events with gaps between them, and a line would imply the app knows what
/// happened on the rest days.
class ProgressCharts extends StatefulWidget {
  final List<DailyTotals> totals;
  final WeightUnit unit;

  const ProgressCharts({super.key, required this.totals, required this.unit});

  @override
  State<ProgressCharts> createState() => _ProgressChartsState();
}

class _ProgressChartsState extends State<ProgressCharts> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totals.isEmpty) {
      return Card(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No sessions logged in this period yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: _Metric.values.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => _MetricChart(
              metric: _Metric.values[index],
              totals: widget.totals,
              unit: widget.unit,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _Metric.values.length; i++)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MetricChart extends StatelessWidget {
  final _Metric metric;
  final List<DailyTotals> totals;
  final WeightUnit unit;

  const _MetricChart({
    required this.metric,
    required this.totals,
    required this.unit,
  });

  double _valueFor(DailyTotals t) => switch (metric) {
    _Metric.volume => kgToDisplay(t.volume, unit),
    _Metric.sets => t.sets.toDouble(),
    _Metric.reps => t.reps.toDouble(),
    _Metric.prs => t.prs.toDouble(),
  };

  @override
  Widget build(BuildContext context) {
    final values = [for (final t in totals) _valueFor(t)];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    // Round the axis top up to a clean multiple and pick an interval that
    // divides it evenly. fl_chart's default interval otherwise lands two
    // labels almost on top of each other near the top (e.g. "1K" and "1.1K"
    // when maxY is 1056) - the same gotcha already hit on the history
    // screen, see CLAUDE.md.
    final axis = niceAxis(maxValue);
    final chartMax = axis.max;
    final interval = axis.interval;

    final title = metric == _Metric.volume
        ? '${metric.label} (${unit == WeightUnit.lbs ? 'lbs' : 'kg'})'
        : metric.label;

    // fl_chart draws to a canvas with no text alternative of its own, so a
    // screen reader gets nothing from it - a swipeable chart series like
    // this one has no visible list of the underlying numbers anywhere else
    // in the screen the way, say, the history screen's chart does. The
    // summary trades away per-day detail for the headline numbers someone
    // would actually want read aloud.
    final latest = values.last;
    final average = values.reduce((a, b) => a + b) / values.length;
    final summary =
        '$title chart. Latest: ${_formatValue(latest)}. '
        'Average over ${values.length} day${values.length == 1 ? '' : 's'}: '
        '${_formatValue(average)}. Highest: ${_formatValue(maxValue)}.';

    return Semantics(
      label: summary,
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      maxY: chartMax,
                      minY: 0,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final t = totals[group.x];
                            return BarTooltipItem(
                              '${DateFormat.MMMd().format(t.day)}\n'
                              '${_formatValue(rod.toY)}',
                              TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onInverseSurface,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            interval: interval,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            // Only label a handful of days - one label per bar
                            // overlaps into an unreadable smear on a full month.
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= totals.length) {
                                return const SizedBox.shrink();
                              }
                              final step = (totals.length / 4).ceil();
                              if (index % step != 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat.Md().format(totals[index].day),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < values.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: values[i],
                                width: 10,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (metric == _Metric.volume) {
      return '${value.toStringAsFixed(0)} ${unit == WeightUnit.lbs ? 'lbs' : 'kg'}';
    }
    return value.toStringAsFixed(0);
  }
}
