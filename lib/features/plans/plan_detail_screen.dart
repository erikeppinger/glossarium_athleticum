import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../calendar/calendar_screen.dart';

final _planDetailsProvider = FutureProvider.family<PlanDetails?, String>(
  (ref, planId) {
    final db = ref.watch(appDatabaseProvider);
    return db.planDao.getPlanDetails(planId);
  },
);

class PlanDetailScreen extends ConsumerWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(_planDetailsProvider(planId));
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: detailsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Plan not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(details.plan.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              for (final session in details.sessions)
                Card(
                  child: ListTile(
                    title: Text(
                      'Week ${session.session.weekNumber} • ${session.session.day} • ${session.session.sessionName}',
                    ),
                    subtitle: Text(
                      session.exercises.map((e) => e.exerciseName).join(', '),
                    ),
                    trailing: TextButton(
                      onPressed: () => _pickDate(context, ref, session.session),
                      child: Text(
                        session.session.assignedDate == null
                            ? 'Assign date'
                            : dateFormat.format(session.session.assignedDate!),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    PlanSession session,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: session.assignedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.planDao.assignSessionDate(session.id, picked);
    ref.invalidate(_planDetailsProvider(planId));
    ref.invalidate(scheduledSessionsProvider);
  }
}
