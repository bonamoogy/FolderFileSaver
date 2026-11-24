import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'folder_file_saver_platform_interface.dart';
import 'src/folder_file_saver_exception.dart';
import 'src/method_names.dart';
import 'src/saved_file.dart';

/// The default [FolderFileSaverPlatform], which talks to the native side
/// over a [MethodChannel].
class MethodChannelFolderFileSaver extends FolderFileSaverPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel(MethodNames.channel);

  @override
  Future<String?> getPlatformVersion() {
    return methodChannel.invokeMethod<String>(MethodNames.getPlatformVersion);
  }

  @override
  Future<SavedFile> saveFile({
    required String filePath,
    String? folderName,
    bool deleteOriginal = false,
  }) {
    return _save(MethodNames.saveFile, {
      'filePath': filePath,
      'folderName': folderName,
      'deleteOriginal': deleteOriginal,
    });
  }

  @override
  Future<SavedFile> saveResizedImage({
    required String imagePath,
    int? width,
    int? height,
    String? folderName,
    bool deleteOriginal = false,
  }) {
    return _save(MethodNames.saveResizedImage, {
      'imagePath': imagePath,
      'width': width,
      'height': height,
      'folderName': folderName,
      'deleteOriginal': deleteOriginal,
    });
  }

  @override
  Future<SavedFile> saveFromUrl({
    required String url,
    String? fileName,
    String? folderName,
    Map<String, String>? headers,
  }) {
    return _save(MethodNames.saveFromUrl, {
      'url': url,
      'fileName': fileName,
      'folderName': folderName,
      'headers': headers,
    });
  }

  @override
  Future<bool> openAppSettings() async {
    final opened =
        await methodChannel.invokeMethod<bool>(MethodNames.openAppSettings);
    return opened ?? false;
  }

  /// Calls [method] and turns its reply into a [SavedFile], or its error
  /// into a [FolderFileSaverException].
  Future<SavedFile> _save(String method, Map<String, Object?> arguments) async {
    try {
      final result = await methodChannel.invokeMapMethod<Object?, Object?>(
          method, arguments);
      if (result == null) {
        throw FolderFileSaverException(
          FolderFileSaverErrorCode.unknown,
          '$method returned no result',
        );
      }
      return SavedFile.fromMap(result);
    } on PlatformException catch (e) {
      throw FolderFileSaverException.fromPlatformException(e);
    }
  }
}
