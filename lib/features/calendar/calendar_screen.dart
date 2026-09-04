import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../home_screen.dart' show settingsAppBarAction;
import '../../import/gpx_import.dart';
import '../../logic/units.dart';
import '../execution/start_session_helper.dart';
import '../history/workout_history_screen.dart';
import '../settings/app_preferences.dart';

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

/// A handful of common activities, quick-pickable rather than always typing
/// a name - "Other" still allows any free text.
const _commonActivities = ['Walk', 'Run', 'Bike', 'Swim', 'Yoga', 'Hike'];

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
        onPressed: () => _chooseLogMethod(context, ref, _selectedDay),
        icon: const Icon(Icons.directions_walk),
        label: const Text('Log activity'),
      ),
      body: Builder(
        builder: (_) {
          final byDay = <DateTime, List<ScheduledSession>>{};
          for (final s in sessions) {
            final date = s.session.assignedDate;
            if (date == null) continue;
            byDay.putIfAbsent(_dayKey(date), () => []).add(s);
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
                    ? const Center(child: Text('Nothing on this day.'))
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
    // `s.session.assignedDate` is non-null here - this tile only ever comes
    // from `byDay`, which is built by grouping sessions on that same field.
    // Counting only logs on that specific day (not "ever, on any day") is
    // what stops a session from reading as done right after being moved to
    // a fresh, untrained date.
    final day = _dayKey(s.session.assignedDate!);
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
          : startSessionWithMoveToTodayPrompt(context, ref, s.session),
    );
  }

  Future<void> _chooseLogMethod(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
  ) async {
    final choice = await showModalBottomSheet<_LogMethod>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Log manually'),
              onTap: () => Navigator.of(context).pop(_LogMethod.manual),
            ),
            ListTile(
              leading: const Icon(Icons.route_outlined),
              title: const Text('Import GPX file'),
              subtitle: const Text('From a GPS watch, phone app, or bike computer'),
              onTap: () => Navigator.of(context).pop(_LogMethod.gpx),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _LogMethod.manual:
        await _logActivity(context, ref, day, initial: null);
      case _LogMethod.gpx:
        await _importGpx(context, ref, day);
    }
  }

  Future<void> _logActivity(
    BuildContext context,
    WidgetRef ref,
    DateTime day, {
    required _ActivityInput? initial,
  }) async {
    final input = await showDialog<_ActivityInput>(
      context: context,
      builder: (context) => _LogActivityDialog(day: day, initial: initial),
    );
    if (input == null) return;

    final db = ref.read(appDatabaseProvider);
    await db.sessionLogDao.createAdHocActivity(
      id: const Uuid().v4(),
      loggedAt: input.day,
      activityName: input.activityName,
      durationSec: input.durationMinutes == null
          ? null
          : input.durationMinutes! * 60,
      distance: input.distanceKm == null ? null : input.distanceKm! * 1000,
      notes: input.notes.isEmpty ? null : input.notes,
    );
    ref.invalidate(adHocActivitiesProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${input.activityName} logged.')));
  }

  /// Picks a .gpx file, parses it, and hands the result to the same
  /// [_LogActivityDialog] used for manual entry - pre-filled rather than
  /// saved straight away, so the user can still name/correct it (a GPX
  /// track often has no name at all, or one that doesn't mean anything
  /// out of context, e.g. a device's auto-generated "Activity").
  Future<void> _importGpx(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
  ) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['gpx'],
    );
    if (file == null || !context.mounted) return;

    final GpxActivity parsed;
    try {
      parsed = parseGpx(utf8.decode(await file.readAsBytes()));
    } on GpxParseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!context.mounted) return;

    await _logActivity(
      context,
      ref,
      parsed.startTime ?? day,
      initial: _ActivityInput(
        day: parsed.startTime ?? day,
        activityName: parsed.name ?? '',
        durationMinutes: parsed.durationSec == null
            ? null
            : parsed.durationSec! / 60,
        distanceKm: parsed.distanceMeters / 1000,
      ),
    );
  }
}

enum _LogMethod { manual, gpx }

class _ActivityInput {
  final DateTime day;
  final String activityName;
  final double? durationMinutes;
  final double? distanceKm;
  final String notes;

  const _ActivityInput({
    required this.day,
    required this.activityName,
    this.durationMinutes,
    this.distanceKm,
    this.notes = '',
  });
}

class _LogActivityDialog extends StatefulWidget {
  final DateTime day;
  final _ActivityInput? initial;

  const _LogActivityDialog({required this.day, this.initial});

  @override
  State<_LogActivityDialog> createState() => _LogActivityDialogState();
}

class _LogActivityDialogState extends State<_LogActivityDialog> {
  late final _nameController = TextEditingController(
    text: widget.initial?.activityName ?? '',
  );
  late final _durationController = TextEditingController(
    text: widget.initial?.durationMinutes == null
        ? ''
        : _trimZeros(widget.initial!.durationMinutes!),
  );
  late final _distanceController = TextEditingController(
    text: widget.initial?.distanceKm == null
        ? ''
        : _trimZeros(widget.initial!.distanceKm!),
  );
  final _notesController = TextEditingController();

  /// Pre-filled numbers (e.g. from a parsed GPX file) shouldn't show a
  /// trailing ".0" the user never typed.
  String _trimZeros(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log activity for ${DateFormat.yMMMd().format(widget.day)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final activity in _commonActivities)
                  ActionChip(
                    label: Text(activity),
                    onPressed: () => setState(() {
                      _nameController.text = activity;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Activity',
                hintText: 'e.g. Walk',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (min)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Distance (km)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        // A plain FilledButton here would only check the controller's text
        // once, at the dialog's first build, then never again - a known
        // gotcha (see CLAUDE.md) with any TextEditingController-derived
        // enabled state.
        ListenableBuilder(
          listenable: _nameController,
          builder: (context, _) => FilledButton(
            onPressed: _nameController.text.trim().isEmpty ? null : _submit,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      _ActivityInput(
        day: widget.day,
        activityName: _nameController.text.trim(),
        durationMinutes: double.tryParse(_durationController.text.trim()),
        distanceKm: double.tryParse(_distanceController.text.trim()),
        notes: _notesController.text.trim(),
      ),
    );
  }
}
