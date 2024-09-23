import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart' as p;

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  final _folderFileSaverPlugin = FolderFileSaver();

  String _progress = "0";
  bool _isLoading = false;
  final _urlVideo =
          'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
      _urlImage =
          'https://images.unsplash.com/photo-1576039716094-066beef36943?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=634&q=80';

  final sampleFileUrl = "https://dummyimage.com/300/09f/fff.png";

  final Dio dio = Dio();

  final _myCustomDir = 'My Custom Directory';

  @override
  void initState() {
    super.initState();
  }

  Future<bool> permissionIsGranted() async {
    // get the current status storage permission
    final status = await Permission.storage.status;
    return status.isGranted;

    // request permssion
    // if (status.isDenied) {
    //   await Permission.storage.request();
    // }
  }

  void _saveImage() async {
    try {
      // check permission status
      if (!await permissionIsGranted()) {
        // request permission
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final dir = await p.getTemporaryDirectory();

      final pathImage = dir.path +
          ('/your_image_named ${DateTime.now().millisecondsSinceEpoch}.png');

      await dio.download(_urlImage, pathImage, onReceiveProgress: (rec, total) {
        setState(() {
          if (total != -1) {
            _progress = "${((rec / total) * 100).toStringAsFixed(0)}%";
          }
        });
      });

      final result = await _folderFileSaverPlugin.saveImage(
        pathImage: pathImage,
        removeOriginFile: true,
        width: 100,
        height: 100,
      );

      // print the result path of your file
      print(result);
    } catch (e) {
      print(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Custom Directory of your file
  void _saveFileToCustomDir() async {
    try {
      // check permission status
      if (!await permissionIsGranted()) {
        // request permission
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final dir = await p.getTemporaryDirectory();

      final pathImage = dir.path +
          ('/your_image_named ${DateTime.now().millisecondsSinceEpoch}.png');
      await dio.download(_urlImage, pathImage, onReceiveProgress: (rec, total) {
        setState(() {
          if (total != -1) {
            _progress = "${((rec / total) * 100).toStringAsFixed(0)}%";
          }
        });
      });

      final result = await _folderFileSaverPlugin.saveFileIntoCustomDir(
        dirNamed: _myCustomDir,
        filePath: pathImage,
        removeOriginFile: true,
      );

      // print the result path of your file
      print(result);
    } catch (e) {
      print(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveFileToFolderExt() async {
    try {
      // check permission status
      if (!await permissionIsGranted()) {
        // request permission
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // get temp directory
      final dir = await p.getTemporaryDirectory();

      // create file path from temp dir
      final filePath = dir.path +
          ('/your_file_named ${DateTime.now().millisecondsSinceEpoch}.mp4');

      await dio.download(
        _urlVideo,
        filePath,
        onReceiveProgress: (rec, total) {
          setState(() {
            if (total != -1) {
              _progress = "${((rec / total) * 100).toStringAsFixed(0)}%";
            }
          });
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      // return the path of the file
      final result = await _folderFileSaverPlugin.saveFileToFolderExt(
        filePath,
        removeOriginFile: true,
      );

      // print the result path of your file
      print(result);
    } catch (e) {
      print(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // copy existing file to folder ext of your app
  void _copyFileToFolderExt() async {
    // check permission status
    if (!await permissionIsGranted()) {
      // request permission
      return;
    }

    setState(() {
      _isLoading = true;
    });

    const fileToCopy = '<your_path>';
    try {
      // copy to folder ext
      // will return the result path of your file
      final result =
          await _folderFileSaverPlugin.saveFileToFolderExt(fileToCopy);

      // print the result path of your file
      print(result);
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFileFromUrl() async {
    try {
      // check permission status
      if (!await permissionIsGranted()) {
        // request permission
        return;
      }

      setState(() {
        _isLoading = true;
      });
      final result =
          await _folderFileSaverPlugin.saveFileFromUrl(sampleFileUrl);

      // print the result path of your file
      print(result);
    } catch (e) {
      print("error : $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
      ),
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
                    ? 'Downloading $_progress'
                    : 'Download Image and Resize'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveFileToCustomDir,
                child: Text(_isLoading
                    ? 'Downloading $_progress'
                    : 'Download Image And Save to Custom Directory'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveFileToFolderExt,
                child: Text(
                    _isLoading ? 'Downloading $_progress' : 'Download File'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _copyFileToFolderExt,
                child: const Text('Copy File to Folder'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveFileFromUrl,
                child: Text(_isLoading
                    ? 'Downloading $_progress'
                    : 'Save File From URL'),
              ),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        await _folderFileSaverPlugin.openSetting;
                      },
                child: const Text('Open Setting App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
