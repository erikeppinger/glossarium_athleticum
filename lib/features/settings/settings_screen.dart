import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_database_provider.dart';
import '../../data/local_storage.dart';
import '../../data/seed/exercise_seed_loader.dart';
import '../../export/backup_export.dart';
import '../../import/backup_import.dart';
import '../../logic/units.dart';
import '../../security/backup_encryption.dart';
import '../exercise_library/exercise_library_providers.dart';
import '../../logic/muscle_group_colors.dart';
import '../notifications/reminder_coordinator.dart';
import '../onboarding/onboarding_screen.dart';
import 'app_preferences.dart';
import 'color_palette_screen.dart';
import 'backup_dialogs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _Section(
            title: 'Units & display',
            icon: Icons.tune,
            summary:
                '${prefs.weightUnit == WeightUnit.kg ? 'kg' : 'lbs'} • '
                '${_themeModeLabel(prefs.themeMode)}',
            children: [
          ListTile(
            leading: const Icon(Icons.monitor_weight_outlined),
            title: const Text('Weight unit'),
            subtitle: Text(
              prefs.weightUnit == WeightUnit.kg ? 'Kilograms (kg)' : 'Pounds (lbs)',
            ),
            onTap: () => _pickWeightUnit(context, ref, prefs.weightUnit),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(prefs.themeMode)),
            onTap: () => _pickThemeMode(context, ref, prefs.themeMode),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Colour palette'),
            subtitle: Text(prefs.colorPalette.label),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ColorPaletteScreen(),
              ),
            ),
          ),
            ],
          ),

          _Section(
            title: 'Calendar & progress',
            icon: Icons.calendar_month_outlined,
            summary:
                'Week starts ${prefs.weekStart == WeekStart.monday ? 'Monday' : 'Sunday'}',
            children: [
          ListTile(
            leading: const Icon(Icons.calendar_view_week),
            title: const Text('Week starts on'),
            subtitle: Text(
              prefs.weekStart == WeekStart.monday ? 'Monday' : 'Sunday',
            ),
            onTap: () => _pickWeekStart(context, ref, prefs.weekStart),
          ),
          ListTile(
            leading: const Icon(Icons.insights),
            title: const Text('Progress summary period'),
            subtitle: Text(
              prefs.summaryPeriod == SummaryPeriod.week ? 'Weekly' : 'Monthly',
            ),
            onTap: () => _pickSummaryPeriod(context, ref, prefs.summaryPeriod),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.bar_chart),
            title: const Text('Show progress charts'),
            subtitle: const Text(
              'Swipeable volume, sets, reps, and PR charts on the Progress tab.',
            ),
            value: prefs.showProgressCharts,
            onChanged: (show) => ref
                .read(appPreferencesProvider.notifier)
                .setShowProgressCharts(show),
          ),
            ],
          ),

          _Section(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            summary: !prefs.workoutRemindersEnabled && !prefs.weeklyDigestEnabled
                ? 'Off'
                : [
                    if (prefs.workoutRemindersEnabled) 'Workouts',
                    if (prefs.weeklyDigestEnabled) 'Weekly overview',
                  ].join(' • '),
            children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Workout reminders'),
            subtitle: const Text(
              'A reminder on the day of each scheduled workout.',
            ),
            value: prefs.workoutRemindersEnabled,
            onChanged: (enabled) =>
                _toggleWorkoutReminders(context, ref, enabled),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.view_week_outlined),
            title: const Text('Weekly overview'),
            subtitle: Text(
              'A weekly summary of planned sessions, on ${_weekdayName(prefs.digestWeekday)}.',
            ),
            value: prefs.weeklyDigestEnabled,
            onChanged: (enabled) => _toggleWeeklyDigest(context, ref, enabled),
          ),
          if (prefs.workoutRemindersEnabled || prefs.weeklyDigestEnabled) ...[
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Reminder time'),
              subtitle: Text(_formatMinutes(prefs.reminderTimeMinutes)),
              onTap: () => _pickReminderTime(context, ref, prefs.reminderTimeMinutes),
            ),
            if (prefs.weeklyDigestEnabled)
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Weekly overview day'),
                subtitle: Text(_weekdayName(prefs.digestWeekday)),
                onTap: () => _pickDigestWeekday(context, ref, prefs.digestWeekday),
              ),
          ],
            ],
          ),

          _Section(
            title: 'Backup & data',
            icon: Icons.folder_outlined,
            summary: 'Export, restore, erase',
            children: [
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export full backup'),
            subtitle: const Text(
              'Every plan, custom exercise, and logged session - encrypted with a passphrase you choose.',
            ),
            onTap: () => _exportBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Restore from backup'),
            subtitle: const Text(
              'Replaces everything currently on this device.',
            ),
            onTap: () => _importBackup(context, ref),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete all data',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text(
              'Permanently erases every plan, exercise, and logged session on this device.',
            ),
            onTap: () => _deleteAllData(context, ref),
          ),
            ],
          ),

          _Section(
            title: 'About',
            icon: Icons.info_outline,
            summary: 'Tour, feedback',
            children: [
          ListTile(
            leading: const Icon(Icons.explore_outlined),
            title: const Text('Take the tour'),
            subtitle: const Text('A quick walkthrough of the main features.'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => const OnboardingScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send feedback'),
            subtitle: const Text('Report a bug or suggest something, by email.'),
            onTap: () => _sendFeedback(context),
          ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _pickWeightUnit(
    BuildContext context,
    WidgetRef ref,
    WeightUnit current,
  ) async {
    final choice = await showDialog<WeightUnit>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Weight unit'),
        children: [
          for (final unit in WeightUnit.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(unit),
              child: Text(unit == WeightUnit.kg ? 'Kilograms (kg)' : 'Pounds (lbs)'),
            ),
        ],
      ),
    );
    if (choice == null || choice == current) return;
    await ref.read(appPreferencesProvider.notifier).setWeightUnit(choice);
  }

  Future<void> _pickWeekStart(
    BuildContext context,
    WidgetRef ref,
    WeekStart current,
  ) async {
    final choice = await showDialog<WeekStart>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Week starts on'),
        children: [
          for (final start in WeekStart.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(start),
              child: Text(start == WeekStart.monday ? 'Monday' : 'Sunday'),
            ),
        ],
      ),
    );
    if (choice == null || choice == current) return;
    await ref.read(appPreferencesProvider.notifier).setWeekStart(choice);
  }

  Future<void> _pickSummaryPeriod(
    BuildContext context,
    WidgetRef ref,
    SummaryPeriod current,
  ) async {
    final choice = await showDialog<SummaryPeriod>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Progress summary period'),
        children: [
          for (final period in SummaryPeriod.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(period),
              child: Text(period == SummaryPeriod.week ? 'Weekly' : 'Monthly'),
            ),
        ],
      ),
    );
    if (choice == null || choice == current) return;
    await ref.read(appPreferencesProvider.notifier).setSummaryPeriod(choice);
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Match system',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  Future<void> _pickThemeMode(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final choice = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          for (final mode in ThemeMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(mode),
              child: Text(_themeModeLabel(mode)),
            ),
        ],
      ),
    );
    if (choice == null || choice == current) return;
    await ref.read(appPreferencesProvider.notifier).setThemeMode(choice);
  }

  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _weekdayName(int weekday) => _weekdayNames[weekday - 1];

  String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Turning a reminder on needs the OS permission first - if it's refused,
  /// the switch stays off rather than silently pretending to be enabled.
  Future<bool> _ensurePermission(BuildContext context, WidgetRef ref) async {
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermissions();
    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are turned off for this app. Enable them in '
            'Android settings to use reminders.',
          ),
        ),
      );
    }
    return granted;
  }

  Future<void> _toggleWorkoutReminders(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (enabled && !await _ensurePermission(context, ref)) return;
    await ref
        .read(appPreferencesProvider.notifier)
        .setWorkoutRemindersEnabled(enabled);
    await resyncReminders(ref);
  }

  Future<void> _toggleWeeklyDigest(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (enabled && !await _ensurePermission(context, ref)) return;
    await ref
        .read(appPreferencesProvider.notifier)
        .setWeeklyDigestEnabled(enabled);
    await resyncReminders(ref);
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    await ref
        .read(appPreferencesProvider.notifier)
        .setReminderTimeMinutes(picked.hour * 60 + picked.minute);
    await resyncReminders(ref);
  }

  Future<void> _pickDigestWeekday(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final choice = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Weekly overview day'),
        children: [
          for (var weekday = 1; weekday <= 7; weekday++)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(weekday),
              child: Text(_weekdayName(weekday)),
            ),
        ],
      ),
    );
    if (choice == null || choice == current) return;
    await ref.read(appPreferencesProvider.notifier).setDigestWeekday(choice);
    await resyncReminders(ref);
  }

  Future<void> _sendFeedback(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'erik.eppinger@gmail.com',
      query: 'subject=Training App feedback',
    );
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email app found.')),
      );
    }
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final passphrase = await promptPassphrase(
      context,
      title: 'Choose a backup passphrase',
      helperText: "You'll need this exact passphrase to restore the backup.",
    );
    if (passphrase == null || passphrase.isEmpty) return;

    final db = ref.read(appDatabaseProvider);
    final backupJson = await buildBackupJson(db);
    final envelope = await encryptBackup(jsonEncode(backupJson), passphrase);

    final fileName =
        'training-app-backup-${DateTime.now().toIso8601String().substring(0, 10)}.$backupFileExtension';
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(envelope)),
      type: FileType.custom,
      allowedExtensions: [backupFileExtension],
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          uri == null ? 'Export cancelled.' : 'Backup saved.',
        ),
      ),
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [backupFileExtension],
    );
    if (file == null) return;

    if (!context.mounted) return;
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Restore from backup?',
      message:
          'This replaces everything currently on this device with the '
          "backup's contents. This can't be undone.",
      confirmLabel: 'Restore',
    );
    if (!confirmed) return;

    if (!context.mounted) return;
    final passphrase = await promptPassphrase(
      context,
      title: 'Enter the backup passphrase',
    );
    if (passphrase == null || passphrase.isEmpty) return;

    final envelope = utf8.decode(await file.readAsBytes());
    final db = ref.read(appDatabaseProvider);

    try {
      final decrypted = await decryptBackup(envelope, passphrase);
      final backupJson = jsonDecode(decrypted) as Map<String, dynamic>;
      await importBackupJson(backupJson, db);
      // The exercise library screen's providers are one-shot Futures, not
      // reactive DB streams, so they don't notice a restore's direct writes
      // on their own.
      ref.invalidate(filteredExercisesProvider);
      ref.invalidate(exerciseCategoriesProvider);
      ref.invalidate(creatorFilterOptionsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Backup restored.')));
    } on BackupDecryptionException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on BackupJsonFormatException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete all data?',
      message:
          'This permanently erases every plan, exercise, and logged '
          "session on this device. This can't be undone.",
      confirmLabel: 'Delete everything',
    );
    if (!confirmed) return;

    final db = ref.read(appDatabaseProvider);
    await db.maintenanceDao.wipeAllData();
    await deleteAllAttachments();
    await seedExerciseLibrary(db);
    // Same reasoning as the restore path above - these providers need an
    // explicit nudge to notice the wipe+reseed.
    ref.invalidate(filteredExercisesProvider);
    ref.invalidate(exerciseCategoriesProvider);
    ref.invalidate(creatorFilterOptionsProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All data deleted.')));
  }
}

/// One collapsible group of settings, collapsed by default.
///
/// The full list had grown to roughly twenty controls, which is a lot to
/// take in at once. Each section shows a one-line summary of its current
/// state while closed, so the common "what is this set to?" question is
/// answerable without expanding anything.
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final String summary;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.summary,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(summary, style: Theme.of(context).textTheme.bodySmall),
      shape: const Border(),
      collapsedShape: const Border(),
      // Nested tiles carry their own leading icons, so drop the extra
      // indent ExpansionTile would otherwise add.
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: EdgeInsets.zero,
      children: children,
    );
  }
}
