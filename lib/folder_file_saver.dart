/// Save files into a folder named after your app, sorted by file type.
library;

import 'folder_file_saver_platform_interface.dart';
import 'src/folder_file_saver_exception.dart';
import 'src/saved_file.dart';

export 'src/folder_file_saver_exception.dart';
export 'src/saved_file.dart';

/// Saves files where the user can find them: the gallery, media players,
/// file managers and, on iOS, the Photos and Files apps.
///
/// Where a file goes depends on its type:
///
/// | File type      | Android 10+                         | iOS                       |
/// |----------------|-------------------------------------|---------------------------|
/// | Images         | `Pictures/<App name> Pictures`      | Photos library            |
/// | Videos         | `Movies/<App name> Videos`          | Photos library            |
/// | Audio          | `Music/<App name> Audios`           | Files: `<App name> Audios`|
/// | Anything else  | `Documents/<App name> Documents`    | Files: `<App name> Documents` |
///
/// Pass `folderName` to use `<App name> <folderName>` instead of the
/// type-based name. The iOS Photos library has no folders, so `folderName`
/// does not apply there.
///
/// Every method throws a [FolderFileSaverException] when the file cannot be
/// saved.
class FolderFileSaver {
  const FolderFileSaver();

  static FolderFileSaverPlatform get _platform =>
      FolderFileSaverPlatform.instance;

  /// Copies the file at [filePath] into the app's folder for its type.
  ///
  /// Set [deleteOriginal] to move the file instead of copying it.
  Future<SavedFile> saveFile(
    String filePath, {
    String? folderName,
    bool deleteOriginal = false,
  }) {
    return _platform.saveFile(
      filePath: filePath,
      folderName: folderName,
      deleteOriginal: deleteOriginal,
    );
  }

  /// Saves a resized copy of the image at [imagePath]. The original is left
  /// unchanged unless [deleteOriginal] is true.
  ///
  /// Give [width], [height] or both, in pixels. With only one of them, the
  /// other is calculated to keep the aspect ratio. JPEG images stay JPEG;
  /// other formats are saved as PNG.
  Future<SavedFile> saveResizedImage(
    String imagePath, {
    int? width,
    int? height,
    String? folderName,
    bool deleteOriginal = false,
  }) {
    if ((width == null || width <= 0) && (height == null || height <= 0)) {
      throw ArgumentError('Give a width or a height greater than 0.');
    }
    return _platform.saveResizedImage(
      imagePath: imagePath,
      width: width,
      height: height,
      folderName: folderName,
      deleteOriginal: deleteOriginal,
    );
  }

  /// Downloads [url] and saves it into the app's folder for its type.
  ///
  /// The file name comes from the server or the URL, unless you pass
  /// [fileName]. Use [headers] for things like an `Authorization` header.
  Future<SavedFile> saveFromUrl(
    String url, {
    String? fileName,
    String? folderName,
    Map<String, String>? headers,
  }) {
    return _platform.saveFromUrl(
      url: url,
      fileName: fileName,
      folderName: folderName,
      headers: headers,
    );
  }

  /// Opens this app's page in the system settings, so the user can grant a
  /// permission they denied before. Returns whether the page was opened.
  Future<bool> openAppSettings() => _platform.openAppSettings();

  // ---------------------------------------------------------------------------
  // Deprecated API. Kept so existing apps keep working. These return the
  // saved path (or URI on iOS Photos), or null when saving fails.
  // ---------------------------------------------------------------------------

  @Deprecated('Not related to saving files. Will be removed in 4.0.0.')
  Future<String?> getPlatformVersion() => _platform.getPlatformVersion();

  @Deprecated(
    'Use saveFile, or saveResizedImage to resize. Will be removed in 4.0.0.',
  )
  Future<String?> saveImage({
    required String pathImage,
    int width = 0,
    int height = 0,
    bool removeOriginFile = false,
  }) {
    if (width <= 0 && height <= 0) {
      return _legacy(
        () => saveFile(pathImage, deleteOriginal: removeOriginFile),
      );
    }
    return _legacy(
      () => saveResizedImage(
        pathImage,
        width: width > 0 ? width : null,
        height: height > 0 ? height : null,
        deleteOriginal: removeOriginFile,
      ),
    );
  }

  @Deprecated('Use saveFile. Will be removed in 4.0.0.')
  Future<String?> saveFileToFolderExt(
    String filePath, {
    bool removeOriginFile = false,
  }) {
    return _legacy(() => saveFile(filePath, deleteOriginal: removeOriginFile));
  }

  @Deprecated('Use saveFile with folderName. Will be removed in 4.0.0.')
  Future<String?> saveFileIntoCustomDir({
    required String filePath,
    required String dirNamed,
    bool removeOriginFile = false,
  }) {
    return _legacy(
      () => saveFile(
        filePath,
        folderName: dirNamed,
        deleteOriginal: removeOriginFile,
      ),
    );
  }

  @Deprecated('Use saveFromUrl. Will be removed in 4.0.0.')
  Future<String?> saveFileFromUrl(String url) {
    return _legacy(() => saveFromUrl(url));
  }

  @Deprecated('Use openAppSettings(). Will be removed in 4.0.0.')
  Future<bool?> get openSetting => openAppSettings();

  Future<String?> _legacy(Future<SavedFile> Function() save) async {
    try {
      final saved = await save();
      return saved.path ?? saved.uri;
    } on FolderFileSaverException {
      return null;
    }
  }
}
