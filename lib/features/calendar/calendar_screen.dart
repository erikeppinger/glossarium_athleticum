import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../home_screen.dart' show homeTabIndexProvider, settingsAppBarAction;
import '../../logic/units.dart';
import '../execution/start_session_helper.dart';
import '../history/workout_history_screen.dart';
import '../settings/app_preferences.dart';
import 'log_activity_flow.dart';

final scheduledSessionsProvider = FutureProvider<List<ScheduledSession>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.planDao.getAllScheduledSessions();
});

/// Maps a scheduled `PlanSessions` id to how many times it's been logged on
/// each calendar day - see `SessionLogDao.getLoggedPlanSessionCounts`. Keyed
/// by day (not just by session id) so a session that gets moved to a new,
/// not-yet-trained date doesn't read as already "done" just because it was
/// logged once under an earlier date. The provider keeps its original name
/// (other features only ever invalidate it, never read its value, so the
/// shape change is invisible to them).
final loggedPlanSessionIdsProvider =
    FutureProvider<Map<int, Map<DateTime, int>>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionLogDao.getLoggedPlanSessionCounts();
});

/// Walks/runs/anything else logged directly against a date rather than a
/// scheduled plan session - see `lib/data/tables/session_logs_table.dart`.
final adHocActivitiesProvider = FutureProvider<List<SessionLog>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionLogDao.getAdHocActivities();
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
    // .valueOrNull rather than .when(): scheduledSessionsProvider gets
    // invalidated by several unrelated actions elsewhere (assigning a
    // session date, archiving/deleting a plan, moving a session to today) -
    // gating the whole body (including TableCalendar itself) behind
    // .when()'s loading branch meant every one of those briefly tore down
    // and rebuilt the entire calendar from a spinner, which could read as
    // "the page reloads" if it happened while scrolling/paging through
    // months. Riverpod keeps a FutureProvider's previous value available
    // through a refresh, so rendering straight from valueOrNull (matching
    // loggedPlanSessionIdsProvider/adHocActivitiesProvider below, which
    // already did this) lets a background refetch update in place instead.
    final sessionsAsync = ref.watch(scheduledSessionsProvider);
    final sessions = sessionsAsync.valueOrNull ?? const <ScheduledSession>[];
    final weekStart = ref.watch(appPreferencesProvider).weekStart;
    final loggedCounts =
        ref.watch(loggedPlanSessionIdsProvider).valueOrNull ??
        const <int, Map<DateTime, int>>{};
    final adHocActivities =
        ref.watch(adHocActivitiesProvider).valueOrNull ?? const <SessionLog>[];

    final adHocByDay = <DateTime, List<SessionLog>>{};
    for (final a in adHocActivities) {
      adHocByDay.putIfAbsent(_dayKey(a.loggedAt), () => []).add(a);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_outlined),
            tooltip: 'Jump to today',
            onPressed: _jumpToToday,
          ),
          settingsAppBarAction(context),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLogActivityFlow(context, ref, _selectedDay),
        icon: const Icon(Icons.directions_walk),
        label: const Text('Log activity'),
      ),
      body: Builder(
        builder: (_) {
          // Each ScheduledSession is already one (session, date) occurrence
          // (see PlanDao.getAllScheduledSessions) - a session scheduled on
          // several dates just appears here once per date, no null-check
          // needed since the DAO's join only ever returns dated rows.
          final byDay = <DateTime, List<ScheduledSession>>{};
          for (final s in sessions) {
            byDay.putIfAbsent(_dayKey(s.date), () => []).add(s);
          }
          final selected = _selectedDay;
          final selectedSessions = byDay[_dayKey(selected)] ?? const [];
          final selectedActivities = adHocByDay[_dayKey(selected)] ?? const [];

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
                    final hasAdHoc =
                        adHocByDay[_dayKey(day)]?.isNotEmpty ?? false;
                    if (events.isEmpty && !hasAdHoc) return null;
                    // Checked against `day` itself, not just "was this
                    // session ever logged" - a session moved to a new date
                    // after already being completed on its old date must not
                    // show that old completion here. `events` only contains
                    // sessions currently assigned to this exact day (see
                    // `byDay` below), so this is exactly "was it logged on
                    // the day it's assigned to now."
                    final hasCompleted =
                        hasAdHoc ||
                        events.any(
                          (s) =>
                              (loggedCounts[s.session.id]?[_dayKey(day)] ??
                                  0) >
                              0,
                        );
                    // TableCalendar's own day cells already carry a full,
                    // readable date label ("Thursday, September 3, 2026")
                    // out of the box - but this marker is drawn as a plain
                    // decoration on top of that, so without its own
                    // Semantics it's a colour/icon-only signal: a screen
                    // reader has no way to tell a day with a workout apart
                    // from an empty one.
                    if (hasCompleted) {
                      return Positioned(
                        bottom: 1,
                        child: Semantics(
                          label: 'Has a completed workout',
                          child: Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                      );
                    }
                    return Positioned(
                      bottom: 1,
                      child: Semantics(
                        label: 'Has a scheduled workout',
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: selectedSessions.isEmpty && selectedActivities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Nothing on this day.'),
                            const SizedBox(height: 12),
                            // Previously the only way to start a workout on
                            // an unscheduled day was to switch to the Plans
                            // tab yourself - reported live as an extra,
                            // easy-to-miss step.
                            OutlinedButton.icon(
                              onPressed: () => ref
                                  .read(homeTabIndexProvider.notifier)
                                  .state = 2,
                              icon: const Icon(Icons.list_alt),
                              label: const Text('Browse plans'),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 88),
                        children: [
                          for (final s in selectedSessions)
                            _scheduledSessionTile(context, s, loggedCounts),
                          for (final a in selectedActivities)
                            ListTile(
                              leading: Icon(
                                Icons.directions_walk,
                                color: Colors.green.shade700,
                              ),
                              title: Text(a.activityName ?? 'Activity'),
                              subtitle: Text(
                                [
                                  if (a.durationSec != null)
                                    formatDurationSec(a.durationSec!),
                                  if (a.distance != null)
                                    formatDistanceMeters(a.distance!),
                                ].join(' • '),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CompletedWorkoutScreen(logId: a.id),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDay = now;
      _focusedDay = now;
    });
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

  Widget _scheduledSessionTile(
    BuildContext context,
    ScheduledSession s,
    Map<int, Map<DateTime, int>> loggedCounts,
  ) {
    // Counting only logs on this specific occurrence's day (not "ever, on
    // any day") is what stops a session from reading as done right after
    // being moved to a fresh, untrained date.
    final day = _dayKey(s.date);
    final count = loggedCounts[s.session.id]?[day] ?? 0;
    final done = count > 0;
    return ListTile(
      leading: done
          ? Icon(Icons.check_circle, color: Colors.green.shade700)
          : null,
      title: Text(s.session.sessionName),
      subtitle: Text(
        '${s.planName} • Week ${s.session.weekNumber}'
        // "Any" is an internal placeholder for an unscheduled weekday;
        // showing it reads as though the user picked it.
        '${s.session.day == 'Any' ? '' : ' • ${s.session.day}'}'
        // The scheduled slot itself never multiplies - it's still one
        // calendar row - but training it more than once in a day is real,
        // tracked data (each logging shows up in Progress independently),
        // so a plain "Completed" would look like the second one vanished.
        '${done ? '\nCompleted${count > 1 ? ' ${count}x' : ''} - tap to review' : ''}',
      ),
      trailing: Icon(done ? Icons.chevron_right : Icons.play_arrow),
      onTap: () => done
          ? _openLoggedWorkout(context, ref, s.session.id)
          : startSessionWithMoveToTodayPrompt(context, ref, s.session, s.date),
    );
  }
}
