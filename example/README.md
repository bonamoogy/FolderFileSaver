# folder_file_saver_example

Demonstrates how to use the folder_file_saver plugin.

## Example
```dart

void _saveImage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Request Permission
      // Return int
      // 0 = permission is PERMISSION_GRANTED
      // 1 = permission is PERMISSION_DENIED
      // 2 = permission is PERMISSION_DENIED wuth (don't ask again)
      final resultPermission = await FolderFileSaver.requestPermission();

      // PERMISSION_DENIED
      if (resultPermission == 1) {
         // Do Something Here
      }
      
      // PERMISSION_DENIED wuth (don't ask again)
      if (resultPermission == 2) {
          // Do Something Info Here To User
          // await FolderFileSaver.openSetting;
      }

      // Permission Is Granted
      if (resultPermission == 0) {
          final dir = await p.getTemporaryDirectory();
          final pathImage = dir.path + ('example_image.png');
          await dio.download(urlImage, pathImage, onReceiveProgress: (rec, total) {
            setState(() {
              progress = ((rec / total) * 100).toStringAsFixed(0) + "%";
            });
          });
          final result = await FolderFileSaver.saveImage(pathImage: pathImage);
          print(result);
      }
    } catch (e) {
      print(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// if you don't need to check permission
// just do like this
void saveFileNotCheckPermission() async
{
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

// Don't forget check your permission
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

// Open settings
RaisedButton(
  onPressed: () async => await FolderFileSaver.openSetting,
  child: Text('Open Setting App'),
),

```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
