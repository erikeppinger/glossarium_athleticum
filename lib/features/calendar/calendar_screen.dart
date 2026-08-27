import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../execution/start_session_helper.dart';

final scheduledSessionsProvider = FutureProvider<List<ScheduledSession>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.planDao.getAllScheduledSessions();
});

DateTime _dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(scheduledSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: sessionsAsync.when(
        data: (sessions) {
          final byDay = <DateTime, List<ScheduledSession>>{};
          for (final s in sessions) {
            final date = s.session.assignedDate;
            if (date == null) continue;
            byDay.putIfAbsent(_dayKey(date), () => []).add(s);
          }
          final selected = _selectedDay;
          final selectedSessions =
              selected == null ? const <ScheduledSession>[] : byDay[_dayKey(selected)] ?? const [];

          return Column(
            children: [
              TableCalendar<ScheduledSession>(
                firstDay: DateTime(DateTime.now().year - 1),
                lastDay: DateTime(DateTime.now().year + 2),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    selected != null && isSameDay(day, selected),
                eventLoader: (day) => byDay[_dayKey(day)] ?? const [],
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              ),
              const Divider(height: 1),
              Expanded(
                child: selectedSessions.isEmpty
                    ? const Center(child: Text('No sessions on this day.'))
                    : ListView.builder(
                        itemCount: selectedSessions.length,
                        itemBuilder: (context, index) {
                          final s = selectedSessions[index];
                          return ListTile(
                            title: Text(s.session.sessionName),
                            subtitle: Text(
                              '${s.planName} • Week ${s.session.weekNumber} • ${s.session.day}',
                            ),
                            trailing: const Icon(Icons.play_arrow),
                            onTap: () => startSessionWithMoveToTodayPrompt(
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
}
