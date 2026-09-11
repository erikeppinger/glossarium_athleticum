import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../calendar/calendar_screen.dart'
    show loggedPlanSessionIdsProvider, scheduledSessionsProvider;
import '../../data/daos/plan_dao.dart';

/// The earliest scheduled occurrence at or after today that hasn't already
/// been logged on its own scheduled day - derived from
/// [scheduledSessionsProvider]/[loggedPlanSessionIdsProvider] (both of
/// which already power the Calendar tab) via `.watch(...future)` rather
/// than a fresh DAO query, so this provider automatically stays fresh
/// whenever either of those is invalidated - the Today dashboard and the
/// Calendar tab can never disagree, and no *new* invalidation call sites
/// are needed anywhere.
final nextScheduledSessionProvider = FutureProvider<ScheduledSession?>((
  ref,
) async {
  final all = await ref.watch(scheduledSessionsProvider.future);
  final counts = await ref.watch(loggedPlanSessionIdsProvider.future);
  final today = DateTime.now();
  final todayDay = DateTime(today.year, today.month, today.day);

  final upcoming =
      all.where((s) {
          final day = DateTime(s.date.year, s.date.month, s.date.day);
          if (day.isBefore(todayDay)) return false;
          return (counts[s.session.id]?[day] ?? 0) == 0;
        }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  return upcoming.isEmpty ? null : upcoming.first;
});
