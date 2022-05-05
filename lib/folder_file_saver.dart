import 'dart:async';
import 'package:flutter/services.dart';

const CHANNELNAME = 'folder_file_saver';

class FolderFileSaver {
  static const MethodChannel _channel = const MethodChannel(CHANNELNAME);

  /// if you want to get original of Image
  /// don't give a value of [width] and [height]
  /// cause default is return [width] = 0, [height} = 0
  /// which will make it to get the original image
  /// remove origin file [removeOriginFile] default false
  static Future<String?> saveImage({
    required String pathImage,
    int width = 0,
    int height = 0,
    bool removeOriginFile = false,
  }) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('pathImage', () => pathImage.toLowerCase());
    args.putIfAbsent('width', () => width);
    args.putIfAbsent('height', () => height);
    args.putIfAbsent('removeOriginFile', () => removeOriginFile);
    return _channel.invokeMethod('saveImage', args);
  }

  /// type is jpg, jpeg, png = your_app_name/your_app_name Pictures
  /// type mp4 = your_app_name/your_app_name Videos
  /// type mp3 = your_app_name/your_app_name Musics
  /// type m4a = your_app_name/your_app_name Audios
  /// any type extension = your_app_name/your_app_name Documents
  /// your path [filePath]
  /// remove origin file [removeOriginFile] default false
  static Future<String?> saveFileToFolderExt(
    String filePath, {
    bool removeOriginFile = false,
  }) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('filePath', () => filePath);
    args.putIfAbsent('removeOriginFile', () => removeOriginFile);
    return _channel.invokeMethod('saveFileToFolderExt', args);
  }

  /// save into custom directory under App name
  static Future<String?> saveFileIntoCustomDir({
    required String filePath,
    required String dirNamed,
    bool removeOriginFile = false,
  }) {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('dirNamed', () => dirNamed);
    args.putIfAbsent('filePath', () => filePath);
    args.putIfAbsent('removeOriginFile', () => removeOriginFile);
    return _channel.invokeMethod('saveFileCustomDir', args);
  }

  /// Open settings Device
  static Future<bool?> get openSetting async {
    return _channel.invokeMethod('openSetting');
  }
}
