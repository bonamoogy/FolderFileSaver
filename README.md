# Folder File Saver

[![Pub Version](https://img.shields.io/pub/v/folder_file_saver)](https://pub.dev/packages/folder_file_saver)
[![GitHub](https://img.shields.io/github/license/bonamoogy/folderfilesaver)](https://github.com/bonamoogy/FolderFileSaver/blob/master/LICENSE)

Save files into a folder named after your app, sorted by file type, so they show up in the Gallery, media players and file managers.

### Features
- Save a file from a URL
- Copy an existing file into your app's folder
- Save a file into a custom directory
- Resize an image while saving it
- Open the app's settings page (e.g. to let the user grant a permission)

### Where files are saved

`<App name>` is your app's label from `AndroidManifest.xml`.

| Extension | Android 10 (Q) and higher | Android 9 and lower |
|---|---|---|
| jpg, jpeg, png | `Pictures/<App name> Pictures` | `<App name>/<App name> Pictures` |
| mp4 | `Movies/<App name> Videos` | `<App name>/<App name> Videos` |
| mp3 | `Music/<App name> Audios` | `<App name>/<App name> Audios` |
| m4a | `Audiobooks/<App name> Audios` | `<App name>/<App name> Audios` |
| anything else | `Documents/<App name> Documents` | `<App name>/<App name> Documents` |

With `saveFileIntoCustomDir`, the last folder becomes `<App name> <dirNamed>`. If a file with the same name already exists, the new one is saved as `name (1).ext`.

Every method returns the absolute path of the saved file, or `null` if saving failed. The reason is written to logcat under the `FolderFileSaver` tag.

## Setup

#### Android
- **Android 10 and higher** saves through MediaStore and needs **no permission**.
- **Android 9 and lower** needs `WRITE_EXTERNAL_STORAGE`. The plugin already declares it (limited to API 28 and lower), but you have to request it at runtime yourself, for example with [permission_handler](https://pub.dev/packages/permission_handler).

#### iOS
> **This plugin is not available for iOS yet.**

## Usage

```dart
import 'package:folder_file_saver/folder_file_saver.dart';

final saver = FolderFileSaver();

// Download a file and save it. The name comes from the URL or the server.
final path = await saver.saveFileFromUrl('https://example.com/photo.png');

// Copy an existing file (set removeOriginFile to move it instead).
await saver.saveFileToFolderExt('/path/to/video.mp4', removeOriginFile: true);

// Save into "<App name> My Folder".
await saver.saveFileIntoCustomDir(
  filePath: '/path/to/image.jpg',
  dirNamed: 'My Folder',
);

// Save a resized copy. The original file is left unchanged.
// Set only width or only height to keep the aspect ratio.
await saver.saveImage(pathImage: '/path/to/image.jpg', width: 300);

// Open the app settings page.
await saver.openSetting;
```

See [example/lib/app_page.dart](example/lib/app_page.dart) for a full app.

## Requirements
- Flutter 3.24 or newer
- Android: minSdk 21, Java 17

## Running the example

```sh
git clone https://github.com/bonamoogy/FolderFileSaver.git
cd FolderFileSaver/example
flutter pub get
flutter run
```
