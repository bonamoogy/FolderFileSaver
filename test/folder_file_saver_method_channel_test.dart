import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:folder_file_saver/folder_file_saver_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelFolderFileSaver();
  const channel = MethodChannel('folder_file_saver');
  final calls = <MethodCall>[];

  /// What the fake native side replies to save calls.
  Object? Function(MethodCall call) reply = (_) => null;

  setUp(() {
    calls.clear();
    reply = (_) => {
          'name': 'a.png',
          'path': '/storage/emulated/0/Pictures/App Pictures/a.png',
          'uri': 'content://media/external/images/media/1',
          'location': 'pictures',
        };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('arguments sent to the native side', () {
    test('saveFile', () async {
      await platform.saveFile(
        filePath: '/tmp/a.png',
        folderName: 'Wallpapers',
        deleteOriginal: true,
      );

      expect(calls.single.method, 'saveFile');
      expect(calls.single.arguments, {
        'filePath': '/tmp/a.png',
        'folderName': 'Wallpapers',
        'deleteOriginal': true,
      });
    });

    test('saveResizedImage', () async {
      await platform.saveResizedImage(imagePath: '/tmp/a.png', width: 100);

      expect(calls.single.method, 'saveResizedImage');
      expect(calls.single.arguments, {
        'imagePath': '/tmp/a.png',
        'width': 100,
        'height': null,
        'folderName': null,
        'deleteOriginal': false,
      });
    });

    test('saveFromUrl', () async {
      await platform.saveFromUrl(
        url: 'https://example.com/a.png',
        fileName: 'b',
        headers: {'Authorization': 'Bearer token'},
      );

      expect(calls.single.method, 'saveFromUrl');
      expect(calls.single.arguments, {
        'url': 'https://example.com/a.png',
        'fileName': 'b',
        'folderName': null,
        'headers': {'Authorization': 'Bearer token'},
      });
    });
  });

  test('a successful save returns a SavedFile', () async {
    final saved = await platform.saveFile(filePath: '/tmp/a.png');

    expect(saved.name, 'a.png');
    expect(saved.path, '/storage/emulated/0/Pictures/App Pictures/a.png');
    expect(saved.uri, 'content://media/external/images/media/1');
    expect(saved.location, SaveLocation.pictures);
  });

  test('an iOS Photos save has no path', () async {
    reply = (_) =>
        {'name': 'a.png', 'uri': 'ph://ABC/L0/001', 'location': 'photos'};

    final saved = await platform.saveFile(filePath: '/tmp/a.png');

    expect(saved.path, isNull);
    expect(saved.location, SaveLocation.photos);
  });

  test('a native error becomes a FolderFileSaverException', () async {
    reply = (_) => throw PlatformException(
          code: 'PERMISSION_DENIED',
          message: 'Photos access was denied',
        );

    await expectLater(
      platform.saveFile(filePath: '/tmp/a.png'),
      throwsA(
        isA<FolderFileSaverException>()
            .having((e) => e.code, 'code',
                FolderFileSaverErrorCode.permissionDenied)
            .having((e) => e.message, 'message', 'Photos access was denied'),
      ),
    );
  });

  test('an unknown error code maps to unknown', () async {
    reply = (_) => throw PlatformException(code: 'SOMETHING_NEW');

    await expectLater(
      platform.saveFromUrl(url: 'https://example.com'),
      throwsA(
        isA<FolderFileSaverException>()
            .having((e) => e.code, 'code', FolderFileSaverErrorCode.unknown),
      ),
    );
  });

  test('openAppSettings', () async {
    reply = (_) => true;
    expect(await platform.openAppSettings(), isTrue);
    expect(calls.single.method, 'openAppSettings');
  });

  test('getPlatformVersion', () async {
    reply = (_) => '42';
    expect(await platform.getPlatformVersion(), '42');
  });
}
