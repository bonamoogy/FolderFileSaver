# Folder File Saver

[![Pub Version](https://img.shields.io/pub/v/folder_file_saver)](https://pub.dev/packages/folder_file_saver)
[![GitHub](https://img.shields.io/github/license/bonamoogy/folderfilesaver)](https://github.com/bonamoogy/FolderFileSaver/blob/master/LICENSE)

Save files where your users can find them: in the gallery, the Photos app, or a folder named after your app.

```dart
const saver = FolderFileSaver();

final saved = await saver.saveFromUrl('https://example.com/photo.jpg');
print(saved.path); // /storage/emulated/0/Pictures/My App Pictures/photo.jpg
```

## Features

- Download a file from a URL and save it
- Save a file you already have (copy or move it)
- Save a resized copy of an image
- Save into a custom folder
- Asks for the permission it needs, and can open the app settings when the user denied it
- Android and iOS

## Where files are saved

`<App name>` is your app's name as shown on the home screen.

| File type | Android 10 and higher | Android 9 and lower | iOS |
|---|---|---|---|
| Images (jpg, png, gif, webp, heic…) | `Pictures/<App name> Pictures` | `<App name>/<App name> Pictures` | Photos library |
| Videos (mp4, mov…) | `Movies/<App name> Videos` | `<App name>/<App name> Videos` | Photos library |
| Audio (mp3, wav, aac…) | `Music/<App name> Audios` | `<App name>/<App name> Audios` | Files app: `<App name> Audios` |
| Anything else | `Documents/<App name> Documents` | `<App name>/<App name> Documents` | Files app: `<App name> Documents` |

With `folderName: 'Invoices'`, the folder becomes `<App name> Invoices` instead. The iOS Photos library has no folders, so images and videos on iOS ignore `folderName`.

If a file with the same name already exists, the new one is saved as `name (1).ext`.

## Setup

### Android

Nothing to do. Android 10 and higher needs no permission. On Android 9 and lower, the plugin asks for the storage permission itself the first time you save.

### iOS

Add these keys to `ios/Runner/Info.plist`:

```xml
<!-- Needed to save images and videos to Photos. -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Saves images and videos to your photo library.</string>

<!-- Show the app's folder in the Files app, for files that are not images or videos. -->
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

The plugin asks for the Photos permission the first time you save an image or video. It only asks to *add* photos, never to read the library.

## Usage

```dart
import 'package:folder_file_saver/folder_file_saver.dart';

const saver = FolderFileSaver();
```

### Save from a URL

```dart
final saved = await saver.saveFromUrl('https://example.com/report.pdf');
```

The file name comes from the server or the URL. You can pick your own name, and the extension is added for you if you leave it out. You can also send headers:

```dart
await saver.saveFromUrl(
  'https://api.example.com/files/42',
  fileName: 'invoice',
  headers: {'Authorization': 'Bearer $token'},
);
```

### Save a file you already have

```dart
await saver.saveFile('/path/to/video.mp4');

// Move instead of copy:
await saver.saveFile('/path/to/video.mp4', deleteOriginal: true);

// Into "<App name> Wallpapers":
await saver.saveFile('/path/to/image.png', folderName: 'Wallpapers');
```

### Save a resized image

```dart
// 300 px wide. The height follows the aspect ratio.
await saver.saveResizedImage('/path/to/image.jpg', width: 300);

// Exactly 200 x 200.
await saver.saveResizedImage('/path/to/image.jpg', width: 200, height: 200);
```

The original file is not changed. JPEG images stay JPEG; other formats are saved as PNG.

### The result

Every save returns a `SavedFile`:

| Property | Description |
|---|---|
| `name` | The name it was saved under, e.g. `photo (1).jpg` |
| `path` | Absolute path. `null` for the iOS Photos library, which has no paths |
| `uri` | `content://…` on Android 10+, `file://…` for files, `ph://…` for iOS Photos |
| `location` | A `SaveLocation`: `pictures`, `videos`, `music`, `audiobooks`, `documents`, `photos` or `files` |

### Errors

A failed save throws a `FolderFileSaverException`. Its `code` tells you why:

```dart
try {
  await saver.saveFromUrl(url);
} on FolderFileSaverException catch (e) {
  switch (e.code) {
    case FolderFileSaverErrorCode.permissionDenied:
      // The user said no. The system will not ask again, so send them to Settings.
      await saver.openAppSettings();
    case FolderFileSaverErrorCode.downloadFailed:
      // No connection, a timeout, or an HTTP error such as 404.
    default:
      print(e.message);
  }
}
```

| Code | When |
|---|---|
| `fileNotFound` | The source file does not exist |
| `permissionDenied` | Storage (Android 9 and lower) or Photos (iOS) permission was denied |
| `downloadFailed` | No connection, a timeout, or an HTTP error |
| `invalidImage` | The file is not an image that can be resized |
| `invalidArgument` | A missing or malformed argument, such as a non-http URL |
| `saveFailed` | The file could not be written |

## Migrating from 3.0 and earlier

The old methods still work but are deprecated, and will be removed in 4.0.0. They return the saved path, or `null` on failure.

| Before | Now |
|---|---|
| `saveFileFromUrl(url)` | `saveFromUrl(url)` |
| `saveFileToFolderExt(path, removeOriginFile: true)` | `saveFile(path, deleteOriginal: true)` |
| `saveFileIntoCustomDir(filePath: path, dirNamed: 'X')` | `saveFile(path, folderName: 'X')` |
| `saveImage(pathImage: path)` | `saveFile(path)` |
| `saveImage(pathImage: path, width: 100, height: 100)` | `saveResizedImage(path, width: 100, height: 100)` |
| `openSetting` | `openAppSettings()` |

You no longer need to ask for the storage permission yourself: the plugin does it when needed.

## Requirements

- Flutter 3.24 or newer
- Android 5.0 (API 21) or newer
- iOS 13 or newer

## Example

See the [example app](https://github.com/bonamoogy/FolderFileSaver/tree/master/example/lib/main.dart).
