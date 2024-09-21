import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'folder_file_saver_platform_interface.dart';
import 'utils/constant.dart';

class MethodChannelFolderFileSaver extends FolderFileSaverPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('folder_file_saver');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>(Constant.getPlatformVersion);
    return version;
  }

  @override
  Future<String?> saveFileFromUrl(String url) {
    final args = {'url': url};
    return methodChannel.invokeMethod<String>(Constant.saveFileFromUrl, args);
  }

  @override
  Future<String?> saveImage(
      {required String pathImage,
      int width = 0,
      int height = 0,
      bool removeOriginFile = false}) {
    final args = {
      'pathImage': pathImage,
      'width': width,
      'height': height,
      'removeOriginFile': removeOriginFile,
    };
    return methodChannel.invokeMethod<String>(Constant.saveImage, args);
  }

  @override
  Future<String?> saveFileToFolderExt(
    String filePath, {
    bool removeOriginFile = false,
  }) {
    final args = {
      'filePath': filePath,
      'removeOriginFile': removeOriginFile,
    };
    return methodChannel.invokeMethod<String>(
        Constant.saveFileToFolderExt, args);
  }

  @override
  Future<String?> saveFileIntoCustomDir(
      {required String filePath,
      required String dirNamed,
      bool removeOriginFile = false}) {
    final args = {
      'dirNamed': dirNamed,
      'filePath': filePath,
      'removeOriginFile': removeOriginFile,
    };
    return methodChannel.invokeMethod<String>(Constant.saveFileCustomDir, args);
  }

  @override
  Future<bool?> get openSetting async {
    return methodChannel.invokeMethod<bool?>(Constant.openSetting);
  }
}
