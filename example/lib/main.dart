import 'package:flutter/material.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:path_provider/path_provider.dart' as p;
import 'package:dio/dio.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String progress = "0";
  bool _isLoading = false;
  final urlVideo =
          'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      urlImage =
          'https://images.unsplash.com/photo-1576039716094-066beef36943?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=634&q=80';
  Dio dio;
  @override
  void initState() {
    super.initState();
    dio = Dio();
  }

  void _saveImage() async {
    await FolderFileSaver.getPermission().then((statusPermission) async {
      if (statusPermission == 0) {
        setState(() {
          _isLoading = true;
        });
        String result;
        final dir = await p.getTemporaryDirectory();
        final pathImage = dir.path + ('example_image.png');
        try {
          await dio.download(urlImage, pathImage,
              onReceiveProgress: (rec, total) {
            setState(() {
              progress = ((rec / total) * 100).toStringAsFixed(0) + "%";
            });
          });
          // if you want to get original of Image
          // don't give a value of width or height
          // cause default is return width = 0, height = 0
          // which will make it to get the original image
          // just write like this
          result = await FolderFileSaver.saveImage(pathImage: pathImage);
        } catch (e) {
          result = e;
        }
        print(result);
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _saveFolderFileExt() async {
    // if you want check permission user
    // use like that
    // if return 0 permission is PERMISSION_GRANTED
    // if return 1 permission is PERMISSION_IS_DENIED
    // if return 2 permission is PERMISSION_IS_DENIED with click don't ask again
    await FolderFileSaver.getPermission().then((statusPermission) async {
      if (statusPermission == 0) {
        setState(() {
          _isLoading = true;
        });
        String result;
        final dir = await p.getTemporaryDirectory();
        // prepare the file and type extension that you want to download
        final filePath = dir.path + ('example_video.mp4');
        try {
          await dio.download(urlVideo, filePath,
              onReceiveProgress: (rec, total) {
            setState(() {
              progress = ((rec / total) * 100).toStringAsFixed(0) + "%";
            });
          });
          result = await FolderFileSaver.saveFileToFolderExt(filePath);
        } catch (e) {
          result = e;
        }
        print(result);
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // if you dont need to check permission
  // just do like this
  void saveFileNotCheckPermission() async {
    String result;
    final dir = await p.getTemporaryDirectory();
    // prepare the file and type extension that you want to download
    final filePath = dir.path + ('example_video.mp4');
    try {
      await dio.download(urlVideo, filePath);
      result = await FolderFileSaver.saveFileToFolderExt(filePath);
    } catch (e) {
      result = e;
    }
    print(result);
  }

  // Don't foreget check your permission
  void copyFileToNewFolder() async {
    setState(() {
      _isLoading = true;
    });
    // get your path from your device your device
    final fileToCopy = '/storage/emulated/0/DCIM/Camera/20200102_202226.jpg';
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
          title: const Text('Folder File Saver'),
          centerTitle: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              onPressed: _isLoading ? null : _saveImage,
              child: Text(_isLoading
                  ? 'Downloading $progress'
                  : 'Download Image and Resize'),
            ),
            RaisedButton(
              onPressed: _isLoading ? null : _saveFolderFileExt,
              child:
                  Text(_isLoading ? 'Downloading $progress' : 'Download File'),
            ),
            RaisedButton(
              onPressed: copyFileToNewFolder,
              child: Text('Copy File to Folder'),
            ),
            RaisedButton(
              onPressed: () async => await FolderFileSaver.openSetting,
              child: Text('Open Setting App'),
            ),
          ],
        ),
      ),
    );
  }
}
