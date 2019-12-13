import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:folder_file_saver/folder_file_saver.dart';

void main() {
  const MethodChannel channel = MethodChannel('folder_file_saver');

  // setUp(() {
  //   channel.setMockMethodCallHandler((MethodCall methodCall) async {
  //     return '42';
  //   });
  // });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  // test('getPlatformVersion', () async {
  //   expect(await FolderFileSaver.platformVersion, '42');
  // });
}
