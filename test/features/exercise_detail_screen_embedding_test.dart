import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/exercise_library/exercise_detail_screen.dart';
import 'package:training_app/features/shared/youtube_embed.dart';

// Embedding is opt-in per exercise (Exercises.embeddingAllowed) and only
// ever applies to a recognized YouTube link - confirms the detail screen
// picks the right branch in both directions rather than always falling back
// to a plain link. This test host is never actually "Android" (dart:io's
// Platform reflects the real machine running `flutter test`, not a mocked
// target - see CLAUDE.md's note on this for other Platform.isX-gated
// features), so YoutubeEmbed itself always renders its thumbnail-fallback
// path here, never the real embedded player - which is fine, this test only
// needs to confirm which widget gets built, not how it renders internally.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<Exercise> seedExercise({
    required bool embeddingAllowed,
    required String videoReference,
  }) async {
    const id = 'EX_TEST';
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: id,
        name: 'Test Exercise',
        category: 'Main Lift',
        movementPattern: 'Push',
        muscleGroups: 'Chest',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
        videoReference: Value(videoReference),
        embeddingAllowed: Value(embeddingAllowed),
      ),
    );
    return (await db.exerciseDao.getExerciseById(id))!;
  }

  Future<void> pump(WidgetTester tester, Exercise exercise) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: ExerciseDetailScreen(exercise: exercise)),
      ),
    );
    // Bounded pumps rather than pumpAndSettle(): YoutubeEmbed's thumbnail
    // fallback kicks off a real Image.network load, which never settles in
    // a test environment with no network access.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
    'embeddingAllowed + a YouTube link shows the embed widget, not the plain link',
    (tester) async {
      final exercise = await seedExercise(
        embeddingAllowed: true,
        videoReference: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      await pump(tester, exercise);

      expect(find.byType(YoutubeEmbed), findsOneWidget);
      expect(find.text(exercise.videoReference), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'embeddingAllowed=false shows the plain tappable link instead',
    (tester) async {
      final exercise = await seedExercise(
        embeddingAllowed: false,
        videoReference: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      await pump(tester, exercise);

      expect(find.byType(YoutubeEmbed), findsNothing);
      expect(find.text(exercise.videoReference), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'embeddingAllowed=true but a non-YouTube link still shows the plain link',
    (tester) async {
      final exercise = await seedExercise(
        embeddingAllowed: true,
        videoReference: 'https://example.com/some-video',
      );
      await pump(tester, exercise);

      expect(find.byType(YoutubeEmbed), findsNothing);
      expect(find.text(exercise.videoReference), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
