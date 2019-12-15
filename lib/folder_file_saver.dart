import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class FolderFileSaver {
  static const MethodChannel _channel =
      const MethodChannel('folder_file_saver');

  /// if you want to check permission status
  /// return 0 permission is PERMISSION_GRANTED
  /// return 1 permission is PERMISSION_IS_DENIED
  /// return 2 permission is PERMISSION_IS_DENIED with c
  /// if return 1 required permission
  /// if return 2 open settings of the app
  /// else permission is granted and ready to download
  static Future<int> getPermission() async {
    return await _channel.invokeMethod('getPermission');
  }

  /// if you want to get original of Image
  /// don't give a value of width or height
  /// cause default is return width = 0, height = 0
  /// which will make it to get the original image
  static Future<String> saveImage({
    @required String pathImage,
    int width = 0,
    int height = 0,
  }) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('pathImage', () => pathImage.toLowerCase());
    args.putIfAbsent('width', () => width);
    args.putIfAbsent('height', () => height);
    final result = await _channel.invokeMethod('saveImage', args);
    return result;
  }

  /// type is jpg, jpeg, png = your_app_name/your_app_name Pictures
  /// type mp4 = your_app_name/your_app_name Videos
  /// type mp3 = your_app_name/your_app_name Musics
  /// type m4a = your_app_name/your_app_name Audios
  /// any type extension = your_app_name/your_app_name Documents
  static Future<String> saveFileToFolderExt(String filePath) async {
    assert(filePath != null);
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('filePath', () => filePath);
    final result = await _channel.invokeMethod('saveFileToFolderExt', args);
    return result;
  }

  /// Open settings Device
  static Future<bool> get openSetting async {
    final openSet = await _channel.invokeMethod('openSetting');
    return openSet;
  }
}
