import 'package:flutter_test/flutter_test.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:folder_file_saver/folder_file_saver_platform_interface.dart';
import 'package:folder_file_saver/folder_file_saver_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFolderFileSaverPlatform
    with MockPlatformInterfaceMixin
    implements FolderFileSaverPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> saveFileFromUrl(String url) {
    // TODO: implement saveFileFromUrl
    throw UnimplementedError();
  }

  @override
  // TODO: implement openSetting
  Future<bool?> get openSetting => throw UnimplementedError();

  @override
  Future<String?> saveFileIntoCustomDir(
      {required String filePath,
      required String dirNamed,
      bool removeOriginFile = false}) {
    // TODO: implement saveFileIntoCustomDir
    throw UnimplementedError();
  }

  @override
  Future<String?> saveFileToFolderExt(String filePath,
      {bool removeOriginFile = false}) {
    // TODO: implement saveFileToFolderExt
    throw UnimplementedError();
  }

  @override
  Future<String?> saveImage(
      {required String pathImage,
      int width = 0,
      int height = 0,
      bool removeOriginFile = false}) {
    // TODO: implement saveImage
    throw UnimplementedError();
  }
}

void main() {
  final FolderFileSaverPlatform initialPlatform =
      FolderFileSaverPlatform.instance;

  test('$MethodChannelFolderFileSaver is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFolderFileSaver>());
  });

  test('getPlatformVersion', () async {
    FolderFileSaver folderFileSaverPlugin = FolderFileSaver();
    MockFolderFileSaverPlatform fakePlatform = MockFolderFileSaverPlatform();
    FolderFileSaverPlatform.instance = fakePlatform;

    expect(await folderFileSaverPlugin.getPlatformVersion(), '42');
  });
}
