import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../exercise_library/exercise_library_import_screen.dart';
import '../shared/markdown_doc_screen.dart';
import '../shared/screen_padding.dart';

class _TemplateFile {
  final String assetPath;
  final String fileName;

  const _TemplateFile({required this.assetPath, required this.fileName});
}

const _planCsv = _TemplateFile(
  assetPath: 'templates/training_plan_template.csv',
  fileName: 'training_plan_template.csv',
);
const _planXlsx = _TemplateFile(
  assetPath: 'templates/training_plan_template.xlsx',
  fileName: 'training_plan_template.xlsx',
);
const _libraryCsv = _TemplateFile(
  assetPath: 'assets/seed-data/strongman_exercise_database.csv',
  fileName: 'exercise_library_template.csv',
);
const _libraryXlsx = _TemplateFile(
  assetPath: 'seed-data/strongman_exercise_database.xlsx',
  fileName: 'exercise_library_template.xlsx',
);
const _wgerLibraryCsv = _TemplateFile(
  assetPath: 'templates/wger_starter_library.csv',
  fileName: 'wger_starter_library.csv',
);

/// Blank(ish) templates for authoring a plan or an exercise library outside
/// the app - in a spreadsheet, on any device - then importing the result.
/// These files existed in the project since Phase 1 (`templates/`,
/// `seed-data/`) but were never reachable from a running, installed app:
/// nothing bundled them as assets, and no screen offered to save or share
/// them. That defeated the entire "low barrier to create a plan" point -
/// someone who only has the installed app, not the source repo, had no way
/// to get the template at all.
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: ListView(
        padding: screenListPadding(context),
        children: [
          Text(
            'Fill one of these in on any device - a phone, a laptop, '
            'whatever you have - then import the result from Plans or the '
            'Exercise Library. The spreadsheet versions have example rows '
            'and (for the library one) a Legend tab explaining every column; '
            'the plain-text version has the same columns with no example '
            "content, for a text editor or a device that can't open a "
            'spreadsheet at all.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Training plan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          _TemplateTile(
            title: 'Spreadsheet (.xlsx)',
            subtitle: 'Excel, Google Sheets, LibreOffice Calc',
            file: _planXlsx,
          ),
          _TemplateTile(
            title: 'Plain text (.csv)',
            subtitle: 'A text editor, or a spreadsheet app that can\'t open .xlsx',
            file: _planCsv,
          ),
          const SizedBox(height: 20),
          Text(
            'Exercise library',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          _TemplateTile(
            title: 'Spreadsheet (.xlsx)',
            subtitle: 'Includes a Legend tab explaining every column',
            file: _libraryXlsx,
          ),
          _TemplateTile(
            title: 'Plain text (.csv)',
            subtitle: 'Same columns, no Legend tab',
            file: _libraryCsv,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Exercise photos: add a "Picture" column to either template '
              'naming an image file (e.g. "bench_press.jpg" - already in '
              'the plan template above), then zip the spreadsheet together '
              'with those image files and use "From spreadsheet + pictures '
              '(.zip)" when importing from Plans or the Exercise Library - '
              'the photo attaches to the resulting exercise either way. A '
              'plain .csv/.xlsx import by itself can\'t carry the image, '
              'since a spreadsheet cell can only hold text.\n\n'
              'Bringing existing photos along a different way - exporting/'
              'importing a library file (.json or the encrypted .tlibrary) '
              'instead - also keeps them, if you\'d rather do that; see the '
              'Exercise Library\'s own share menu.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Starter library (general fitness, from wger.de)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _importWgerLibrary(context),
            icon: const Icon(Icons.playlist_add),
            label: const Text('Import into your library now'),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '~900 general-fitness exercises from wger.de\'s open '
                  'exercise database, licensed CC BY-SA. This is a separate, '
                  'optional starter set - importing it adds these as their '
                  'own manageable group; it does not replace or merge with '
                  'your existing library. wger doesn\'t track difficulty or '
                  'a weight/time/distance measurement type, so both are '
                  'defaulted here - adjust individual exercises after '
                  'importing if that matters to you. The import screen '
                  'shows every exercise before anything is saved, same as '
                  'any other import.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MarkdownDocScreen(
                        title: 'Third-Party Data',
                        assetPath: 'docs/THIRD_PARTY_LICENSES.md',
                      ),
                    ),
                  ),
                  child: const Text('See the full license notice'),
                ),
              ],
            ),
          ),
          _TemplateTile(
            title: 'Spreadsheet (.csv)',
            subtitle: 'Save or share the raw file instead - e.g. to '
                'inspect it first or hand it to someone else',
            file: _wgerLibraryCsv,
          ),
        ],
      ),
    );
  }

  /// Reads the bundled wger CSV directly and jumps straight to the same
  /// preview/import screen a manually-picked file would reach - skipping
  /// the save-then-reimport round trip the file-picker path needs, but
  /// deliberately not skipping the preview screen itself: every other
  /// import in this app shows what it's about to do before writing
  /// anything, and a bulk third-party import (with its own defaulted
  /// Difficulty/Measurement Type fields - see docs/THIRD_PARTY_LICENSES.md)
  /// is exactly the case where that review matters most.
  ///
  /// No widget test drives this button end-to-end: `await
  /// rootBundle.loadString(...)` inside a `testWidgets` callback hung for
  /// the full test timeout on this machine, even called as the very first
  /// line before any `pumpWidget` - a new variant of this project's already
  /// -documented "real async I/O inside testWidgets can hang" gotcha (see
  /// CLAUDE.md), not previously known to extend to asset loads, only
  /// `dart:io`. `ExerciseLibraryImportScreen(csvContent: ...)` itself is
  /// already covered directly (`exercise_library_import_screen_test.dart`);
  /// this method is the thin, reviewed-by-eye glue between that and the
  /// bundled asset, verified live instead (build + tap the real button).
  Future<void> _importWgerLibrary(BuildContext context) async {
    final csv = await rootBundle.loadString(_wgerLibraryCsv.assetPath);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseLibraryImportScreen(csvContent: csv),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final _TemplateFile file;

  const _TemplateTile({
    required this.title,
    required this.subtitle,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Save',
            onPressed: () => _save(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => _share(context),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _loadBytes() async {
    final data = await rootBundle.load(file.assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  String get _extension => p.extension(file.fileName).replaceFirst('.', '');

  Future<void> _save(BuildContext context) async {
    final bytes = await _loadBytes();
    final uri = await FilePicker.saveFile(
      fileName: file.fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: [_extension],
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uri == null ? 'Save cancelled.' : 'Saved.')),
    );
  }

  Future<void> _share(BuildContext context) async {
    final bytes = await _loadBytes();
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, file.fileName));
    await tempFile.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(tempFile.path)], text: title),
    );
  }
}
