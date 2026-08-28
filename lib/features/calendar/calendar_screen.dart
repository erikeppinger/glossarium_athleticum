import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../home_screen.dart' show settingsAppBarAction;
import '../execution/start_session_helper.dart';
import '../history/workout_history_screen.dart';
import '../settings/app_preferences.dart';

final scheduledSessionsProvider = FutureProvider<List<ScheduledSession>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.planDao.getAllScheduledSessions();
});

final loggedPlanSessionIdsProvider = FutureProvider<Set<int>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionLogDao.getLoggedPlanSessionIds();
});

DateTime _dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  // Defaults to today rather than null. Leaving it unset made the day-list
  // read "No sessions on this day" before the user had picked any day -
  // which looked like a contradiction next to today's own session marker.
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(scheduledSessionsProvider);
    final weekStart = ref.watch(appPreferencesProvider).weekStart;
    final loggedIds =
        ref.watch(loggedPlanSessionIdsProvider).valueOrNull ?? const <int>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [settingsAppBarAction(context)],
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          final byDay = <DateTime, List<ScheduledSession>>{};
          for (final s in sessions) {
            final date = s.session.assignedDate;
            if (date == null) continue;
            byDay.putIfAbsent(_dayKey(date), () => []).add(s);
          }
          final selected = _selectedDay;
          final selectedSessions = byDay[_dayKey(selected)] ?? const [];

          return Column(
            children: [
              TableCalendar<ScheduledSession>(
                firstDay: DateTime(DateTime.now().year - 1),
                lastDay: DateTime(DateTime.now().year + 2),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                startingDayOfWeek: weekStart == WeekStart.sunday
                    ? StartingDayOfWeek.sunday
                    : StartingDayOfWeek.monday,
                selectedDayPredicate: (day) => isSameDay(day, selected),
                eventLoader: (day) => byDay[_dayKey(day)] ?? const [],
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) =>
                    setState(() => _calendarFormat = format),
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                calendarBuilders: CalendarBuilders<ScheduledSession>(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final hasCompleted = events.any(
                      (s) => loggedIds.contains(s.session.id),
                    );
                    if (hasCompleted) {
                      return Positioned(
                        bottom: 1,
                        child: Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                      );
                    }
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: selectedSessions.isEmpty
                    ? const Center(child: Text('No sessions on this day.'))
                    : ListView.builder(
                        itemCount: selectedSessions.length,
                        itemBuilder: (context, index) {
                          final s = selectedSessions[index];
                          final done = loggedIds.contains(s.session.id);
                          return ListTile(
                            leading: done
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                  )
                                : null,
                            title: Text(s.session.sessionName),
                            subtitle: Text(
                              '${s.planName} • Week ${s.session.weekNumber}'
                              // "Any" is an internal placeholder for an
                              // unscheduled weekday; showing it reads as
                              // though the user picked it.
                              '${s.session.day == 'Any' ? '' : ' • ${s.session.day}'}'
                              '${done ? '\nCompleted - tap to review' : ''}',
                            ),
                            trailing: Icon(
                              done ? Icons.chevron_right : Icons.play_arrow,
                            ),
                            onTap: () => done
                                ? _openLoggedWorkout(context, ref, s.session.id)
                                : startSessionWithMoveToTodayPrompt(
                                    context,
                                    ref,
                                    s.session,
                                  ),
                          );
                        },
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

  /// Opens the most recent logged workout for this session. A session can be
  /// trained more than once; the latest is what someone tapping "review"
  /// almost always means.
  Future<void> _openLoggedWorkout(
    BuildContext context,
    WidgetRef ref,
    int planSessionId,
  ) async {
    final db = ref.read(appDatabaseProvider);
    final logs = await db.sessionLogDao.getLogsForPlanSession(planSessionId);
    if (logs.isEmpty || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompletedWorkoutScreen(logId: logs.first.id),
      ),
    );
  }
}
