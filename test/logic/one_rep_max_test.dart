import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/one_rep_max.dart';
import 'package:training_app/logic/progression.dart';

void main() {
  group('estimateOneRepMax', () {
    test('reps=1 passes the weight through unchanged', () {
      expect(estimateOneRepMax(weightKg: 100, reps: 1), 100);
    });

    test('applies the Epley formula for reps > 1', () {
      // 100 * (1 + 5/30) = 116.666...
      expect(
        estimateOneRepMax(weightKg: 100, reps: 5),
        closeTo(116.67, 0.01),
      );
    });

    test('returns null for non-positive weight or reps', () {
      expect(estimateOneRepMax(weightKg: 0, reps: 5), isNull);
      expect(estimateOneRepMax(weightKg: -10, reps: 5), isNull);
      expect(estimateOneRepMax(weightKg: 100, reps: 0), isNull);
    });
  });

  group('bestEstimatedOneRepMax', () {
    test('picks the highest estimate across all entries, not just the latest', () {
      final history = [
        ProgressionHistoryEntry(date: DateTime(2026, 1, 1), weight: 100, reps: 5),
        ProgressionHistoryEntry(date: DateTime(2026, 2, 1), weight: 90, reps: 3),
        ProgressionHistoryEntry(date: DateTime(2026, 3, 1), weight: 95, reps: 4),
      ];
      // 100*(1+5/30)=116.67, 90*(1+3/30)=99, 95*(1+4/30)=107.67 - the first
      // (oldest) entry has the highest estimate, and must still win.
      expect(bestEstimatedOneRepMax(history), closeTo(116.67, 0.01));
    });

    test('returns null for an empty history', () {
      expect(bestEstimatedOneRepMax(const []), isNull);
    });
  });
}
