import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folder_file_saver/folder_file_saver_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFolderFileSaver platform = MethodChannelFolderFileSaver();
  const MethodChannel channel = MethodChannel('folder_file_saver');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
