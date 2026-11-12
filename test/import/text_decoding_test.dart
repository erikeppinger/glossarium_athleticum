import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/import/text_decoding.dart';
import 'package:training_app/import/xlsx_reader.dart';

// Found in the 2026-11 code review: umlauts were garbled in every Excel
// import, and a CSV saved by German Excel (Windows-1252) crashed the import
// screen.
void main() {
  test('a UTF-8 file is read as UTF-8', () {
    expect(decodeTextFile(utf8.encode('Körper – Übung')), 'Körper – Übung');
  });

  test('a Windows-1252 file is read instead of throwing', () {
    // "Körper – 5€" as Excel's plain CSV format writes it.
    final bytes = [
      0x4B, 0xF6, 0x72, 0x70, 0x65, 0x72, 0x20, 0x96, 0x20, 0x35, 0x80, //
    ];
    expect(decodeTextFile(bytes), 'Körper – 5€');
  });

  test('an .xlsx keeps umlauts and dashes', () {
    final archive = Archive();
    void add(String name, String xml) {
      final bytes = utf8.encode(xml);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add(
      'xl/workbook.xml',
      '<workbook xmlns:r="x"><sheets>'
          '<sheet name="P" sheetId="1" r:id="rId1"/></sheets></workbook>',
    );
    add(
      'xl/_rels/workbook.xml.rels',
      '<Relationships>'
          '<Relationship Id="rId1" Target="worksheets/sheet1.xml"/>'
          '</Relationships>',
    );
    add('xl/sharedStrings.xml', '<sst><si><t>Körper – Übung</t></si></sst>');
    add(
      'xl/worksheets/sheet1.xml',
      '<worksheet><sheetData><row>'
          '<c r="A1" t="s"><v>0</v></c></row></sheetData></worksheet>',
    );
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));

    expect(readXlsxSheets(bytes).single.single.single, 'Körper – Übung');
  });
}
