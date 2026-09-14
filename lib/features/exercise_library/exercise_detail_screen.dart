import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/local_storage.dart';
import '../../logic/exercise_images.dart';
import '../plans/add_exercise_to_plan_screen.dart';
import '../plans/plan_providers.dart';
import '../history/history_screen.dart';
import '../shared/attachment_image.dart';
import '../shared/photo_viewer_screen.dart';
import 'create_exercise_screen.dart';
import 'exercise_library_providers.dart';

/// Shows everything the library has on one exercise - description, safety
/// notes, muscle groups, and a reference video/link - with a way to jump to
/// its logged history or add it straight into a plan. Previously, tapping
/// an exercise skipped straight to its history with no way to read about it
/// first; that's still one tap away via the app bar action.
class ExerciseDetailScreen extends ConsumerWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscleGroups = exercise.muscleGroups
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'View history',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => HistoryScreen(
                  exerciseId: exercise.id,
                  exerciseName: exercise.name,
                ),
              ),
            ),
          ),
          // Seed-library entries are reseeded on every launch, so deleting
          // one would silently be undone - only custom exercises can be
          // deleted. Editing is open to everyone, though: create_exercise_
          // screen.dart forks a built-in exercise into a new custom one
          // rather than trying to mutate the original in place.
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: exercise.isCustom
                ? 'Edit exercise'
                : 'Edit (saves as a new custom exercise)',
            onPressed: () => _edit(context),
          ),
          if (exercise.isCustom)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete exercise',
              onPressed: () => _delete(context, ref),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (parseImagePaths(exercise.imagePaths).isNotEmpty) ...[
            _ImageGallery(
              fileNames: parseImagePaths(exercise.imagePaths),
              exerciseName: exercise.name,
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Every field here is optional on a custom exercise (only the
              // name is required by create_exercise_screen.dart's form), so
              // each chip needs its own empty-string guard - movementPattern
              // was the only one that had it, so a custom exercise with,
              // say, no equipment filled in rendered a visibly empty chip
              // right after Category.
              if (exercise.category.isNotEmpty)
                Chip(label: Text(exercise.category)),
              if (exercise.movementPattern.isNotEmpty)
                Chip(label: Text(exercise.movementPattern)),
              if (exercise.equipment.isNotEmpty)
                Chip(label: Text(exercise.equipment)),
              if (exercise.difficulty.isNotEmpty)
                Chip(label: Text(exercise.difficulty)),
              if (exercise.measurementType.isNotEmpty)
                Chip(label: Text(exercise.measurementType)),
            ],
          ),
          if (muscleGroups.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Muscle groups',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(muscleGroups.join(', ')),
          ],
          if (exercise.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(exercise.description),
          ],
          if (exercise.safetyNotes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Safety notes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 4),
            Text(exercise.safetyNotes),
          ],
          if (exercise.videoReference.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Reference video',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => _openVideo(context, exercise.videoReference),
              child: Text(
                exercise.videoReference,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add to plan'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddExerciseToPlanScreen(
                  exerciseId: exercise.id,
                  exerciseName: exercise.name,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the shared create/edit form pre-filled with this exercise. Pops
  /// afterwards because this screen holds an immutable snapshot taken when it
  /// was pushed - reopening it from the (refreshed) list shows the edit.
  Future<void> _edit(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateExerciseScreen(existing: exercise),
      ),
    );
    if (saved == true && context.mounted) Navigator.of(context).pop();
  }

  /// Shows where the exercise is used before removing it, and never destroys
  /// logged sets as a side effect - a record of what you actually lifted
  /// shouldn't disappear because a library entry was tidied up.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final usage = await db.exerciseDao.getExerciseUsage(exercise.id);
    if (!context.mounted) return;

    final lines = <String>[
      if (usage.planReferences > 0)
        'It appears ${usage.planReferences} time'
            '${usage.planReferences == 1 ? '' : 's'} in '
            '${usage.planNames.length == 1 ? '' : 'these plans: '}'
            '${usage.planNames.join(', ')}. '
            'It will be removed from ${usage.planNames.length == 1 ? 'it' : 'them'}.',
      if (usage.loggedSets > 0)
        'You have logged ${usage.loggedSets} set'
            '${usage.loggedSets == 1 ? '' : 's'} of this exercise. '
            'That history is kept.',
      if (usage.isUnused)
        "It isn't used in any plan and has no logged history.",
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${exercise.name}"?'),
        content: Text(lines.join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Nothing else references these images once the row is gone.
    for (final path in parseImagePaths(exercise.imagePaths)) {
      await deleteAttachment(path);
    }
    await db.exerciseDao.deleteExerciseKeepingHistory(exercise.id);
    ref.invalidate(filteredExercisesProvider);
    ref.invalidate(exerciseCategoriesProvider);
    ref.invalidate(creatorFilterOptionsProvider);
    ref.invalidate(allExercisesForMatchingProvider);

    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _openVideo(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final launched =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't open this link.")));
    }
  }
}

/// A swipeable gallery for an exercise's photos - a single image just shows
/// itself with no chrome (matching the pre-multi-photo look exactly), so
/// this only grows more complex once there's actually more than one to page
/// between.
class _ImageGallery extends StatefulWidget {
  final List<String> fileNames;
  final String exerciseName;

  const _ImageGallery({required this.fileNames, required this.exerciseName});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Reported live: the gallery's fixed-height, BoxFit.cover thumbnails crop
  // the photo to fill their box, with no way to see the whole original -
  // tapping one now pushes PhotoViewerScreen (pinch-zoom, BoxFit.contain)
  // landing on whichever photo was actually tapped.
  void _openViewer(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          fileNames: widget.fileNames,
          initialIndex: index,
          title: widget.exerciseName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fileNames.length == 1) {
      return GestureDetector(
        key: const Key('galleryPhotoTap'),
        onTap: () => _openViewer(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AttachmentImage(
            fileName: widget.fileNames.first,
            width: double.infinity,
            height: 200,
            semanticLabel: 'Photo of ${widget.exerciseName}',
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 200,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (var i = 0; i < widget.fileNames.length; i++)
                  GestureDetector(
                    key: Key('galleryPhotoTap_$i'),
                    onTap: () => _openViewer(i),
                    child: AttachmentImage(
                      fileName: widget.fileNames[i],
                      width: double.infinity,
                      height: 200,
                      semanticLabel:
                          'Photo ${i + 1} of ${widget.fileNames.length} of '
                          '${widget.exerciseName}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.fileNames.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
