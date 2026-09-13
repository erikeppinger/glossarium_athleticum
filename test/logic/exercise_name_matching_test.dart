import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/exercise_name_matching.dart';

void main() {
  group('normalizeExerciseName', () {
    test('lowercases and collapses punctuation/whitespace', () {
      expect(normalizeExerciseName('  Deadlift!! '), 'deadlift');
    });

    test('strips apostrophes rather than turning them into a space', () {
      expect(normalizeExerciseName("Farmer's Carry"), 'farmers carry');
    });

    test('two spellings that only differ by accents now match', () {
      // The real bug this closes: a plan spelled without accents used to
      // never match a library entry that has them, since the old
      // implementation deleted the accented letter outright instead of
      // folding it to its plain base form.
      expect(
        normalizeExerciseName('Zancada Búlgara'),
        normalizeExerciseName('Zancada Bulgara'),
      );
    });

    test('an eszett folds to "ss"', () {
      expect(
        normalizeExerciseName('Straßenlauf'),
        normalizeExerciseName('Strassenlauf'),
      );
    });

    test('an umlaut folds to its plain vowel, not deleted', () {
      // Regression guard for the exact reported failure mode: the old regex
      // stripped 'ü' entirely (leaving a gap), producing "berkopfdr cken".
      expect(normalizeExerciseName('Überkopfdrücken'), 'uberkopfdrucken');
    });

    test(
      'a phonetic ASCII respelling (ue for ü) is a deliberate non-match',
      () {
        // Not a bug: folding diacritics only handles the accent itself, not
        // a locale-specific phonetic transliteration convention - doing the
        // latter risked matching unrelated words. Locking this in so a
        // future "let's make this fuzzier" change doesn't silently widen
        // matching without the tradeoff being reconsidered deliberately.
        expect(
          normalizeExerciseName('Überkopfdrücken'),
          isNot(normalizeExerciseName('Uberkopfdruecken')),
        );
      },
    );
  });
}
