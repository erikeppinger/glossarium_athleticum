import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../import/plan_json_import.dart';
import '../../import/plan_sync.dart';
import '../../logic/week_label.dart';
import '../settings/backup_dialogs.dart';
import '../shared/exercise_list_invalidation.dart';
import '../shared/screen_padding.dart';
import 'plan_providers.dart';

/// Shown when an incoming plan JSON (received via Phase 4's share/receive
/// pipeline, or manually re-imported) shares an id with a local plan whose
/// `updated_at` doesn't match - i.e. the two have diverged since they were
/// last in sync. Per the dev plan's exit criteria, this never resolves
/// automatically: the user always gets an explicit choice between the two
/// versions, or can keep both as separate plans.
class PlanConflictScreen extends ConsumerStatefulWidget {
  final PlanDetails local;
  final Map<String, dynamic> incomingJson;

  const PlanConflictScreen({
    super.key,
    required this.local,
    required this.incomingJson,
  });

  @override
  ConsumerState<PlanConflictScreen> createState() =>
      _PlanConflictScreenState();
}

class _PlanConflictScreenState extends ConsumerState<PlanConflictScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    final local = widget.local;
    final incoming = widget.incomingJson;
    final incomingUpdatedAt = DateTime.tryParse(
      incoming['updated_at'] as String? ?? '',
    );
    final incomingWeeks = incoming['weeks'] as List;
    // Both versions get the same treatment, so a side-by-side comparison
    // never hides a week on one side that the other side shows.
    final showWeek = showsWeekNumber([
      for (final s in local.sessions) s.session.weekNumber,
      for (final week in incomingWeeks)
        if ((week['sessions'] as List).isNotEmpty) week['week_number'] as int,
    ]);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync conflict')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: screenListPadding(context),
              children: [
                Text(
                  '"${local.plan.name}" was changed on this device and in '
                  'the version you received since they last matched. '
                  'Choose which version to keep.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _VersionCard(
                  title: 'This device',
                  updatedAtLabel: dateFormat.format(local.plan.updatedAt),
                  sessionSummaries: [
                    for (final s in local.sessions)
                      '${_sessionLabel(showWeek, s.session.weekNumber, s.session.day, s.session.sessionName)} '
                          '(${s.exercises.length} exercise(s))',
                  ],
                ),
                const SizedBox(height: 12),
                _VersionCard(
                  title: 'Incoming',
                  updatedAtLabel: incomingUpdatedAt == null
                      ? 'Unknown'
                      : dateFormat.format(incomingUpdatedAt),
                  sessionSummaries: [
                    for (final week in incomingWeeks)
                      for (final session in week['sessions'] as List)
                        '${_sessionLabel(showWeek, week['week_number'] as int, session['day'] as String, session['session_name'] as String)} '
                            '(${(session['exercises'] as List).length} exercise(s))',
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _keepLocal,
                  child: const Text("Keep this device's version"),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: _useIncoming,
                  child: const Text('Use incoming version'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _keepBoth,
                  child: const Text('Keep both as separate plans'),
                ),
              ],
            ),
    );
  }

  String _sessionLabel(
    bool showWeek,
    int weekNumber,
    String day,
    String sessionName,
  ) => joinSessionLabel([if (showWeek) 'Week $weekNumber', day, sessionName]);

  void _keepLocal() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Kept this device's version.")));
  }

  /// Nothing was written (the import rolled back), so the user stays on
  /// this screen with both choices still available.
  void _showImportFailure(PlanJsonFormatException e) {
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.message)));
  }

  Future<void> _keepBoth() async {
    setState(() => _busy = true);
    final db = ref.read(appDatabaseProvider);
    try {
      await importPlanJson(widget.incomingJson, db);
    } on PlanJsonFormatException catch (e) {
      _showImportFailure(e);
      return;
    }
    invalidateExerciseListProviders(ref);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Imported as a new plan.')));
  }

  Future<void> _useIncoming() async {
    final db = ref.read(appDatabaseProvider);
    final lost = await findLogsThatWouldBeLost(
      widget.local,
      widget.incomingJson,
      db,
    );
    if (!mounted) return;
    if (lost.isNotEmpty) {
      final confirmed = await confirmDestructiveAction(
        context,
        title: 'Logged sessions will be lost',
        message:
            'The incoming version removes ${lost.length} session(s) that '
            "have logged workouts on this device. Those logs can't be kept "
            "if you continue. This can't be undone.",
        confirmLabel: 'Continue anyway',
      );
      if (!confirmed) return;
    }

    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await applyIncomingPlan(widget.incomingJson, db);
    } on PlanJsonFormatException catch (e) {
      _showImportFailure(e);
      return;
    }
    invalidateExerciseListProviders(ref);
    // applyIncomingPlan rewrites the plan's data under its existing id - the
    // detail screen's one-shot FutureProvider for that id won't notice on
    // its own (same gotcha as filteredExercisesProvider, see plan_providers.dart).
    ref.invalidate(planDetailsProvider(widget.incomingJson['id'] as String));
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updated to the incoming version.')),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final String title;
  final String updatedAtLabel;
  final List<String> sessionSummaries;

  const _VersionCard({
    required this.title,
    required this.updatedAtLabel,
    required this.sessionSummaries,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(
              'Last changed $updatedAtLabel',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final summary in sessionSummaries) Text(summary),
          ],
        ),
      ),
    );
  }
}
