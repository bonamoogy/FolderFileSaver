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
    final dir = await p.getTemporaryDirectory();
    final pathImage = dir.path + ('example_image.png');
    await FolderFileSaver.getPermission().then((statusPermission) async {
      if (statusPermission == 0) {
        setState(() {
          _isLoading = true;
        });
        String result;
        try {
          await dio.download(urlImage, pathImage,
              onReceiveProgress: (rec, total) {
            setState(() {
              progress = ((rec / total) * 100).toStringAsFixed(0) + "%";
            });
          });
          result = await FolderFileSaver.saveImage(
            pathImage: pathImage,
          );
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
    await FolderFileSaver.getPermission().then((statusPermission) async {
      if (statusPermission == 0) {
        setState(() {
          _isLoading = true;
        });
        final dir = await p.getTemporaryDirectory();
        final filePath = dir.path + ('example_video.mp4');
        String result;
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
              child:
                  Text(_isLoading ? 'Downloading $progress' : 'Download File'),
            ),
            RaisedButton(
              onPressed: _isLoading ? null : _saveFolderFileExt,
              child:
                  Text(_isLoading ? 'Downloading $progress' : 'Download File'),
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
