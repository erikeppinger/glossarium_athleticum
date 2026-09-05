import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Thrown when a file isn't readable as an .xlsx workbook at all (not a zip,
/// or missing the parts every .xlsx must have) - as opposed to a problem
/// with what's *in* a sheet, which the caller (a specific importer's
/// required-column check) reports instead.
class XlsxFormatException implements Exception {
  final String message;
  const XlsxFormatException(this.message);
  @override
  String toString() => message;
}

/// A minimal, dependency-free (beyond the `archive`/`xml` packages this
/// project already needs elsewhere) reader for the small slice of the
/// .xlsx (OOXML spreadsheet) format this app's importers need: an .xlsx
/// file is a zip of XML parts - `xl/workbook.xml` lists sheets in order,
/// `xl/_rels/workbook.xml.rels` maps each sheet to its actual
/// `worksheets/sheetN.xml` file (not necessarily in numeric order - never
/// assume sheet1.xml is the first *declared* sheet), `xl/sharedStrings.xml`
/// holds the de-duplicated string table most text cells reference by index,
/// and each worksheet's `<row>`/`<c>` elements hold the actual cell grid.
///
/// Deliberately not a general-purpose xlsx library (no styles, formulas,
/// merged cells, dates-as-numbers, multiple workbook parts, etc.) - just
/// enough to read the plain data-grid templates this app hands out. The
/// `excel` package would normally be the standard choice here, but its
/// published versions all require `xml <7.0.0`, which conflicts with both
/// this project's own `xml ^7.0.1` pin (already security-reviewed at that
/// version - see CLAUDE.md) and the `pdf` package's own transitive
/// requirement on it.
///
/// Returns one [List<List<String>>] (rows of cell text, blank cells as
/// `''`) per sheet, in the workbook's own declared sheet order - the
/// caller decides which sheet actually has the data it wants (see
/// `parsePlanXlsx`/`parseExerciseXlsx`, which try each in turn against
/// their own required columns, so an "Instructions"/"Legend" tab ahead of
/// the real data is skipped automatically rather than needing a hardcoded
/// sheet name or position).
List<List<List<String>>> readXlsxSheets(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const XlsxFormatException('Not a valid .xlsx file.');
  }

  String? readPart(String name) {
    final file = archive.findFile(name);
    if (file == null) return null;
    return String.fromCharCodes(file.content as List<int>);
  }

  final workbookXml = readPart('xl/workbook.xml');
  if (workbookXml == null) {
    throw const XlsxFormatException('Not a valid .xlsx file (missing workbook.xml).');
  }
  final relsXml = readPart('xl/_rels/workbook.xml.rels');
  if (relsXml == null) {
    throw const XlsxFormatException(
      'Not a valid .xlsx file (missing workbook.xml.rels).',
    );
  }

  final relTargetById = <String, String>{};
  for (final rel in XmlDocument.parse(relsXml).findAllElements('Relationship')) {
    final id = rel.getAttribute('Id');
    final target = rel.getAttribute('Target');
    if (id != null && target != null) {
      relTargetById[id] = target.startsWith('/') ? target.substring(1) : 'xl/$target';
    }
  }

  final sharedStrings = _readSharedStrings(readPart('xl/sharedStrings.xml'));

  final sheetIds = XmlDocument.parse(
    workbookXml,
  ).findAllElements('sheet').map((e) => e.getAttribute('r:id')).whereType<String>();

  final sheets = <List<List<String>>>[];
  for (final id in sheetIds) {
    final target = relTargetById[id];
    if (target == null) continue;
    final sheetXml = readPart(target);
    if (sheetXml == null) continue;
    sheets.add(_readSheetRows(sheetXml, sharedStrings));
  }

  if (sheets.isEmpty) {
    throw const XlsxFormatException('This workbook has no readable sheets.');
  }
  return sheets;
}

List<String> _readSharedStrings(String? xml) {
  if (xml == null) return const [];
  final doc = XmlDocument.parse(xml);
  return doc.findAllElements('si').map((si) {
    // Concatenates every <t> found anywhere under this <si>, whether it's a
    // plain string entry (<si><t>...</t></si>) or made of rich-text runs
    // (<si><r><t>...</t></r><r><t>...</t></r></si>) - either way the cell's
    // actual text is just those pieces joined together.
    return si.findAllElements('t').map((t) => t.innerText).join();
  }).toList();
}

List<List<String>> _readSheetRows(String xml, List<String> sharedStrings) {
  final doc = XmlDocument.parse(xml);
  final rows = <List<String>>[];

  for (final row in doc.findAllElements('row')) {
    final cells = <int, String>{};
    var maxColumn = -1;
    for (final cell in row.findElements('c')) {
      final ref = cell.getAttribute('r');
      final column = ref == null ? cells.length : _columnIndexFromRef(ref);
      if (column > maxColumn) maxColumn = column;
      cells[column] = _cellText(cell, sharedStrings);
    }
    rows.add([for (var i = 0; i <= maxColumn; i++) cells[i] ?? '']);
  }
  return rows;
}

String _cellText(XmlElement cell, List<String> sharedStrings) {
  final type = cell.getAttribute('t');
  if (type == 'inlineStr') {
    final text = cell.findElements('is').firstOrNull;
    return text?.findAllElements('t').map((t) => t.innerText).join() ?? '';
  }
  final value = cell.findElements('v').firstOrNull?.innerText;
  if (value == null) return '';
  if (type == 's') {
    final index = int.tryParse(value);
    if (index == null || index < 0 || index >= sharedStrings.length) return '';
    return sharedStrings[index];
  }
  return value;
}

/// "A1" -> 0, "B1" -> 1, "AA1" -> 26, ... - the letters-only prefix of a
/// cell reference encodes its column in base 26 (A=1, not A=0, hence the
/// -1 at the end to make it a 0-based index matching this reader's rows).
int _columnIndexFromRef(String ref) {
  var index = 0;
  for (final code in ref.codeUnits) {
    if (code < 65 || code > 90) break; // stops at the first digit
    index = index * 26 + (code - 64);
  }
  return index - 1;
}
