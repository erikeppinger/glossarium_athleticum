import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Thrown when a zip doesn't contain anything usable as a plan import - no
/// .csv or .xlsx found inside it at all. Per-row problems in whichever
/// spreadsheet *is* found are still reported the normal way, via
/// [PlanImportResult.errors] once it's handed to `parsePlanCsv`/`parsePlanXlsx`.
class PlanZipBundleException implements Exception {
  final String message;
  const PlanZipBundleException(this.message);
  @override
  String toString() => message;
}

/// The result of unpacking a "plan with pictures" zip: the single plan
/// spreadsheet inside (exactly one of [csvContent]/[xlsxBytes] is set,
/// mirroring `PlanImportScreen`'s own either/or contract) plus every image
/// file alongside it, keyed by filename so a spreadsheet row's "Picture"
/// column value can look one up directly.
class PlanZipBundle {
  final String? csvContent;
  final Uint8List? xlsxBytes;
  final Map<String, Uint8List> imagesByFileName;

  const PlanZipBundle({
    this.csvContent,
    this.xlsxBytes,
    required this.imagesByFileName,
  });
}

const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};

/// Unzips a "plan with pictures" bundle: one .csv or .xlsx (the plan itself,
/// same shape `parsePlanCsv`/`parsePlanXlsx` already expect - a "Picture"
/// column is optional, matched by name like every other column) sitting
/// next to the image files it references by filename. Folder structure
/// inside the zip is ignored - only each entry's own filename is used, so
/// "images/squat.jpg" and "squat.jpg" are treated the same.
///
/// The first spreadsheet found wins if a zip somehow contains more than one
/// (not expected from a normally-built bundle, but no reason to throw over
/// it) - everything else is either an image (collected) or ignored.
PlanZipBundle readPlanZipBundle(Uint8List zipBytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(zipBytes);
  } catch (e) {
    throw PlanZipBundleException('Not a valid zip file: $e');
  }

  String? csvContent;
  Uint8List? xlsxBytes;
  final images = <String, Uint8List>{};

  for (final file in archive.files) {
    if (!file.isFile) continue;
    final name = file.name.split('/').last;
    if (name.isEmpty) continue;
    final dot = name.lastIndexOf('.');
    final ext = dot == -1 ? '' : name.substring(dot).toLowerCase();
    final bytes = file.content;

    if (ext == '.csv' && csvContent == null && xlsxBytes == null) {
      csvContent = utf8.decode(bytes, allowMalformed: true);
    } else if (ext == '.xlsx' && csvContent == null && xlsxBytes == null) {
      xlsxBytes = bytes;
    } else if (_imageExtensions.contains(ext)) {
      images[name] = bytes;
    }
  }

  if (csvContent == null && xlsxBytes == null) {
    throw const PlanZipBundleException(
      'No .csv or .xlsx plan file found inside this zip.',
    );
  }

  return PlanZipBundle(
    csvContent: csvContent,
    xlsxBytes: xlsxBytes,
    imagesByFileName: images,
  );
}
