# folder_file_saver_example

### Demonstrates how to use the folder_file_saver plugin.

#### Save Image to Folder and Resize [Optional]

```dart
  void saveImage() async {
    try {
      // check permission status
      if (!await permissionIsGranted()) {
        // request permission
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final pathImage = "example_your_path_image.png";
      final result = await _folderFileSaverPlugin.saveImage(
        pathImage: pathImage,
        removeOriginFile: true,
        width: 100, // optional
        height: 100, // optional
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

```
#### Save File From URL
```dart
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
```

#### Custom Directory Of Your File

```dart
  void saveFileToCustomDir() async {
    try {
      // check permission status
      if (!await permissionIsGranted()) {
        // request permission
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final dirNamed = "My Custom Directory";
      final filePath = "<your_file_path";

      final result = await _folderFileSaverPlugin.saveFileIntoCustomDir(
        dirNamed: dirNamed,
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
```

#### Save File to Folder Ext

```dart
  void saveFolderFileExt() async {
    try {
      // check permission status
      if (!await permissionIsGranted()) {
        // request permission
        return;
      }

      // your file path
      final filePath = "<your_file_path>"

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
```

#### Copy Existing File to Ext Folder
```dart
  // copy existing file to folder ext of your app
  void copyFileToFolderExt() async {
    // check permission status
    if (!await permissionIsGranted()) {
      // request permission
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // your file path
      const fileToCopy = '<your_path>';
      
      // will return the result path of your file
      final result = await _folderFileSaverPlugin.saveFileToFolderExt(fileToCopy);

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

```

#### Open settings of your App
```dart
ElevatedButton(
    onPressed: () async {
        await _folderFileSaverPlugin.openSetting;
    },
    child: const Text('Open Setting App'),
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
