# folder_file_saver_example

Demonstrates how to use the folder_file_saver plugin.

## Example
```dart
void saveFileToFolderExt()async
{
// if you want check permission user
// use like that
// if return 0 permission is PERMISSION_GRANTED
// if return 1 permission is PERMISSION_IS_DENIED it will be open require permission
// if return 2 permission is PERMISSION_IS_DENIED with click don't ask again it will be open setting of app
await FolderFileSaver.getPermission().then((statusPermission) async {
      if (statusPermission == 0) {
        String result;
        final dir = await p.getTemporaryDirectory();
        // prepare the file and type that you want to download
        final filePath = dir.path + ('example_video.mp4');
        try {
          await dio.download(urlVideo, filePath);
          result = await FolderFileSaver.saveFileToFolderExt(filePath);
        } catch (e) {
          result = e;
        }
        print(result);
      }
    });
}

void _saveImage() async 
{
  String result;
  final dir = await p.getTemporaryDirectory();
  // prepare the file and type that you want to download
  final pathImage = dir.path + ('example_image.png');
        try {
          await dio.download(urlImage, pathImage);
          // if you want to get original of Image
          // don't give a value of width or height
          // cause default is return width = 0, height = 0
          // which will make it to get the original image
          // just write like this
          result = await FolderFileSaver.saveImage(
            pathImage: pathImage);
        } catch (e) {
          result = e;
        }
        print(result);
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
