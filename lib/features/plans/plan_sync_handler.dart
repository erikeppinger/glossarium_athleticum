import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database_provider.dart';
import '../../import/plan_json_import.dart';
import '../../import/plan_sync.dart';
import '../exercise_library/exercise_library_providers.dart';
import 'plan_conflict_screen.dart';

/// Imports a plan JSON, checking first whether it's actually a sync of a
/// plan already on this device (Phase 5, built on Phase 4's file-sharing
/// transport) rather than a brand-new plan. Shared between the manual
/// "Import plan -> From plan file" flow and the incoming-share handler, so
/// a sync conflict is caught the same way regardless of how the file
/// arrived.
Future<void> importOrSyncPlanJson(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> json,
) async {
  final db = ref.read(appDatabaseProvider);

  try {
    switch (await checkPlanSync(json, db)) {
      case PlanSyncNew():
        await importPlanJson(json, db);
        ref.invalidate(filteredExercisesProvider);
        ref.invalidate(exerciseCategoriesProvider);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plan imported.')));

      case PlanSyncUpToDate():
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already up to date.')),
        );

      case PlanSyncConflict(:final local, :final incomingJson):
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlanConflictScreen(
              local: local,
              incomingJson: incomingJson,
            ),
          ),
        );
    }
  } on PlanJsonFormatException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.message)));
  }
}
