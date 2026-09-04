import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
        padding: const EdgeInsets.all(16),
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
              'Exercise photos: the spreadsheet/text templates can\'t carry '
              'an image the way an exported plan file can (there\'s no '
              'reliable way on every device to point a spreadsheet cell at '
              'a photo file and have the app find it). Add photos to an '
              'exercise after importing, from the exercise\'s own screen, '
              'or use a JSON plan export instead - see the Plan screen\'s '
              'share menu.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
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
