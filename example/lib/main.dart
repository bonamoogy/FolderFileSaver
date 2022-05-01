import 'package:flutter/material.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:path_provider/path_provider.dart' as p;
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String progress = "0";
  bool _isLoading = false;
  final urlVideo =
          'https://media.istockphoto.com/videos/lovely-puppy-labrador-running-to-the-camera-on-the-lawn-4k-video-id1073535242',
      urlImage =
          'https://images.unsplash.com/photo-1576039716094-066beef36943?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=634&q=80';

  late final Dio dio;
  @override
  void initState() {
    dio = Dio();
    super.initState();
  }

  void _saveImage() async {
    try {
      // get status permission
      final status = await Permission.storage.status;

      // check status permission
      if (status.isDenied) {
        // request permission
        await Permission.storage.request();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // do save
      await _doSaveImage();
    } catch (e) {
      print(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveFolderFileExt() async {
    try {
      // get status permission
      final status = await Permission.storage.status;

      // check status permission
      if (status.isDenied) {
        // request permission
        await Permission.storage.request();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // do save
      await _doSave();
    } catch (e) {
      print(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Don't forget to check
  // device permission
  Future<void> _doSaveImage() async {
    final dir = await p.getTemporaryDirectory();
    final pathImage = dir.path + ('/example_image.png');
    await dio.download(urlImage, pathImage, onReceiveProgress: (rec, total) {
      setState(() {
        progress = ((rec / total) * 100).toStringAsFixed(0) + "%";
      });
    });
    // if you want to get original of Image
    // don't give a value of width or height
    // cause default is return width = 0, height = 0
    // which will make it to get the original image
    // just write like this
    // remove originFile default = false
    final result = await FolderFileSaver.saveImage(
      pathImage: pathImage,
      removeOriginFile: true,
    );
    print(result);
  }

  // Don't forget to check
  // device permission
  Future<void> _doSave() async {
    final dir = await p.getTemporaryDirectory();
    // prepare the file and type extension that you want to download
    // remove originFile after success default = false
    final filePath = dir.path + ('/example_video.mp4');
    await dio.download(urlVideo, filePath, onReceiveProgress: (rec, total) {
      setState(() {
        progress = ((rec / total) * 100).toStringAsFixed(0) + "%";
      });
    });
    final result = await FolderFileSaver.saveFileToFolderExt(
      filePath,
      removeOriginFile: true,
    );
    print(result);
  }

  // Don't forget to check
  // device permission
  void saveFile() async {
    String? result = '';
    final dir = await p.getTemporaryDirectory();
    // prepare the file and type extension that you want to download
    final filePath = dir.path + ('/example_video.mp4');
    try {
      await dio.download(urlVideo, filePath);
      result = await FolderFileSaver.saveFileToFolderExt(filePath);
    } catch (e) {
      result = e.toString();
    }
    print(result);
  }

  // Don't foreget check your permission
  void copyFileToNewFolder() async {
    setState(() {
      _isLoading = true;
    });
    // get your path from your device your device
    // final fileToCopy = '/storage/emulated/0/DCIM/Camera/20200102_202226.jpg'; // example
    // remove originFile default = false
    final fileToCopy = '<local_path_from_your_device>';
    try {
      await FolderFileSaver.saveFileToFolderExt(fileToCopy);
    } catch (e) {
      print(e);
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Folder File Saver Example'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _isLoading ? null : _saveImage,
                child: Text(_isLoading
                    ? 'Downloading $progress'
                    : 'Download Image and Resize'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveFolderFileExt,
                child: Text(
                    _isLoading ? 'Downloading $progress' : 'Download File'),
              ),
              ElevatedButton(
                onPressed: copyFileToNewFolder,
                child: Text('Copy File to Folder'),
              ),
              ElevatedButton(
                onPressed: () async => await FolderFileSaver.openSetting,
                child: Text('Open Setting App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
