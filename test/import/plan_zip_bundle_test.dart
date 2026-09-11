import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/import/plan_zip_bundle.dart';

Uint8List _buildZip(Map<String, List<int>> entries) {
  final archive = Archive();
  for (final entry in entries.entries) {
    archive.addFile(
      ArchiveFile(entry.key, entry.value.length, entry.value),
    );
  }
  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded);
}

void main() {
  group('readPlanZipBundle', () {
    test('extracts the csv and images by filename', () {
      final csvBytes = utf8.encode('Week,Day\n1,Mon\n');
      final zip = _buildZip({
        'plan.csv': csvBytes,
        'images/bench.jpg': [1, 2, 3],
        'squat.png': [4, 5, 6],
      });

      final bundle = readPlanZipBundle(zip);
      expect(bundle.csvContent, 'Week,Day\n1,Mon\n');
      expect(bundle.xlsxBytes, isNull);
      expect(bundle.imagesByFileName.keys, containsAll(['bench.jpg', 'squat.png']));
      expect(bundle.imagesByFileName['bench.jpg'], [1, 2, 3]);
      // The zip's own folder structure is ignored - only the filename
      // itself is used as the lookup key.
      expect(bundle.imagesByFileName.containsKey('images/bench.jpg'), isFalse);
    });

    test('extracts xlsx bytes instead of csv when that\'s what the zip has', () {
      final zip = _buildZip({
        'plan.xlsx': [10, 20, 30],
        'photo.jpg': [1],
      });

      final bundle = readPlanZipBundle(zip);
      expect(bundle.csvContent, isNull);
      expect(bundle.xlsxBytes, [10, 20, 30]);
      expect(bundle.imagesByFileName, {'photo.jpg': [1]});
    });

    test('throws when the zip has no .csv or .xlsx at all', () {
      final zip = _buildZip({'readme.txt': utf8.encode('hi')});
      expect(
        () => readPlanZipBundle(zip),
        throwsA(isA<PlanZipBundleException>()),
      );
    });

    test('throws for bytes that are not a real zip', () {
      expect(
        () => readPlanZipBundle(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(isA<PlanZipBundleException>()),
      );
    });
  });
}
