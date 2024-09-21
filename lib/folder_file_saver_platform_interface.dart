import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'folder_file_saver_method_channel.dart';

abstract class FolderFileSaverPlatform extends PlatformInterface {
  FolderFileSaverPlatform() : super(token: _token);

  static final Object _token = Object();

  static FolderFileSaverPlatform _instance = MethodChannelFolderFileSaver();

  static FolderFileSaverPlatform get instance => _instance;

  static set instance(FolderFileSaverPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> saveFileFromUrl(String url) {
    throw UnimplementedError('saveFileFromUrl() has not been implemented.');
  }

  Future<String?> saveImage({
    required String pathImage,
    int width = 0,
    int height = 0,
    bool removeOriginFile = false,
  }) {
    throw UnimplementedError('saveImage() has not been implemented.');
  }

  Future<String?> saveFileToFolderExt(
    String filePath, {
    bool removeOriginFile = false,
  }) {
    throw UnimplementedError('saveFileToFolderExt() has not been implemented.');
  }

  Future<String?> saveFileIntoCustomDir({
    required String filePath,
    required String dirNamed,
    bool removeOriginFile = false,
  }) {
    throw UnimplementedError(
        'saveFileIntoCustomDir() has not been implemented.');
  }

  Future<bool?> get openSetting async {
    throw UnimplementedError('openSetting() has not been implemented.');
  }
}
