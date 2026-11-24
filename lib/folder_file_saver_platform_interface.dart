import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'folder_file_saver_method_channel.dart';
import 'src/saved_file.dart';

/// The interface each platform implementation of folder_file_saver extends.
///
/// App code should use `FolderFileSaver` instead of calling this directly.
abstract class FolderFileSaverPlatform extends PlatformInterface {
  FolderFileSaverPlatform() : super(token: _token);

  static final Object _token = Object();

  static FolderFileSaverPlatform _instance = MethodChannelFolderFileSaver();

  /// The implementation in use. Defaults to [MethodChannelFolderFileSaver].
  static FolderFileSaverPlatform get instance => _instance;

  static set instance(FolderFileSaverPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<SavedFile> saveFile({
    required String filePath,
    String? folderName,
    bool deleteOriginal = false,
  }) {
    throw UnimplementedError('saveFile() has not been implemented.');
  }

  Future<SavedFile> saveResizedImage({
    required String imagePath,
    int? width,
    int? height,
    String? folderName,
    bool deleteOriginal = false,
  }) {
    throw UnimplementedError('saveResizedImage() has not been implemented.');
  }

  Future<SavedFile> saveFromUrl({
    required String url,
    String? fileName,
    String? folderName,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError('saveFromUrl() has not been implemented.');
  }

  Future<bool> openAppSettings() {
    throw UnimplementedError('openAppSettings() has not been implemented.');
  }
}
