import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class FolderFileSaver {
  static const MethodChannel _channel =
      const MethodChannel('folder_file_saver');

  static Future<int> getPermission() async {
    return await _channel.invokeMethod('getPermission');
  }

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

  static Future<String> saveFileToFolderExt(String filePath) async {
    assert(filePath != null);
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('filePath', () => filePath);
    final result = await _channel.invokeMethod('saveFileToFolderExt', args);
    return result;
  }

  static Future<void> get openSetting async {
    final openSetting = await _channel.invokeMethod('openSetting');
    return openSetting;
  }
}
