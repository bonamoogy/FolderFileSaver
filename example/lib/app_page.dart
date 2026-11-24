import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:path_provider/path_provider.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class AppPage extends StatelessWidget {
  const AppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folder File Saver Example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _folderFileSaverPlugin = FolderFileSaver();
  final _dio = Dio();

  static const _urlVideo = 'https://download.samplelib.com/mp4/sample-5s.mp4';
  static const _urlImage =
      'https://images.unsplash.com/photo-1576039716094-066beef36943?auto=format&fit=crop&w=634&q=80';
  static const _urlPng = 'https://dummyimage.com/300/09f/fff.png';
  static const _urlPdf =
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
  static const _myCustomDir = 'My Custom Directory';

  String _platformVersion = 'Unknown';
  String? _busyAction;
  String? _progress;
  String? _lastResult;

  bool get _isBusy => _busyAction != null;

  @override
  void initState() {
    super.initState();
    _folderFileSaverPlugin.getPlatformVersion().then((version) {
      if (mounted) setState(() => _platformVersion = version ?? 'Unknown');
    });
  }

  /// Android 10 (API 29) and up saves through MediaStore, which needs no
  /// permission. Android 9 and below needs WRITE_EXTERNAL_STORAGE.
  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 29) return true;

    final status = await Permission.storage.request();
    if (status.isPermanentlyDenied) {
      await _folderFileSaverPlugin.openSetting;
    }
    return status.isGranted;
  }

  Future<String> _download(String url, String fileName) async {
    final dir = await p.getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    await _dio.download(
      url,
      path,
      onReceiveProgress: (received, total) {
        if (total <= 0 || !mounted) return;
        setState(() => _progress = '${(received / total * 100).round()}%');
      },
    );
    return path;
  }

  /// Runs [action] with a busy indicator and shows the saved path.
  Future<void> _run(String label, Future<String?> Function() action) async {
    if (!await _ensureStoragePermission()) {
      _show(label, null, error: 'Storage permission denied');
      return;
    }

    setState(() {
      _busyAction = label;
      _progress = null;
    });
    try {
      final result = await action();
      _show(label, result);
    } catch (e) {
      _show(label, null, error: e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _busyAction = null;
          _progress = null;
        });
      }
    }
  }

  void _show(String label, String? path, {String? error}) {
    final message = path != null
        ? '$label: saved to\n$path'
        : '$label: failed${error != null ? ' ($error)' : ''}';
    debugPrint(message);
    if (!mounted) return;
    setState(() => _lastResult = message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _timestamp => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String?> _saveImage() async {
    final path = await _download(_urlImage, 'resized_image_$_timestamp.jpg');
    return _folderFileSaverPlugin.saveImage(
      pathImage: path,
      width: 100,
      height: 100,
      removeOriginFile: true,
    );
  }

  Future<String?> _saveFileToCustomDir() async {
    final path = await _download(_urlImage, 'custom_dir_image_$_timestamp.jpg');
    return _folderFileSaverPlugin.saveFileIntoCustomDir(
      filePath: path,
      dirNamed: _myCustomDir,
      removeOriginFile: true,
    );
  }

  Future<String?> _saveFileToFolderExt() async {
    final path = await _download(_urlVideo, 'video_$_timestamp.mp4');
    return _folderFileSaverPlugin.saveFileToFolderExt(
      path,
      removeOriginFile: true,
    );
  }

  /// Copies an existing file. The original stays where it is.
  Future<String?> _copyFileToFolderExt() async {
    final dir = await p.getApplicationDocumentsDirectory();
    final file = File('${dir.path}/note_$_timestamp.txt');
    await file.writeAsString(
      'Created by Folder File Saver at ${DateTime.now()}',
    );
    return _folderFileSaverPlugin.saveFileToFolderExt(file.path);
  }

  Widget _button(String label, Future<String?> Function() action) {
    final busyHere = _busyAction == label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FilledButton.tonal(
        onPressed: _isBusy ? null : () => _run(label, action),
        child: Text(busyHere ? '$label… ${_progress ?? ''}'.trim() : label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder File Saver Example'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Running on: $_platformVersion', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _button('Download Image and Resize', _saveImage),
          _button('Download Image to Custom Directory', _saveFileToCustomDir),
          _button('Download Video', _saveFileToFolderExt),
          _button('Copy File to Folder', _copyFileToFolderExt),
          _button(
            'Save Image From URL',
            () => _folderFileSaverPlugin.saveFileFromUrl(_urlPng),
          ),
          _button(
            'Save PDF From URL',
            () => _folderFileSaverPlugin.saveFileFromUrl(_urlPdf),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: OutlinedButton(
              onPressed: () => _folderFileSaverPlugin.openSetting,
              child: const Text('Open App Settings'),
            ),
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            SelectableText(_lastResult!, key: const Key('last-result')),
          ],
        ],
      ),
    );
  }
}
