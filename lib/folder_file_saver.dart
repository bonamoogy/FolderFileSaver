import 'folder_file_saver_platform_interface.dart';

class FolderFileSaver {
  Future<String?> getPlatformVersion() {
    return FolderFileSaverPlatform.instance.getPlatformVersion();
  }

  /// Saves an image to local storage with optional resizing
  ///
  /// Params:
  /// - [pathImage]: The path of the image file to be saved (required).
  /// - [width]: Desired width of the saved image (default is 0 for original width).
  /// - [height]: Desired height of the saved image (default is 0 for original height).
  /// - [removeOriginFile]: If true, the original file will be deleted after saving (default is false).
  Future<String?> saveImage({
    required String pathImage,
    int width = 0,
    int height = 0,
    bool removeOriginFile = false,
  }) async {
    final result = await FolderFileSaverPlatform.instance.saveImage(
      pathImage: pathImage,
      width: width,
      height: height,
      removeOriginFile: removeOriginFile,
    );

    return result;
  }

  /// Saves a file to an external folder
  ///
  /// Params:
  /// - [filePath]: The path of the file to be saved to the external folder (required).
  /// - [removeOriginFile]: If true, the original file will be deleted after saving (default is false).
  Future<String?> saveFileToFolderExt(
    String filePath, {
    bool removeOriginFile = false,
  }) async {
    final result = await FolderFileSaverPlatform.instance.saveFileToFolderExt(
      filePath,
      removeOriginFile: removeOriginFile,
    );

    return result;
  }

  /// Saves a file into a custom directory with a specified name
  ///
  /// Params:
  /// - [filePath]: The path of the file to be saved (required).
  /// - [dirNamed]: The name of the custom directory where the file will be saved (required).
  /// - [removeOriginFile]: If true, the original file will be deleted after saving (default is false).
  Future<String?> saveFileIntoCustomDir({
    required String filePath,
    required String dirNamed,
    bool removeOriginFile = false,
  }) async {
    final result = await FolderFileSaverPlatform.instance.saveFileIntoCustomDir(
      filePath: filePath,
      dirNamed: dirNamed,
      removeOriginFile: removeOriginFile,
    );

    return result;
  }

  /// Saves a file from a given URL to local storage
  ///
  /// Params:
  /// - [url]: The URL of the file to be saved.
  Future<String?> saveFileFromUrl(String url) async {
    final result = await FolderFileSaverPlatform.instance.saveFileFromUrl(url);
    return result;
  }

  /// Opens the app settings, for example, to manage permissions
  Future<bool?> get openSetting async {
    return FolderFileSaverPlatform.instance.openSetting;
  }
}
