/// Names of the methods on the `folder_file_saver` method channel.
///
/// Must match `Constant.kt` on Android and `FolderFileSaverPlugin.swift` on iOS.
abstract final class MethodNames {
  static const channel = 'folder_file_saver';

  static const saveFile = 'saveFile';
  static const saveResizedImage = 'saveResizedImage';
  static const saveFromUrl = 'saveFromUrl';
  static const openAppSettings = 'openAppSettings';
  static const getPlatformVersion = 'getPlatformVersion';
}
