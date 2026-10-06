import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
import '../onboarding/whats_new_screen.dart';
import '../progress/progress_providers.dart';
import '../../l10n/app_localizations.dart';
import 'app_preferences.dart';
import 'color_palette_screen.dart';
import 'backup_dialogs.dart';
import '../shared/markdown_doc_screen.dart';
import 'templates_screen.dart';

final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _Section(
            title: l10n.unitsAndDisplaySectionTitle,
            icon: Icons.tune,
            summary:
                '${prefs.weightUnit == WeightUnit.kg ? 'kg' : 'lbs'} • '
                '${_themeModeLabel(prefs.themeMode)}',
            children: [
          ListTile(
            leading: const Icon(Icons.monitor_weight_outlined),
            title: Text(l10n.weightUnitTitle),
            subtitle: Text(
              prefs.weightUnit == WeightUnit.kg
                  ? l10n.weightUnitKg
                  : l10n.weightUnitLbs,
            ),
            onTap: () => _pickWeightUnit(context, ref, prefs.weightUnit),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: Text(l10n.themeTitle),
            subtitle: Text(_themeModeLabel(prefs.themeMode)),
            onTap: () => _pickThemeMode(context, ref, prefs.themeMode),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(l10n.clockFormatTitle),
            subtitle: Text(prefs.clockFormat.label),
            onTap: () => _pickClockFormat(context, ref, prefs.clockFormat),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.colourPaletteTitle),
            subtitle: Text(prefs.colorPalette.label),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ColorPaletteScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: Text(l10n.fitnessLevelTitle),
            subtitle: Text(
              l10n.fitnessLevelSubtitle(prefs.experienceLevel.label),
            ),
            onTap: () =>
                _pickExperienceLevel(context, ref, prefs.experienceLevel),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_graph),
            title: const Text('Progression suggestions'),
            subtitle: const Text(
              'Shows a "Suggested next session" card in exercise history, '
              'based on published resistance-training research (tap the '
              'info icon on the card for details). Turning this off does '
              'not affect logged data.',
            ),
            value: prefs.progressionSuggestionsEnabled,
            onChanged: (enabled) => ref
                .read(appPreferencesProvider.notifier)
                .setProgressionSuggestionsEnabled(enabled),
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: Text(l10n.availableEquipmentTitle),
            subtitle: Text(
              prefs.availableEquipment.isEmpty
                  ? l10n.availableEquipmentEmptySubtitle
                  : prefs.availableEquipment.join(', '),
            ),
            onTap: () => _pickAvailableEquipment(
              context,
              ref,
              prefs.availableEquipment,
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
            secondary: const Icon(Icons.straighten),
            title: const Text('Track body measurements'),
            subtitle: const Text(
              'Optional. Adds bodyweight and measurement tracking to the '
              'Progress tab. Turning it off hides it; nothing already '
              'recorded is deleted.',
            ),
            value: prefs.bodyTrackingEnabled,
            onChanged: (on) => ref
                .read(appPreferencesProvider.notifier)
                .setBodyTracking(
                  on ? BodyTracking.enabled : BodyTracking.declined,
                ),
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
          ListTile(
            leading: const Icon(Icons.summarize_outlined),
            title: const Text('Default share detail'),
            subtitle: Text(
              '${prefs.reportDetail.label} - the Progress tab\'s share '
              'button can still pick either, one-off, from its menu.',
            ),
            onTap: () => _pickReportDetail(context, ref, prefs.reportDetail),
          ),
            ],
          ),

          _Section(
            title: 'Focus mode',
            icon: Icons.center_focus_strong,
            summary: prefs.focusModeEnabled ? 'On' : 'Off',
            children: [
          SwitchListTile(
            secondary: const Icon(Icons.center_focus_strong),
            title: const Text('Focus mode'),
            subtitle: const Text(
              'Hides progress reports, PRs, and streaks so you can just '
              'train without being nudged about any of it. Nothing is '
              'deleted - turn it off anytime to see everything again.',
            ),
            value: prefs.focusModeEnabled,
            onChanged: (enabled) => ref
                .read(appPreferencesProvider.notifier)
                .setFocusModeEnabled(enabled),
          ),
          if (prefs.focusModeEnabled) ...[
            SwitchListTile(
              secondary: const Icon(Icons.bar_chart),
              title: const Text('Hide progress & PRs'),
              subtitle: const Text(
                'Empties the Progress tab and skips the trophy icon when '
                'you log a new best.',
              ),
              value: prefs.focusModeHideProgress,
              onChanged: (hide) => ref
                  .read(appPreferencesProvider.notifier)
                  .setFocusModeHideProgress(hide),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.local_fire_department_outlined),
              title: const Text('Hide streaks & weekly summary'),
              subtitle: const Text(
                'Empties the streak and "this week" cards on the Today tab.',
              ),
              value: prefs.focusModeHideStreaks,
              onChanged: (hide) => ref
                  .read(appPreferencesProvider.notifier)
                  .setFocusModeHideStreaks(hide),
            ),
          ],
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
              subtitle: Text(
                _formatMinutes(context, prefs.reminderTimeMinutes, prefs.clockFormat),
              ),
              onTap: () => _pickReminderTime(
                context,
                ref,
                prefs.reminderTimeMinutes,
                prefs.clockFormat,
              ),
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
            leading: const Icon(Icons.description_outlined),
            title: const Text('Plan / library templates'),
            subtitle: const Text(
              'Blank spreadsheet or text templates to build a plan or '
              'exercise library outside the app, then import it.',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const TemplatesScreen()),
            ),
          ),
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
            summary: "Tour, what's new, feedback",
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
            leading: const Icon(Icons.new_releases_outlined),
            title: const Text("What's new"),
            subtitle: const Text('Recently added features.'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => const WhatsNewScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send feedback'),
            subtitle: const Text('Report a bug or suggest something, by email.'),
            onTap: () => _sendFeedback(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text(
              'What this app does (and does not) do with your data.',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MarkdownDocScreen(
                  title: 'Privacy Policy',
                  assetPath: 'docs/PRIVACY_POLICY.md',
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Disclaimer'),
            subtitle: const Text(
              'Training carries risk - read this before you start.',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MarkdownDocScreen(
                  title: 'Disclaimer',
                  assetPath: 'docs/DISCLAIMER.md',
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.source_outlined),
            title: const Text('Third-Party Data'),
            subtitle: const Text(
              'Licensing for the optional wger.de starter exercise library.',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MarkdownDocScreen(
                  title: 'Third-Party Data',
                  assetPath: 'docs/THIRD_PARTY_LICENSES.md',
                ),
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final versionAsync = ref.watch(_appVersionProvider);
              return ListTile(
                leading: const Icon(Icons.tag_outlined),
                title: const Text('Version'),
                subtitle: Text(versionAsync.valueOrNull ?? '...'),
              );
            },
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
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SimpleDialog(
          title: Text(l10n.weightUnitTitle),
          children: [
            for (final unit in WeightUnit.values)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(unit),
                child: Text(
                  unit == WeightUnit.kg ? l10n.weightUnitKg : l10n.weightUnitLbs,
                ),
              ),
          ],
        );
      },
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

  Future<void> _pickReportDetail(
    BuildContext context,
    WidgetRef ref,
    ReportDetail current,
  ) async {
    final choice = await showDialog<ReportDetail>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default share detail'),
        children: [
          for (final detail in ReportDetail.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(detail),
              child: ListTile(
                title: Text(detail.label),
                subtitle: Text(detail.description),
              ),
            ),
        ],
      ),
    );
    if (choice == null || choice == current) return;
    await ref.read(appPreferencesProvider.notifier).setReportDetail(choice);
  }

  Future<void> _pickExperienceLevel(
    BuildContext context,
    WidgetRef ref,
    ExperienceLevel current,
  ) async {
    final choice = await showDialog<ExperienceLevel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.fitnessLevelTitle),
        children: [
          for (final level in ExperienceLevel.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(level),
              child: Text(level.label),
            ),
        ],
      ),
    );
    if (choice == null || choice == current) return;
    await ref.read(appPreferencesProvider.notifier).setExperienceLevel(choice);
  }

  Future<void> _pickAvailableEquipment(
    BuildContext context,
    WidgetRef ref,
    Set<String> current,
  ) async {
    final tags = await ref.read(libraryEquipmentTagsProvider.future);
    if (!context.mounted) return;
    var selection = {...current};
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.availableEquipmentTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final tag in tags)
                    CheckboxListTile(
                      title: Text(tag),
                      value: selection.contains(tag),
                      onChanged: (checked) => setState(() {
                        if (checked ?? false) {
                          selection.add(tag);
                        } else {
                          selection.remove(tag);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selection),
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    await ref
        .read(appPreferencesProvider.notifier)
        .setAvailableEquipment(result);
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
        title: Text(AppLocalizations.of(context)!.themeTitle),
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

  Future<void> _pickClockFormat(
    BuildContext context,
    WidgetRef ref,
    ClockFormat current,
  ) async {
    final choice = await showDialog<ClockFormat>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.clockFormatTitle),
        children: [
          for (final format in ClockFormat.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(format),
              child: Text(format.label),
            ),
        ],
      ),
    );
    if (choice == null || choice == current) return;
    await ref.read(appPreferencesProvider.notifier).setClockFormat(choice);
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

  /// [ClockFormat.system] follows the device's own 24-hour setting rather
  /// than guessing from locale - `MediaQuery.alwaysUse24HourFormat` is
  /// exactly the flag Flutter's own time picker uses for the same decision.
  bool _use24Hour(BuildContext context, ClockFormat format) => switch (format) {
    ClockFormat.h24 => true,
    ClockFormat.h12 => false,
    ClockFormat.system => MediaQuery.of(context).alwaysUse24HourFormat,
  };

  String _formatMinutes(BuildContext context, int minutes, ClockFormat format) {
    return formatTimeOfDay(
      minutes ~/ 60,
      minutes % 60,
      use24Hour: _use24Hour(context, format),
    );
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
    ClockFormat clockFormat,
  ) async {
    // An explicit h24/h12 choice overrides whatever the picker would
    // otherwise show for "system" (the device's own 24-hour setting) - so
    // the dialog matches what the settings row itself just displayed.
    final forced = clockFormat == ClockFormat.system
        ? null
        : clockFormat == ClockFormat.h24;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      builder: forced == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: forced),
              child: child!,
            ),
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
    final backupJson = await buildBackupJson(
      db,
      attachmentsDirectory: await getAttachmentsDirectory(),
    );
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
      await importBackupJson(
        backupJson,
        db,
        attachmentsDirectory: await getAttachmentsDirectory(),
      );
      // The exercise library screen's providers are one-shot Futures, not
      // reactive DB streams, so they don't notice a restore's direct writes
      // on their own.
      ref.invalidate(filteredExercisesProvider);
      ref.invalidate(exerciseCategoriesProvider);
      ref.invalidate(creatorFilterOptionsProvider);
      invalidateProgressProviders(ref);
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
    invalidateProgressProviders(ref);

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
