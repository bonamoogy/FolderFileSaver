import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folder_file_saver/folder_file_saver_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelFolderFileSaver();
  const channel = MethodChannel('folder_file_saver');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      calls.add(methodCall);
      return switch (methodCall.method) {
        'getPlatformVersion' => '42',
        'openSetting' => true,
        _ => '/storage/emulated/0/Pictures/App Pictures/a.png',
      };
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('saveImage sends path, size and removeOriginFile', () async {
    final result = await platform.saveImage(
      pathImage: '/tmp/a.png',
      width: 100,
      height: 50,
      removeOriginFile: true,
    );

    expect(result, '/storage/emulated/0/Pictures/App Pictures/a.png');
    expect(calls.single.method, 'saveImage');
    expect(calls.single.arguments, {
      'pathImage': '/tmp/a.png',
      'width': 100,
      'height': 50,
      'removeOriginFile': true,
    });
  });

  test('saveFileToFolderExt defaults removeOriginFile to false', () async {
    await platform.saveFileToFolderExt('/tmp/a.mp4');

    expect(calls.single.method, 'saveFileToFolderExt');
    expect(calls.single.arguments, {
      'filePath': '/tmp/a.mp4',
      'removeOriginFile': false,
    });
  });

  test('saveFileIntoCustomDir sends the directory name', () async {
    await platform.saveFileIntoCustomDir(
      filePath: '/tmp/a.png',
      dirNamed: 'My Dir',
    );

    expect(calls.single.method, 'saveFileCustomDir');
    expect(calls.single.arguments, {
      'dirNamed': 'My Dir',
      'filePath': '/tmp/a.png',
      'removeOriginFile': false,
    });
  });

  test('saveFileFromUrl sends the url', () async {
    await platform.saveFileFromUrl('https://example.com/a.png');

    expect(calls.single.method, 'saveFileFromUrl');
    expect(calls.single.arguments, {'url': 'https://example.com/a.png'});
  });

  test('openSetting', () async {
    expect(await platform.openSetting, isTrue);
    expect(calls.single.method, 'openSetting');
  });
}
