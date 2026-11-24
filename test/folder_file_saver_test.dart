// The deprecated API is tested on purpose.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_test/flutter_test.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:folder_file_saver/folder_file_saver_method_channel.dart';
import 'package:folder_file_saver/folder_file_saver_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Records calls and returns canned results, or throws [error] if set.
class FakeFolderFileSaverPlatform extends FolderFileSaverPlatform
    with MockPlatformInterfaceMixin {
  final calls = <String>[];
  FolderFileSaverException? error;

  static const saved = SavedFile(
    name: 'a.png',
    path: '/saved/a.png',
    uri: 'file:///saved/a.png',
    location: SaveLocation.pictures,
  );

  Future<SavedFile> _result(String call) async {
    calls.add(call);
    if (error != null) throw error!;
    return saved;
  }

  @override
  Future<String?> getPlatformVersion() async => '42';

  @override
  Future<SavedFile> saveFile({
    required String filePath,
    String? folderName,
    bool deleteOriginal = false,
  }) =>
      _result('saveFile($filePath, $folderName, $deleteOriginal)');

  @override
  Future<SavedFile> saveResizedImage({
    required String imagePath,
    int? width,
    int? height,
    String? folderName,
    bool deleteOriginal = false,
  }) =>
      _result('saveResizedImage($imagePath, $width, $height, $deleteOriginal)');

  @override
  Future<SavedFile> saveFromUrl({
    required String url,
    String? fileName,
    String? folderName,
    Map<String, String>? headers,
  }) =>
      _result('saveFromUrl($url)');

  @override
  Future<bool> openAppSettings() async {
    calls.add('openAppSettings');
    return true;
  }
}

void main() {
  test('MethodChannelFolderFileSaver is the default instance', () {
    expect(
      FolderFileSaverPlatform.instance,
      isInstanceOf<MethodChannelFolderFileSaver>(),
    );
  });

  group('FolderFileSaver', () {
    const saver = FolderFileSaver();
    late FakeFolderFileSaverPlatform fake;

    setUp(() {
      fake = FakeFolderFileSaverPlatform();
      FolderFileSaverPlatform.instance = fake;
    });

    test('saveFile passes its options through', () async {
      final saved = await saver.saveFile(
        '/tmp/a.png',
        folderName: 'Wallpapers',
        deleteOriginal: true,
      );

      expect(saved, same(FakeFolderFileSaverPlatform.saved));
      expect(fake.calls, ['saveFile(/tmp/a.png, Wallpapers, true)']);
    });

    test('saveResizedImage needs a width or height', () {
      expect(() => saver.saveResizedImage('/tmp/a.png'), throwsArgumentError);
      expect(
        () => saver.saveResizedImage('/tmp/a.png', width: 0, height: -1),
        throwsArgumentError,
      );
      expect(fake.calls, isEmpty);
    });

    test('saveResizedImage with only a width', () async {
      await saver.saveResizedImage('/tmp/a.png', width: 300);
      expect(fake.calls, ['saveResizedImage(/tmp/a.png, 300, null, false)']);
    });

    test('openAppSettings', () async {
      expect(await saver.openAppSettings(), isTrue);
    });

    test('errors are thrown as FolderFileSaverException', () {
      fake.error = const FolderFileSaverException(
        FolderFileSaverErrorCode.fileNotFound,
        'File not found',
      );
      expect(
        saver.saveFile('/missing.png'),
        throwsA(isA<FolderFileSaverException>()),
      );
    });
  });

  group('deprecated API', () {
    const saver = FolderFileSaver();
    late FakeFolderFileSaverPlatform fake;

    setUp(() {
      fake = FakeFolderFileSaverPlatform();
      FolderFileSaverPlatform.instance = fake;
    });

    test('saveImage without a size saves the file as-is', () async {
      expect(await saver.saveImage(pathImage: '/tmp/a.png'), '/saved/a.png');
      expect(fake.calls, ['saveFile(/tmp/a.png, null, false)']);
    });

    test('saveImage with a size resizes', () async {
      await saver.saveImage(pathImage: '/tmp/a.png', width: 100);
      expect(fake.calls, ['saveResizedImage(/tmp/a.png, 100, null, false)']);
    });

    test('saveFileToFolderExt and saveFileIntoCustomDir map to saveFile',
        () async {
      await saver.saveFileToFolderExt('/tmp/a.mp4', removeOriginFile: true);
      await saver.saveFileIntoCustomDir(filePath: '/tmp/b.png', dirNamed: 'X');
      expect(fake.calls, [
        'saveFile(/tmp/a.mp4, null, true)',
        'saveFile(/tmp/b.png, X, false)',
      ]);
    });

    test('saveFileFromUrl returns the path', () async {
      expect(
          await saver.saveFileFromUrl('https://a.com/a.png'), '/saved/a.png');
    });

    test('failures still return null instead of throwing', () async {
      fake.error = const FolderFileSaverException(
        FolderFileSaverErrorCode.downloadFailed,
        'HTTP 404',
      );
      expect(await saver.saveFileFromUrl('https://a.com/missing.png'), isNull);
    });

    test('openSetting', () async {
      expect(await saver.openSetting, isTrue);
    });
  });
}
