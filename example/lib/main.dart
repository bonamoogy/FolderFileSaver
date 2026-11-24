import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const ExampleApp());

const saver = FolderFileSaver();

// -----------------------------------------------------------------------------
// The examples. Each one is a single call to folder_file_saver.
// -----------------------------------------------------------------------------

/// Downloads an image. It lands in the gallery (Android) or Photos (iOS).
Future<SavedFile> saveImageFromUrl() {
  return saver.saveFromUrl('https://dummyimage.com/600x400/09f/fff.png');
}

/// Downloads a PDF. It lands in `Documents/<App name> Documents` (Android)
/// or the app's folder in the Files app (iOS).
Future<SavedFile> savePdfFromUrl() {
  return saver.saveFromUrl(
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    fileName: 'sample', // The ".pdf" extension is added for you.
  );
}

/// Downloads a short video.
Future<SavedFile> saveVideoFromUrl() {
  return saver.saveFromUrl('https://download.samplelib.com/mp4/sample-5s.mp4');
}

/// Saves a 300 px wide copy of an image. The height keeps the aspect ratio.
Future<SavedFile> saveResizedImage() async {
  final image = await copyAssetToTempFile('assets/sample.png');
  return saver.saveResizedImage(image.path, width: 300, deleteOriginal: true);
}

/// Saves a file into a custom folder: `<App name> Notes`.
Future<SavedFile> saveFileToCustomFolder() async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/note.txt');
  await file.writeAsString('Saved by folder_file_saver at ${DateTime.now()}');

  return saver.saveFile(file.path, folderName: 'Notes', deleteOriginal: true);
}

/// Copies a bundled asset to a temporary file, so it has a file path.
Future<File> copyAssetToTempFile(String asset) async {
  final bytes = await rootBundle.load(asset);
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/${asset.split('/').last}');
  return file.writeAsBytes(bytes.buffer.asUint8List());
}

// -----------------------------------------------------------------------------
// The UI: one button per example, and the result below it.
// -----------------------------------------------------------------------------

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folder File Saver',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Folder File Saver')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ExampleTile(
            title: 'Save an image from a URL',
            run: saveImageFromUrl,
          ),
          const ExampleTile(
            title: 'Save a PDF from a URL',
            run: savePdfFromUrl,
          ),
          const ExampleTile(
            title: 'Save a video from a URL',
            run: saveVideoFromUrl,
          ),
          const ExampleTile(
            title: 'Save a resized image',
            run: saveResizedImage,
          ),
          const ExampleTile(
            title: 'Save a file to a custom folder',
            run: saveFileToCustomFolder,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: saver.openAppSettings,
            child: const Text('Open app settings'),
          ),
        ],
      ),
    );
  }
}

/// A button that runs one example and shows where the file was saved.
class ExampleTile extends StatefulWidget {
  const ExampleTile({super.key, required this.title, required this.run});

  final String title;
  final Future<SavedFile> Function() run;

  @override
  State<ExampleTile> createState() => _ExampleTileState();
}

class _ExampleTileState extends State<ExampleTile> {
  bool _saving = false;
  String? _result;

  Future<void> _onPressed() async {
    setState(() => _saving = true);
    String result;
    try {
      final saved = await widget.run();
      result = 'Saved to ${saved.path ?? saved.uri}';
    } on FolderFileSaverException catch (e) {
      result = 'Failed: ${e.message}';
      if (e.code == FolderFileSaverErrorCode.permissionDenied) {
        _askToOpenSettings();
      }
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _result = result;
    });
  }

  /// The user denied the permission, so the system will not ask again.
  /// Point them to the app settings instead.
  void _askToOpenSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Permission is needed to save files.'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: saver.openAppSettings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.tonal(
            onPressed: _saving ? null : _onPressed,
            child: Text(_saving ? 'Saving…' : widget.title),
          ),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SelectableText(
                _result!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
